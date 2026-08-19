/**
 * HANDOFF §2.10 — the queue is never risk-ordered.
 *
 * The triage queue sorts by wait time and file completeness ONLY. This input
 * type carries no severity, urgency, or risk field — a risk sort cannot even
 * be expressed through this API. That is deliberate: ordering by risk would be
 * triage performed by software, the regulatory line this architecture exists
 * to stay behind.
 */

export interface QueueEntry {
  id: string
  /** Epoch ms the file arrived. Earlier = waited longer. */
  receivedAt: number
  /** 0..1 — share of template fields with content (see fileCompleteness). */
  completeness: number
}

/**
 * Longest wait first; among equal waits, more complete files first (they can
 * be reviewed immediately); id as the final deterministic tie-break.
 */
export function orderQueue<T extends QueueEntry>(entries: readonly T[]): T[] {
  return [...entries].sort(
    (a, b) =>
      a.receivedAt - b.receivedAt ||
      b.completeness - a.completeness ||
      a.id.localeCompare(b.id),
  )
}

/** The sort order, stated on screen next to the queue (HANDOFF §7 Live). */
export const QUEUE_SORT_STATEMENT =
  'Sorted by wait time, then file completeness. Never by clinical risk.'
