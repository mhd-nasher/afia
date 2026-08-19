/** Who is completing — two identical 64px options. */
export function WhoScreen({
  current,
  onChoose,
}: {
  current: 'self' | 'carer' | null
  onChoose: (v: 'self' | 'carer') => void
}) {
  const options: { value: 'self' | 'carer'; label: string }[] = [
    { value: 'self', label: 'Myself' },
    { value: 'carer', label: "I'm helping someone else" },
  ]
  return (
    <div className="stack">
      <h1>Who is filling this in?</h1>
      <div className="stack" role="group" aria-label="Who is filling this in?">
        {options.map((o) => (
          <button
            key={o.value}
            type="button"
            className={current === o.value ? 'answer-btn answer-btn--selected' : 'answer-btn'}
            onClick={() => onChoose(o.value)}
          >
            {o.label}
          </button>
        ))}
      </div>
    </div>
  )
}
