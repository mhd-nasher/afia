import type { ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import { StatusPill } from '@afia/ui'
import type { Go } from '../nav'
import { receivedHandovers, store } from '../store'
import { timeAgo } from '../lib'

/**
 * Screen 8 — incoming list: handovers authored by others, signed, newest first.
 */
export function ReceivedList({
  practitioner,
  go,
}: {
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const items = receivedHandovers(practitioner.id)

  return (
    <div className="screen">
      <header className="patient-head">
        <h1>Received</h1>
        <p className="patient-head__meta">Signed handovers from other clinicians · newest first</p>
      </header>

      {items.length === 0 && (
        <div className="card">
          <p className="empty">Nothing received yet.</p>
        </div>
      )}

      <div className="list">
        {items.map((h) => {
          const patient = store.patient(h.patientId)
          const author = store.practitioner(h.authorId)
          return (
            <button
              key={h.id}
              type="button"
              className="list__row"
              onClick={() => go({ name: 'receivedDetail', handoverId: h.id })}
            >
              <span className="list__main">
                <span className="list__title">
                  {patient?.name ?? 'Patient'}
                  {patient !== undefined ? ` · bed ${patient.bed}` : ''}
                </span>
                <span className="list__sub">
                  {author?.name ?? h.authorId} · {timeAgo(h.signature?.signedAt ?? h.createdAt)}
                </span>
              </span>
              <StatusPill status={h.status} />
            </button>
          )
        })}
      </div>
    </div>
  )
}
