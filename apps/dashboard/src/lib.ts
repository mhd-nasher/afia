import { useEffect, useState } from 'react'
import type { PatientCase } from '@afia/core'
import { store } from './store'

/** Re-render on an interval so wait times stay honest without a reload. */
export function useNow(intervalMs = 30_000): number {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    const id = window.setInterval(() => setNow(Date.now()), intervalMs)
    return () => window.clearInterval(id)
  }, [intervalMs])
  return now
}

export function fmtTime(t: number): string {
  return new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

export function fmtDateTime(t: number): string {
  return new Date(t).toLocaleString([], {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function minutesSince(t: number, now: number): number {
  return Math.max(0, Math.floor((now - t) / 60_000))
}

/** "52 min" / "3 h 12 min" — always rendered in mono by the caller. */
export function fmtMinutes(min: number): string {
  if (min < 60) return `${min} min`
  return `${Math.floor(min / 60)} h ${min % 60} min`
}

/** Epoch ms the case's file arrived = the first update's `at`. */
export function caseReceivedAt(c: PatientCase): number {
  return c.updates[0]?.at ?? c.createdAt
}

/**
 * File completeness for the queue: answered red-flag + functional answers
 * (anything not NOT_ASKED — an explicit "I don't know" IS an answer, §2.2)
 * divided by the total number of configured questions.
 */
export function caseCompleteness(c: PatientCase): {
  completeness: number
  answered: number
  total: number
  unanswered: number
} {
  const total = store.redFlagQuestions().length + store.functionalQuestions().length
  const latest = c.updates[c.updates.length - 1]
  if (latest === undefined) {
    return { completeness: 0, answered: 0, total, unanswered: total }
  }
  const answered =
    latest.redFlagAnswers.filter((a) => a.answer !== 'NOT_ASKED').length +
    latest.functionalAnswers.filter((a) => a.value !== 'NOT_ASKED').length
  return {
    completeness: total === 0 ? 1 : answered / total,
    answered,
    total,
    unanswered: Math.max(0, total - answered),
  }
}

export function pct(x: number): string {
  return `${Math.round(x * 100)}%`
}

export function actorName(actor: string): string {
  return store.practitioner(actor)?.name ?? actor
}

export function wardName(wardId: string): string {
  return store.ward(wardId)?.name ?? wardId
}

export const ROLE_LABELS: Record<string, string> = {
  nurse: 'Nurse',
  doctor: 'Doctor',
  charge_nurse: 'Charge nurse',
  manager: 'Manager',
}
