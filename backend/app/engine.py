from __future__ import annotations

from .database import admissions_for_year
from .models import AnalysisResult, Recommendation, Score, StudentProfile, TrackScore

MAJOR_PROFILES = {
    "컴퓨터": {"keywords": ["알고리즘", "프로그래밍", "코딩", "데이터", "정보", "소프트웨어", "ai", "인공지능", "수학"], "core": ["math", "science"], "label": "컴퓨터·소프트웨어"},
    "공학": {"keywords": ["설계", "실험", "제작", "수학", "물리", "과학", "코딩", "탐구"], "core": ["math", "science"], "label": "공학"},
    "의학": {"keywords": ["생명", "의료", "보건", "인체", "화학", "봉사", "과학"], "core": ["science", "english"], "label": "의·보건"},
    "간호": {"keywords": ["생명", "의료", "보건", "인체", "봉사", "건강", "과학"], "core": ["science", "english"], "label": "간호·보건"},
    "경영": {"keywords": ["경제", "경영", "시장", "통계", "데이터", "창업", "사회", "수학"], "core": ["math", "social"], "label": "경영·경제"},
    "교육": {"keywords": ["교육", "수업", "학습", "멘토링", "봉사", "심리", "국어"], "core": ["korean", "social"], "label": "교육"},
    "디자인": {"keywords": ["디자인", "시각", "제작", "기획", "콘텐츠", "예술", "창작"], "core": ["korean", "social"], "label": "디자인·예술"},
}
DEFAULT_PROFILE = {"keywords": ["탐구", "분석", "발표", "프로젝트", "기획", "자료"], "core": ["korean", "social"], "label": "희망 전공"}
TRACK_LABELS = {"school_record": "학생부교과", "student_record": "학생부종합", "csat": "정시", "essay": "논술"}


def _average(values: list[float | None]) -> float:
    actual = [value for value in values if value is not None]
    return sum(actual) / len(actual)


def _grade_to_score(grade: float) -> int:
    return round(max(0, min(100, 112.5 - grade * 12.5)))


def _profile(major: str) -> dict:
    return next((item for keyword, item in MAJOR_PROFILES.items() if keyword in major), DEFAULT_PROFILE)


def _decision(student_score: int, cut_70: float) -> str:
    # 샘플 데이터의 70%컷(낮을수록 유리)을 전략용 등급 점수로 변환한다.
    cut_score = _grade_to_score(cut_70)
    difference = student_score - cut_score
    if difference >= 14:
        return "매우 안정"
    if difference >= 7:
        return "안정"
    if difference >= -3:
        return "적정"
    if difference >= -11:
        return "상향"
    return "매우 상향"


def _sample_recommendations(profile: StudentProfile, track_scores: dict[str, int]) -> list[Recommendation]:
    items = []
    for admission in admissions_for_year(profile.admission_year):
        if admission["grade_70_cut"] is None:
            continue
        target_score = track_scores[admission["track_key"]]
        decision = _decision(target_score, admission["grade_70_cut"])
        items.append(Recommendation(
            university=admission["university"],
            department=admission["department"],
            track=TRACK_LABELS[admission["track_key"]],
            admission_type=admission["admission_type"],
            decision=decision,
            reasons=[
                f"{TRACK_LABELS[admission['track_key']]} 전략 점수 {target_score}점",
                f"{'공식 검증' if admission['data_status'] == 'verified' else '테스트'} 전년도 70%컷 {admission['grade_70_cut']}등급",
            ],
            caution=admission["caution"],
            is_sample_data=admission["data_status"] != "verified",
        ))
    order = {"매우 상향": 0, "상향": 1, "적정": 2, "안정": 3, "매우 안정": 4}
    return sorted(items, key=lambda item: order[item.decision])


def analyze(profile: StudentProfile) -> AnalysisResult:
    major_profile = _profile(profile.major)
    school = profile.school_grades
    mock = profile.mock_grades
    school_average = _average([school.korean, school.math, school.english, school.social, school.science])
    mock_average = _average([mock.korean, mock.math, mock.english, mock.inquiry])
    academic = _grade_to_score(school_average)
    csat = _grade_to_score(mock_average)
    core_average = _average([getattr(school, subject) for subject in major_profile["core"]])
    core = _grade_to_score(core_average)
    text = profile.record_text.lower()
    keyword_hits = sum(1 for keyword in major_profile["keywords"] if keyword in text)
    record = min(95, round(48 + keyword_hits * 8 + min(len(text) / 40, 16)))
    course_choice = round(core * 0.68 + record * 0.32)
    track_scores = {
        "school_record": round(academic * 0.73 + core * 0.27),
        "student_record": round(academic * 0.32 + record * 0.43 + course_choice * 0.25),
        "csat": round(csat * 0.82 + core * 0.18),
        "essay": round(csat * 0.46 + academic * 0.27 + core * 0.27),
    }
    ordered_tracks = sorted(track_scores.items(), key=lambda item: item[1], reverse=True)
    first_key, first_score = ordered_tracks[0]
    second_key, second_score = ordered_tracks[1]
    risks = []
    risks.append(
        "수능최저가 있는 전형은 목표 등급과 실제 모의고사 추세를 별도로 점검하세요."
        if mock_average > 2.3 else "수능 경쟁력이 강점입니다. 수시 지원 시에도 수능최저 충족 가능성을 유지하세요."
    )
    risks.append(
        f"학생부에서 {major_profile['label']} 관련 탐구의 과정·결과·확장성을 더 구체적으로 남겨야 합니다."
        if record < 70 else "학생부에 전공 연결 키워드가 확인됩니다. 후속 탐구로 깊이와 일관성을 강화하세요."
    )
    risks.append(
        "전공 핵심교과 성적이 전체 평균보다 약합니다. 다음 시험의 우선 보완 과목으로 설정하세요."
        if core_average > school_average + 0.25 else "전공 핵심교과 성취가 안정적입니다. 세특에서 성취 근거를 연결하세요."
    )
    first_label = TRACK_LABELS[first_key]
    primary_reason = {
        "csat": "모의고사 경쟁력이 내신 대비 높거나 안정적이어서 수능 실전 성과를 전략의 중심에 둘 수 있습니다.",
        "student_record": "전공 연계 활동과 기록의 맥락이 강점입니다. 탐구의 깊이를 이어가세요.",
        "school_record": "내신 평균과 핵심교과 성취가 안정적입니다. 대학별 반영 교과·수능최저를 확인하세요.",
        "essay": "교과 성취와 수능 역량의 균형이 좋습니다. 기출 풀이와 논증 훈련이 필요합니다.",
    }[first_key]
    return AnalysisResult(
        admission_year=profile.admission_year,
        major=profile.major,
        scores=[Score(label="학업역량", value=academic), Score(label="수능역량", value=csat), Score(label="과목선택", value=course_choice), Score(label="학생부역량", value=record)],
        track_scores=[TrackScore(key=key, label=TRACK_LABELS[key], value=value) for key, value in ordered_tracks],
        primary_strategy=f"{first_label} 중심 전략",
        primary_reason=primary_reason,
        secondary_strategy=f"{TRACK_LABELS[second_key]} 병행 전략",
        secondary_reason=f"{TRACK_LABELS[second_key]} 적합도 {second_score}점으로 보조 지원축을 만들 수 있습니다.",
        risks=risks,
        action_plan=f"이번 달은 {'모의고사 취약 과목의 오답 원인 정리와 주간 보완' if mock_average > school_average else '내신 핵심교과의 다음 시험 목표 등급 설정'}, 다음 세특에는 {profile.major} 관련 탐구를 ‘질문–과정–결과’로 남기세요.",
        report={
            "overall": f"학업 {academic} · 수능 {csat} · 학생부 {record}점. {first_label} 경로가 현재 우세합니다.",
            "grades": f"내신 평균 {school_average:.1f}등급. {major_profile['label']} 핵심교과는 {core}점입니다.",
            "record": f"전공 연결 키워드 {keyword_hits}개가 확인됩니다. 활동 간 후속 질문을 준비하세요." if keyword_hits else "전공 관련 탐구의 문제의식·방법·결과를 세특에 구체적으로 남기세요.",
            "major": f"{profile.major} 기준 핵심교과와 학생부 연결성은 {course_choice}점입니다.",
            "track": " · ".join(f"{TRACK_LABELS[key]} {value}" for key, value in ordered_tracks),
            "risk": risks[0],
        },
        recommendations=_sample_recommendations(profile, track_scores),
        disclaimer="현재 대학 추천은 가상 테스트 데이터입니다. 실제 지원 판단에는 해당 학년도 대학 공식 모집요강·전형별 환산식·입시결과를 검증한 DB가 필요합니다.",
    )
