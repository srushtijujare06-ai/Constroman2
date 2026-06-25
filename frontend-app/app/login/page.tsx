'use client'

import { useState, FormEvent } from "react"
import { useAuth } from "@/components/auth/AuthProvider"
import { login, register, verifyOtp, resendOtp, isVerificationRequired } from "@/lib/auth-service"
import { NotebookPen } from "lucide-react"

type Mode = "signin" | "signup"
type Step = "form" | "otp"

export default function LoginPage() {
  const { loginWithToken } = useAuth()
  const [mode, setMode] = useState<Mode>("signin")
  const [step, setStep] = useState<Step>("form")

  const [orgSlug, setOrgSlug] = useState("constroman")
  const [orgPassword, setOrgPassword] = useState("org123")
  const [name, setName] = useState("")
  const [email, setEmail] = useState("admin@constroman.com")
  const [password, setPassword] = useState("admin123")

  // OTP step state.
  const [code, setCode] = useState("")
  const [pending, setPending] = useState<{ orgSlug: string; email: string }>({ orgSlug: "", email: "" })

  const [error, setError] = useState("")
  const [info, setInfo] = useState("")
  const [submitting, setSubmitting] = useState(false)

  function startOtpStep(slug: string, mail: string, message: string) {
    setPending({ orgSlug: slug, email: mail })
    setStep("otp")
    setCode("")
    setError("")
    setInfo(message)
  }

  async function handleSignin(e: FormEvent) {
    e.preventDefault()
    setError("")
    setInfo("")
    setSubmitting(true)
    try {
      const res = await login({ organization_slug: orgSlug, org_password: orgPassword, email, password })
      if (isVerificationRequired(res)) {
        startOtpStep(res.organization_slug, res.email, res.message)
      } else {
        await loginWithToken(res.access_token)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed")
    } finally {
      setSubmitting(false)
    }
  }

  async function handleSignup(e: FormEvent) {
    e.preventDefault()
    setError("")
    setInfo("")
    setSubmitting(true)
    try {
      const res = await register({ organization_slug: orgSlug, name, email, password })
      startOtpStep(res.organization_slug, res.email, res.message)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed")
    } finally {
      setSubmitting(false)
    }
  }

  async function handleVerify(e: FormEvent) {
    e.preventDefault()
    setError("")
    setSubmitting(true)
    try {
      const res = await verifyOtp({ organization_slug: pending.orgSlug, email: pending.email, code })
      await loginWithToken(res.access_token)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Verification failed")
    } finally {
      setSubmitting(false)
    }
  }

  async function handleResend() {
    setError("")
    setInfo("")
    setSubmitting(true)
    try {
      const res = await resendOtp({ organization_slug: pending.orgSlug, email: pending.email })
      setInfo(res.message)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not resend code")
    } finally {
      setSubmitting(false)
    }
  }

  function useDemo(kind: "admin" | "employee") {
    setOrgSlug("constroman")
    setOrgPassword("org123")
    if (kind === "admin") {
      setEmail("admin@constroman.com")
      setPassword("admin123")
    } else {
      setEmail("employee@constroman.com")
      setPassword("emp123")
    }
  }

  function switchMode(next: Mode) {
    setMode(next)
    setStep("form")
    setError("")
    setInfo("")
    if (next === "signup") {
      setName("")
      setEmail("")
      setPassword("")
    }
  }

  const inputCls =
    "w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/40 focus:border-teal-500"

  return (
    <div className="min-h-screen grid lg:grid-cols-2">
      {/* Brand panel */}
      <div className="hidden lg:flex flex-col justify-between p-12 text-white bg-gradient-to-br from-slate-900 via-slate-800 to-teal-900">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-xl bg-teal-500 flex items-center justify-center">
            <NotebookPen className="w-6 h-6 text-white" />
          </div>
          <div>
            <p className="text-xl font-bold">SiteLedger</p>
            <p className="text-teal-300 text-xs">Daily Site Records</p>
          </div>
        </div>
        <div>
          <h2 className="text-3xl font-bold leading-tight">
            Every register.<br />One place. One day at a time.
          </h2>
          <p className="text-slate-300 mt-4 max-w-md">
            Record weather, labour, materials, quality and safety data each day — store it,
            search it by date, and export any sheet to PDF.
          </p>
        </div>
        <p className="text-slate-400 text-xs">Constroman Constructions Pvt Ltd</p>
      </div>

      {/* Form panel */}
      <div className="flex items-center justify-center p-6 bg-slate-50">
        <div className="w-full max-w-sm">
          <div className="lg:hidden flex items-center gap-2 mb-6 justify-center">
            <div className="w-9 h-9 rounded-lg bg-teal-500 flex items-center justify-center">
              <NotebookPen className="w-5 h-5 text-white" />
            </div>
            <span className="text-lg font-bold text-slate-800">SiteLedger</span>
          </div>

          {step === "otp" ? (
            <>
              <h1 className="text-2xl font-bold text-slate-800">Verify your email</h1>
              <p className="text-sm text-slate-500 mb-6">
                We sent a 6-digit code to <span className="font-medium text-slate-700">{pending.email}</span>.
              </p>

              <form onSubmit={handleVerify} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Verification code</label>
                  <input
                    type="text"
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    maxLength={6}
                    value={code}
                    onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
                    required
                    placeholder="••••••"
                    className={`${inputCls} text-center tracking-[0.5em] text-lg font-semibold`}
                  />
                </div>
                {info && <p className="text-sm text-teal-700">{info}</p>}
                {error && <p className="text-sm text-red-600">{error}</p>}
                <button
                  type="submit"
                  disabled={submitting || code.length !== 6}
                  className="w-full bg-teal-600 text-white rounded-lg py-2.5 text-sm font-semibold hover:bg-teal-700 disabled:opacity-50 transition-colors"
                >
                  {submitting ? "Verifying…" : "Verify & continue"}
                </button>
              </form>

              <div className="mt-4 flex items-center justify-between text-sm">
                <button onClick={() => switchMode(mode)} className="text-slate-500 hover:text-slate-700">
                  ← Back
                </button>
                <button onClick={handleResend} disabled={submitting} className="text-teal-700 font-medium hover:underline disabled:opacity-50">
                  Resend code
                </button>
              </div>
            </>
          ) : mode === "signin" ? (
            <>
              <h1 className="text-2xl font-bold text-slate-800">Sign in</h1>
              <p className="text-sm text-slate-500 mb-6">Access your organization’s daily site records.</p>

              <div className="mb-6">
                <p className="text-xs text-slate-400 mb-2">Quick sign in as</p>
                <div className="flex gap-3">
                  <button type="button" onClick={() => useDemo("admin")} className="flex-1 text-base font-semibold px-5 py-3.5 rounded-xl border-2 border-slate-200 text-slate-700 hover:border-teal-400 hover:bg-white transition-colors">
                    Admin
                  </button>
                  <button type="button" onClick={() => useDemo("employee")} className="flex-1 text-base font-semibold px-5 py-3.5 rounded-xl border-2 border-slate-200 text-slate-700 hover:border-teal-400 hover:bg-white transition-colors">
                    Employee
                  </button>
                </div>
              </div>

              <form onSubmit={handleSignin} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Organization</label>
                  <input type="text" value={orgSlug} onChange={(e) => setOrgSlug(e.target.value)} required placeholder="org-slug" className={inputCls} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Organization Password</label>
                  <input type="password" value={orgPassword} onChange={(e) => setOrgPassword(e.target.value)} required className={inputCls} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                  <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required className={inputCls} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
                  <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required className={inputCls} />
                </div>
                {error && <p className="text-sm text-red-600">{error}</p>}
                <button type="submit" disabled={submitting} className="w-full bg-teal-600 text-white rounded-lg py-2.5 text-sm font-semibold hover:bg-teal-700 disabled:opacity-50 transition-colors">
                  {submitting ? "Signing in…" : "Sign in"}
                </button>
              </form>

              <p className="mt-5 text-center text-sm text-slate-500">
                New here?{" "}
                <button onClick={() => switchMode("signup")} className="text-teal-700 font-medium hover:underline">
                  Create an account
                </button>
              </p>
            </>
          ) : (
            <>
              <h1 className="text-2xl font-bold text-slate-800">Create account</h1>
              <p className="text-sm text-slate-500 mb-6">We’ll email you a code to verify it’s really you.</p>

              <form onSubmit={handleSignup} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Organization</label>
                  <input type="text" value={orgSlug} onChange={(e) => setOrgSlug(e.target.value)} required placeholder="org-slug" className={inputCls} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Full name</label>
                  <input type="text" value={name} onChange={(e) => setName(e.target.value)} required placeholder="Your name" className={inputCls} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                  <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required placeholder="you@example.com" className={inputCls} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
                  <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required placeholder="Choose a password" className={inputCls} />
                </div>
                {error && <p className="text-sm text-red-600">{error}</p>}
                <button type="submit" disabled={submitting} className="w-full bg-teal-600 text-white rounded-lg py-2.5 text-sm font-semibold hover:bg-teal-700 disabled:opacity-50 transition-colors">
                  {submitting ? "Creating account…" : "Create account"}
                </button>
              </form>

              <p className="mt-5 text-center text-sm text-slate-500">
                Already have an account?{" "}
                <button onClick={() => switchMode("signin")} className="text-teal-700 font-medium hover:underline">
                  Sign in
                </button>
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
