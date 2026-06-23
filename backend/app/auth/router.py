from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.auth.schemas import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from app.auth.utils import create_access_token, hash_password, verify_password
from app.database import get_db
from app.dependencies import DbSession
from app.models import Organization, Role, User

router = APIRouter(prefix="/auth", tags=["auth"])


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


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: DbSession = None):
    org = db.query(Organization).filter(Organization.slug == body.organization_slug).first()
    if not org:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid organization slug",
        )
    if not verify_password(body.org_password, org.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid organization password",
        )
    user = (
        db.query(User)
        .filter(
            User.organization_id == org.id,
            User.email == body.email,
        )
        .first()
    )
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
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    token = create_access_token(user.id, user.organization_id)
    return TokenResponse(access_token=token, user=_user_response(user))


@router.post("/register", response_model=TokenResponse, status_code=201)
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
    existing = (
        db.query(User)
        .filter(
            User.organization_id == org.id,
            User.email == body.email,
        )
        .first()
    )
    if existing:
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
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.id, user.organization_id)
    return TokenResponse(access_token=token, user=_user_response(user))


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return _user_response(current_user)
