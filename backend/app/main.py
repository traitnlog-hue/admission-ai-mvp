from pathlib import Path

import os
from typing import Optional

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .database import admissions_for_year, initialize, upsert_admissions
from .engine import analyze
from .importer import parse_official_csv
from .models import AnalysisResult, StudentProfile

ROOT_DIR = Path(__file__).resolve().parents[2]
FRONTEND_DIR = ROOT_DIR / "frontend"

app = FastAPI(title="진로입시 AI API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8000", "http://127.0.0.1:8000"],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)


@app.on_event("startup")
def setup_data_store() -> None:
    initialize()


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/admissions/{year}")
def list_admissions(year: int) -> dict:
    """데이터 운영 화면이 사용할 전형 목록. sample/verified 상태를 함께 반환한다."""
    if year not in (2027, 2028):
        return {"items": [], "notice": "지원하는 입시연도는 2027, 2028입니다."}
    return {"items": admissions_for_year(year), "notice": "verified 데이터만 실제 컨설팅 판단에 사용하세요."}


@app.post("/api/admin/import-admissions")
async def import_admissions(request: Request, x_admin_token: Optional[str] = Header(default=None)) -> dict:
    """공식 출처가 명시된 CSV만 upsert한다. 배포 전에는 ADMIN_API_TOKEN을 반드시 설정한다."""
    expected_token = os.getenv("ADMIN_API_TOKEN")
    if not expected_token or x_admin_token != expected_token:
        raise HTTPException(status_code=403, detail="관리자 토큰이 필요합니다.")
    try:
        records = parse_official_csv((await request.body()).decode("utf-8-sig"))
    except (UnicodeDecodeError, ValueError) as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    upsert_admissions(records)
    return {"imported": len(records), "data_status": "verified"}


@app.post("/api/analyze", response_model=AnalysisResult)
def admission_analysis(profile: StudentProfile) -> AnalysisResult:
    """규칙 기반 분석 결과를 반환한다. 합격선은 생성하거나 추론하지 않는다."""
    return analyze(profile)


app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="web")
