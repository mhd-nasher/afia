import type { ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import { StatusPill } from '@afia/ui'
import type { Go } from '../nav'
import { newestHandoverFor, store } from '../store'
import { ageFrom } from '../lib'

/**
 * Screen 1 — ward list. All 12 patients on one screen with NO scroll:
 * the container is calc(100dvh − banner − tabbar) and each row is flex:1.
 * The pill is the newest handover BY THE CURRENT AUTHOR (not_started if none).
 */
export function WardList({
  practitioner,
  go,
}: {
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const patients = [...store.patients()].sort((a, b) =>
    a.bed.localeCompare(b.bed, undefined, { numeric: true }),
  )
  const firstPatient = patients[0]
  const ward = firstPatient !== undefined ? store.ward(firstPatient.wardId) : undefined

  return (
    <div className="ward">
      <div className="ward__head">
        <span className="ward__title">{ward?.name ?? 'Ward'}</span>
        <span className="ward__who">On shift: {practitioner.name}</span>
      </div>
      <div className="ward__list">
        {patients.map((p) => {
          const newest = newestHandoverFor(p.id, practitioner.id)
          return (
            <button
              key={p.id}
              type="button"
              className="ward__row"
              onClick={() => go({ name: 'patient', patientId: p.id })}
            >
              <span className="ward__bed">{p.bed}</span>
              <span className="ward__name">
                {p.name}
                <span className="ward__age">{ageFrom(p.dateOfBirth)}</span>
              </span>
              <StatusPill status={newest?.status ?? 'not_started'} />
            </button>
          )
        })}
      </div>
    </div>
  )
}
