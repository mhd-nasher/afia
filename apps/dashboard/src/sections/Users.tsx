import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { actorName, fmtDateTime, ROLE_LABELS, wardName } from '../lib'
import { store } from '../store'
import { useManager } from '../session'
import {
  createInvitation,
  watchInvitations,
  type InvitationDoc,
} from '../firebaseAdmin'

/**
 * Users — clinician accounts exist by invitation only (§5, §11). The invite
 * flow creates invitations/{phoneE164}; the clinician app claims one on first
 * OTP sign-in. The signature identity is fixed here, permanently (§2.5).
 *
 * Deliberately absent (§2.9): any per-clinician speed, volume, or ranking
 * metric. Nothing here measures performance.
 */

const COUNTRIES = [
  { code: '+973', label: 'Bahrain +973' },
  { code: '+966', label: 'Saudi Arabia +966' },
  { code: '+971', label: 'UAE +971' },
  { code: '+965', label: 'Kuwait +965' },
  { code: '+974', label: 'Qatar +974' },
  { code: '+968', label: 'Oman +968' },
  { code: '+962', label: 'Jordan +962' },
  { code: '+20', label: 'Egypt +20' },
  { code: '+44', label: 'United Kingdom +44' },
] as const

type InviteRole = 'nurse' | 'charge_nurse' | 'manager'

const ROLE_PREFIX: Record<InviteRole, string> = {
  nurse: 'RN',
  charge_nurse: 'CN',
  manager: 'MGR',
}

function LockIcon(): ReactNode {
  return (
    <svg className="lock" width="11" height="13" viewBox="0 0 11 13" aria-label="Locked" role="img">
      <rect x="0.5" y="5.2" width="10" height="7.3" fill="currentColor" />
      <path
        d="M2.7 5.2V3.6a2.8 2.8 0 0 1 5.6 0v1.6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.5"
      />
    </svg>
  )
}

function InviteForm({
  invitations,
  onDone,
}: {
  invitations: InvitationDoc[]
  onDone: (phone: string) => void
}): ReactNode {
  const manager = useManager()
  const wards = store.wards()
  const [name, setName] = useState('')
  const [role, setRole] = useState<InviteRole>('nurse')
  const [wardId, setWardId] = useState(wards[0]?.id ?? '')
  const [country, setCountry] = useState<string>('+973')
  const [national, setNational] = useState('')
  const [regNo, setRegNo] = useState('')
  const [sig, setSig] = useState('')
  const [sigTouched, setSigTouched] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const composed = `${ROLE_PREFIX[role]}${regNo.trim() !== '' ? ` ${regNo.trim()}` : ''}${
    name.trim() !== '' ? ` · ${name.trim()}` : ''
  }`
  const signatureIdentity = sigTouched ? sig : composed

  const digits = national.replace(/[^\d]/g, '').replace(/^0+/, '')
  const phoneE164 = `${country}${digits}`

  const validate = (): string | null => {
    if (name.trim() === '') return 'Enter the clinician’s full name.'
    if (digits.length < 7 || digits.length > 10)
      return 'Enter a valid phone number (7–10 digits after the country code).'
    if (wardId === '') return 'Pick a ward.'
    if (signatureIdentity.trim().length < 4)
      return 'Compose the signature identity — it appears on every signed handover.'
    if (invitations.some((i) => i.phone === phoneE164))
      return `An invitation already exists for ${phoneE164} — invitations cannot be overwritten.`
    return null
  }

  const submit = async (): Promise<void> => {
    const v = validate()
    if (v !== null) {
      setError(v)
      return
    }
    setError(null)
    setBusy(true)
    try {
      await createInvitation({
        phone: phoneE164,
        name: name.trim(),
        role,
        wardId,
        signatureIdentity: signatureIdentity.trim(),
        invitedBy: manager.name,
        createdAt: Date.now(),
        claimedBy: null,
      })
      onDone(phoneE164)
    } catch (e) {
      setError(
        e instanceof Error
          ? `Could not create the invitation: ${e.message}`
          : 'Could not create the invitation.',
      )
    }
    setBusy(false)
  }

  return (
    <div className="invite-form">
      <div className="invite-grid">
        <span>
          <span className="field-label">Full name</span>
          <input
            className="input input-sm"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. Huda Al Khalifa"
          />
        </span>
        <span>
          <span className="field-label">Role</span>
          <select
            className="input input-sm"
            value={role}
            onChange={(e) => setRole(e.target.value as InviteRole)}
          >
            <option value="nurse">Nurse</option>
            <option value="charge_nurse">Charge nurse</option>
            <option value="manager">Manager</option>
          </select>
        </span>
      </div>

      <div className="invite-grid">
        <span>
          <span className="field-label">Phone — the clinician signs in with this number</span>
          <span className="phone-row">
            <select
              className="input input-sm"
              value={country}
              onChange={(e) => setCountry(e.target.value)}
              aria-label="Country code"
            >
              {COUNTRIES.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.label}
                </option>
              ))}
            </select>
            <input
              className="input input-sm input-mono"
              value={national}
              onChange={(e) => setNational(e.target.value)}
              placeholder="33001122"
              inputMode="numeric"
            />
          </span>
          <span className="cell-sub">
            Stored as <span className="mono">{phoneE164}</span>
          </span>
        </span>
        <span>
          <span className="field-label">Ward</span>
          <select
            className="input input-sm"
            value={wardId}
            onChange={(e) => setWardId(e.target.value)}
          >
            {wards.map((w) => (
              <option key={w.id} value={w.id}>
                {w.name}
              </option>
            ))}
          </select>
        </span>
      </div>

      <div className="invite-grid-3">
        <span>
          <span className="field-label">Registration no.</span>
          <input
            className="input input-sm input-mono"
            value={regNo}
            onChange={(e) => setRegNo(e.target.value)}
            placeholder="88-1042"
          />
        </span>
        <span>
          <span className="field-label">Signature identity</span>
          <input
            className="input input-sm input-mono"
            value={signatureIdentity}
            onChange={(e) => {
              setSigTouched(true)
              setSig(e.target.value)
            }}
            placeholder="RN 88-1042 · Full Name"
          />
        </span>
      </div>

      <div className="permanent-note">
        The signature identity is <b>permanent</b>. It is fixed the moment this
        invitation is created, appears on every handover this clinician signs, and
        can never be edited afterwards — not by the clinician, not by an
        administrator, not through any API (§2.5). Check it carefully now.
      </div>

      {error !== null && <div className="form-error">{error}</div>}

      <div style={{ display: 'flex', gap: 10 }}>
        <button className="btn btn-primary" onClick={() => void submit()} disabled={busy}>
          {busy ? 'Creating…' : 'Create invitation'}
        </button>
        <span className="save-as" style={{ alignSelf: 'center' }}>
          invited by {manager.name}
        </span>
      </div>
    </div>
  )
}

export function Users(): ReactNode {
  const [inviting, setInviting] = useState(true)
  const [invitations, setInvitations] = useState<InvitationDoc[]>([])
  const [createdMsg, setCreatedMsg] = useState<string | null>(null)

  useEffect(() => watchInvitations(setInvitations), [])

  const practitioners = store.practitioners()
  const signIns = [...store.signInLog()].sort((a, b) => b.at - a.at)

  const lastSignIn = useMemo(() => {
    const map = new Map<string, number>()
    for (const e of store.signInLog()) {
      if (e.kind === 'sign_in') {
        map.set(e.practitionerId, Math.max(map.get(e.practitionerId) ?? 0, e.at))
      }
    }
    return map
  }, [signIns.length])

  const wardOf = (practitionerId: string): string => {
    const inv = invitations.find((i) => i.claimedBy === practitionerId)
    return inv?.wardId !== undefined ? wardName(inv.wardId) : '—'
  }

  return (
    <>
      <h1 className="page-title">Users</h1>
      <p className="page-caption">
        Clinician accounts exist by invitation only — there is no self-signup, and a
        signature identity can never be edited after the invitation fixes it.
      </p>

      <section className="panel">
        <h2>Invite clinician</h2>
        <p className="panel-caption">
          Creates an invitation keyed to the clinician&apos;s phone number. Their
          first sign-in on the clinician app claims it and creates the account with
          the identity fixed below.
        </p>
        <button className="btn" onClick={() => setInviting((v) => !v)}>
          {inviting ? 'Hide invitation form' : 'Invite clinician'}
        </button>
        {createdMsg !== null && (
          <span className="form-ok" style={{ marginLeft: 12 }}>
            {createdMsg}
          </span>
        )}
        {inviting && (
          <InviteForm
            invitations={invitations}
            onDone={(phone) => {
              setCreatedMsg(`Invitation created for ${phone}.`)
            }}
          />
        )}
      </section>

      <section className="panel">
        <h2>Invitations</h2>
        <p className="panel-caption">
          Unclaimed invitations are waiting for the clinician&apos;s first sign-in.
          Invitations are never deleted; a claim fills only the claimed-by field.
        </p>
        {invitations.length === 0 ? (
          <p className="empty-note">No invitations yet.</p>
        ) : (
          <table className="data">
            <thead>
              <tr>
                <th>Phone</th>
                <th>Name</th>
                <th>Role</th>
                <th>Ward</th>
                <th>Signature identity</th>
                <th>Invited by</th>
                <th>Created</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {invitations.map((inv) => (
                <tr key={inv.phone}>
                  <td className="num">{inv.phone}</td>
                  <td>{inv.name}</td>
                  <td>{ROLE_LABELS[inv.role] ?? inv.role}</td>
                  <td>{inv.wardId !== undefined ? wardName(inv.wardId) : '—'}</td>
                  <td>
                    <span className="sig-cell">
                      <LockIcon />
                      <span className="mono">{inv.signatureIdentity}</span>
                    </span>
                  </td>
                  <td>{inv.invitedBy}</td>
                  <td className="num">
                    {inv.createdAt !== undefined ? fmtDateTime(inv.createdAt) : '—'}
                  </td>
                  <td>
                    {inv.claimedBy !== null ? (
                      <span className="status-word status-stable">Claimed</span>
                    ) : (
                      <span className="status-neutral">Unclaimed</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="panel">
        <h2>Practitioners</h2>
        <p className="panel-caption">
          The signature identity is what appears on every signed handover.
        </p>
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Role</th>
              <th>Ward</th>
              <th>Signature identity</th>
              <th>Status</th>
              <th>Last sign-in</th>
            </tr>
          </thead>
          <tbody>
            {practitioners.map((p) => {
              const last = lastSignIn.get(p.id)
              return (
                <tr key={p.id}>
                  <td>{p.name}</td>
                  <td>{ROLE_LABELS[p.role] ?? p.role}</td>
                  <td>{wardOf(p.id)}</td>
                  <td>
                    <span className="sig-cell">
                      <LockIcon />
                      <span className="mono">{p.signatureIdentity}</span>
                    </span>
                    <div className="sig-note">read-only — fixed at invitation</div>
                  </td>
                  <td className="status-neutral">Active</td>
                  <td className="num">{last !== undefined ? fmtDateTime(last) : '—'}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </section>

      <section className="panel">
        <h2>Sign-in log</h2>
        <p className="panel-caption">
          Ward devices are shared — the log shows who was signed in where.
        </p>
        <table className="data">
          <thead>
            <tr>
              <th>Practitioner</th>
              <th>Event</th>
              <th>Device</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {signIns.map((e) => (
              <tr key={e.id}>
                <td>{actorName(e.practitionerId)}</td>
                <td>{e.kind === 'sign_in' ? 'Sign in' : 'Sign out'}</td>
                <td>{e.device}</td>
                <td className="num">{fmtDateTime(e.at)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <p className="foot-note">
        Individual performance metrics are deliberately absent (§2.9): this system
        does not track any individual&apos;s speed, volume, or ranking.
      </p>
    </>
  )
}
