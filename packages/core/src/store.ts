import {
  detectGaps,
  extractChips,
  type FieldContent,
  type FormularyEntry,
  type FunctionalQuestion,
  type RedFlagQuestion,
  type TemplateField,
  aggregateWellbeing,
  type WellbeingAggregate,
} from '@afia/rules'
import { AuditLog, type AuditAction, type AuditEvent } from './audit'
import { appendUpdate, type CaseUpdate, type PatientCase } from './case'
import type {
  ConsentRecord,
  Patient,
  PlatformConfig,
  Practitioner,
  SignInEvent,
  Ward,
} from './entities'
import {
  confirmChip,
  sign,
  supersede,
  transition,
  type AudioRecording,
  type ConfirmableChip,
  type Handover,
  type HandoverFlag,
  type HandoverStatus,
} from './handover'
import { newId } from './ids'
import { escalate, type Priority } from './priority'

/**
 * The data seam (architecture R-003). LocalStore is the demo implementation
 * (in-memory + optional persistence). A future FirestoreStore implements the
 * same interface — that is the entire Firebase migration surface.
 *
 * Constraint enforcement lives HERE and in the pure functions it calls,
 * not in any UI layer (§2.1). Note what is absent: no method lowers a
 * priority, dismisses a flag, deletes an audit event, edits a signature
 * identity, or confirms more than one chip per call.
 */

export interface StorageLike {
  getItem(key: string): string | null
  setItem(key: string, value: string): void
}

export interface TemplateVersion {
  version: number
  fields: TemplateField[]
  editedBy: string
  at: number
}

export interface SeedData {
  patients: Patient[]
  practitioners: Practitioner[]
  wards: Ward[]
  handovers: Handover[]
  cases: PatientCase[]
  consents: ConsentRecord[]
  formulary: FormularyEntry[]
  templateVersions: TemplateVersion[]
  redFlagQuestions: RedFlagQuestion[]
  functionalQuestions: FunctionalQuestion[]
  wellbeingScores: Record<string, number[]>
  signInLog: SignInEvent[]
  config: PlatformConfig
  auditEvents: AuditEvent[]
}

interface State {
  patients: Patient[]
  practitioners: Practitioner[]
  wards: Ward[]
  handovers: Handover[]
  cases: PatientCase[]
  consents: ConsentRecord[]
  formulary: FormularyEntry[]
  templateVersions: TemplateVersion[]
  redFlagQuestions: RedFlagQuestion[]
  functionalQuestions: FunctionalQuestion[]
  wellbeingScores: Record<string, number[]>
  signInLog: SignInEvent[]
  config: PlatformConfig
}

export class LocalStore {
  protected state: State
  protected audit: AuditLog
  protected listeners = new Set<() => void>()
  private storage: StorageLike | null
  private storageKey: string

  constructor(
    seed: SeedData,
    opts: { storage?: StorageLike; key?: string } = {},
  ) {
    this.storage = opts.storage ?? null
    this.storageKey = opts.key ?? 'afia-store'
    const persisted = this.storage?.getItem(this.storageKey)
    if (persisted !== null && persisted !== undefined && persisted !== '') {
      const parsed = JSON.parse(persisted) as State & { auditEvents: AuditEvent[] }
      const { auditEvents, ...rest } = parsed
      this.state = rest
      this.audit = AuditLog.from(auditEvents)
    } else {
      const { auditEvents, ...rest } = seed
      this.state = rest
      this.audit = AuditLog.from(auditEvents)
    }
  }

  // ── subscription (React useSyncExternalStore) ────────────────────────────

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  /** Re-reference state and wake subscribers — no persistence side effects. */
  protected notify(): void {
    this.state = { ...this.state }
    for (const l of this.listeners) l()
  }

  protected commit(): void {
    if (this.storage) {
      this.storage.setItem(
        this.storageKey,
        JSON.stringify({ ...this.state, auditEvents: this.audit.read() }),
      )
    }
    this.notify()
  }

  protected log(
    actor: string,
    action: AuditAction,
    entityId: string,
    previousValue: unknown = null,
    detail: string | null = null,
  ): void {
    this.audit.append({ at: Date.now(), actor, action, entityId, previousValue, detail })
  }

  /**
   * Resolves when every mutation so far is durably persisted. LocalStore
   * persists synchronously, so this is immediate; FirestoreStore overrides it
   * to resolve only on SERVER acknowledgement — the honest definition of
   * "sent" (§6: never imply the nursing team received what it has not).
   */
  flush(): Promise<void> {
    return Promise.resolve()
  }

  /** Wipe persisted state so the seed loads fresh on next construction (demo reset). */
  resetDemo(): void {
    if (this.storage) this.storage.setItem(this.storageKey, '')
    // Callers reload the page after this; no in-place reseed to keep the API small.
  }

  // ── reads ────────────────────────────────────────────────────────────────

  getSnapshot = (): State => this.state
  patients(): readonly Patient[] { return this.state.patients }
  patient(id: string): Patient | undefined { return this.state.patients.find((p) => p.id === id) }
  practitioners(): readonly Practitioner[] { return this.state.practitioners }
  practitioner(id: string): Practitioner | undefined { return this.state.practitioners.find((p) => p.id === id) }
  wards(): readonly Ward[] { return this.state.wards }
  ward(id: string): Ward | undefined { return this.state.wards.find((w) => w.id === id) }
  handovers(): readonly Handover[] { return this.state.handovers }
  handover(id: string): Handover | undefined { return this.state.handovers.find((h) => h.id === id) }
  cases(): readonly PatientCase[] { return this.state.cases }
  caseById(id: string): PatientCase | undefined { return this.state.cases.find((c) => c.id === id) }
  consents(): readonly ConsentRecord[] { return this.state.consents }
  formulary(): readonly FormularyEntry[] { return this.state.formulary }
  redFlagQuestions(): readonly RedFlagQuestion[] { return this.state.redFlagQuestions }
  functionalQuestions(): readonly FunctionalQuestion[] { return this.state.functionalQuestions }
  signInLog(): readonly SignInEvent[] { return this.state.signInLog }
  config(): PlatformConfig { return this.state.config }
  auditTrail(): readonly AuditEvent[] { return this.audit.read() }

  template(): TemplateField[] {
    const latest = this.state.templateVersions[this.state.templateVersions.length - 1]
    return latest ? latest.fields : []
  }
  templateVersions(): readonly TemplateVersion[] { return this.state.templateVersions }

  /** §2.9 — aggregate only, suppressed below five. No per-person read exists. */
  wellbeing(wardId: string): WellbeingAggregate {
    return aggregateWellbeing(this.state.wellbeingScores[wardId] ?? [])
  }

  // ── handover lifecycle ───────────────────────────────────────────────────

  createHandover(patientId: string, authorId: string): Handover {
    const h: Handover = {
      id: newId('handover'),
      externalIdentifier: null,
      createdAt: Date.now(),
      fhirResource: 'DocumentReference',
      patientId,
      authorId,
      status: 'recording',
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
    }
    this.state.handovers = [...this.state.handovers, h]
    this.log(authorId, 'created', h.id)
    this.log(authorId, 'recorded', h.id, null, 'recording started')
    this.commit()
    return h
  }

  /**
   * Auto-checkpoint (§5): safe to call every few seconds. Recomputes chips
   * (preserving confirmations for unchanged chips) and omission flags —
   * §2.8 gap detection runs here, deterministically, on every save.
   */
  updateDraft(
    handoverId: string,
    patch: {
      transcript?: string
      fields?: FieldContent[]
      audio?: AudioRecording | null
    },
    actor: string,
  ): Handover {
    const h = this.mustGet(handoverId)
    if (h.status !== 'recording' && h.status !== 'draft_ready')
      throw new Error(`Cannot edit a handover in state ${h.status} — supersede it instead.`)

    const transcript = patch.transcript ?? h.transcript
    const fields = patch.fields ?? h.fields
    const audio = patch.audio === undefined ? h.audio : patch.audio

    const extracted = extractChips(transcript, this.state.formulary)
    const chips: ConfirmableChip[] = extracted.map((chip) => {
      const existing = h.chips.find((c) => c.id === chip.id && c.text === chip.text)
      return existing !== undefined
        ? { ...chip, confirmedBy: existing.confirmedBy, confirmedAt: existing.confirmedAt, correctedTo: existing.correctedTo }
        : { ...chip, confirmedBy: null, confirmedAt: null, correctedTo: null }
    })

    const gaps = detectGaps(this.template(), fields)
    const flags: HandoverFlag[] = gaps.map((g) => {
      const existing = h.flags.find((f) => f.fieldId === g.fieldId)
      return existing !== undefined
        ? { ...existing, ...g }
        : { ...g, id: newId('flag'), state: 'open' as const, signingNote: null }
    })

    const updated: Handover = { ...h, transcript, fields, audio, chips, flags }
    this.replaceHandover(updated)
    this.commit()
    return updated
  }

  setHandoverStatus(handoverId: string, to: HandoverStatus, actor: string): Handover {
    const h = this.mustGet(handoverId)
    const updated = transition(h, to)
    this.replaceHandover(updated)
    this.log(actor, to === 'confirmed_in_system' ? 'confirmed' : 'created', h.id, h.status, `status → ${to}`)
    this.commit()
    return updated
  }

  /** §2.3 — one chip per call. No bulk variant exists. */
  confirmChip(
    handoverId: string,
    chipId: string,
    practitionerId: string,
    correctedTo: string | null = null,
  ): Handover {
    const h = this.mustGet(handoverId)
    const practitioner = this.mustGetPractitioner(practitionerId)
    const updated = confirmChip(h, chipId, practitioner, correctedTo)
    this.replaceHandover(updated)
    this.log(
      practitionerId,
      correctedTo !== null ? 'corrected' : 'chip_confirmed',
      handoverId,
      h.chips.find((c) => c.id === chipId)?.text ?? null,
      correctedTo !== null ? `corrected to ${correctedTo}` : `confirmed chip ${chipId}`,
    )
    this.commit()
    return updated
  }

  /**
   * Sign and immediately queue for export (§5 — export fires automatically on
   * signature; there is no manual export button).
   */
  signHandover(
    handoverId: string,
    practitionerId: string,
    opts: { openFlagReason?: string } = {},
  ): Handover {
    const h = this.mustGet(handoverId)
    const practitioner = this.mustGetPractitioner(practitionerId)
    const signed = sign(h, practitioner, opts)
    const queued = transition(signed, 'queued')
    this.replaceHandover(queued)
    this.log(practitionerId, 'signed', handoverId, null, `v${h.version} signed as ${practitioner.signatureIdentity}`)
    this.log(practitionerId, 'exported', handoverId, null, 'export queued automatically on signature')
    this.commit()
    return queued
  }

  /**
   * §5 — confirmed_in_system requires POSITIVE acknowledgement from the
   * receiving system. The demo simulates the receiving side; the state
   * machine still refuses this transition from anywhere but queued.
   */
  acknowledgeExport(handoverId: string, ack: { ok: true } | { ok: false; error: string }): Handover {
    const h = this.mustGet(handoverId)
    const updated = ack.ok
      ? { ...transition(h, 'confirmed_in_system'), acknowledgedAt: Date.now(), exportError: null }
      : { ...transition(h, 'export_failed'), exportError: ack.error }
    this.replaceHandover(updated)
    this.log('system', ack.ok ? 'confirmed' : 'export_failed', handoverId, h.status, ack.ok ? 'positive acknowledgement received' : ack.error)
    this.commit()
    return updated
  }

  retryExport(handoverId: string, actor: string): Handover {
    const h = this.mustGet(handoverId)
    const updated = transition(h, 'queued')
    this.replaceHandover(updated)
    this.log(actor, 'exported', handoverId, 'export_failed', 'export retried')
    this.commit()
    return updated
  }

  /** §2.5 — post-signature edit: both versions and both signatures persist. */
  supersedeHandover(handoverId: string, actor: string): { original: Handover; draft: Handover } {
    const h = this.mustGet(handoverId)
    const result = supersede(h)
    this.state.handovers = [
      ...this.state.handovers.map((x) => (x.id === h.id ? result.original : x)),
      result.draft,
    ]
    this.log(actor, 'superseded', h.id, null, `superseded by ${result.draft.id} (v${result.draft.version})`)
    this.commit()
    return result
  }

  // ── patient cases ────────────────────────────────────────────────────────

  createCase(patientName: string, completedBy: 'self' | 'carer', consentId: string | null): PatientCase {
    const c: PatientCase = {
      id: newId('case'),
      externalIdentifier: null,
      createdAt: Date.now(),
      patientName,
      completedBy,
      status: 'in_progress',
      priority: 'routine',
      updates: [],
      consentId,
    }
    this.state.cases = [...this.state.cases, c]
    this.log(patientName, 'created', c.id)
    this.commit()
    return c
  }

  /** "My condition has changed" and the initial submission both land here — same case, appended. */
  appendCaseUpdate(caseId: string, update: CaseUpdate): PatientCase {
    const c = this.mustGetCase(caseId)
    const before = c.priority
    const updated = appendUpdate(c, update)
    this.state.cases = this.state.cases.map((x) => (x.id === caseId ? updated : x))
    this.log(
      c.patientName,
      update.kind === 'initial' ? 'case_submitted' : 'case_updated',
      caseId,
      null,
      update.kind === 'condition_changed' ? 'condition-changed update appended to same case' : null,
    )
    if (updated.priority !== before)
      this.log('rules', 'escalated', caseId, before, `priority ${before} → ${updated.priority} (one-way)`)
    this.commit()
    return updated
  }

  /** §2.1 — the only priority mutation. escalate() cannot lower. */
  escalateCase(caseId: string, proposed: Priority, actor: string): PatientCase {
    const c = this.mustGetCase(caseId)
    const next = escalate(c.priority, proposed)
    if (next === c.priority) return c
    const updated = { ...c, priority: next }
    this.state.cases = this.state.cases.map((x) => (x.id === caseId ? updated : x))
    this.log(actor, 'escalated', caseId, c.priority, `priority ${c.priority} → ${next}`)
    this.commit()
    return updated
  }

  markUpdateSent(caseId: string, updateId: string): PatientCase {
    const c = this.mustGetCase(caseId)
    const updated: PatientCase = {
      ...c,
      updates: c.updates.map((u) => (u.id === updateId ? { ...u, syncState: 'sent' as const } : u)),
    }
    this.state.cases = this.state.cases.map((x) => (x.id === caseId ? updated : x))
    this.commit()
    return updated
  }

  // ── consent ──────────────────────────────────────────────────────────────

  grantConsent(subjectId: string, scope: ConsentRecord['scope']): ConsentRecord {
    const record: ConsentRecord = {
      id: newId('consent'),
      externalIdentifier: null,
      createdAt: Date.now(),
      subjectId,
      scope,
      grantedAt: Date.now(),
      withdrawnAt: null,
    }
    this.state.consents = [...this.state.consents, record]
    this.log(subjectId, 'consent_granted', record.id, null, scope)
    this.commit()
    return record
  }

  withdrawConsent(consentId: string, actor: string): ConsentRecord {
    const record = this.state.consents.find((c) => c.id === consentId)
    if (record === undefined) throw new Error(`Unknown consent: ${consentId}`)
    const updated = { ...record, withdrawnAt: Date.now() }
    this.state.consents = this.state.consents.map((c) => (c.id === consentId ? updated : c))
    this.log(actor, 'consent_withdrawn', consentId)
    this.commit()
    return updated
  }

  // ── admin: templates & rules ─────────────────────────────────────────────

  saveTemplateVersion(fields: TemplateField[], editedBy: string): TemplateVersion {
    const latest = this.state.templateVersions[this.state.templateVersions.length - 1]
    const version: TemplateVersion = {
      version: (latest?.version ?? 0) + 1,
      fields,
      editedBy,
      at: Date.now(),
    }
    this.state.templateVersions = [...this.state.templateVersions, version]
    this.log(editedBy, 'template_edited', `template-v${version.version}`)
    this.commit()
    return version
  }

  /**
   * §7 — editing a red-flag rule requires entering the approver's name.
   * Passing approval=null saves the rule in the unapproved caution state.
   */
  saveRedFlagQuestion(question: RedFlagQuestion, editedBy: string): RedFlagQuestion {
    const exists = this.state.redFlagQuestions.some((q) => q.id === question.id)
    this.state.redFlagQuestions = exists
      ? this.state.redFlagQuestions.map((q) => (q.id === question.id ? question : q))
      : [...this.state.redFlagQuestions, question]
    this.log(editedBy, 'rule_edited', question.id, null, question.approval ? `approved by ${question.approval.approvedBy}` : 'UNAPPROVED — caution state')
    this.commit()
    return question
  }

  recordSignIn(practitionerId: string, kind: 'sign_in' | 'sign_out', device: string): void {
    this.state.signInLog = [
      ...this.state.signInLog,
      { id: newId('signin'), practitionerId, at: Date.now(), kind, device },
    ]
    this.log(practitionerId, kind, practitionerId, null, device)
    this.commit()
  }

  // ── internals ────────────────────────────────────────────────────────────

  private mustGet(id: string): Handover {
    const h = this.handover(id)
    if (h === undefined) throw new Error(`Unknown handover: ${id}`)
    return h
  }
  private mustGetCase(id: string): PatientCase {
    const c = this.caseById(id)
    if (c === undefined) throw new Error(`Unknown case: ${id}`)
    return c
  }
  private mustGetPractitioner(id: string): Practitioner {
    const p = this.practitioner(id)
    if (p === undefined) throw new Error(`Unknown practitioner: ${id}`)
    return p
  }
  private replaceHandover(h: Handover): void {
    this.state.handovers = this.state.handovers.map((x) => (x.id === h.id ? h : x))
  }
}
