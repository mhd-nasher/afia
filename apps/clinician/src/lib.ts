import type { Practitioner } from '@afia/core'

/** Whole years since a YYYY-MM-DD date of birth. */
export function ageFrom(dateOfBirth: string): number {
  const dob = new Date(dateOfBirth)
  const now = new Date()
  let age = now.getFullYear() - dob.getFullYear()
  const monthDiff = now.getMonth() - dob.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dob.getDate())) age -= 1
  return age
}

export function clock(ts: number): string {
  return new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

export function timeAgo(ts: number): string {
  const mins = Math.max(0, Math.round((Date.now() - ts) / 60_000))
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins} min ago`
  const h = Math.floor(mins / 60)
  return `${h} h ${mins % 60} min ago`
}

export function fmtElapsed(totalSeconds: number): string {
  const m = Math.floor(totalSeconds / 60)
  const s = totalSeconds % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

const ROLE_LABELS: Record<Practitioner['role'], string> = {
  nurse: 'Nurse',
  doctor: 'Doctor',
  charge_nurse: 'Charge nurse',
  manager: 'Manager',
}

export function roleLabel(role: Practitioner['role']): string {
  return ROLE_LABELS[role]
}

/**
 * Split a vitals sentence ("BP 110/70 · sats 94% on 2 L · taken 06:00.")
 * into aligned label/value rows for the mono table on patient detail.
 */
export function vitalRows(text: string): Array<{ label: string; value: string }> {
  return text
    .split('·')
    .map((seg) => seg.trim().replace(/\.$/, ''))
    .filter((seg) => seg !== '')
    .map((seg) => {
      const m = seg.match(/^([A-Za-z][A-Za-z %/]*?)\s+(\d.*)$/)
      if (m !== null && m[1] !== undefined && m[2] !== undefined) {
        return { label: m[1].trim(), value: m[2].trim() }
      }
      return { label: seg, value: '' }
    })
}

/** Blob → data URI, for persisting the recording inside the store. */
export function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(reader.error ?? new Error('Could not read recording'))
    reader.readAsDataURL(blob)
  })
}
