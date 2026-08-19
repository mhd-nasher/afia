import type {
  AnswerState,
  FunctionalAnswer,
  RedFlagResult,
} from '@afia/rules'
import { functionalEscalation } from '@afia/rules'
import type { BaseEntity } from './entities'
import type { AudioRecording } from './handover'
import { escalate, type Priority } from './priority'

/**
 * A patient-app episode. One case per attendance; "my condition has changed"
 * APPENDS an update to the same case (HANDOFF §6) — it never re-queues,
 * never resets, never creates a second case.
 */

export interface CaseAnswer {
  questionId: string
  answer: AnswerState
}

export interface CaseUpdate {
  id: string
  at: number
  kind: 'initial' | 'condition_changed'
  transcript: string
  audio: AudioRecording | null
  redFlagAnswers: CaseAnswer[]
  redFlags: RedFlagResult
  functionalAnswers: FunctionalAnswer[]
  /**
   * §6 offline honesty — 'queued_on_device' renders as "saved on this device,
   * not yet sent"; the UI never implies a nurse has seen it.
   */
  syncState: 'queued_on_device' | 'sent'
}

export interface PatientCase extends BaseEntity {
  patientName: string
  completedBy: 'self' | 'carer'
  status: 'in_progress' | 'submitted'
  priority: Priority
  /** Append-only. updates[0] is the initial submission. */
  updates: CaseUpdate[]
  consentId: string | null
}

/**
 * The only way case state advances. Priority moves through escalate() —
 * a red-flag YES raises to urgent, MUCH_WORSE functional answers raise to
 * elevated, and nothing in this module (or anywhere) lowers it (§2.1).
 * UNKNOWN answers change nothing: they never reduce priority (§2.2).
 */
export function appendUpdate(c: PatientCase, update: CaseUpdate): PatientCase {
  let priority = c.priority
  if (update.redFlags.triggered) priority = escalate(priority, 'urgent')
  if (functionalEscalation(update.functionalAnswers) === 'elevated')
    priority = escalate(priority, 'elevated')

  return {
    ...c,
    status: 'submitted',
    priority,
    updates: [...c.updates, update],
  }
}
