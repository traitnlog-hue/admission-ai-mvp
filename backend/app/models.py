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
