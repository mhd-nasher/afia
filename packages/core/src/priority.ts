/**
 * HANDOFF §2.1 — Escalation is one-way.
 *
 * escalate() is the ONLY function in the codebase that changes a priority,
 * and it is monotonic: it returns the higher of the two values. There is no
 * decreasePriority, no markAsNormal, no reset. A downgrade cannot be
 * expressed through this module, which is the point — a false negative here
 * kills someone.
 */

export const PRIORITY_LEVELS = ['routine', 'elevated', 'urgent'] as const
export type Priority = (typeof PRIORITY_LEVELS)[number]

const RANK: Record<Priority, number> = { routine: 0, elevated: 1, urgent: 2 }

export function escalate(current: Priority, proposed: Priority): Priority {
  return RANK[proposed] > RANK[current] ? proposed : current
}

export function priorityRank(p: Priority): number {
  return RANK[p]
}
