"""로그인 회원용 GACHI AI 대화 API.

모델은 한국 입시 준비를 돕는 정보 정리·학습 코칭 보조로만 사용한다.
합격 여부, 합격선, 특정 기관의 우열처럼 검증할 수 없는 판단은 생성하지 않는다.
"""

from __future__ import annotations

import json
import os
from collections import defaultdict
from datetime import date
from threading import Lock
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from fastapi import HTTPException

from .models import AiChatMessage


class _DailyChatGuard:
    """크레딧 보호를 위한 보수적 MVP 요청 제한.

    Cloud Run max-instances=1과 함께 사용한다. 운영 전환 시에는 Redis 또는
    데이터베이스 기반의 전역 카운터로 교체해야 한다.
    """

    def __init__(self) -> None:
        self._counts: dict[tuple[str, str], int] = defaultdict(int)
        self._lock = Lock()

    def reserve(self, account_key: str) -> None:
        if os.getenv("GACHI_AI_CHAT_ENABLED", "false").lower() != "true":
            raise HTTPException(status_code=503, detail="AI 대화 서비스의 운영 설정이 아직 완료되지 않았습니다.")

        per_user = int(os.getenv("GACHI_AI_CHAT_DAILY_LIMIT", "10"))
        global_limit = int(os.getenv("GACHI_AI_CHAT_GLOBAL_DAILY_LIMIT", "100"))
        today = date.today().isoformat()
        user_key = (today, account_key)
        global_key = (today, "__all__")
        with self._lock:
            if self._counts[user_key] >= per_user:
                raise HTTPException(status_code=429, detail=f"오늘의 AI 대화 횟수({per_user}회)를 모두 사용했습니다. 내일 다시 이용해 주세요.")
            if self._counts[global_key] >= global_limit:
                raise HTTPException(status_code=429, detail="오늘의 AI 대화 제공 한도에 도달했습니다. 내일 다시 이용해 주세요.")
            self._counts[user_key] += 1
            self._counts[global_key] += 1


_chat_guard = _DailyChatGuard()


def verified_supabase_user(access_token: str) -> dict:
    """Supabase Auth가 발급한 현재 세션을 서버에서 다시 확인한다."""

    supabase_url = os.getenv("SUPABASE_URL", "").rstrip("/")
    publishable_key = os.getenv("SUPABASE_PUBLISHABLE_KEY", "")
    if not supabase_url or not publishable_key:
        raise HTTPException(status_code=503, detail="AI 대화 인증 설정이 비어 있습니다.")
    if not access_token:
        raise HTTPException(status_code=401, detail="로그인 후 AI 코치를 이용할 수 있습니다.")

    request = Request(
        f"{supabase_url}/auth/v1/user",
        headers={
            "apikey": publishable_key,
            "Authorization": f"Bearer {access_token}",
        },
        method="GET",
    )
    try:
        with urlopen(request, timeout=8) as response:
            user = json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        raise HTTPException(status_code=401, detail="로그인 세션을 확인하지 못했습니다. 다시 로그인해 주세요.") from error

    if not isinstance(user, dict) or not user.get("id"):
        raise HTTPException(status_code=401, detail="로그인 세션을 확인하지 못했습니다. 다시 로그인해 주세요.")
    return user


def _conversation(messages: list[AiChatMessage]) -> str:
    lines = []
    for message in messages:
        speaker = "사용자" if message.role == "user" else "AI"
        lines.append(f"{speaker}: {message.content}")
    return "\n".join(lines)


def generate_ai_chat(messages: list[AiChatMessage], account_key: str) -> str:
    """Vertex AI Gemini가 짧은 대화형 학습 코칭 문장을 반환한다."""

    _chat_guard.reserve(account_key)
    project = os.getenv("GOOGLE_CLOUD_PROJECT", "").strip()
    if not project:
        raise HTTPException(status_code=503, detail="AI 대화 서버 프로젝트 설정이 비어 있습니다.")

    prompt = f"""당신은 GACHI의 한국 교육·입시 준비 AI 코치입니다.
아래 대화에 이어 한국어로 답하세요. 450자 이내로, 공감 한 문장과 바로 할 수 있는 다음 행동 1~3개를 제안하세요.

안전 규칙:
- 합격 여부·합격 확률·합격선·특정 대학 합격 가능성을 단정하거나 추정하지 마세요.
- 특정 대학, 학원, 강사의 우열·순위를 매기거나 추천하지 마세요.
- 최신 모집요강·전형 정보는 교육부, 대교협, 대학 입학처의 해당 학년도 공식 원문을 확인하도록 안내하세요.
- 사용자가 제공하지 않은 성적·학생부·개인정보를 만들어 내지 마세요.
- 개인 식별 정보, 비밀번호, 연락처, 주민등록번호는 요청하지 마세요.
- 질문이 불명확하면 학년, 목표, 현재 고민 중 필요한 한 가지만 짧게 물어보세요.

대화:
{_conversation(messages)}
"""
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
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.35,
                max_output_tokens=420,
            ),
        )
        reply = (response.text or "").strip()
        if not reply:
            raise ValueError("empty model response")
        return reply[:900]
    except HTTPException:
        raise
    except Exception as error:
        # 공급자/권한 정보 등 내부 오류는 사용자에게 노출하지 않는다.
        raise HTTPException(status_code=503, detail="AI 코치가 일시적으로 답변을 준비하지 못했습니다. 잠시 후 다시 시도해 주세요.") from error
