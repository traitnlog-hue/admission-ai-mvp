import csv
import io
from datetime import date

REQUIRED_COLUMNS = {
    "year", "university", "department", "track_key", "admission_type", "grade_70_cut",
    "caution", "source_url", "source_title", "verified_at",
}
TRACKS = {"school_record", "student_record", "csat", "essay"}
NUMBERS = {"recruitment_count": int, "grade_50_cut": float, "grade_70_cut": float,
           "competition_rate": float, "additional_acceptance_rate": float}


def parse_official_csv(content: str) -> list[dict]:
    rows = list(csv.DictReader(io.StringIO(content)))
    if not rows:
        raise ValueError("CSV에 데이터 행이 없습니다.")
    missing = REQUIRED_COLUMNS - set(rows[0])
    if missing:
        raise ValueError(f"필수 열이 없습니다: {', '.join(sorted(missing))}")
    output = []
    for row_number, raw in enumerate(rows, start=2):
        try:
            year = int(raw["year"])
            if year not in (2027, 2028):
                raise ValueError("year는 2027 또는 2028이어야 합니다")
            if raw["track_key"] not in TRACKS:
                raise ValueError("track_key가 올바르지 않습니다")
            if not raw["source_url"].startswith("https://"):
                raise ValueError("source_url은 https URL이어야 합니다")
            date.fromisoformat(raw["verified_at"])
            item = {"year": year, "university": raw["university"].strip(), "department": raw["department"].strip(),
                    "track_key": raw["track_key"].strip(), "admission_type": raw["admission_type"].strip(),
                    "caution": raw["caution"].strip(), "source_url": raw["source_url"].strip(),
                    "source_title": raw["source_title"].strip(), "verified_at": raw["verified_at"].strip(),
                    "csat_minimum": raw.get("csat_minimum", "").strip() or None,
                    "interview": raw.get("interview", "false").lower() == "true",
                    "essay": raw.get("essay", "false").lower() == "true", "data_status": "verified"}
            if not all([item["university"], item["department"], item["admission_type"], item["caution"], item["source_title"]]):
                raise ValueError("텍스트 필수값이 비어 있습니다")
            for column, converter in NUMBERS.items():
                value = raw.get(column, "").strip()
                item[column] = converter(value) if value else None
            if item["grade_70_cut"] is None or not 1 <= item["grade_70_cut"] <= 9:
                raise ValueError("grade_70_cut은 1~9 사이여야 합니다")
            output.append(item)
        except (TypeError, ValueError) as error:
            raise ValueError(f"{row_number}행: {error}") from error
    return output
