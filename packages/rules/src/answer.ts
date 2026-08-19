/**
 * HANDOFF §2.2 — Absent is not normal.
 *
 * Missing, skipped, unanswered, or low-confidence data is UNKNOWN — a distinct
 * value from a normal reading and from a negative answer. UNKNOWN is never
 * coerced to NO or to a default, and UNKNOWN never reduces priority.
 */
export const ANSWER_STATES = ['YES', 'NO', 'UNKNOWN', 'NOT_ASKED'] as const
export type AnswerState = (typeof ANSWER_STATES)[number]

export function isAffirmative(answer: AnswerState): boolean {
  return answer === 'YES'
}

/**
 * UNKNOWN and NOT_ASKED are "unanswered", which is not the same as "no".
 * There is deliberately no isNegative() helper that lumps UNKNOWN with NO —
 * that helper is the code path §2.2 forbids.
 */
export function isUnanswered(answer: AnswerState): boolean {
  return answer === 'UNKNOWN' || answer === 'NOT_ASKED'
}

/**
 * Baseline-anchored functional answers (patient app, HANDOFF §6).
 * "I don't know" is first-class and stored as UNKNOWN.
 */
export const FUNCTIONAL_VALUES = ['SAME_AS_NORMAL', 'WORSE', 'MUCH_WORSE', 'UNKNOWN', 'NOT_ASKED'] as const
export type FunctionalValue = (typeof FUNCTIONAL_VALUES)[number]
