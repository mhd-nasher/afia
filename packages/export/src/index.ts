import type { Handover, Patient } from '@afia/core'

/**
 * HANDOFF §3.2 — one internal representation, exporters translate.
 * ClipboardExporter is the only real exporter. FhirExporter generates valid
 * DocumentReference JSON and SENDS NOTHING. Hl7v2Exporter is a stub that
 * says so. The accurate phrase is FHIR-ready — never "FHIR-integrated".
 */

export interface HandoverExportView {
  handover: Handover
  patient: Patient
}

export interface ExportResult {
  ok: boolean
  target: string
  /** The rendered payload (text or JSON). The caller decides what to do with it. */
  payload: string | null
  error: string | null
}

export interface ExportTarget {
  readonly name: string
  export(view: HandoverExportView): ExportResult
}

function flagLines(view: HandoverExportView): string[] {
  const { handover } = view
  if (handover.flags.length === 0) return ['Omissions: none flagged.']
  // §2.4 — flags export visibly, with the recorded note.
  return [
    'OMISSIONS (documented, not resolved):',
    ...handover.flags.map(
      (f) => `  - ${f.message}${f.signingNote ? ` — note: ${f.signingNote}` : ''}`,
    ),
  ]
}

export class ClipboardExporter implements ExportTarget {
  readonly name = 'clipboard'

  export(view: HandoverExportView): ExportResult {
    const { handover, patient } = view
    const lines: string[] = [
      `Handover v${handover.version} — ${patient.name} (bed ${patient.bed})`,
      `DOB ${patient.dateOfBirth} · local id ${patient.id} · external id ${patient.externalIdentifier ?? '—'}`,
      '',
      ...handover.fields
        .filter((f) => f.text.trim() !== '')
        .map((f) => `${f.fieldId.toUpperCase()}: ${f.text}`),
      '',
      ...flagLines(view),
      '',
      handover.signature
        ? `Signed: ${handover.signature.signatureIdentity} at ${new Date(handover.signature.signedAt).toISOString()}`
        : 'UNSIGNED DRAFT',
      handover.signature?.openFlagReason
        ? `Open-flag reason: ${handover.signature.openFlagReason}`
        : '',
      'Original audio recording retained and available for playback.',
    ]
    return { ok: true, target: this.name, payload: lines.filter((l) => l !== '').join('\n'), error: null }
  }
}

function toBase64(text: string): string {
  if (typeof btoa === 'function') {
    return btoa(unescape(encodeURIComponent(text)))
  }
  return Buffer.from(text, 'utf8').toString('base64')
}

export class FhirExporter implements ExportTarget {
  readonly name = 'fhir'

  export(view: HandoverExportView): ExportResult {
    const { handover, patient } = view
    const noteText = handover.fields
      .filter((f) => f.text.trim() !== '')
      .map((f) => `${f.fieldId}: ${f.text}`)
      .join('\n')

    const doc = {
      resourceType: 'DocumentReference',
      id: handover.id,
      identifier: handover.externalIdentifier
        ? [{ system: 'urn:afia:external', value: handover.externalIdentifier }]
        : [],
      status: handover.supersededBy !== null ? 'superseded' : 'current',
      docStatus: handover.signature !== null ? 'final' : 'preliminary',
      type: {
        coding: [{ system: 'http://loinc.org', code: '57833-6', display: 'Nurse shift handover note' }],
        text: 'Nursing shift handover',
      },
      subject: {
        reference: `Patient/${patient.id}`,
        display: patient.name,
        identifier: patient.externalIdentifier
          ? { system: 'urn:afia:mrn', value: patient.externalIdentifier }
          : undefined,
      },
      date: new Date(handover.createdAt).toISOString(),
      author: [{ reference: `Practitioner/${handover.authorId}` }],
      authenticator: handover.signature
        ? {
            reference: `Practitioner/${handover.signature.practitionerId}`,
            display: handover.signature.signatureIdentity,
          }
        : undefined,
      relatesTo: handover.supersedes
        ? [{ code: 'replaces', target: { reference: `DocumentReference/${handover.supersedes}` } }]
        : [],
      description:
        handover.flags.length > 0
          ? `Includes ${handover.flags.length} documented omission flag(s): ${handover.flags.map((f) => f.message).join('; ')}`
          : 'No omission flags.',
      content: [
        {
          attachment: {
            contentType: 'text/plain',
            data: toBase64(noteText),
            title: 'Structured handover note',
          },
        },
        ...(handover.audio
          ? [
              {
                attachment: {
                  contentType: handover.audio.mimeType,
                  title: 'Original voice recording (retained, playable)',
                  duration: handover.audio.durationSec,
                },
              },
            ]
          : []),
      ],
      contained: handover.signature
        ? [
            {
              resourceType: 'Provenance',
              id: `prov-${handover.id}`,
              target: [{ reference: `DocumentReference/${handover.id}` }],
              recorded: new Date(handover.signature.signedAt).toISOString(),
              activity: {
                coding: [
                  { system: 'http://terminology.hl7.org/CodeSystem/v3-DocumentCompletion', code: 'LA', display: 'legally authenticated' },
                ],
              },
              agent: [
                {
                  who: {
                    reference: `Practitioner/${handover.signature.practitionerId}`,
                    display: handover.signature.signatureIdentity,
                  },
                },
              ],
            },
          ]
        : [],
    }

    return { ok: true, target: this.name, payload: JSON.stringify(doc, null, 2), error: null }
  }
}

export class Hl7v2Exporter implements ExportTarget {
  readonly name = 'hl7v2'

  export(_view: HandoverExportView): ExportResult {
    return {
      ok: false,
      target: this.name,
      payload: null,
      error: 'HL7v2 export is a stub — not implemented in the demonstration build.',
    }
  }
}

export const EXPORT_TARGETS: ExportTarget[] = [
  new ClipboardExporter(),
  new FhirExporter(),
  new Hl7v2Exporter(),
]
