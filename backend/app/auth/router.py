from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.auth.otp import (
    MAX_ATTEMPTS,
    build_otp_record,
    generate_otp,
    otp_expired,
    otp_matches,
)
from app.auth.schemas import (
    LoginRequest,
    RegisterRequest,
    ResendOtpRequest,
    TokenResponse,
    UserResponse,
    VerificationRequiredResponse,
    VerifyOtpRequest,
)
from app.auth.utils import create_access_token, hash_password, verify_password
from app.email import send_otp_email
from app.dependencies import DbSession
from app.models import Organization, Role, User

router = APIRouter(prefix="/auth", tags=["auth"])

VERIFY_MESSAGE = "Enter the 6-digit verification code we emailed you."


def _user_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        organization_id=user.organization_id,
        name=user.name,
        email=user.email,
        role=user.role,
        role_id=user.role_id,
        phone=user.phone,
        avatar_url=user.avatar_url,
        is_active=user.is_active,
        created_at=user.created_at,
    )


def _is_verified(user: User) -> bool:
    # Users created before this feature have no "verified" key and are
    # treated as already verified (grandfathered).
    return user.preferences.get("verified", True)


def _set_prefs(user: User, **changes) -> None:
    # Reassign a new dict so SQLAlchemy detects the JSONB change.
    prefs = dict(user.preferences)
    prefs.update(changes)
    user.preferences = prefs


def _clear_otp(user: User) -> None:
    prefs = dict(user.preferences)
    prefs.pop("otp", None)
    user.preferences = prefs


def _issue_and_send_otp(user: User, db: DbSession) -> None:
    # Send before committing so a send failure rolls the whole request back
    # (no half-created account, no stranded OTP record).
    code = generate_otp()
    _set_prefs(user, otp=build_otp_record(code))
    send_otp_email(user.email, user.name, code)
    db.commit()


def _require_org(db: DbSession, slug: str) -> Organization:
    org = db.query(Organization).filter(Organization.slug == slug).first()
    if not org:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid organization slug",
        )
    return org


def _find_user(db: DbSession, org_id: int, email: str) -> User | None:
    return (
        db.query(User)
        .filter(User.organization_id == org_id, User.email == email)
        .first()
    )


@router.post("/login", response_model=TokenResponse | VerificationRequiredResponse)
def login(body: LoginRequest, db: DbSession = None):
    org = _require_org(db, body.organization_slug)
    if not verify_password(body.org_password, org.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid organization password",
        )
    user = _find_user(db, org.id, body.email)
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive",
        )
    if not _is_verified(user):
        _issue_and_send_otp(user, db)
        return VerificationRequiredResponse(
            organization_slug=org.slug, email=user.email, message=VERIFY_MESSAGE
        )
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    token = create_access_token(user.id, user.organization_id)
    return TokenResponse(access_token=token, user=_user_response(user))


@router.post(
    "/register",
    response_model=VerificationRequiredResponse,
    status_code=201,
)
def register(body: RegisterRequest, db: DbSession = None):
    org = (
        db.query(Organization)
        .filter(Organization.slug == body.organization_slug)
        .first()
    )
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found",
        )
    if _find_user(db, org.id, body.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered in this organization",
        )
    employee_role = db.query(Role).filter(Role.name == "employee").first()
    if not employee_role:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Default role not found. Seed the database first.",
        )
    user = User(
        organization_id=org.id,
        name=body.name,
        email=body.email,
        password_hash=hash_password(body.password),
        role_id=employee_role.id,
        role="employee",
        phone=body.phone,
        is_active=True,
        preferences={"verified": False},
    )
    db.add(user)
    db.flush()
    _issue_and_send_otp(user, db)
    return VerificationRequiredResponse(
        organization_slug=org.slug, email=user.email, message=VERIFY_MESSAGE
    )


@router.post("/verify-otp", response_model=TokenResponse)
def verify_otp(body: VerifyOtpRequest, db: DbSession = None):
    org = _require_org(db, body.organization_slug)
    user = _find_user(db, org.id, body.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    if _is_verified(user):
        # Already verified — just log them in is not possible without a
        # password, so this is a client error.
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account is already verified. Please sign in.",
        )
    record = user.preferences.get("otp")
    if not record:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No verification code is pending. Request a new one.",
        )
    if record["attempts"] >= MAX_ATTEMPTS:
        _clear_otp(user)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many incorrect attempts. Request a new code.",
        )
    if otp_expired(record):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code has expired. Request a new one.",
        )
    if not otp_matches(record, body.code):
        record = dict(record)
        record["attempts"] += 1
        _set_prefs(user, otp=record)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect verification code.",
        )
    _clear_otp(user)
    _set_prefs(user, verified=True)
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    token = create_access_token(user.id, user.organization_id)
    return TokenResponse(access_token=token, user=_user_response(user))


@router.post("/resend-otp", response_model=VerificationRequiredResponse)
def resend_otp(body: ResendOtpRequest, db: DbSession = None):
    org = _require_org(db, body.organization_slug)
    user = _find_user(db, org.id, body.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    if _is_verified(user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account is already verified. Please sign in.",
        )
    _issue_and_send_otp(user, db)
    return VerificationRequiredResponse(
        organization_slug=org.slug, email=user.email, message=VERIFY_MESSAGE
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return _user_response(current_user)
