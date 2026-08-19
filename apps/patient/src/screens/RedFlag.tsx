import type { AnswerState } from '@afia/rules'
import type { RedFlagQuestion } from '@afia/rules'

/**
 * One red-flag question per screen. Three answers styled IDENTICALLY —
 * same size, same weight, same shape (F-053). "I don't know" is first-class
 * and stores UNKNOWN, never NO (§2.2). No step counter, no progress bar.
 */
export function RedFlagScreen({
  question,
  isRepeat,
  current,
  onAnswer,
}: {
  question: RedFlagQuestion
  isRepeat: boolean
  current: AnswerState | undefined
  onAnswer: (a: AnswerState) => void
}) {
  const options: { value: AnswerState; label: string }[] = [
    { value: 'YES', label: 'Yes' },
    { value: 'NO', label: 'No' },
    { value: 'UNKNOWN', label: "I don't know" },
  ]
  return (
    <div className="stack">
      <p className="eyebrow">{isRepeat ? 'Safety questions — asked again, to be safe' : 'Safety questions'}</p>
      <h1>{question.text}</h1>
      <div className="stack" role="group" aria-label={question.text}>
        {options.map((o) => (
          <button
            key={o.value}
            type="button"
            className={current === o.value ? 'answer-btn answer-btn--selected' : 'answer-btn'}
            onClick={() => onAnswer(o.value)}
          >
            {o.label}
          </button>
        ))}
      </div>
    </div>
  )
}
