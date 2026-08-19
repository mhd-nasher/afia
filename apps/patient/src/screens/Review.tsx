import type {
  AnswerState,
  FunctionalQuestion,
  FunctionalValue,
  RedFlagQuestion,
} from '@afia/rules'
import type { EpisodeState } from '../episode'

/**
 * Review — a neutral list of what's answered, with "Not answered" for
 * anything UNKNOWN or skipped. Plain wording only: no importance ranking,
 * no urgency levels, nothing implying the person is fine (§11 / §4.3).
 * Edit buttons jump back to a question and return here.
 */

const RED_FLAG_LABEL: Record<AnswerState, string> = {
  YES: 'Yes',
  NO: 'No',
  UNKNOWN: 'Not answered',
  NOT_ASKED: 'Not answered',
}

const FUNCTIONAL_LABEL: Record<FunctionalValue, string> = {
  SAME_AS_NORMAL: 'About the same as normal',
  WORSE: 'Worse than normal',
  MUCH_WORSE: 'Much worse than normal',
  UNKNOWN: 'Not answered',
  NOT_ASKED: 'Not answered',
}

export function ReviewScreen({
  redFlagQs,
  functionalQs,
  episode,
  onEditRedFlag,
  onEditWho,
  onEditVoice,
  onEditFunctional,
  onSend,
}: {
  redFlagQs: readonly RedFlagQuestion[]
  functionalQs: readonly FunctionalQuestion[]
  episode: EpisodeState
  onEditRedFlag: (index: number) => void
  onEditWho: () => void
  onEditVoice: () => void
  onEditFunctional: (index: number) => void
  onSend: () => void
}) {
  const description = episode.transcript.trim()
  return (
    <div className="stack">
      <h1>Check what you are sending</h1>
      <p>
        This is everything you entered. Anything you did not answer is shown as
        “Not answered”. You can change any answer, or send it as it is.
      </p>

      <h2 className="review-heading">Safety questions</h2>
      {redFlagQs.map((q, i) => {
        const answer = episode.redFlagAnswers[q.id]
        const missing = answer === undefined || answer === 'UNKNOWN' || answer === 'NOT_ASKED'
        return (
          <div className="review-item" key={q.id}>
            <div className="review-text">
              <div className="review-q">{q.text}</div>
              <div className={missing ? 'review-a review-a--missing' : 'review-a'}>
                {answer === undefined ? 'Not answered' : RED_FLAG_LABEL[answer]}
              </div>
            </div>
            <button type="button" className="edit-btn" onClick={() => onEditRedFlag(i)}>
              Edit
            </button>
          </div>
        )
      })}

      <h2 className="review-heading">Who filled this in</h2>
      <div className="review-item">
        <div className="review-text">
          <div className="review-a">
            {episode.completedBy === null
              ? 'Not answered'
              : episode.completedBy === 'self'
                ? 'Myself'
                : 'Someone helping'}
          </div>
        </div>
        <button type="button" className="edit-btn" onClick={onEditWho}>
          Edit
        </button>
      </div>

      <h2 className="review-heading">Your description</h2>
      <div className="review-item">
        <div className="review-text">
          <div className={description === '' ? 'review-a review-a--missing' : 'review-a review-a--body'}>
            {description === '' ? 'Not answered' : description}
          </div>
          {episode.audio !== null ? <div className="review-q">Voice recording included</div> : null}
        </div>
        <button type="button" className="edit-btn" onClick={onEditVoice}>
          Edit
        </button>
      </div>

      <h2 className="review-heading">Compared with your normal</h2>
      {functionalQs.map((q, i) => {
        const value = episode.functionalAnswers[q.id]
        const missing = value === undefined || value === 'UNKNOWN' || value === 'NOT_ASKED'
        return (
          <div className="review-item" key={q.id}>
            <div className="review-text">
              <div className="review-q">{q.text}</div>
              <div className={missing ? 'review-a review-a--missing' : 'review-a'}>
                {value === undefined ? 'Not answered' : FUNCTIONAL_LABEL[value]}
              </div>
            </div>
            <button type="button" className="edit-btn" onClick={() => onEditFunctional(i)}>
              Edit
            </button>
          </div>
        )
      })}

      <button type="button" className="btn-primary" onClick={onSend}>
        Send to the nursing team
      </button>
    </div>
  )
}
