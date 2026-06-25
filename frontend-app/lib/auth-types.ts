export type User = {
  id: number
  organization_id: number
  name: string
  email: string
  email_verified: boolean
  role: string
  role_id: number
  phone: string | null
  avatar_url: string | null
  is_active: boolean
  created_at: string
}

export type LoginRequest = {
  organization_slug: string
  org_password: string
  email: string
  password: string
  role?: string
}

export type TokenResponse = {
  access_token: string
  token_type: string
  user: User
}

export type RegisterRequest = {
  organization_slug: string
  email: string
  otp: string
  name: string
  password: string
  phone?: string
}

export type VerificationRequiredResponse = {
  verification_required: true
  organization_slug: string
  email: string
  message: string
}

export type VerifyOtpRequest = {
  organization_slug: string
  email: string
  code: string
}

export type ResendOtpRequest = {
  organization_slug: string
  email: string
}

export function isVerificationRequired(
  res: TokenResponse | VerificationRequiredResponse
): res is VerificationRequiredResponse {
  return "verification_required" in res
}
