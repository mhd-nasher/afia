import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react'
import {
  evaluateRedFlags,
  type AnswerState,
  type FunctionalAnswer,
  type FunctionalValue,
  type RedFlagAnswer,
} from '@afia/rules'
import { newId, type CaseUpdate } from '@afia/core'
import { SafetyDock } from './components/SafetyDock'
import { EmergencyInterrupt } from './components/EmergencyInterrupt'
import { Entry } from './screens/Entry'
import { RedFlagScreen } from './screens/RedFlag'
import { WhoScreen } from './screens/Who'
import { DescribeScreen } from './screens/Describe'
import { FunctionalScreen } from './screens/Functional'
import { ReviewScreen } from './screens/Review'
import { StatusScreen } from './screens/Status'
import { UpdateConfirmScreen } from './screens/UpdateConfirm'
import {
  clearEpisode,
  emptyUpdateDraft,
  initialEpisode,
  loadEpisode,
  saveEpisode,
  shortRef,
  type EpisodeState,
  type Step,
} from './episode'
import { store, useStoreSnapshot } from './store'

/**
 * One linear flow, one question per screen, a single large Continue.
 * NO tab bar, NO bottom navigation, NO progress bar, NO step counter (§6 /
 * F-050). The safety dock and the demo banner live outside this hierarchy.
 *
 * Every piece of episode state persists on every change (F-055) — a refresh
 * resumes exactly where the person was.
 */

function toRedFlagPairs(answers: Record<string, AnswerState>): RedFlagAnswer[] {
  return Object.entries(answers).map(([questionId, answer]) => ({ questionId, answer }))
}

function toFunctionalPairs(answers: Record<string, FunctionalValue>): FunctionalAnswer[] {
  return Object.entries(answers).map(([questionId, value]) => ({ questionId, value }))
}

export function App() {
  const snapshot = useStoreSnapshot()
  const [episode, setEpisodeState] = useState<EpisodeState>(() => loadEpisode())

  /** The single write path: persist to localStorage, then render. */
  const update = useCallback((fn: (e: EpisodeState) => EpisodeState) => {
    setEpisodeState((prev) => {
      const next = fn(prev)
      saveEpisode(next)
      return next
    })
  }, [])

  const redFlagQs = snapshot.redFlagQuestions
  const functionalQs = snapshot.functionalQuestions
  const patientCase =
    episode.caseId !== null ? snapshot.cases.find((c) => c.id === episode.caseId) : undefined

  // ── offline honesty: an update is "sent" only once the store's flush()
  // resolves — for the Firebase backend that is SERVER acknowledgement, never
  // navigator.onLine, never local echo (§6: don't imply the team received it).
  const caseIdRef = useRef(episode.caseId)
  caseIdRef.current = episode.caseId
  useEffect(() => {
    const confirmSent = () => {
      const id = caseIdRef.current
      if (id === null) return
      void store.flush().then(() => {
        const c = store.caseById(id)
        if (c === undefined) return
        for (const u of c.updates) {
          if (u.syncState === 'queued_on_device') store.markUpdateSent(id, u.id)
        }
      })
    }
    confirmSent()
    window.addEventListener('online', confirmSent)
    return () => window.removeEventListener('online', confirmSent)
  }, [episode.caseId])

  // ── flow actions ──────────────────────────────────────────────────────────

  const startEpisode = () => {
    let consentId = episode.consentId
    if (consentId === null) {
      const record = store.grantConsent(episode.name.trim() || 'anonymous', 'symptom_submission')
      consentId = record.id
    }
    update((e) => ({ ...e, consentId, step: { kind: 'redflag', index: 0 } }))
  }

  const resetDemo = () => {
    store.resetDemo()
    clearEpisode()
    window.location.reload()
  }

  /**
   * Red flags are evaluated LOCALLY after EVERY answer (§2.7 — pure function,
   * no network, instant, works in airplane mode). A YES shows the emergency
   * interrupt immediately. Going back un-does nothing: the answer stays
   * recorded, and once a case exists its priority is escalated one-way.
   */
  const answerRedFlag = (questionId: string, answer: AnswerState) => {
    const isUpdateFlow = episode.step.kind === 'update-redflag'
    const answers = isUpdateFlow
      ? { ...(episode.update ?? emptyUpdateDraft()).redFlagAnswers, [questionId]: answer }
      : { ...episode.redFlagAnswers, [questionId]: answer }

    const result = evaluateRedFlags(redFlagQs, toRedFlagPairs(answers))
    const fired = answer === 'YES' && result.triggered
    if (fired && episode.caseId !== null) {
      // The case already exists — escalate now. escalate() is monotonic;
      // there is no downgrade API and none is built here.
      store.escalateCase(episode.caseId, 'urgent', episode.name.trim() || 'anonymous')
    }

    const nextStep = ((): { step: Step; returnTo: 'review' | null } => {
      if (!isUpdateFlow && episode.returnTo === 'review')
        return { step: { kind: 'review', index: 0 }, returnTo: null }
      const nextIndex = episode.step.index + 1
      if (nextIndex < redFlagQs.length)
        return {
          step: { kind: isUpdateFlow ? 'update-redflag' : 'redflag', index: nextIndex },
          returnTo: episode.returnTo,
        }
      return {
        step: isUpdateFlow ? { kind: 'update-delta', index: 0 } : { kind: 'who', index: 0 },
        returnTo: episode.returnTo,
      }
    })()

    update((e) => ({
      ...e,
      ...(isUpdateFlow
        ? { update: { ...(e.update ?? emptyUpdateDraft()), redFlagAnswers: answers } }
        : { redFlagAnswers: answers }),
      emergency: fired ? true : e.emergency,
      step: nextStep.step,
      returnTo: nextStep.returnTo,
    }))
  }

  const chooseCompletedBy = (value: 'self' | 'carer') => {
    update((e) => ({
      ...e,
      completedBy: value,
      step: e.returnTo === 'review' ? { kind: 'review', index: 0 } : { kind: 'voice', index: 0 },
      returnTo: null,
    }))
  }

  const answerFunctional = (questionId: string, value: FunctionalValue) => {
    update((e) => {
      const answers = { ...e.functionalAnswers, [questionId]: value }
      if (e.returnTo === 'review')
        return { ...e, functionalAnswers: answers, step: { kind: 'review', index: 0 }, returnTo: null }
      const nextIndex = e.step.index + 1
      const step: Step =
        nextIndex < functionalQs.length
          ? { kind: 'functional', index: nextIndex }
          : { kind: 'review', index: 0 }
      return { ...e, functionalAnswers: answers, step }
    })
  }

  /** Send: create the case if needed, append the initial update. */
  const send = () => {
    let caseId = episode.caseId
    if (caseId === null) {
      const c = store.createCase(
        episode.name.trim() || 'Anonymous',
        episode.completedBy ?? 'self',
        episode.consentId,
      )
      caseId = c.id
    }
    const pairs = toRedFlagPairs(episode.redFlagAnswers)
    const caseUpdate: CaseUpdate = {
      id: newId('update'),
      at: Date.now(),
      kind: 'initial',
      transcript: episode.transcript.trim(),
      audio: episode.audio,
      redFlagAnswers: pairs,
      redFlags: evaluateRedFlags(redFlagQs, pairs),
      functionalAnswers: toFunctionalPairs(episode.functionalAnswers),
      // Honest default: queued until the store confirms durable persistence
      // (server acknowledgement on the Firebase backend, §6).
      syncState: 'queued_on_device',
    }
    store.appendCaseUpdate(caseId, caseUpdate)
    const sentCaseId = caseId
    void store.flush().then(() => store.markUpdateSent(sentCaseId, caseUpdate.id))
    update((e) => ({ ...e, caseId, step: { kind: 'status', index: 0 } }))
  }

  /** "My condition has changed" — red flags again, then delta, APPENDED to the same case. */
  const startConditionChanged = () => {
    if (episode.caseId === null) return
    if (episode.step.kind.startsWith('update-')) return
    update((e) => ({
      ...e,
      update: emptyUpdateDraft(),
      step: { kind: 'update-redflag', index: 0 },
      returnTo: null,
    }))
  }

  const sendConditionChanged = () => {
    const caseId = episode.caseId
    const draft = episode.update
    if (caseId === null || draft === null) return
    const pairs = toRedFlagPairs(draft.redFlagAnswers)
    const caseUpdate: CaseUpdate = {
      id: newId('update'),
      at: Date.now(),
      kind: 'condition_changed',
      transcript: draft.transcript.trim(),
      audio: draft.audio,
      redFlagAnswers: pairs,
      redFlags: evaluateRedFlags(redFlagQs, pairs),
      functionalAnswers: [],
      syncState: 'queued_on_device',
    }
    store.appendCaseUpdate(caseId, caseUpdate)
    void store.flush().then(() => store.markUpdateSent(caseId, caseUpdate.id))
    update((e) => ({ ...e, update: null, step: { kind: 'update-confirm', index: 0 } }))
  }

  // ── step rendering ────────────────────────────────────────────────────────

  const renderStep = (): ReactNode => {
    const step = episode.step
    switch (step.kind) {
      case 'entry':
        return (
          <Entry
            name={episode.name}
            terms={episode.termsAccepted}
            consent={episode.consentGiven}
            onName={(v) => update((e) => ({ ...e, name: v }))}
            onTerms={(v) => update((e) => ({ ...e, termsAccepted: v }))}
            onConsent={(v) => update((e) => ({ ...e, consentGiven: v }))}
            onContinue={startEpisode}
            onReset={resetDemo}
          />
        )

      case 'redflag':
      case 'update-redflag': {
        const q = redFlagQs[step.index]
        if (q === undefined) return null
        const isRepeat = step.kind === 'update-redflag'
        const answers = isRepeat
          ? (episode.update ?? emptyUpdateDraft()).redFlagAnswers
          : episode.redFlagAnswers
        return (
          <RedFlagScreen
            question={q}
            isRepeat={isRepeat}
            current={answers[q.id]}
            onAnswer={(a) => answerRedFlag(q.id, a)}
          />
        )
      }

      case 'who':
        return <WhoScreen current={episode.completedBy} onChoose={chooseCompletedBy} />

      case 'voice':
        return (
          <DescribeScreen
            eyebrow="In your own words"
            title="Describe how you feel"
            lead="Talk the way you would to a nurse. There are no wrong words."
            transcript={episode.transcript}
            audio={episode.audio}
            continueLabel="Continue"
            onTranscript={(t) => update((e) => ({ ...e, transcript: t }))}
            onAudio={(a) => update((e) => ({ ...e, audio: a }))}
            onContinue={() =>
              update((e) => ({
                ...e,
                step:
                  e.returnTo === 'review'
                    ? { kind: 'review', index: 0 }
                    : { kind: 'functional', index: 0 },
                returnTo: null,
              }))
            }
          />
        )

      case 'functional': {
        const q = functionalQs[step.index]
        if (q === undefined) return null
        return (
          <FunctionalScreen
            question={q}
            current={episode.functionalAnswers[q.id]}
            onAnswer={(v) => answerFunctional(q.id, v)}
          />
        )
      }

      case 'review':
        return (
          <ReviewScreen
            redFlagQs={redFlagQs}
            functionalQs={functionalQs}
            episode={episode}
            onEditRedFlag={(i) =>
              update((e) => ({ ...e, returnTo: 'review', step: { kind: 'redflag', index: i } }))
            }
            onEditWho={() =>
              update((e) => ({ ...e, returnTo: 'review', step: { kind: 'who', index: 0 } }))
            }
            onEditVoice={() =>
              update((e) => ({ ...e, returnTo: 'review', step: { kind: 'voice', index: 0 } }))
            }
            onEditFunctional={(i) =>
              update((e) => ({ ...e, returnTo: 'review', step: { kind: 'functional', index: i } }))
            }
            onSend={send}
          />
        )

      case 'status':
        if (patientCase === undefined) {
          return (
            <div className="stack">
              <h1>This demo was reset</h1>
              <p>Your saved case is no longer on this phone. You can start again.</p>
              <button
                type="button"
                className="btn-primary"
                onClick={() => {
                  clearEpisode()
                  saveEpisode(initialEpisode())
                  window.location.reload()
                }}
              >
                Start again
              </button>
            </div>
          )
        }
        return <StatusScreen patientCase={patientCase} />

      case 'update-delta':
        return (
          <DescribeScreen
            eyebrow="Your update"
            title="What has changed since last time?"
            lead="Talk or type — whichever is easier right now."
            transcript={(episode.update ?? emptyUpdateDraft()).transcript}
            audio={(episode.update ?? emptyUpdateDraft()).audio}
            continueLabel="Add this to my case"
            onTranscript={(t) =>
              update((e) => ({ ...e, update: { ...(e.update ?? emptyUpdateDraft()), transcript: t } }))
            }
            onAudio={(a) =>
              update((e) => ({ ...e, update: { ...(e.update ?? emptyUpdateDraft()), audio: a } }))
            }
            onContinue={sendConditionChanged}
          />
        )

      case 'update-confirm':
        return (
          <UpdateConfirmScreen
            refCode={episode.caseId !== null ? shortRef(episode.caseId) : ''}
            onDone={() => update((e) => ({ ...e, step: { kind: 'status', index: 0 } }))}
          />
        )
    }
  }

  return (
    <>
      <main className="app">
        {episode.emergency ? (
          <EmergencyInterrupt onBack={() => update((e) => ({ ...e, emergency: false }))} />
        ) : (
          renderStep()
        )}
      </main>
      {/* Outside the step hierarchy, via portal — never occluded (F-051). */}
      <SafetyDock
        showConditionChanged={episode.caseId !== null}
        onConditionChanged={startConditionChanged}
      />
    </>
  )
}
