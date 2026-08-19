import type { AnswerState, FunctionalValue } from '@afia/rules'
import type { AudioRecording } from '@afia/core'

/**
 * In-progress episode state — current step plus every partial answer.
 * Persisted to localStorage under 'afia-patient-episode' on EVERY change,
 * so a refresh resumes exactly where the person was. No unsaved state
 * exists (HANDOFF §6 / F-055).
 */

export const EPISODE_KEY = 'afia-patient-episode'

export type StepKind =
  | 'entry'
  | 'redflag'
  | 'who'
  | 'voice'
  | 'functional'
  | 'review'
  | 'status'
  | 'update-redflag'
  | 'update-delta'
  | 'update-confirm'

const STEP_KINDS: readonly StepKind[] = [
  'entry',
  'redflag',
  'who',
  'voice',
  'functional',
  'review',
  'status',
  'update-redflag',
  'update-delta',
  'update-confirm',
]

export interface Step {
  kind: StepKind
  /** Question index for redflag / functional / update-redflag; 0 otherwise. */
  index: number
}

/** Draft of a "my condition has changed" update — fresh red-flag answers + delta. */
export interface UpdateDraft {
  redFlagAnswers: Record<string, AnswerState>
  transcript: string
  audio: AudioRecording | null
}

export interface EpisodeState {
  step: Step
  /** Set when an Edit button on the review screen jumped back to a question. */
  returnTo: 'review' | null
  name: string
  termsAccepted: boolean
  consentGiven: boolean
  consentId: string | null
  completedBy: 'self' | 'carer' | null
  redFlagAnswers: Record<string, AnswerState>
  transcript: string
  audio: AudioRecording | null
  functionalAnswers: Record<string, FunctionalValue>
  caseId: string | null
  /** True while the emergency interrupt is shown; persisted so refresh resumes it. */
  emergency: boolean
  update: UpdateDraft | null
}

export function emptyUpdateDraft(): UpdateDraft {
  return { redFlagAnswers: {}, transcript: '', audio: null }
}

export function initialEpisode(): EpisodeState {
  return {
    step: { kind: 'entry', index: 0 },
    returnTo: null,
    name: '',
    termsAccepted: false,
    consentGiven: false,
    consentId: null,
    completedBy: null,
    redFlagAnswers: {},
    transcript: '',
    audio: null,
    functionalAnswers: {},
    caseId: null,
    emergency: false,
    update: null,
  }
}

export function loadEpisode(): EpisodeState {
  try {
    const raw = window.localStorage.getItem(EPISODE_KEY)
    if (raw === null || raw === '') return initialEpisode()
    const parsed = JSON.parse(raw) as Partial<EpisodeState> | null
    if (parsed === null || typeof parsed !== 'object') return initialEpisode()
    const step = parsed.step
    if (step === undefined || !STEP_KINDS.includes(step.kind)) return initialEpisode()
    return {
      ...initialEpisode(),
      ...parsed,
      step: { kind: step.kind, index: typeof step.index === 'number' ? step.index : 0 },
    }
  } catch {
    return initialEpisode()
  }
}

export function saveEpisode(e: EpisodeState): void {
  window.localStorage.setItem(EPISODE_KEY, JSON.stringify(e))
}

export function clearEpisode(): void {
  window.localStorage.removeItem(EPISODE_KEY)
}

/** Short human-readable case reference from a case id. */
export function shortRef(caseId: string): string {
  return caseId.replace(/[^a-z0-9]/gi, '').slice(-6).toUpperCase()
}
