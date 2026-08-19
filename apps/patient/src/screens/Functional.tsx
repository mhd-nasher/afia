import type { FunctionalQuestion, FunctionalValue } from '@afia/rules'

/**
 * One baseline-anchored functional question per screen. All four answers
 * styled identically (F-053); "I don't know" stores UNKNOWN.
 */
export function FunctionalScreen({
  question,
  current,
  onAnswer,
}: {
  question: FunctionalQuestion
  current: FunctionalValue | undefined
  onAnswer: (v: FunctionalValue) => void
}) {
  const options: { value: FunctionalValue; label: string }[] = [
    { value: 'SAME_AS_NORMAL', label: 'About the same as normal' },
    { value: 'WORSE', label: 'Worse than normal' },
    { value: 'MUCH_WORSE', label: 'Much worse than normal' },
    { value: 'UNKNOWN', label: "I don't know" },
  ]
  return (
    <div className="stack">
      <p className="eyebrow">Compared with your normal</p>
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
