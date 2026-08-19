import { useRef, useState, type ReactNode } from 'react'

/**
 * @afia/ui — shared components. Import '@afia/ui/src/tokens.css' once per app.
 */

/**
 * The demo-data banner was removed 2026-08-19 by owner decision: the product
 * moved from hackathon demo to real-use posture. `--banner-h` is pinned to 0
 * in tokens.css so existing layout offsets collapse cleanly.
 */

const STATUS_LABELS: Record<string, string> = {
  not_started: 'Not started',
  recording: 'Recording',
  draft_ready: 'Draft ready',
  signed: 'Signed',
  queued: 'Queued',
  confirmed_in_system: 'Confirmed in system',
  export_failed: 'Export failed',
}

/** Row-state pill. `signed` and `confirmed_in_system` are visually distinct (§5). */
export function StatusPill({ status }: { status: string }): ReactNode {
  return (
    <span className={`afia-pill afia-pill--${status}`}>
      {STATUS_LABELS[status] ?? status}
    </span>
  )
}

/**
 * Hold-to-sign (§5 screen 7). Completing the hold fires onComplete once.
 * Releasing early resets — a deliberate friction for a legally meaningful act.
 */
export function HoldButton({
  label,
  holdMs = 1200,
  onComplete,
  disabled = false,
}: {
  label: string
  holdMs?: number
  onComplete: () => void
  disabled?: boolean
}): ReactNode {
  const [progress, setProgress] = useState(0)
  const timer = useRef<number | null>(null)
  const startedAt = useRef(0)

  const stop = () => {
    if (timer.current !== null) cancelAnimationFrame(timer.current)
    timer.current = null
    setProgress(0)
  }

  const tick = () => {
    const elapsed = performance.now() - startedAt.current
    const p = Math.min(1, elapsed / holdMs)
    setProgress(p)
    if (p >= 1) {
      stop()
      onComplete()
      return
    }
    timer.current = requestAnimationFrame(tick)
  }

  const start = () => {
    if (disabled) return
    startedAt.current = performance.now()
    timer.current = requestAnimationFrame(tick)
  }

  return (
    <button
      className="afia-hold"
      style={disabled ? { opacity: 0.45, cursor: 'not-allowed' } : undefined}
      onPointerDown={start}
      onPointerUp={stop}
      onPointerLeave={stop}
      onPointerCancel={stop}
      aria-disabled={disabled}
    >
      <span className="afia-hold__fill" style={{ width: `${progress * 100}%` }} />
      <span className="afia-hold__label">{label}</span>
    </button>
  )
}
