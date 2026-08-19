import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it, vi } from 'vitest'
import {
  EMERGENCY_NUMBERS,
  QUEUE_SORT_STATEMENT,
  aggregateWellbeing,
  detectGaps,
  evaluateRedFlags,
  extractChips,
  fileCompleteness,
  functionalEscalation,
  levenshtein,
  matchDrug,
  orderQueue,
  searchFormulary,
  type RedFlagQuestion,
  type TemplateField,
} from './index'

const __dir = dirname(fileURLToPath(import.meta.url))

const QUESTIONS: RedFlagQuestion[] = [
  { id: 'q1', text: 'Chest pain?', approval: null },
  { id: 'q2', text: 'Severe breathlessness?', approval: null },
  { id: 'q3', text: 'Uncontrolled bleeding?', approval: null },
]

const TEMPLATE: TemplateField[] = [
  { id: 'meds', label: 'Medications given', required: true, keywords: [] },
  { id: 'vitals', label: 'Latest vitals', required: true, keywords: [] },
  { id: 'notes', label: 'Notes', required: false, keywords: [] },
]

const FORMULARY = [
  { id: 'f1', name: 'furosemide', soundAlikeGroup: 'g1' },
  { id: 'f2', name: 'fluoxetine', soundAlikeGroup: 'g1' },
  { id: 'f3', name: 'paracetamol', soundAlikeGroup: null },
]

describe('T-002 — absent is not normal (§2.2)', () => {
  it('UNKNOWN and NOT_ASKED never count as NO and never trigger', () => {
    const result = evaluateRedFlags(QUESTIONS, [
      { questionId: 'q1', answer: 'UNKNOWN' },
      { questionId: 'q2', answer: 'NO' },
      // q3 not asked at all
    ])
    expect(result.triggered).toBe(false)
    expect(result.unanswered).toEqual(['q1', 'q3'])
  })

  it('a single YES triggers regardless of unknowns', () => {
    const result = evaluateRedFlags(QUESTIONS, [
      { questionId: 'q1', answer: 'UNKNOWN' },
      { questionId: 'q2', answer: 'YES' },
    ])
    expect(result.triggered).toBe(true)
    expect(result.triggeredBy).toEqual(['q2'])
    expect(result.unanswered).toContain('q1')
  })

  it('UNKNOWN functional answers never escalate (and never de-escalate)', () => {
    expect(functionalEscalation([{ questionId: 'fn1', value: 'UNKNOWN' }])).toBe('none')
    expect(
      functionalEscalation([
        { questionId: 'fn1', value: 'UNKNOWN' },
        { questionId: 'fn2', value: 'MUCH_WORSE' },
      ]),
    ).toBe('elevated')
  })
})

describe('T-007 — red flags are local and deterministic (§2.7)', () => {
  it('works in airplane mode: identical output with all network APIs poisoned', () => {
    const noNetwork = () => {
      throw new Error('NETWORK CALL ATTEMPTED — §2.7 violated')
    }
    vi.stubGlobal('fetch', noNetwork)
    vi.stubGlobal('XMLHttpRequest', noNetwork)
    vi.stubGlobal('WebSocket', noNetwork)
    try {
      const answers = [{ questionId: 'q1', answer: 'YES' as const }]
      const a = evaluateRedFlags(QUESTIONS, answers)
      const b = evaluateRedFlags(QUESTIONS, answers)
      expect(a).toEqual(b)
      expect(a.triggered).toBe(true)
    } finally {
      vi.unstubAllGlobals()
    }
  })

  it('emergency numbers are bundled constants, not fetched (Bahrain: 999 emergency, 444 health line)', () => {
    expect(EMERGENCY_NUMBERS.emergency).toBe('999')
    expect(EMERGENCY_NUMBERS.urgentAdvice).toBe('444')
  })

  it('the rules package source contains no network primitive and no dependencies', () => {
    for (const file of ['redFlags.ts', 'gaps.ts', 'formulary.ts', 'chips.ts', 'queue.ts', 'wellbeing.ts', 'answer.ts']) {
      const src = readFileSync(join(__dir, file), 'utf8')
      expect(src, `${file} must not reference fetch`).not.toMatch(/\bfetch\s*\(/)
      expect(src, `${file} must not reference XMLHttpRequest`).not.toMatch(/XMLHttpRequest/)
      expect(src, `${file} must not import other packages`).not.toMatch(/from '@afia\/(?!rules)/)
    }
    const pkg = JSON.parse(readFileSync(join(__dir, '..', 'package.json'), 'utf8'))
    expect(pkg.dependencies).toEqual({})
  })
})

describe('T-008 — gap detection is deterministic rules, neutrally worded (§2.8, §4.3)', () => {
  it('flags required empty fields in template order with neutral wording', () => {
    const flags = detectGaps(TEMPLATE, [{ fieldId: 'vitals', text: 'BP 120/80' }])
    expect(flags).toEqual([
      { fieldId: 'meds', label: 'Medications given', message: 'Not mentioned: Medications given' },
    ])
  })

  it('same input → same output (determinism, 50 runs)', () => {
    const contents = [{ fieldId: 'meds', text: '  ' }]
    const first = detectGaps(TEMPLATE, contents)
    for (let i = 0; i < 50; i++) expect(detectGaps(TEMPLATE, contents)).toEqual(first)
  })

  it('never uses importance language', () => {
    const flags = detectGaps(TEMPLATE, [])
    for (const f of flags) {
      expect(f.message).toMatch(/^Not mentioned: /)
      expect(f.message.toLowerCase()).not.toContain('critical')
      expect(f.message.toLowerCase()).not.toContain('important')
    }
  })

  it('optional fields are not flagged', () => {
    const flags = detectGaps(TEMPLATE, [
      { fieldId: 'meds', text: 'x' },
      { fieldId: 'vitals', text: 'y' },
    ])
    expect(flags).toEqual([])
  })
})

describe('T-010 — the queue is never risk-ordered (§2.10)', () => {
  it('sorts by wait time then completeness, deterministically', () => {
    const ordered = orderQueue([
      { id: 'c', receivedAt: 300, completeness: 0.2 },
      { id: 'a', receivedAt: 100, completeness: 0.5 },
      { id: 'b', receivedAt: 100, completeness: 0.9 },
      { id: 'd', receivedAt: 200, completeness: 1 },
    ])
    expect(ordered.map((e) => e.id)).toEqual(['b', 'a', 'd', 'c'])
  })

  it('the entry type carries no severity/risk field (compile-time) and the statement is displayed text', () => {
    // @ts-expect-error — severity cannot be expressed through this API (§2.10)
    const entry: import('./queue').QueueEntry = { id: 'x', receivedAt: 1, completeness: 1, severity: 9 }
    void entry
    expect(QUEUE_SORT_STATEMENT).toContain('Never by clinical risk')
  })
})

describe('T-009 — wellbeing aggregates are suppressed below five (§2.9)', () => {
  it('suppresses n<5 without disclosing the count', () => {
    const agg = aggregateWellbeing([3, 4, 4, 2])
    expect(agg.suppressed).toBe(true)
    expect(JSON.stringify(agg)).not.toContain('4')
  })
  it('aggregates at n>=5', () => {
    const agg = aggregateWellbeing([3, 4, 4, 2, 5])
    expect(agg).toEqual({ suppressed: false, count: 5, mean: 3.6 })
  })
})

describe('drug name safety layer (§4.4)', () => {
  it('levenshtein basics', () => {
    expect(levenshtein('furosemide', 'furosemide')).toBe(0)
    expect(levenshtein('furosemide', 'furosemid')).toBe(1)
  })

  it('exact match → high confidence; near-miss → low; unrelated → none', () => {
    expect(matchDrug('furosemide', FORMULARY).confidence).toBe('high')
    expect(matchDrug('furosemid', FORMULARY).confidence).toBe('low')
    expect(matchDrug('wheelchair', FORMULARY).confidence).toBe('none')
  })

  it('candidates for a match always include its sound-alike partner', () => {
    const m = matchDrug('furosemide', FORMULARY)
    expect(m.candidates).toContain('fluoxetine')
  })

  it('picker search returns sound-alike clusters complete', () => {
    const clusters = searchFormulary('furos', FORMULARY)
    expect(clusters[0]?.map((e) => e.name).sort()).toEqual(['fluoxetine', 'furosemide'])
  })

  it('chips extraction finds drugs and dosed numbers deterministically', () => {
    const text = 'Gave furosemide 40 mg IV, obs 110/70, then paracetamol 1 g.'
    const chips = extractChips(text, FORMULARY)
    const kinds = chips.map((c) => `${c.kind}:${c.text}`)
    expect(kinds).toContain('drug:furosemide')
    expect(kinds).toContain('drug:paracetamol')
    expect(kinds).toContain('number:40 mg')
    expect(kinds).toContain('number:110/70')
    expect(extractChips(text, FORMULARY)).toEqual(chips)
  })
})

describe('completeness (queue second key)', () => {
  it('is the share of template fields with content', () => {
    expect(fileCompleteness(TEMPLATE, [{ fieldId: 'meds', text: 'x' }])).toBeCloseTo(1 / 3)
    expect(fileCompleteness(TEMPLATE, [])).toBe(0)
  })
})
