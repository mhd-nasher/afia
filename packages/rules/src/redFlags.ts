import type { AnswerState, FunctionalValue } from './answer'

/**
 * HANDOFF §2.7 — Emergency escalation is local and deterministic.
 *
 * Red-flag evaluation is a pure function with zero I/O: no network call, no
 * model inference, no server round-trip. It must produce identical output in
 * airplane mode — that property is a test case (T-007).
 */

/** HANDOFF §7 — every clinical rule carries an approval record. */
export interface ApprovalRecord {
  approvedBy: string
  role: string
  approvedAt: number
}

export interface RedFlagQuestion {
  id: string
  text: string
  /** null = unapproved → the dashboard renders a caution state. */
  approval: ApprovalRecord | null
}

export interface RedFlagAnswer {
  questionId: string
  answer: AnswerState
}

export interface RedFlagResult {
  /** True iff at least one question is answered YES. */
  triggered: boolean
  /** Question ids answered YES. */
  triggeredBy: string[]
  /**
   * Question ids left UNKNOWN or NOT_ASKED. Listed, never coerced to NO
   * (§2.2). Unanswered questions do not trigger, and they never reduce
   * whatever priority the case already has.
   */
  unanswered: string[]
}

export function evaluateRedFlags(
  questions: readonly RedFlagQuestion[],
  answers: readonly RedFlagAnswer[],
): RedFlagResult {
  const byId = new Map<string, AnswerState>()
  for (const a of answers) byId.set(a.questionId, a.answer)

  const triggeredBy: string[] = []
  const unanswered: string[] = []

  for (const q of questions) {
    const answer = byId.get(q.id) ?? 'NOT_ASKED'
    if (answer === 'YES') triggeredBy.push(q.id)
    else if (answer === 'UNKNOWN' || answer === 'NOT_ASKED') unanswered.push(q.id)
  }

  return { triggered: triggeredBy.length > 0, triggeredBy, unanswered }
}

/**
 * HANDOFF §2.7 — emergency numbers are bundled at install, never fetched.
 * Bahrain (confirmed jurisdiction; Firestore region me-central2 is the
 * nearest GCP region): 999 = unified emergency (ambulance/police/fire) ·
 * 444 = Ministry of Health advice line.
 */
export const EMERGENCY_NUMBERS = {
  emergency: '999',
  urgentAdvice: '444',
} as const

/** Functional questions are configured rules with the same approval shape. */
export interface FunctionalQuestion {
  id: string
  text: string
  approval: ApprovalRecord | null
}

export interface FunctionalAnswer {
  questionId: string
  value: FunctionalValue
}

/**
 * Deterministic, configured escalation from the patient's own answers —
 * this is the patient's information raising urgency (§2.1 allows raising),
 * not a model judging severity (§4.3 forbids that).
 * Returns the floor priority the answers justify; the caller merges it with
 * escalate(), which can only raise.
 */
export function functionalEscalation(
  answers: readonly FunctionalAnswer[],
): 'none' | 'elevated' {
  return answers.some((a) => a.value === 'MUCH_WORSE') ? 'elevated' : 'none'
}
