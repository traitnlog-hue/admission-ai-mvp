"""공식 입시 데이터 저장소.

실서비스에서는 이 모듈을 PostgreSQL과 권한이 있는 관리자 화면으로 교체한다.
현재 SQLite는 로컬 MVP 검증 및 데이터 이관 포맷 검증용이다.
"""
import json
import sqlite3
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[1] / "data"
DB_PATH = DATA_DIR / "admissions.sqlite3"

SCHEMA = """
CREATE TABLE IF NOT EXISTS admissions (
  id INTEGER PRIMARY KEY,
  year INTEGER NOT NULL CHECK(year IN (2027, 2028)),
  university TEXT NOT NULL,
  department TEXT NOT NULL,
  track_key TEXT NOT NULL CHECK(track_key IN ('school_record','student_record','csat','essay')),
  admission_type TEXT NOT NULL,
  recruitment_count INTEGER,
  grade_50_cut REAL,
  grade_70_cut REAL,
  competition_rate REAL,
  additional_acceptance_rate REAL,
  csat_minimum TEXT,
  interview BOOLEAN NOT NULL DEFAULT 0,
  essay BOOLEAN NOT NULL DEFAULT 0,
  caution TEXT NOT NULL,
  source_url TEXT NOT NULL,
  source_title TEXT NOT NULL,
  verified_at TEXT,
  data_status TEXT NOT NULL CHECK(data_status IN ('sample','verified')),
  UNIQUE(year, university, department, track_key, admission_type)
);
"""


def connection() -> sqlite3.Connection:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    return db


def initialize() -> None:
    with connection() as db:
        db.executescript(SCHEMA)
        grade_column = next((row for row in db.execute("PRAGMA table_info(admissions)") if row[1] == "grade_70_cut"), None)
        if grade_column and grade_column[3]:
            # 초기 MVP의 NOT NULL 제약을 완화한다. 2027 전형은 전년도 컷이 아직 없을 수 있다.
            db.execute("ALTER TABLE admissions RENAME TO admissions_legacy")
            db.executescript(SCHEMA)
            db.execute("""INSERT INTO admissions (id, year, university, department, track_key, admission_type,
            recruitment_count, grade_50_cut, grade_70_cut, competition_rate, additional_acceptance_rate, csat_minimum,
            interview, essay, caution, source_url, source_title, verified_at, data_status)
            SELECT id, year, university, department, track_key, admission_type, recruitment_count, grade_50_cut,
            grade_70_cut, competition_rate, additional_acceptance_rate, csat_minimum, interview, essay, caution,
            source_url, source_title, verified_at, data_status FROM admissions_legacy""")
            db.execute("DROP TABLE admissions_legacy")
        count = db.execute("SELECT COUNT(*) FROM admissions").fetchone()[0]
        if not count:
            sample = json.loads((DATA_DIR / "universities.sample.json").read_text(encoding="utf-8"))["admissions"]
            for item in sample:
                result = item["previous_result"]
                db.execute(
                    """INSERT INTO admissions (year, university, department, track_key, admission_type,
                    grade_50_cut, grade_70_cut, caution, source_url, source_title, data_status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'sample')""",
                    (item["year"], item["university"], item["department"], item["track_key"], item["admission_type"],
                     result["grade_50_cut"], result["grade_70_cut"], item["caution"], "https://example.invalid/sample", "MVP 테스트 데이터"),
                )
        official = json.loads((DATA_DIR / "admissions.official.json").read_text(encoding="utf-8"))
        for item in official:
            db.execute("""INSERT OR IGNORE INTO admissions (year, university, department, track_key, admission_type,
            recruitment_count, grade_50_cut, grade_70_cut, competition_rate, additional_acceptance_rate, csat_minimum,
            interview, essay, caution, source_url, source_title, verified_at, data_status)
            VALUES (:year, :university, :department, :track_key, :admission_type, :recruitment_count, :grade_50_cut,
            :grade_70_cut, :competition_rate, :additional_acceptance_rate, :csat_minimum, :interview, :essay, :caution,
            :source_url, :source_title, :verified_at, :data_status)""", item)


def admissions_for_year(year: int) -> list[dict]:
    initialize()
    with connection() as db:
        return [dict(row) for row in db.execute("SELECT * FROM admissions WHERE year = ?", (year,))]


def upsert_admissions(items: list[dict]) -> None:
    """검증 완료된 공식 전형만 등록한다. 동일 자연키는 최신 값으로 갱신한다."""
    initialize()
    columns = ("year", "university", "department", "track_key", "admission_type", "recruitment_count",
               "grade_50_cut", "grade_70_cut", "competition_rate", "additional_acceptance_rate", "csat_minimum",
               "interview", "essay", "caution", "source_url", "source_title", "verified_at", "data_status")
    placeholders = ", ".join("?" for _ in columns)
    update_columns = ", ".join(f"{column}=excluded.{column}" for column in columns[5:])
    query = f"""INSERT INTO admissions ({', '.join(columns)}) VALUES ({placeholders})
    ON CONFLICT(year, university, department, track_key, admission_type) DO UPDATE SET {update_columns}"""
    with connection() as db:
        db.executemany(query, [tuple(item.get(column) for column in columns) for item in items])
