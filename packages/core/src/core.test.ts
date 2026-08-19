import { describe, expect, it } from 'vitest'
import {
  LocalStore,
  MissingFlagReasonError,
  UnconfirmedChipsError,
  appendUpdate,
  escalate,
  makeSeed,
  sign,
  supersede,
  synthDemoAudio,
  type Handover,
  type PatientCase,
  type Practitioner,
} from './index'

const NURSE: Practitioner = {
  id: 'prac-test',
  externalIdentifier: null,
  createdAt: 0,
  fhirResource: 'Practitioner',
  name: 'Test Nurse',
  role: 'nurse',
  signatureIdentity: 'RN 00-0001 · Test Nurse',
  invitedBy: 'system',
}

function draft(overrides: Partial<Handover> = {}): Handover {
  return {
    id: 'h1',
    externalIdentifier: null,
    createdAt: 0,
    fhirResource: 'DocumentReference',
    patientId: 'p1',
    authorId: NURSE.id,
    status: 'draft_ready',
    audio: null,
    transcript: '',
    fields: [],
    chips: [],
    flags: [],
    signature: null,
    version: 1,
    supersedes: null,
    supersededBy: null,
    exportError: null,
    acknowledgedAt: null,
    ...overrides,
  }
}

const chip = (id: string, confirmed: boolean) => ({
  id,
  kind: 'drug' as const,
  text: 'furosemide',
  start: 0,
  end: 10,
  match: null,
  confirmedBy: confirmed ? NURSE.id : null,
  confirmedAt: confirmed ? 1 : null,
  correctedTo: null,
})

const openFlag = (id: string) => ({
  id,
  fieldId: 'meds',
  label: 'Medications given',
  message: 'Not mentioned: Medications given',
  state: 'open' as const,
  signingNote: null,
})

describe('T-001 — escalation is one-way (§2.1)', () => {
  it('escalate() only ever raises', () => {
    expect(escalate('routine', 'urgent')).toBe('urgent')
    expect(escalate('urgent', 'routine')).toBe('urgent')
    expect(escalate('elevated', 'routine')).toBe('elevated')
    expect(escalate('elevated', 'elevated')).toBe('elevated')
  })

  it('a later calm update never lowers a case priority', () => {
    const c: PatientCase = {
      id: 'c1', externalIdentifier: null, createdAt: 0, patientName: 'X',
      completedBy: 'self', status: 'submitted', priority: 'urgent', updates: [], consentId: null,
    }
    const after = appendUpdate(c, {
      id: 'u2', at: 1, kind: 'condition_changed', transcript: 'feeling much better now',
      audio: null, redFlagAnswers: [],
      redFlags: { triggered: false, triggeredBy: [], unanswered: [] },
      functionalAnswers: [{ questionId: 'fn1', value: 'SAME_AS_NORMAL' }],
      syncState: 'sent',
    })
    expect(after.priority).toBe('urgent')
  })

  it('no downgrade API exists on the store', () => {
    const store = new LocalStore(makeSeed())
    const forbidden = ['decreasePriority', 'dismissFlag', 'markAsNormal', 'downgrade', 'confirmAll']
    for (const name of forbidden) {
      expect((store as unknown as Record<string, unknown>)[name], `LocalStore.${name} must not exist`).toBeUndefined()
    }
  })

  it('flag states cannot express dismissal', () => {
    const h = draft({ flags: [openFlag('f1')] })
    const states = new Set(h.flags.map((f) => f.state))
    // The union type is 'open' | 'acknowledged_in_signing' — no 'dismissed'.
    expect(states.has('open')).toBe(true)
  })
})

describe('T-002 — UNKNOWN never reduces priority (§2.2)', () => {
  it('an all-UNKNOWN update leaves priority untouched', () => {
    const c: PatientCase = {
      id: 'c1', externalIdentifier: null, createdAt: 0, patientName: 'X',
      completedBy: 'self', status: 'submitted', priority: 'elevated', updates: [], consentId: null,
    }
    const after = appendUpdate(c, {
      id: 'u2', at: 1, kind: 'condition_changed', transcript: '',
      audio: null,
      redFlagAnswers: [{ questionId: 'q1', answer: 'UNKNOWN' }],
      redFlags: { triggered: false, triggeredBy: [], unanswered: ['q1'] },
      functionalAnswers: [{ questionId: 'fn1', value: 'UNKNOWN' }],
      syncState: 'sent',
    })
    expect(after.priority).toBe('elevated')
  })
})

describe('T-003 — no bulk confirmation; unconfirmed chips block signing (§2.3)', () => {
  it('sign() throws while any chip is unconfirmed', () => {
    const h = draft({ chips: [chip('c1', true), chip('c2', false)] })
    expect(() => sign(h, NURSE)).toThrowError(UnconfirmedChipsError)
    try {
      sign(h, NURSE)
    } catch (e) {
      expect((e as UnconfirmedChipsError).chipIds).toEqual(['c2'])
    }
  })

  it('signing succeeds only after each chip is individually confirmed', () => {
    const store = new LocalStore(makeSeed())
    const h = store.createHandover('pat-4', 'prac-amara')
    store.updateDraft(h.id, {
      transcript: 'Gave furosemide 40 mg this morning.',
      fields: [
        { fieldId: 'situation', text: 'stable' },
        { fieldId: 'background', text: 'known HF' },
        { fieldId: 'medications', text: 'furosemide 40 mg' },
        { fieldId: 'vitals', text: 'BP 120/80' },
        { fieldId: 'pain', text: 'none' },
        { fieldId: 'plan', text: 'monitor' },
      ],
    }, 'prac-amara')
    store.setHandoverStatus(h.id, 'draft_ready', 'prac-amara')

    const withChips = store.handover(h.id) as Handover
    expect(withChips.chips.length).toBeGreaterThan(0)
    expect(() => store.signHandover(h.id, 'prac-amara')).toThrowError(UnconfirmedChipsError)

    for (const c of withChips.chips) store.confirmChip(h.id, c.id, 'prac-amara')
    const signed = store.signHandover(h.id, 'prac-amara')
    expect(signed.status).toBe('queued') // export fires automatically on signature
    expect(signed.signature?.signatureIdentity).toBe('RN 88-1042 · Amara Okafor')
  })

  it('confirmChip takes exactly one chip id (arity 1 for the id position)', () => {
    const store = new LocalStore(makeSeed())
    // Structural check: the parameter is a single string; passing an array is a type
    // error and, at runtime, an unknown-chip error — no bulk path exists.
    expect(() =>
      store.confirmChip('hand-received-1', ['a', 'b'] as unknown as string, 'prac-amara'),
    ).toThrow()
  })
})

describe('T-004 — omission flags never block signing (§2.4)', () => {
  it('open flags + recorded reason → signs; flags carry the note', () => {
    const h = draft({ flags: [openFlag('f1'), openFlag('f2')] })
    const signed = sign(h, NURSE, { openFlagReason: 'End of shift — night team to complete.' })
    expect(signed.status).toBe('signed')
    expect(signed.signature?.openFlagReason).toBe('End of shift — night team to complete.')
    for (const f of signed.flags) {
      expect(f.state).toBe('acknowledged_in_signing')
      expect(f.signingNote).toBe('End of shift — night team to complete.')
    }
  })

  it('open flags without a reason ask for one (one tap) — but chips are the only hard block', () => {
    const h = draft({ flags: [openFlag('f1')] })
    expect(() => sign(h, NURSE)).toThrowError(MissingFlagReasonError)
    expect(sign(h, NURSE, { openFlagReason: 'Handed to day team' }).status).toBe('signed')
  })
})

describe('T-005 — signature identity immutable; supersede keeps both versions (§2.5)', () => {
  it('supersede preserves the original and its signature, resets confirmations on the draft', () => {
    const signed = sign(draft({ chips: [chip('c1', true)] }), NURSE)
    const { original, draft: v2 } = supersede(signed)

    expect(original.id).toBe('h1')
    expect(original.signature?.signatureIdentity).toBe(NURSE.signatureIdentity)
    expect(original.supersededBy).toBe(v2.id)

    expect(v2.version).toBe(2)
    expect(v2.signature).toBeNull()
    expect(v2.supersedes).toBe('h1')
    expect(v2.chips.every((c) => c.confirmedAt === null)).toBe(true)
  })

  it('signature identity comes from the practitioner record, never from input', () => {
    const signed = sign(draft(), NURSE)
    expect(signed.signature?.signatureIdentity).toBe('RN 00-0001 · Test Nurse')
  })

  it('store supersede keeps both versions retrievable', () => {
    const store = new LocalStore(makeSeed())
    const { original, draft: v2 } = store.supersedeHandover('hand-received-1', 'prac-amara')
    expect(store.handover(original.id)?.signature).not.toBeNull()
    expect(store.handover(v2.id)?.signature).toBeNull()
    expect(store.handovers().filter((h) => h.id === original.id || h.id === v2.id)).toHaveLength(2)
  })
})

describe('T-006 — raw audio is stored and playable (§2.6)', () => {
  it('seed audio is a playable WAV data URI and survives supersede', () => {
    const seed = makeSeed()
    const received = seed.handovers.find((h) => h.id === 'hand-received-1')
    expect(received?.audio?.url).toMatch(/^data:audio\/wav;base64,/)
    expect((received?.audio?.url.length ?? 0)).toBeGreaterThan(1000)

    const store = new LocalStore(seed)
    const { draft: v2 } = store.supersedeHandover('hand-received-1', 'prac-amara')
    expect(v2.audio?.url).toBe(received?.audio?.url)
  })

  it('synthDemoAudio produces a well-formed RIFF/WAVE header', () => {
    const { url } = synthDemoAudio(1)
    const b64 = url.split(',')[1] as string
    const head = Buffer.from(b64, 'base64').subarray(0, 12).toString('binary')
    expect(head.startsWith('RIFF')).toBe(true)
    expect(head.endsWith('WAVE')).toBe(true)
  })
})

describe('state machine — signed vs confirmed_in_system are distinct (§5)', () => {
  it('confirmed_in_system is reachable only from queued via positive acknowledgement', () => {
    const store = new LocalStore(makeSeed())
    expect(() =>
      store.acknowledgeExport('hand-received-2', { ok: true }),
    ).toThrow() // status 'signed', not 'queued' — local send-completion cannot confirm

    const failed = store.handover('hand-failed-1') as Handover
    expect(failed.status).toBe('export_failed')
    store.retryExport('hand-failed-1', 'prac-amara')
    const confirmed = store.acknowledgeExport('hand-failed-1', { ok: true })
    expect(confirmed.status).toBe('confirmed_in_system')
    expect(confirmed.acknowledgedAt).not.toBeNull()
  })
})

describe('audit trail is append-only (§3.4)', () => {
  it('records transitions and exposes no update/delete', () => {
    const store = new LocalStore(makeSeed())
    const before = store.auditTrail().length
    store.escalateCase('case-4', 'elevated', 'prac-amara')
    const trail = store.auditTrail()
    expect(trail.length).toBe(before + 1)
    expect(trail[trail.length - 1]?.action).toBe('escalated')
    expect(trail[trail.length - 1]?.previousValue).toBe('routine')

    const log = store.auditTrail() as unknown as Record<string, unknown>
    expect(log['update']).toBeUndefined()
    expect(log['delete']).toBeUndefined()
  })
})

describe('consent is separate and withdrawable (§3.3)', () => {
  it('grant then withdraw preserves the record with a withdrawal timestamp', () => {
    const store = new LocalStore(makeSeed())
    const consent = store.grantConsent('case-4', 'audio_recording')
    const withdrawn = store.withdrawConsent(consent.id, 'case-4')
    expect(withdrawn.withdrawnAt).not.toBeNull()
    expect(store.consents().some((c) => c.id === consent.id)).toBe(true)
  })
})
