"""Minimal account/session store for the GACHI MVP.

Passwords are salted and stretched with PBKDF2. Session tokens are opaque and
only their SHA-256 digest is stored. Production deployments should place this
behind HTTPS and set GACHI_AUTH_PEPPER to a deployment secret.
"""

from __future__ import annotations

import hashlib
import hmac
import os
import re
import secrets
import sqlite3
from datetime import datetime, timedelta, timezone
from pathlib import Path


AUTH_DB_PATH = Path(__file__).resolve().parents[1] / "data" / "auth.sqlite3"
PASSWORD_ITERATIONS = 310_000
SESSION_DAYS = 30
EMAIL_PATTERN = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


def _connection() -> sqlite3.Connection:
    database = sqlite3.connect(AUTH_DB_PATH)
    database.row_factory = sqlite3.Row
    return database


def initialize_auth() -> None:
    AUTH_DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with _connection() as database:
        database.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE,
              display_name TEXT NOT NULL,
              password_salt TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              identity_verified INTEGER NOT NULL DEFAULT 0,
              identity_provider TEXT,
              identity_verified_at TEXT,
              created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS auth_sessions (
              token_hash TEXT PRIMARY KEY,
              user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              expires_at TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
            """
        )


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _password_digest(password: str, salt: bytes) -> str:
    pepper = os.getenv("GACHI_AUTH_PEPPER", "").encode("utf-8")
    return hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8") + pepper, salt, PASSWORD_ITERATIONS
    ).hex()


def _public_user(row: sqlite3.Row) -> dict:
    return {
        "name": row["display_name"],
        "email": row["email"],
        "identity_verified": bool(row["identity_verified"]),
        "identity_provider": row["identity_provider"],
        "identity_verified_at": row["identity_verified_at"],
    }


def _new_session(database: sqlite3.Connection, user_id: int) -> str:
    token = secrets.token_urlsafe(40)
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    now = _now()
    database.execute(
        "INSERT INTO auth_sessions (token_hash, user_id, expires_at, created_at) VALUES (?, ?, ?, ?)",
        (token_hash, user_id, (now + timedelta(days=SESSION_DAYS)).isoformat(), now.isoformat()),
    )
    return token


def register(email: str, password: str, display_name: str) -> dict:
    initialize_auth()
    normalized_email = email.strip().lower()
    normalized_name = display_name.strip()
    if not EMAIL_PATTERN.match(normalized_email):
        raise ValueError("올바른 이메일 주소를 입력해 주세요.")
    if len(normalized_name) < 2 or len(normalized_name) > 30:
        raise ValueError("이름은 2~30자로 입력해 주세요.")
    if len(password) < 8 or not re.search(r"[A-Za-z]", password) or not re.search(r"\d", password):
        raise ValueError("비밀번호는 영문과 숫자를 포함해 8자 이상이어야 합니다.")

    salt = secrets.token_bytes(16)
    now = _now().isoformat()
    try:
        with _connection() as database:
            cursor = database.execute(
                "INSERT INTO users (email, display_name, password_salt, password_hash, created_at) VALUES (?, ?, ?, ?, ?)",
                (normalized_email, normalized_name, salt.hex(), _password_digest(password, salt), now),
            )
            token = _new_session(database, cursor.lastrowid)
            row = database.execute("SELECT * FROM users WHERE id = ?", (cursor.lastrowid,)).fetchone()
    except sqlite3.IntegrityError as error:
        raise ValueError("이미 가입된 이메일입니다.") from error
    return {"token": token, "user": _public_user(row)}


def login(email: str, password: str) -> dict | None:
    initialize_auth()
    with _connection() as database:
        row = database.execute(
            "SELECT * FROM users WHERE email = ?", (email.strip().lower(),)
        ).fetchone()
        if row is None:
            return None
        expected = _password_digest(password, bytes.fromhex(row["password_salt"]))
        if not hmac.compare_digest(expected, row["password_hash"]):
            return None
        token = _new_session(database, row["id"])
        return {"token": token, "user": _public_user(row)}


def user_for_token(token: str) -> dict | None:
    initialize_auth()
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    with _connection() as database:
        row = database.execute(
            """SELECT users.*, auth_sessions.expires_at
               FROM auth_sessions JOIN users ON users.id = auth_sessions.user_id
               WHERE auth_sessions.token_hash = ?""",
            (token_hash,),
        ).fetchone()
        if row is None:
            return None
        if datetime.fromisoformat(row["expires_at"]) <= _now():
            database.execute("DELETE FROM auth_sessions WHERE token_hash = ?", (token_hash,))
            return None
        return _public_user(row)


def logout(token: str) -> None:
    initialize_auth()
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    with _connection() as database:
        database.execute("DELETE FROM auth_sessions WHERE token_hash = ?", (token_hash,))

