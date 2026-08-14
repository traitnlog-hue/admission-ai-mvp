"""무료 공공데이터 CSV 기반 학원 매칭. 제휴·광고 순위는 사용하지 않는다."""
import csv
from pathlib import Path

DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "academies.free.csv"


def recommendations(region: str, grade: str, subjects: list[str], level: str) -> list[dict]:
    if not DATA_PATH.exists():
        return []
    with DATA_PATH.open(encoding="utf-8-sig") as source:
        rows = list(csv.DictReader(source))
    matches = []
    for row in rows:
        if row.get("registration_status") != "정상":
            continue
        academy_subjects = set(row.get("subjects", "").split("|"))
        academy_grades = set(row.get("grades", "").split("|"))
        academy_levels = set(row.get("levels", "").split("|"))
        score = (50 if row.get("region") == region else 0) + 25 * len(academy_subjects & set(subjects)) + (15 if grade in academy_grades else 0) + (10 if level in academy_levels else 0)
        if score:
            matches.append({"name": row["name"], "region": row["region"], "address": row["address"], "subjects": list(academy_subjects), "score": min(score, 100), "source_url": row["source_url"], "verified_at": row["verified_at"]})
    return sorted(matches, key=lambda item: item["score"], reverse=True)[:10]
