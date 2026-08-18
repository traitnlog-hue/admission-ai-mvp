import sqlite3

import pytest

from backend.app import auth


@pytest.fixture()
def isolated_auth_db(tmp_path, monkeypatch):
    path = tmp_path / "auth.sqlite3"
    monkeypatch.setattr(auth, "AUTH_DB_PATH", path)
    return path


def test_email_registration_login_and_session(isolated_auth_db):
    registered = auth.register("student@example.com", "study2026", "김가치")

    assert registered["user"]["email"] == "student@example.com"
    assert registered["user"]["identity_verified"] is False
    assert auth.user_for_token(registered["token"])["name"] == "김가치"

    logged_in = auth.login("STUDENT@example.com", "study2026")
    assert logged_in is not None
    assert logged_in["user"]["name"] == "김가치"
    assert auth.login("student@example.com", "wrong-password") is None

    with sqlite3.connect(isolated_auth_db) as database:
        stored_hash = database.execute(
            "SELECT password_hash FROM users WHERE email = ?",
            ("student@example.com",),
        ).fetchone()[0]
    assert stored_hash != "study2026"
    assert "study2026" not in stored_hash


def test_duplicate_email_is_rejected(isolated_auth_db):
    auth.register("student@example.com", "study2026", "김가치")
    with pytest.raises(ValueError, match="이미 가입된 이메일"):
        auth.register("student@example.com", "study2027", "김가치")


def test_password_policy_requires_letters_and_numbers(isolated_auth_db):
    with pytest.raises(ValueError, match="영문과 숫자"):
        auth.register("student@example.com", "12345678", "김가치")
