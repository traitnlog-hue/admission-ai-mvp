"""Toss Payments order preparation and server-side confirmation for GACHI."""

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from fastapi import HTTPException


CATALOG = {
    "컨설턴트 매칭 상담": 9900,
    "고교선택·고입 전략 컨설팅": 39000,
    "특목·자사 1% 자소서·면접 컨설팅": 79000,
    "1% 관리형 컨설팅": 99000,
    "입시전략 분석 리포트": 49000,
    "생기부 전략 컨설팅": 69000,
    "수시 컨설팅": 79000,
    "결과 후 보완 컨설팅": 39000,
    "정시 컨설팅": 79000,
}


def _secret() -> bytes:
    value = os.getenv("TOSS_ORDER_SIGNING_SECRET") or os.getenv("TOSS_PAYMENTS_SECRET_KEY")
    if not value:
        raise HTTPException(status_code=503, detail="토스페이먼츠 서버 키가 아직 설정되지 않았습니다.")
    return value.encode()


def _encode(payload: dict) -> str:
    raw = base64.urlsafe_b64encode(json.dumps(payload, separators=(",", ":")).encode()).rstrip(b"=")
    signature = hmac.new(_secret(), raw, hashlib.sha256).digest()
    return f"{raw.decode()}.{base64.urlsafe_b64encode(signature).rstrip(b'=').decode()}"


def _decode(token: str) -> dict:
    try:
        payload, signature = token.split(".", 1)
        raw = payload.encode()
        expected = hmac.new(_secret(), raw, hashlib.sha256).digest()
        supplied = base64.urlsafe_b64decode(signature + "=" * (-len(signature) % 4))
        if not hmac.compare_digest(expected, supplied):
            raise ValueError
        order = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if order["expires_at"] < time.time():
            raise HTTPException(status_code=400, detail="결제 가능 시간이 만료되었습니다. 다시 주문해 주세요.")
        return order
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=400, detail="결제 주문 검증에 실패했습니다.") from error


def prepare_order(items: list[str]) -> dict:
    if not items or len(items) > 10 or any(item not in CATALOG for item in items):
        raise HTTPException(status_code=422, detail="결제 프로그램을 다시 확인해 주세요.")
    amount = sum(CATALOG[item] for item in items)
    name = items[0] if len(items) == 1 else f"{items[0]} 외 {len(items) - 1}건"
    order = {
        "order_id": f"GACHI-{secrets.token_urlsafe(18)}",
        "order_name": name[:100],
        "amount": amount,
        "expires_at": int(time.time()) + 600,
    }
    return {**order, "order_token": _encode(order)}


def confirm_order(payment_key: str, order_id: str, amount: int, order_token: str) -> dict:
    order = _decode(order_token)
    if order["order_id"] != order_id or order["amount"] != amount:
        raise HTTPException(status_code=400, detail="주문 금액 검증에 실패했습니다.")
    encoded = base64.b64encode(f"{_secret().decode()}:".encode()).decode()
    request = Request(
        "https://api.tosspayments.com/v1/payments/confirm",
        data=json.dumps({"paymentKey": payment_key, "orderId": order_id, "amount": amount}).encode(),
        headers={"Authorization": f"Basic {encoded}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=15) as response:
            return json.loads(response.read())
    except HTTPError as error:
        detail = json.loads(error.read() or b"{}")
        raise HTTPException(status_code=error.code, detail=detail.get("message", "결제 승인에 실패했습니다.")) from error
