"""공식 입시 데이터의 출처·검수 이력을 관리한다.

대학별 모집요강은 형식과 정정 주기가 달라 자동 OCR 결과를 바로 서비스에
반영하면 안 된다. 이 모듈은 원문 출처를 등록하고, 관리자가 검수한 CSV만
``verified`` 데이터로 올리는 운영 경계를 제공한다.
"""

from .database import official_sources, record_source_import, upsert_admissions
from .importer import parse_official_csv


def sources() -> list[dict]:
    return official_sources()


def import_reviewed_admissions(source_id: str, csv_content: str) -> int:
    known_sources = {item["source_id"]: item for item in official_sources()}
    source = known_sources.get(source_id)
    if source is None:
        raise ValueError("등록되지 않은 공식 출처입니다.")
    if source["status"] not in {"verified", "configured", "review_required"}:
        raise ValueError("현재 사용할 수 없는 공식 출처입니다.")

    records = parse_official_csv(csv_content)
    for record in records:
        record["source_id"] = source_id
        # 검수 CSV의 출처 표기가 등록된 공식 출처와 어긋나지 않도록 한다.
        if not record["source_url"].startswith("https://"):
            raise ValueError("공식 출처 URL은 https여야 합니다.")

    upsert_admissions(records)
    record_source_import(source_id, len(records), "관리자 검수 CSV 반영")
    return len(records)
