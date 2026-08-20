from __future__ import annotations

from typing import Dict, List, Literal, Optional

from pydantic import BaseModel, Field, field_validator


class Grades(BaseModel):
    korean: float = Field(ge=1, le=9)
    math: float = Field(ge=1, le=9)
    english: float = Field(ge=1, le=9)
    social: Optional[float] = Field(default=None, ge=1, le=9)
    science: Optional[float] = Field(default=None, ge=1, le=9)


class MockGrades(BaseModel):
    korean: float = Field(ge=1, le=9)
    math: float = Field(ge=1, le=9)
    english: float = Field(ge=1, le=9)
    inquiry: float = Field(ge=1, le=9)


class StudentProfile(BaseModel):
    admission_year: Literal[2027, 2028]
    grade: Literal[1, 2, 3]
    major: str = Field(min_length=1, max_length=80)
    school_grades: Grades
    mock_grades: MockGrades
    record_text: str = Field(default="", max_length=10000)
    ai_record_analysis: bool = False

    @field_validator("major")
    @classmethod
    def clean_major(cls, value: str) -> str:
        return value.strip()


class Score(BaseModel):
    label: str
    value: int = Field(ge=0, le=100)


class TrackScore(Score):
    key: str


class Recommendation(BaseModel):
    university: str
    department: str
    track: str
    admission_type: str
    decision: str
    reasons: List[str]
    caution: str
    is_sample_data: bool


class AnalysisResult(BaseModel):
    admission_year: int
    major: str
    scores: List[Score]
    track_scores: List[TrackScore]
    primary_strategy: str
    primary_reason: str
    secondary_strategy: str
    secondary_reason: str
    risks: List[str]
    action_plan: str
    report: Dict[str, str]
    recommendations: List[Recommendation]
    disclaimer: str


class AiAdmissionAnalysis(BaseModel):
    """생성 AI가 보조하는 코칭 문장. 지원 판정 데이터가 아니다."""

    summary: str = Field(min_length=1, max_length=600)
    strengths: List[str] = Field(min_length=1, max_length=3)
    focus_points: List[str] = Field(min_length=1, max_length=4)
    questions_for_consultant: List[str] = Field(min_length=1, max_length=3)
    disclaimer: str = Field(min_length=1, max_length=300)


class ReceiptOcrRequest(BaseModel):
    image_base64: str = Field(min_length=40, max_length=7_000_000)
    mime_type: Literal["image/jpeg", "image/png", "image/webp"]


class ReceiptOcrResult(BaseModel):
    academy: Optional[str] = Field(default=None, max_length=80)
    receipt_number: Optional[str] = Field(default=None, max_length=80)
    amount: Optional[str] = Field(default=None, max_length=20)
    paid_at: Optional[str] = Field(default=None, pattern=r"^20\d{2}-\d{2}-\d{2}$")
    notice: str


class PaymentPrepareRequest(BaseModel):
    items: list[str] = Field(min_length=1, max_length=10)


class PaymentConfirmRequest(BaseModel):
    payment_key: str = Field(min_length=10, max_length=300)
    order_id: str = Field(min_length=6, max_length=80)
    amount: int = Field(gt=0, le=2_000_000)
    order_token: str = Field(min_length=20, max_length=3000)
