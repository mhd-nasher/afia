import { useState, type FormEvent, type ReactNode } from 'react'
import {
  authErrorMessage,
  loginManager,
  registerManager,
  resetManagerPassword,
} from './firebaseAdmin'

/**
 * Sign in · Register · Reset — the gate in front of every dashboard section.
 * Manager accounts are email/password; each signed-in manager owns a
 * managerAccounts/{uid} document.
 */

type Mode = 'login' | 'register' | 'reset'

export function AuthScreen(): ReactNode {
  const [mode, setMode] = useState<Mode>('login')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)

  const switchMode = (m: Mode): void => {
    setMode(m)
    setError(null)
    setNotice(null)
  }

  const submit = async (e: FormEvent): Promise<void> => {
    e.preventDefault()
    setError(null)
    setNotice(null)
    setBusy(true)
    try {
      if (mode === 'login') {
        await loginManager(email.trim(), password)
      } else if (mode === 'register') {
        if (name.trim() === '') {
          setError('Enter your name — it appears on every invitation you send.')
          setBusy(false)
          return
        }
        await registerManager(name.trim(), email.trim(), password)
      } else {
        await resetManagerPassword(email.trim())
        setNotice(`A password reset email is on its way to ${email.trim()}.`)
      }
    } catch (err) {
      setError(authErrorMessage(err))
    }
    setBusy(false)
  }

  return (
    <div className="auth-wrap">
      <div className="auth-box">
        <div className="auth-brand">
          <span className="auth-wordmark">Afia</span>
          <span className="auth-product">Admin dashboard</span>
        </div>
        <p className="auth-lede">
          {mode === 'login' && 'Sign in with your manager account.'}
          {mode === 'register' && 'Register a manager account for this dashboard.'}
          {mode === 'reset' && 'Enter your email and we will send a reset link.'}
        </p>

        {error !== null && (
          <div className="invert-strip" role="alert">
            <span className="invert-icon" aria-hidden>▲</span>
            <span>{error}</span>
          </div>
        )}
        {notice !== null && <div className="auth-notice">{notice}</div>}

        <form onSubmit={(e) => void submit(e)}>
          {mode === 'register' && (
            <label className="auth-field">
              <span className="field-label">Name</span>
              <input
                className="input"
                value={name}
                onChange={(e) => setName(e.target.value)}
                autoComplete="name"
                placeholder="Full name"
              />
            </label>
          )}
          <label className="auth-field">
            <span className="field-label">Email</span>
            <input
              className="input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              required
            />
          </label>
          {mode !== 'reset' && (
            <label className="auth-field">
              <span className="field-label">Password</span>
              <input
                className="input"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete={mode === 'register' ? 'new-password' : 'current-password'}
                minLength={6}
                required
              />
            </label>
          )}
          <button className="btn btn-primary btn-block" type="submit" disabled={busy}>
            {busy
              ? 'Working…'
              : mode === 'login'
                ? 'Sign in'
                : mode === 'register'
                  ? 'Register'
                  : 'Send reset email'}
          </button>
        </form>

        <div className="auth-links">
          {mode !== 'login' && (
            <button className="link-btn" onClick={() => switchMode('login')}>
              Sign in
            </button>
          )}
          {mode !== 'register' && (
            <button className="link-btn" onClick={() => switchMode('register')}>
              Register an account
            </button>
          )}
          {mode !== 'reset' && (
            <button className="link-btn" onClick={() => switchMode('reset')}>
              Forgot password
            </button>
          )}
        </div>
      </div>
      <p className="auth-foot">
        Clinician accounts are not created here — clinicians join by invitation
        from the Users section and sign in on the clinician app.
      </p>
    </div>
  )
}
