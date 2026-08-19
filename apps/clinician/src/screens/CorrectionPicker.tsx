import { useState, type ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import { searchFormulary } from '@afia/rules'
import { store } from '../store'

/**
 * Screen 6 — correction picker. Recognition, never recall (§4.4): a searchable
 * formulary where sound-alike clusters render together as one bordered group,
 * with audio replay above the list. There is deliberately NO free-text option.
 */
export function CorrectionPicker({
  handoverId,
  chipId,
  practitioner,
  onClose,
}: {
  handoverId: string
  chipId: string
  practitioner: Practitioner
  onClose: () => void
}): ReactNode {
  const [query, setQuery] = useState('')

  const handover = store.handover(handoverId)
  if (handover === undefined) return null
  const chip = handover.chips.find((c) => c.id === chipId)
  if (chip === undefined) return null

  const clusters = searchFormulary(query, store.formulary())

  const choose = (entryName: string): void => {
    store.confirmChip(handoverId, chipId, practitioner.id, entryName)
    onClose()
  }

  return (
    <div className="overlay">
      <div className="picker">
        <div className="picker__head">
          <h1>Pick the correct drug</h1>
          <button type="button" className="picker__cancel" onClick={onClose}>
            Cancel
          </button>
        </div>

        <p className="picker__heard">
          Heard: <strong>&ldquo;{chip.text}&rdquo;</strong>
        </p>

        <div className="picker__audio">
          <p className="picker__audio-label">Listen again before choosing</p>
          {handover.audio !== null ? (
            <audio controls src={handover.audio.url} className="picker__player" />
          ) : (
            <p className="empty">No audio was recorded for this draft (typed handover).</p>
          )}
        </div>

        <input
          type="search"
          className="picker__search"
          placeholder="Search the formulary…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          autoFocus
        />

        <div className="picker__results">
          {clusters.length === 0 && <p className="empty">No formulary entries match.</p>}
          {clusters.map((cluster, i) => (
            <div
              key={cluster[0]?.id ?? i}
              className={cluster.length > 1 ? 'cluster cluster--soundalike' : 'cluster'}
            >
              {cluster.length > 1 && (
                <p className="cluster__note">Sound-alike group — shown together</p>
              )}
              {cluster.map((entry) => (
                <button
                  key={entry.id}
                  type="button"
                  className="cluster__entry"
                  onClick={() => choose(entry.name)}
                >
                  {entry.name}
                </button>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
