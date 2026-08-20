from pathlib import Path

import os
from typing import Optional

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .database import admissions_for_year, initialize, upsert_admissions
from .academies import recommendations
from .auth import initialize_auth, login, logout, register, user_for_token
from .engine import analyze
from .importer import parse_official_csv
from .official_data import import_reviewed_admissions, sources as official_sources
from .models import AiAdmissionAnalysis, AnalysisResult, PaymentConfirmRequest, PaymentPrepareRequest, ReceiptOcrRequest, ReceiptOcrResult, StudentProfile
from .payments import confirm_order, prepare_order
from .receipt_ocr import scan_receipt
from .vertex_ai import generate_ai_analysis

ROOT_DIR = Path(__file__).resolve().parents[2]
FRONTEND_DIR = ROOT_DIR / "frontend"

app = FastAPI(title="진로입시 AI API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:7357",
        "http://127.0.0.1:7357",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:7397",
        "http://127.0.0.1:7397",
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)


@app.on_event("startup")
def setup_data_store() -> None:
    initialize()
    initialize_auth()


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


def _bearer_token(authorization: Optional[str]) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    return authorization.removeprefix("Bearer ").strip()


@app.post("/api/auth/register", status_code=201)
async def register_account(request: Request) -> dict:
    data = await request.json()
    try:
        return register(
            str(data.get("email", "")),
            str(data.get("password", "")),
            str(data.get("name", "")),
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/api/auth/login")
async def login_account(request: Request) -> dict:
    data = await request.json()
    result = login(str(data.get("email", "")), str(data.get("password", "")))
    if result is None:
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다.")
    return result


@app.get("/api/auth/me")
def current_account(authorization: Optional[str] = Header(default=None)) -> dict:
    account = user_for_token(_bearer_token(authorization))
    if account is None:
        raise HTTPException(status_code=401, detail="세션이 만료되었습니다. 다시 로그인해 주세요.")
    return {"user": account}


@app.post("/api/auth/logout", status_code=204)
def logout_account(authorization: Optional[str] = Header(default=None)) -> None:
    logout(_bearer_token(authorization))


@app.post("/api/identity/start")
def start_identity_verification(authorization: Optional[str] = Header(default=None)) -> dict:
    account = user_for_token(_bearer_token(authorization))
    if account is None:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    verification_url = os.getenv("IDENTITY_VERIFICATION_URL", "").strip()
    if not verification_url:
        raise HTTPException(
            status_code=503,
            detail="실명인증 사업자 연동 정보가 아직 설정되지 않았습니다.",
        )
    return {"verification_url": verification_url}


@app.get("/api/admissions/{year}")
def list_admissions(year: int) -> dict:
    """데이터 운영 화면이 사용할 전형 목록. sample/verified 상태를 함께 반환한다."""
    if year not in (2027, 2028):
        return {"items": [], "notice": "지원하는 입시연도는 2027, 2028입니다."}
    return {"items": admissions_for_year(year), "notice": "verified 데이터만 실제 컨설팅 판단에 사용하세요."}


@app.get("/api/official-data/sources")
def list_official_sources() -> dict:
    """서비스에서 사용하는 교육부·대교협·대학 공식 출처와 검수 이력을 공개한다."""
    return {
        "items": official_sources(),
        "notice": "전형 데이터는 원문 출처·확인일·검수 상태를 함께 표시합니다. 모집요강 정정 공지는 원문을 우선합니다.",
    }


@app.post("/api/academy-recommendations")
async def academy_recommendations(request: Request) -> dict:
    """공공데이터 CSV에서만 추천하며, 학생 정보는 저장하지 않는다."""
    data = await request.json()
    required = ("region", "grade", "subjects", "level")
    if not all(data.get(key) for key in required) or not isinstance(data["subjects"], list):
        raise HTTPException(status_code=422, detail="region, grade, subjects, level은 필수입니다.")
    items = recommendations(data["region"], data["grade"], data["subjects"], data["level"])
    return {"items": items, "notice": "무료 공공데이터 CSV 기반 결과입니다. 수강료·시간표·모집 상태는 상담 전 재확인하세요.", "source": "전국학원및교습소표준데이터"}


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


@app.post("/api/admin/official-sources/{source_id}/import-admissions")
async def import_official_source_admissions(
    source_id: str,
    request: Request,
    x_admin_token: Optional[str] = Header(default=None),
) -> dict:
    """검수된 CSV를 출처 ID에 연결해 반영하고, 반영 이력을 남긴다."""
    expected_token = os.getenv("ADMIN_API_TOKEN")
    if not expected_token or x_admin_token != expected_token:
        raise HTTPException(status_code=403, detail="관리자 토큰이 필요합니다.")
    try:
        imported = import_reviewed_admissions(
            source_id,
            (await request.body()).decode("utf-8-sig"),
        )
    except (UnicodeDecodeError, ValueError) as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    return {
        "imported": imported,
        "source_id": source_id,
        "data_status": "verified",
        "notice": "출처와 반영 이력이 기록되었습니다.",
    }


@app.post("/api/analyze", response_model=AnalysisResult)
def admission_analysis(profile: StudentProfile) -> AnalysisResult:
    """규칙 기반 분석 결과를 반환한다. 합격선은 생성하거나 추론하지 않는다."""
    return analyze(profile)


@app.post("/api/receipt-ocr", response_model=ReceiptOcrResult)
def receipt_ocr(request: ReceiptOcrRequest) -> ReceiptOcrResult:
    """영수증 사진에서 입력 보조 필드만 추출하며, 원본 파일은 저장하지 않는다."""
    return scan_receipt(request)


@app.post("/api/payments/prepare")
def payment_prepare(request: PaymentPrepareRequest) -> dict:
    """Server-calculated and signed Toss Payments order. Never trust client totals."""
    return prepare_order(request.items)


@app.post("/api/payments/confirm")
def payment_confirm(request: PaymentConfirmRequest) -> dict:
    """Confirms Toss authentication only after matching the server-signed order."""
    return confirm_order(request.payment_key, request.order_id, request.amount, request.order_token)


@app.post("/api/ai-admission-analysis", response_model=AiAdmissionAnalysis)
def ai_admission_analysis(
    profile: StudentProfile,
    authorization: Optional[str] = Header(default=None),
) -> AiAdmissionAnalysis:
    """로그인 회원만 사용할 수 있는 Vertex AI 입시 코칭 보조 API."""
    account = user_for_token(_bearer_token(authorization))
    if account is None:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    return generate_ai_analysis(profile, str(account["email"]))


app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="web")
