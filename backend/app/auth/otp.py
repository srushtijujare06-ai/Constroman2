"""One-time-password generation and verification.

The pending OTP for an unverified user is stored inside the user's existing
`preferences` JSONB column under the "otp" key, so no schema migration is
needed. The code itself is stored hashed (never in plaintext).
"""

import secrets
from datetime import datetime, timedelta, timezone

from app.auth.utils import hash_password, verify_password
from app.config import get_settings

settings = get_settings()

MAX_ATTEMPTS = 5


def generate_otp() -> str:
    """A 6-digit numeric code, zero-padded."""
    return f"{secrets.randbelow(1_000_000):06d}"


def build_otp_record(code: str) -> dict:
    expires = datetime.now(timezone.utc) + timedelta(
        minutes=settings.otp_expiry_minutes
    )
    return {
        "hash": hash_password(code),
        "expires_at": expires.isoformat(),
        "attempts": 0,
    }


def otp_expired(record: dict) -> bool:
    return datetime.now(timezone.utc) > datetime.fromisoformat(record["expires_at"])


def otp_matches(record: dict, code: str) -> bool:
    return verify_password(code, record["hash"])
