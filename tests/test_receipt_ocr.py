from backend.app.receipt_ocr import _extract_fields


def test_extracts_receipt_candidates() -> None:
    academy, receipt_number, amount, paid_at = _extract_fields(
        """가치수학학원
        승인번호: A123-4567
        결제일시 2026.08.20
        결제 금액 280,000원
        """
    )

    assert academy == "가치수학학원"
    assert receipt_number == "A123-4567"
    assert amount == "280000"
    assert paid_at == "2026-08-20"


def test_ignores_out_of_range_amount() -> None:
    _, _, amount, _ = _extract_fields("승인금액 10원")

    assert amount is None
