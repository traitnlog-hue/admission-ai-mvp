"""교육부·시도교육청 공개 CSV에서 서울의 정상 운영 보습·외국어 학원만 추천 형식으로 변환한다."""
import csv
import sys
from pathlib import Path


def tags(field: str, category: str) -> str:
    text = f"{field} {category}"
    result = []
    if "외국어" in text:
        result.append("영어")
    if any(word in text for word in ("입시", "보습", "보통교과")):
        result.extend(["수학", "국어", "과학", "학생부·입시"])
    return "|".join(dict.fromkeys(result))


def main(source_name: str) -> None:
    source = Path(source_name)
    destination = Path(__file__).resolve().parents[1] / "backend" / "data" / "academies.free.csv"
    with source.open(encoding="cp949", newline="") as source_file:
        reader = csv.DictReader(source_file)
        rows = []
        for row in reader:
            field = row.get("분야명", "")
            category = row.get("교습계열명", "")
            subject_tags = tags(field, category)
            if row.get("시도교육청명") != "서울특별시교육청" or row.get("등록상태명") not in ("개원", "정상") or not subject_tags:
                continue
            rows.append({
                "name": row["학원명"], "region": f"서울 {row['행정구역명']}", "address": row["도로명주소"] or row["도로명상세주소"],
                "subjects": subject_tags, "grades": "중1|중2|중3|고1|고2|고3",
                "levels": "기초부터 다시|개념은 안정적, 심화 보완 필요|상위권 심화·실전 중심",
                "registration_status": "정상", "source_url": "https://open.neis.go.kr/portal/data/service/selectServicePage.do?page=1&rows=10&sortColumn=&sortDirection=&infId=OPEN19220231012134453534385&infSeq=1",
                "verified_at": row.get("수정일자", ""),
            })
    with destination.open("w", encoding="utf-8", newline="") as destination_file:
        writer = csv.DictWriter(destination_file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"{len(rows)} academies written to {destination}")


if __name__ == "__main__":
    main(sys.argv[1])
