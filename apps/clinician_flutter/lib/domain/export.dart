/// HANDOFF §3.2 — one internal representation, exporters translate.
/// Dart port of packages/export/src/index.ts. ClipboardExporter renders the
/// plain-text record; FhirExporter generates valid DocumentReference JSON and
/// SENDS NOTHING. The accurate phrase everywhere is FHIR-ready — never
/// "FHIR-integrated".
library;

import 'dart:convert';

import 'entities.dart';
import 'handover.dart';

class ExportResult {
  final bool ok;
  final String target;
  final String? payload;
  final String? error;
  const ExportResult(
      {required this.ok, required this.target, this.payload, this.error});
}

abstract class ExportTarget {
  String get name;
  ExportResult export(Handover handover, Patient patient);
}

List<String> _flagLines(Handover handover) {
  if (handover.flags.isEmpty) return ['Omissions: none flagged.'];
  // §2.4 — flags export visibly, with the recorded note.
  return [
    'OMISSIONS (documented, not resolved):',
    ...handover.flags.map((f) =>
        '  - ${f.message}${f.signingNote != null ? ' — note: ${f.signingNote}' : ''}'),
  ];
}

class ClipboardExporter implements ExportTarget {
  @override
  final String name = 'clipboard';

  const ClipboardExporter();

  @override
  ExportResult export(Handover handover, Patient patient) {
    final lines = <String>[
      'Handover v${handover.version} — ${patient.name} (bed ${patient.bed})',
      'DOB ${patient.dateOfBirth} · local id ${patient.id} · external id ${patient.externalIdentifier ?? '—'}',
      '',
      ...handover.fields
          .where((f) => f.text.trim().isNotEmpty)
          .map((f) => '${f.fieldId.toUpperCase()}: ${f.text}'),
      '',
      ..._flagLines(handover),
      '',
      handover.signature != null
          ? 'Signed: ${handover.signature!.signatureIdentity} at ${DateTime.fromMillisecondsSinceEpoch(handover.signature!.signedAt).toUtc().toIso8601String()}'
          : 'UNSIGNED DRAFT',
      if (handover.signature?.openFlagReason != null)
        'Open-flag reason: ${handover.signature!.openFlagReason}',
      'Original audio recording retained and available for playback.',
    ];
    return ExportResult(
        ok: true,
        target: name,
        payload: lines.where((l) => l.isNotEmpty).join('\n'));
  }
}

class FhirExporter implements ExportTarget {
  @override
  final String name = 'fhir';

  const FhirExporter();

  @override
  ExportResult export(Handover handover, Patient patient) {
    final noteText = handover.fields
        .where((f) => f.text.trim().isNotEmpty)
        .map((f) => '${f.fieldId}: ${f.text}')
        .join('\n');

    String iso(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String();

    final doc = <String, dynamic>{
      'resourceType': 'DocumentReference',
      'id': handover.id,
      'identifier': handover.externalIdentifier != null
          ? [
              {
                'system': 'urn:afia:external',
                'value': handover.externalIdentifier
              }
            ]
          : <dynamic>[],
      'status': handover.supersededBy != null ? 'superseded' : 'current',
      'docStatus': handover.signature != null ? 'final' : 'preliminary',
      'type': {
        'coding': [
          {
            'system': 'http://loinc.org',
            'code': '57833-6',
            'display': 'Nurse shift handover note'
          }
        ],
        'text': 'Nursing shift handover',
      },
      'subject': {
        'reference': 'Patient/${patient.id}',
        'display': patient.name,
        if (patient.externalIdentifier != null)
          'identifier': {
            'system': 'urn:afia:mrn',
            'value': patient.externalIdentifier
          },
      },
      'date': iso(handover.createdAt),
      'author': [
        {'reference': 'Practitioner/${handover.authorId}'}
      ],
      if (handover.signature != null)
        'authenticator': {
          'reference': 'Practitioner/${handover.signature!.practitionerId}',
          'display': handover.signature!.signatureIdentity,
        },
      'relatesTo': handover.supersedes != null
          ? [
              {
                'code': 'replaces',
                'target': {
                  'reference': 'DocumentReference/${handover.supersedes}'
                }
              }
            ]
          : <dynamic>[],
      'description': handover.flags.isNotEmpty
          ? 'Includes ${handover.flags.length} documented omission flag(s): ${handover.flags.map((f) => f.message).join('; ')}'
          : 'No omission flags.',
      'content': [
        {
          'attachment': {
            'contentType': 'text/plain',
            'data': base64Encode(utf8.encode(noteText)),
            'title': 'Structured handover note',
          }
        },
        if (handover.audio != null)
          {
            'attachment': {
              'contentType': handover.audio!.mimeType,
              'title': 'Original voice recording (retained, playable)',
              'duration': handover.audio!.durationSec,
            }
          },
      ],
      'contained': handover.signature != null
          ? [
              {
                'resourceType': 'Provenance',
                'id': 'prov-${handover.id}',
                'target': [
                  {'reference': 'DocumentReference/${handover.id}'}
                ],
                'recorded': iso(handover.signature!.signedAt),
                'activity': {
                  'coding': [
                    {
                      'system':
                          'http://terminology.hl7.org/CodeSystem/v3-DocumentCompletion',
                      'code': 'LA',
                      'display': 'legally authenticated',
                    }
                  ]
                },
                'agent': [
                  {
                    'who': {
                      'reference':
                          'Practitioner/${handover.signature!.practitionerId}',
                      'display': handover.signature!.signatureIdentity,
                    }
                  }
                ],
              }
            ]
          : <dynamic>[],
    };

    return ExportResult(
        ok: true,
        target: name,
        payload: const JsonEncoder.withIndent('  ').convert(doc));
  }
}

class Hl7v2Exporter implements ExportTarget {
  @override
  final String name = 'hl7v2';

  const Hl7v2Exporter();

  @override
  ExportResult export(Handover handover, Patient patient) => const ExportResult(
        ok: false,
        target: 'hl7v2',
        error:
            'HL7v2 export is a stub — not implemented in this build.',
      );
}
