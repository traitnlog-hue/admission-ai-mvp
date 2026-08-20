"""Cloud Vision 기반 영수증 OCR.

원본 이미지는 Vision API 호출에만 사용하며 파일·OCR 전문을 저장하지 않는다.
금액, 결제일, 승인번호는 보조 입력값이므로 최종 제출 전 사용자가 반드시 확인한다.
"""

from __future__ import annotations

import base64
import os
import re
from collections import defaultdict
from datetime import date
from threading import Lock

from fastapi import HTTPException

from .models import ReceiptOcrRequest, ReceiptOcrResult


class _OcrUsageGuard:
    """무료 할당량보다 낮게 시작하는 MVP용 보호 장치.

    단일 인스턴스 배포 기준이다. 운영 단계에는 영속 저장소 기반 카운터로 교체한다.
    """

    def __init__(self) -> None:
        self._counts: dict[tuple[str, str], int] = defaultdict(int)
        self._lock = Lock()

    def reserve(self) -> None:
        if os.getenv("GACHI_RECEIPT_OCR_ENABLED", "false").lower() != "true":
            raise HTTPException(status_code=503, detail="영수증 OCR 서버 설정이 아직 완료되지 않았습니다.")
        today = date.today().isoformat()
        month = today[:7]
        daily_limit = int(os.getenv("GACHI_OCR_DAILY_LIMIT", "10"))
        monthly_limit = int(os.getenv("GACHI_OCR_MONTHLY_LIMIT", "500"))
        with self._lock:
            if self._counts[("day", today)] >= daily_limit:
                raise HTTPException(status_code=429, detail="오늘의 영수증 자동 입력 횟수를 모두 사용했습니다.")
            if self._counts[("month", month)] >= monthly_limit:
                raise HTTPException(status_code=429, detail="이번 달 영수증 자동 입력 한도에 도달했습니다.")
            self._counts[("day", today)] += 1
            self._counts[("month", month)] += 1


_usage_guard = _OcrUsageGuard()


def _clean_amount(value: str) -> str | None:
    digits = value.replace(",", "").replace(" ", "")
    amount = int(digits) if digits.isdigit() else 0
    return str(amount) if 100 <= amount <= 100_000_000 else None


def _extract_fields(text: str) -> tuple[str | None, str | None, str | None, str | None]:
    compact = "\n".join(line.strip() for line in text.splitlines() if line.strip())
    amount = None
    for pattern in (
        r"(?:승인\s*금액|결제\s*금액|합계|총\s*액|거래\s*금액)\D{0,16}([0-9][0-9, ]{2,})",
        r"([0-9][0-9,]{2,})\s*(?:원|KRW)",
    ):
        match = re.search(pattern, compact, re.IGNORECASE)
        if match:
            amount = _clean_amount(match.group(1))
            if amount:
                break

    paid_at = None
    date_match = re.search(r"(20\d{2})[./년\-\s]+(1[0-2]|0?[1-9])[./월\-\s]+(3[01]|[12]\d|0?[1-9])", compact)
    if date_match:
        paid_at = f"{date_match.group(1)}-{int(date_match.group(2)):02d}-{int(date_match.group(3)):02d}"

    receipt_number = None
    number_match = re.search(
        r"(?:승인\s*(?:번호|No)?|거래\s*번호|영수\s*번호)[^A-Z0-9]{0,12}([A-Z0-9][A-Z0-9\-]{3,})",
        compact,
        re.IGNORECASE,
    )
    if number_match:
        receipt_number = number_match.group(1).upper()

    academy = None
    skip = ("영수", "카드", "승인", "결제", "매출", "사업자", "부가", "합계", "가맹", "전화", "번호")
    for line in compact.splitlines()[:8]:
        if len(line) >= 2 and not any(word in line for word in skip) and not re.search(r"\d{4}[-./]\d", line):
            academy = line[:80]
            break
    return academy, receipt_number, amount, paid_at


def scan_receipt(request: ReceiptOcrRequest) -> ReceiptOcrResult:
    _usage_guard.reserve()
    try:
        image_bytes = base64.b64decode(request.image_base64, validate=True)
    except ValueError as error:
        raise HTTPException(status_code=422, detail="이미지 형식을 읽을 수 없습니다.") from error
    if not image_bytes or len(image_bytes) > 5 * 1024 * 1024:
        raise HTTPException(status_code=422, detail="5MB 이하의 영수증 이미지만 스캔할 수 있습니다.")

    try:
        from google.cloud import vision

        client = vision.ImageAnnotatorClient()
        response = client.document_text_detection(
            image=vision.Image(content=image_bytes),
            image_context=vision.ImageContext(language_hints=["ko", "en"]),
        )
        if response.error.message:
            raise RuntimeError(response.error.message)
        extracted = response.full_text_annotation.text or ""
        if not extracted.strip():
            raise HTTPException(status_code=422, detail="글자를 찾지 못했습니다. 밝고 선명한 영수증 사진을 올려 주세요.")
        academy, receipt_number, amount, paid_at = _extract_fields(extracted)
        return ReceiptOcrResult(
            academy=academy,
            receipt_number=receipt_number,
            amount=amount,
            paid_at=paid_at,
            notice="자동 입력 결과는 영수증 원본과 대조한 뒤 수정해 주세요. 이미지는 서버에 저장하지 않습니다.",
        )
    except HTTPException:
        raise
    except ImportError as error:
        raise HTTPException(status_code=503, detail="OCR 모듈 설치가 필요합니다.") from error
    except Exception as error:
        raise HTTPException(status_code=503, detail="영수증을 읽지 못했습니다. 직접 입력하거나 잠시 후 다시 시도해 주세요.") from error
