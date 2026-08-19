/**
 * HANDOFF §2.9 — staff wellbeing responses are aggregate and anonymous only,
 * suppressed below five responses. When suppressed, the count itself is not
 * disclosed (a count of "4" narrows identity in a small team).
 */

export const WELLBEING_SUPPRESSION_THRESHOLD = 5

export type WellbeingAggregate =
  | { suppressed: true; reason: string }
  | { suppressed: false; count: number; mean: number }

export function aggregateWellbeing(
  scores: readonly number[],
): WellbeingAggregate {
  if (scores.length < WELLBEING_SUPPRESSION_THRESHOLD) {
    return {
      suppressed: true,
      reason: `Fewer than ${WELLBEING_SUPPRESSION_THRESHOLD} responses — aggregate withheld to protect anonymity.`,
    }
  }
  const mean = scores.reduce((s, v) => s + v, 0) / scores.length
  return { suppressed: false, count: scores.length, mean: Math.round(mean * 10) / 10 }
}
