/**
 * HANDOFF §4.4 — Drug name safety layer. The highest-value component in the
 * system: a sound-alike substitution (furosemide/fluoxetine) is the most
 * dangerous failure this product can produce, and this layer is the only
 * interception.
 *
 * Correction is recognition, never recall: the picker searches the formulary
 * and shows sound-alike pairs together. Free-text spelling is never offered.
 */

export interface FormularyEntry {
  id: string
  name: string
  /** Entries sharing a group are sound-alikes and are always displayed together. */
  soundAlikeGroup: string | null
}

export type MatchConfidence = 'high' | 'low' | 'none'

export interface DrugMatch {
  /** The term exactly as transcribed. */
  term: string
  entryId: string | null
  entryName: string | null
  confidence: MatchConfidence
  /** Nearby formulary names (incl. sound-alike partners), nearest first. */
  candidates: string[]
}

/** Plain Levenshtein distance — deterministic, dependency-free. */
export function levenshtein(a: string, b: string): number {
  if (a === b) return 0
  if (a.length === 0) return b.length
  if (b.length === 0) return a.length
  let prev = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    const curr = [i]
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1
      curr[j] = Math.min(
        (curr[j - 1] as number) + 1,
        (prev[j] as number) + 1,
        (prev[j - 1] as number) + cost,
      )
    }
    prev = curr
  }
  return prev[b.length] as number
}

const norm = (s: string) => s.trim().toLowerCase()

function soundAlikePartners(
  entry: FormularyEntry,
  formulary: readonly FormularyEntry[],
): FormularyEntry[] {
  if (entry.soundAlikeGroup === null) return []
  return formulary.filter(
    (e) => e.id !== entry.id && e.soundAlikeGroup === entry.soundAlikeGroup,
  )
}

/**
 * Match one transcribed term against the formulary.
 * distance 0 → high · distance ≤ 2 → low (flagged for review) · else none
 * (chip requires explicit confirmation). Candidates always include the
 * sound-alike partners of anything close — that is the whole point.
 */
export function matchDrug(
  term: string,
  formulary: readonly FormularyEntry[],
): DrugMatch {
  const t = norm(term)
  const scored = formulary
    .map((entry) => ({ entry, d: levenshtein(t, norm(entry.name)) }))
    .sort((a, b) => a.d - b.d || a.entry.name.localeCompare(b.entry.name))

  const best = scored[0]
  if (best === undefined) {
    return { term, entryId: null, entryName: null, confidence: 'none', candidates: [] }
  }

  const near = scored.filter((s) => s.d <= 3).map((s) => s.entry)
  const withPartners = new Map<string, FormularyEntry>()
  for (const e of near) {
    withPartners.set(e.id, e)
    for (const p of soundAlikePartners(e, formulary)) withPartners.set(p.id, p)
  }
  const candidates = [...withPartners.values()].map((e) => e.name)

  if (best.d === 0) {
    return {
      term,
      entryId: best.entry.id,
      entryName: best.entry.name,
      confidence: 'high',
      candidates,
    }
  }
  if (best.d <= 2) {
    return {
      term,
      entryId: best.entry.id,
      entryName: best.entry.name,
      confidence: 'low',
      candidates,
    }
  }
  return { term, entryId: null, entryName: null, confidence: 'none', candidates: [] }
}

/**
 * Formulary picker search (screen 6). Returns clusters: each cluster is either
 * a sound-alike group (displayed together, always complete) or a singleton.
 * Clusters are ordered by their best match to the query.
 */
export function searchFormulary(
  query: string,
  formulary: readonly FormularyEntry[],
): FormularyEntry[][] {
  const q = norm(query)
  const matches = formulary.filter((e) => {
    const n = norm(e.name)
    return q === '' || n.includes(q) || levenshtein(q, n) <= 2
  })

  const clusters = new Map<string, FormularyEntry[]>()
  const order: string[] = []
  for (const e of matches) {
    const key = e.soundAlikeGroup ?? `solo:${e.id}`
    if (!clusters.has(key)) {
      // A sound-alike cluster is always shown complete, even if only one
      // member matched the query — the near-miss is what must be visible.
      const members =
        e.soundAlikeGroup === null
          ? [e]
          : formulary.filter((f) => f.soundAlikeGroup === e.soundAlikeGroup)
      clusters.set(key, [...members].sort((a, b) => a.name.localeCompare(b.name)))
      order.push(key)
    }
  }
  return order.map((k) => clusters.get(k) as FormularyEntry[])
}
