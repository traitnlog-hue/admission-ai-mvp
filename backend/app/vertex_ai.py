"""Vertex AI를 이용한 제한형 입시 코칭 보조 모듈.

점수 산출과 대학/전형 추천은 ``engine.py``의 규칙과 검증된 데이터가 담당한다.
이 모듈은 그 결과를 학생이 이해하기 쉬운 학습·준비 조언으로 풀어 쓰는 데만 사용한다.
"""

from __future__ import annotations

import json
import os
from collections import defaultdict
from datetime import date
from threading import Lock

from fastapi import HTTPException

from .engine import analyze
from .models import AiAdmissionAnalysis, StudentProfile


class _DailyRequestGuard:
    """MVP의 보수적 요청 제한.

    Cloud Run 배포 시 max-instances=1과 함께 사용해 전역 한도로 동작하게 한다.
    운영 단계에서는 Redis/DB 기반 카운터로 교체해야 한다.
    """

    def __init__(self) -> None:
        self._counts: dict[tuple[str, str], int] = defaultdict(int)
        self._lock = Lock()

    def reserve(self, account_key: str) -> None:
        if os.getenv("GACHI_AI_ANALYSIS_ENABLED", "false").lower() != "true":
            raise HTTPException(status_code=503, detail="AI 입시 분석은 아직 운영 설정이 완료되지 않았습니다.")

        per_user = int(os.getenv("GACHI_AI_DAILY_LIMIT", "3"))
        global_limit = int(os.getenv("GACHI_AI_GLOBAL_DAILY_LIMIT", "20"))
        today = date.today().isoformat()
        user_key = (today, account_key)
        global_key = (today, "__all__")
        with self._lock:
            if self._counts[user_key] >= per_user:
                raise HTTPException(status_code=429, detail="오늘의 AI 입시 분석 횟수(3회)를 모두 사용했습니다.")
            if self._counts[global_key] >= global_limit:
                raise HTTPException(status_code=429, detail="오늘의 AI 분석 제공 한도에 도달했습니다. 내일 다시 시도해 주세요.")
            self._counts[user_key] += 1
            self._counts[global_key] += 1


_request_guard = _DailyRequestGuard()


def _prompt(profile: StudentProfile) -> str:
    base = analyze(profile)
    return f"""당신은 한국 입시 준비를 돕는 학습 코치입니다.
아래 학생에게 짧고 행동 가능한 코칭을 한국어 JSON으로 작성하세요.

안전 규칙:
- 합격 여부·합격 확률·합격선을 단정하거나 추정하지 마세요.
- 특정 대학·학원·강사를 추천하거나 순위를 매기지 마세요.
- 제공된 점수와 학생부 텍스트 밖의 사실을 만들어 내지 마세요.
- 실제 지원 판단은 해당 학년도 대학 공식 모집요강과 상담을 통해 확인하도록 안내하세요.
- 평가는 비난하지 말고, 이번 주에 실행 가능한 조언을 제시하세요.

학생 정보:
- 학년: 고{profile.grade}
- 지원 연도: {profile.admission_year}
- 희망 전공: {profile.major}
- 내신: 국어 {profile.school_grades.korean}, 수학 {profile.school_grades.math}, 영어 {profile.school_grades.english}, 사회 {profile.school_grades.social}, 과학 {profile.school_grades.science}
- 모의고사: 국어 {profile.mock_grades.korean}, 수학 {profile.mock_grades.math}, 영어 {profile.mock_grades.english}, 탐구 {profile.mock_grades.inquiry}
- 학생부/활동 요약: {profile.record_text[:2500] or '미입력'}
- 규칙 기반 우선 전략: {base.primary_strategy}
- 규칙 기반 보완 전략: {base.secondary_strategy}
- 규칙 기반 유의사항: {' / '.join(base.risks)}

반드시 아래 JSON 형식만 반환하세요.
{{
  "summary": "현재 상태를 2문장으로 요약",
  "strengths": ["강점 1", "강점 2"],
  "focus_points": ["이번 주 집중할 항목 1", "항목 2", "항목 3"],
  "questions_for_consultant": ["상담 시 확인할 질문 1", "질문 2"],
  "disclaimer": "공식 모집요강 확인 안내"
}}"""


def generate_ai_analysis(profile: StudentProfile, account_key: str) -> AiAdmissionAnalysis:
    """Vertex AI Gemini 호출. 서버의 ADC(Cloud Run 서비스 계정)만 사용한다."""
    _request_guard.reserve(account_key)
    project = os.getenv("GOOGLE_CLOUD_PROJECT", "").strip()
    if not project:
        raise HTTPException(status_code=503, detail="AI 분석 서버 프로젝트 설정이 비어 있습니다.")

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(
            vertexai=True,
            project=project,
            location=os.getenv("GOOGLE_CLOUD_LOCATION", "global"),
        )
        response = client.models.generate_content(
            model=os.getenv("GACHI_VERTEX_MODEL", "gemini-2.5-flash"),
            contents=_prompt(profile),
            config=types.GenerateContentConfig(
                temperature=0.2,
                max_output_tokens=700,
                response_mime_type="application/json",
            ),
        )
        payload = json.loads(response.text or "{}")
        return AiAdmissionAnalysis.model_validate(payload)
    except HTTPException:
        raise
    except (ImportError, json.JSONDecodeError, ValueError) as error:
        raise HTTPException(status_code=503, detail="AI 분석 응답을 준비하지 못했습니다. 잠시 후 다시 시도해 주세요.") from error
    except Exception as error:
        # 자격 증명/할당량/Vertex 일시 오류를 외부에 그대로 노출하지 않는다.
        raise HTTPException(status_code=503, detail="AI 분석 서비스를 일시적으로 사용할 수 없습니다.") from error
