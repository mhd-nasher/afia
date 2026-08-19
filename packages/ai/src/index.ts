import type { FieldContent, TemplateField } from '@afia/rules'

/**
 * HANDOFF §4 — the AI layer. Everything here REORGANISES information a human
 * already provided. Nothing here classifies severity, suggests a diagnosis or
 * medication, or ranks importance — those are clinical judgements and are
 * forbidden (§4.3).
 *
 * Every stage is behind an interface (§4.1): a hospital can swap in a locally
 * hosted model without touching business logic. The demo adapters are the
 * browser's speech recognition and a deterministic keyword structurer.
 */

// ── transcription ──────────────────────────────────────────────────────────

export interface Transcriber {
  readonly kind: string
  available(): boolean
  start(onText: (text: string, isFinal: boolean) => void, onError?: (message: string) => void): void
  stop(): void
}

type SpeechRecognitionLike = {
  new (): {
    continuous: boolean
    interimResults: boolean
    lang: string
    onresult: ((event: { resultIndex: number; results: ArrayLike<{ isFinal: boolean; 0: { transcript: string } }> }) => void) | null
    onerror: ((event: { error: string }) => void) | null
    start(): void
    stop(): void
  }
}

function speechApi(): SpeechRecognitionLike | null {
  const w = globalThis as Record<string, unknown>
  return (w['SpeechRecognition'] ?? w['webkitSpeechRecognition'] ?? null) as SpeechRecognitionLike | null
}

/**
 * Browser speech recognition (Chrome/Edge). In production this seat is taken
 * by faster-whisper behind the same interface — accuracy on real ward speech
 * is UNVALIDATED either way (HANDOFF §9.2).
 */
export class BrowserTranscriber implements Transcriber {
  readonly kind = 'browser-speech'
  private recognition: InstanceType<SpeechRecognitionLike> | null = null

  available(): boolean {
    return speechApi() !== null
  }

  start(onText: (text: string, isFinal: boolean) => void, onError?: (message: string) => void): void {
    const Api = speechApi()
    if (Api === null) {
      onError?.('Speech recognition is not available in this browser — type instead.')
      return
    }
    const r = new Api()
    r.continuous = true
    r.interimResults = true
    r.lang = 'en-GB'
    r.onresult = (event) => {
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const result = event.results[i]
        if (result !== undefined) onText(result[0].transcript, result.isFinal)
      }
    }
    r.onerror = (event) => onError?.(`Speech recognition error: ${event.error}`)
    this.recognition = r
    r.start()
  }

  stop(): void {
    this.recognition?.stop()
    this.recognition = null
  }
}

// ── structuring ────────────────────────────────────────────────────────────

export interface Structurer {
  readonly kind: string
  structure(transcript: string, template: readonly TemplateField[]): FieldContent[]
}

/**
 * Deterministic keyword router: splits speech into sentences, scores each
 * against the template's configured keywords, and routes it to the
 * best-matching field. A sentence with no match follows the previous
 * sentence's field (speech flows in topics) — that is the "side note routed
 * to its correct field" behaviour of §4.2, with zero model inference.
 * In production this seat is taken by a fine-tuned 8B model behind the same
 * interface.
 */
export class KeywordStructurer implements Structurer {
  readonly kind = 'keyword-router'

  structure(transcript: string, template: readonly TemplateField[]): FieldContent[] {
    const first = template[0]
    if (first === undefined) return []
    const sentences = transcript
      .split(/(?<=[.!?])\s+|\n+/)
      .map((s) => s.trim())
      .filter((s) => s !== '')

    const buckets = new Map<string, string[]>()
    let currentField = first.id

    for (const sentence of sentences) {
      const lower = sentence.toLowerCase()
      let best: { id: string; score: number } | null = null
      for (const field of template) {
        let score = 0
        for (const kw of field.keywords) if (lower.includes(kw.toLowerCase())) score += 1
        if (score > 0 && (best === null || score > best.score)) best = { id: field.id, score }
      }
      if (best !== null) currentField = best.id
      const bucket = buckets.get(currentField) ?? []
      bucket.push(sentence)
      buckets.set(currentField, bucket)
    }

    return template
      .filter((f) => buckets.has(f.id))
      .map((f) => ({ fieldId: f.id, text: (buckets.get(f.id) as string[]).join(' ') }))
  }
}

// ── reader aids (§4.2 — reorganisation only) ───────────────────────────────

/** Ten-second summary: the situation, medications, and plan the author already stated. */
export function tenSecondSummary(
  fields: readonly FieldContent[],
  template: readonly TemplateField[],
): string {
  const pick = (id: string) => fields.find((f) => f.fieldId === id)?.text.trim() ?? ''
  const preferred = ['situation', 'medications', 'plan']
    .map(pick)
    .filter((t) => t !== '')
  if (preferred.length > 0) return preferred.join(' · ')
  const firstFilled = template
    .map((t) => pick(t.id))
    .find((t) => t !== '')
  return firstFilled ?? ''
}

export type FieldDiff = {
  fieldId: string
  label: string
  kind: 'added' | 'changed' | 'unchanged' | 'now-empty'
  text: string
}

/** Diff against the previous handover — what changed, stated neutrally. */
export function diffHandovers(
  previous: readonly FieldContent[],
  current: readonly FieldContent[],
  template: readonly TemplateField[],
): FieldDiff[] {
  const prev = new Map(previous.map((f) => [f.fieldId, f.text.trim()]))
  const curr = new Map(current.map((f) => [f.fieldId, f.text.trim()]))
  return template.map((field) => {
    const p = prev.get(field.id) ?? ''
    const c = curr.get(field.id) ?? ''
    const kind: FieldDiff['kind'] =
      p === c ? 'unchanged' : p === '' ? 'added' : c === '' ? 'now-empty' : 'changed'
    return { fieldId: field.id, label: field.label, kind, text: c }
  })
}

/** Merge interrupted recording segments in order (§4.2). */
export function mergeSegments(segments: readonly string[]): string {
  return segments.map((s) => s.trim()).filter((s) => s !== '').join(' ')
}
