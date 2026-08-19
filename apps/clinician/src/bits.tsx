import type { ReactNode } from 'react'
import type { Go, Screen } from './nav'

/** Small padlock glyph — signature identity is immutable (§2.5). */
export function LockIcon(): ReactNode {
  return (
    <svg
      className="lock-icon"
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.4"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-label="Locked"
      role="img"
    >
      <rect x="4" y="11" width="16" height="10" rx="2" />
      <path d="M8 11V7a4 4 0 0 1 8 0v4" />
    </svg>
  )
}

export function BackButton({
  go,
  to,
  label,
}: {
  go: Go
  to: Screen
  label: string
}): ReactNode {
  return (
    <button type="button" className="back" onClick={() => go(to)}>
      &#8249; {label}
    </button>
  )
}

/** Fallback when a screen references a record that no longer exists. */
export function MissingRecord({ go }: { go: Go }): ReactNode {
  return (
    <div className="screen">
      <div className="card">
        <p>That record is no longer available.</p>
        <button type="button" className="btn btn--ghost" onClick={() => go({ name: 'ward' })}>
          Back to ward list
        </button>
      </div>
    </div>
  )
}
