from datetime import datetime

from pydantic import BaseModel


class SendOtpRequest(BaseModel):
    organization_slug: str
    email: str


class SendOtpResponse(BaseModel):
    message: str
    otp: str | None = None


class VerifyOtpRequest(BaseModel):
    organization_slug: str
    email: str
    otp: str


class VerifyOtpResponse(BaseModel):
    message: str


class RegisterRequest(BaseModel):
    organization_slug: str
    email: str
    otp: str
    name: str
    password: str
    phone: str | None = None


class LoginRequest(BaseModel):
    organization_slug: str
    org_password: str
    email: str
    password: str
    role: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: int
    organization_id: int
    name: str
    email: str
    email_verified: bool
    role: str
    role_id: int
    phone: str | None = None
    avatar_url: str | None = None
    is_active: bool
    created_at: datetime
