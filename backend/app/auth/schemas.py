from datetime import datetime

from pydantic import BaseModel


class LoginRequest(BaseModel):
    organization_slug: str
    org_password: str
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: int
    organization_id: int
    name: str
    email: str
    role: str
    role_id: int
    phone: str | None = None
    avatar_url: str | None = None
    is_active: bool
    created_at: datetime


class RegisterRequest(BaseModel):
    organization_slug: str
    name: str
    email: str
    password: str
    phone: str | None = None


class VerificationRequiredResponse(BaseModel):
    verification_required: bool = True
    organization_slug: str
    email: str
    message: str


class VerifyOtpRequest(BaseModel):
    organization_slug: str
    email: str
    code: str


class ResendOtpRequest(BaseModel):
    organization_slug: str
    email: str
