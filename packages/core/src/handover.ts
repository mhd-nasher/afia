import type { ExtractedChip, FieldContent, OmissionFlag } from '@afia/rules'
import type { BaseEntity, Practitioner } from './entities'
import { newId } from './ids'

/**
 * The handover note — FHIR `DocumentReference`. Carries the state machine for
 * the row states of HANDOFF §5, the per-chip confirmation of §2.3, the
 * never-blocking omission flags of §2.4, and the supersede rule of §2.5.
 */

export const HANDOVER_STATES = [
  'not_started',
  'recording',
  'draft_ready',
  'signed',
  'queued',
  'confirmed_in_system',
  'export_failed',
] as const
export type HandoverStatus = (typeof HANDOVER_STATES)[number]

/**
 * HANDOFF §5 — `signed` and `confirmed_in_system` are distinct states.
 * confirmed_in_system is reachable only from queued, on POSITIVE
 * acknowledgement from the receiving system — never from local send-completion.
 */
const TRANSITIONS: Record<HandoverStatus, readonly HandoverStatus[]> = {
  not_started: ['recording'],
  recording: ['recording', 'draft_ready'], // recording→recording = checkpoint
  draft_ready: ['recording', 'signed'], // may resume recording; sign() guards signing
  signed: ['queued'],
  queued: ['confirmed_in_system', 'export_failed'],
  export_failed: ['queued'], // retry re-queues; no path back to draft without supersede
  confirmed_in_system: [],
}

export interface ConfirmableChip extends ExtractedChip {
  /** §2.3 — each chip is confirmed individually. null = unconfirmed. */
  confirmedBy: string | null
  confirmedAt: number | null
  /** Formulary name chosen in the correction picker (recognition, never recall). */
  correctedTo: string | null
}

export interface HandoverFlag extends OmissionFlag {
  id: string
  /**
   * §2.1 / §2.4 — a flag is never dismissed. It stays open until signing
   * acknowledges it with a recorded reason; it exports visibly either way.
   */
  state: 'open' | 'acknowledged_in_signing'
  signingNote: string | null
}

export interface Signature {
  practitionerId: string
  /** Copied from Practitioner.signatureIdentity — immutable (§2.5). */
  signatureIdentity: string
  signedAt: number
  openFlagReason: string | null
}

export interface AudioRecording {
  id: string
  /** §2.6 — persisted and delivered playable. Never transcript-only. */
  url: string
  mimeType: string
  durationSec: number
  recordedAt: number
}

export interface Handover extends BaseEntity {
  fhirResource: 'DocumentReference'
  patientId: string
  authorId: string
  status: HandoverStatus
  audio: AudioRecording | null
  transcript: string
  fields: FieldContent[]
  chips: ConfirmableChip[]
  flags: HandoverFlag[]
  signature: Signature | null
  version: number
  /** §2.5 — the original is never overwritten; both versions and both signatures persist. */
  supersedes: string | null
  supersededBy: string | null
  exportError: string | null
  /** When the receiving system positively acknowledged (→ confirmed_in_system). */
  acknowledgedAt: number | null
}

export class IllegalTransitionError extends Error {
  constructor(from: HandoverStatus, to: HandoverStatus) {
    super(`Illegal handover transition: ${from} → ${to}`)
  }
}

export class UnconfirmedChipsError extends Error {
  constructor(public readonly chipIds: string[]) {
    super(
      `Signing is blocked: ${chipIds.length} drug/number chip(s) are not individually confirmed.`,
    )
  }
}

export class MissingFlagReasonError extends Error {
  constructor(openCount: number) {
    super(
      `${openCount} omission flag(s) are open — signing proceeds, but a reason must be recorded.`,
    )
  }
}

export function transition(h: Handover, to: HandoverStatus): Handover {
  if (!TRANSITIONS[h.status].includes(to)) throw new IllegalTransitionError(h.status, to)
  return { ...h, status: to }
}

/**
 * HANDOFF §2.3 — confirmation is per chip. The signature of this function is
 * the enforcement: it accepts exactly ONE chip id. There is no variant that
 * accepts an array, and no confirmAll anywhere in the codebase.
 */
export function confirmChip(
  h: Handover,
  chipId: string,
  practitioner: Practitioner,
  correctedTo: string | null = null,
  now: number = Date.now(),
): Handover {
  const chip = h.chips.find((c) => c.id === chipId)
  if (chip === undefined) throw new Error(`Unknown chip: ${chipId}`)
  return {
    ...h,
    chips: h.chips.map((c) =>
      c.id === chipId
        ? { ...c, confirmedBy: practitioner.id, confirmedAt: now, correctedTo }
        : c,
    ),
  }
}

export function unconfirmedChips(h: Handover): ConfirmableChip[] {
  return h.chips.filter((c) => c.confirmedAt === null)
}

export function openFlags(h: Handover): HandoverFlag[] {
  return h.flags.filter((f) => f.state === 'open')
}

/**
 * Signing — the ONLY hard block in the clinician app, and it blocks on
 * exactly one thing: unconfirmed chips (§2.3). Open omission flags never
 * block (§2.4); they require a recorded reason and export visibly.
 */
export function sign(
  h: Handover,
  practitioner: Practitioner,
  opts: { openFlagReason?: string } = {},
  now: number = Date.now(),
): Handover {
  if (h.status !== 'draft_ready') throw new IllegalTransitionError(h.status, 'signed')

  const unconfirmed = unconfirmedChips(h)
  if (unconfirmed.length > 0)
    throw new UnconfirmedChipsError(unconfirmed.map((c) => c.id))

  const open = openFlags(h)
  const reason = opts.openFlagReason?.trim() || null
  if (open.length > 0 && reason === null) throw new MissingFlagReasonError(open.length)

  return {
    ...h,
    status: 'signed',
    flags: h.flags.map((f) =>
      f.state === 'open'
        ? { ...f, state: 'acknowledged_in_signing' as const, signingNote: reason }
        : f,
    ),
    signature: {
      practitionerId: practitioner.id,
      signatureIdentity: practitioner.signatureIdentity,
      signedAt: now,
      openFlagReason: open.length > 0 ? reason : null,
    },
  }
}

/**
 * HANDOFF §2.5 — post-signature edits invalidate the signature and require
 * explicit re-signing. The original is returned unchanged apart from the
 * supersededBy link; the new draft starts unsigned with every chip
 * confirmation reset (edited content must be re-verified).
 */
export function supersede(
  original: Handover,
  now: number = Date.now(),
): { original: Handover; draft: Handover } {
  if (original.signature === null)
    throw new Error('Only a signed handover can be superseded — edit the draft directly.')

  const draftId = newId('handover')
  return {
    original: { ...original, supersededBy: draftId },
    draft: {
      ...original,
      id: draftId,
      createdAt: now,
      status: 'draft_ready',
      signature: null,
      version: original.version + 1,
      supersedes: original.id,
      supersededBy: null,
      exportError: null,
      acknowledgedAt: null,
      chips: original.chips.map((c) => ({
        ...c,
        confirmedBy: null,
        confirmedAt: null,
      })),
      flags: original.flags.map((f) => ({
        ...f,
        state: 'open' as const,
        signingNote: null,
      })),
    },
  }
}
