import type { FormularyEntry, DrugMatch } from './formulary'
import { matchDrug } from './formulary'

/**
 * HANDOFF §2.3 — drug names and numeric values become chips that each require
 * INDIVIDUAL confirmation before signing. Extraction is deterministic text
 * processing (no model): same transcript + same formulary → same chips.
 */

export type ChipKind = 'drug' | 'number'

export interface ExtractedChip {
  /** Deterministic id derived from kind + character offset. */
  id: string
  kind: ChipKind
  /** Exact source text from the transcript. */
  text: string
  start: number
  end: number
  match: DrugMatch | null
}

const NUMBER_PATTERN =
  /\b\d+(?:\.\d+)?\s?(?:mg|mcg|micrograms?|milligrams?|g|ml|mls|l|units?|mmol(?:\/l)?|bpm|%|degrees|°c)\b|\b\d{2,3}\/\d{2,3}\b/gi

const WORD_PATTERN = /[a-zA-Z][a-zA-Z-]{3,}/g

export function extractChips(
  transcript: string,
  formulary: readonly FormularyEntry[],
): ExtractedChip[] {
  const chips: ExtractedChip[] = []

  for (const m of transcript.matchAll(NUMBER_PATTERN)) {
    const start = m.index
    chips.push({
      id: `number-${start}`,
      kind: 'number',
      text: m[0],
      start,
      end: start + m[0].length,
      match: null,
    })
  }

  for (const m of transcript.matchAll(WORD_PATTERN)) {
    const word = m[0]
    const match = matchDrug(word, formulary)
    // A word becomes a drug chip when it is exactly a formulary name or a
    // near-miss of one (the dangerous case). Unrelated words never match.
    if (match.confidence === 'high' || match.confidence === 'low') {
      const start = m.index
      chips.push({
        id: `drug-${start}`,
        kind: 'drug',
        text: word,
        start,
        end: start + word.length,
        match,
      })
    }
  }

  return chips.sort((a, b) => a.start - b.start)
}
