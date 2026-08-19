import type { ReactNode } from 'react'

/**
 * Charts for the Quality section — lines and bars only, per the design brief.
 * Chart series use indigo tints exclusively (#2D4A8A action, #7B6FD4 accent);
 * the clinical trio never appears as a chart colour. No gauges, no donuts,
 * no radial meters, no gradients.
 */

export interface LineSeries {
  label: string
  color: string
  /** x in epoch ms (or any monotonic unit), y in the chart's unit. */
  points: Array<{ x: number; y: number }>
}

const W = 460
const H = 150
const PAD_L = 40
const PAD_R = 8
const PAD_T = 8
const PAD_B = 22

export function LineChart({
  series,
  yFormat,
  xFormat,
  yMax,
}: {
  series: LineSeries[]
  yFormat: (y: number) => string
  xFormat: (x: number) => string
  yMax?: number
}): ReactNode {
  const all = series.flatMap((s) => s.points)
  if (all.length === 0) return <p className="empty-note">Not enough history to draw yet.</p>

  const xs = all.map((p) => p.x)
  const ys = all.map((p) => p.y)
  const xMin = Math.min(...xs)
  const xMax = Math.max(...xs)
  const yTop = yMax ?? Math.max(1, Math.max(...ys)) * 1.15
  const xSpan = Math.max(1, xMax - xMin)

  const px = (x: number): number => PAD_L + ((x - xMin) / xSpan) * (W - PAD_L - PAD_R)
  const py = (y: number): number => PAD_T + (1 - y / yTop) * (H - PAD_T - PAD_B)

  const yTicks = [0, yTop / 2, yTop]
  const xTicks = xMin === xMax ? [xMin] : [xMin, xMin + xSpan / 2, xMax]

  return (
    <>
      <div className="legend">
        {series.map((s) => (
          <span key={s.label}>
            <span className="legend-swatch" style={{ background: s.color }} />
            {s.label}
          </span>
        ))}
      </div>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        width="100%"
        role="img"
        aria-label={series.map((s) => s.label).join(' and ')}
      >
        {/* axes + gridlines */}
        {yTicks.map((t) => (
          <g key={`y${t}`}>
            <line
              x1={PAD_L}
              x2={W - PAD_R}
              y1={py(t)}
              y2={py(t)}
              stroke="#e2dfd9"
              strokeWidth="1"
            />
            <text
              x={PAD_L - 6}
              y={py(t) + 3}
              textAnchor="end"
              fontSize="9"
              fill="#8a9099"
              fontFamily="IBM Plex Mono, monospace"
            >
              {yFormat(t)}
            </text>
          </g>
        ))}
        {xTicks.map((t) => (
          <text
            key={`x${t}`}
            x={px(t)}
            y={H - 6}
            textAnchor="middle"
            fontSize="9"
            fill="#8a9099"
            fontFamily="IBM Plex Mono, monospace"
          >
            {xFormat(t)}
          </text>
        ))}
        {/* series */}
        {series.map((s) => {
          if (s.points.length === 0) return null
          const sorted = [...s.points].sort((a, b) => a.x - b.x)
          const d = sorted.map((p) => `${px(p.x)},${py(p.y)}`).join(' ')
          return (
            <g key={s.label}>
              <polyline
                points={d}
                fill="none"
                stroke={s.color}
                strokeWidth="1.5"
              />
              {sorted.map((p, i) => (
                <circle key={i} cx={px(p.x)} cy={py(p.y)} r="2.2" fill={s.color} />
              ))}
            </g>
          )
        })}
      </svg>
    </>
  )
}

/** Horizontal bar list — indigo fill, mono counts. */
export function BarList({
  rows,
}: {
  rows: Array<{ label: string; value: number }>
}): ReactNode {
  if (rows.length === 0) return <p className="empty-note">Nothing recorded yet.</p>
  const max = Math.max(...rows.map((r) => r.value), 1)
  return (
    <>
      {rows.map((r) => (
        <div className="bar-row" key={r.label}>
          <span>
            {r.label}
            <span className="bar-track">
              <span className="bar-fill" style={{ width: `${(r.value / max) * 100}%` }} />
            </span>
          </span>
          <span className="num" style={{ textAlign: 'right' }}>
            {r.value}
          </span>
        </div>
      ))}
    </>
  )
}
