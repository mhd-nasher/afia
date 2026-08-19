import { newId } from './ids'

/**
 * HANDOFF §3.4 — every state transition is recorded and immutable. The log
 * exposes append and read; there is no update, no delete, no edit-in-place.
 */

export const AUDIT_ACTIONS = [
  'created',
  'recorded',
  'transcribed',
  'structured',
  'flagged',
  'corrected',
  'chip_confirmed',
  'signed',
  'exported',
  'export_failed',
  'confirmed',
  'superseded',
  'escalated',
  'case_submitted',
  'case_updated',
  'consent_granted',
  'consent_withdrawn',
  'sign_in',
  'sign_out',
  'template_edited',
  'rule_edited',
] as const
export type AuditAction = (typeof AUDIT_ACTIONS)[number]

export interface AuditEvent {
  id: string
  at: number
  actor: string
  action: AuditAction
  entityId: string
  previousValue: unknown
  detail: string | null
}

export class AuditLog {
  private events: AuditEvent[] = []

  append(e: Omit<AuditEvent, 'id'>): AuditEvent {
    const event: AuditEvent = { ...e, id: newId('audit') }
    this.events.push(event)
    return event
  }

  read(): readonly AuditEvent[] {
    return [...this.events]
  }

  /** Restore from persistence — replaces nothing, only rehydrates. */
  static from(events: readonly AuditEvent[]): AuditLog {
    const log = new AuditLog()
    log.events = [...events]
    return log
  }
}
