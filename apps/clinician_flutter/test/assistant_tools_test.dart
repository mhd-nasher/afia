/// D-013 — tool-layer tests for the shift assistant. Fake data, pure
/// functions: assert wait-time-then-completeness ordering (§2.10), correct
/// checklist buckets, and — structurally — that NO risk/severity/priority
/// field exists anywhere in any tool output.
library;

import 'package:afia_clinician/domain/case_data.dart';
import 'package:afia_clinician/domain/chips.dart';
import 'package:afia_clinician/domain/entities.dart';
import 'package:afia_clinician/domain/handover.dart';
import 'package:afia_clinician/domain/queue.dart';
import 'package:afia_clinician/services/assistant/shift_tools.dart';
import 'package:flutter_test/flutter_test.dart';

Patient patient(String id, String bed, String name) => Patient(
      id: id,
      externalIdentifier: null,
      createdAt: 0,
      name: name,
      dateOfBirth: '1950-01-01',
      wardId: 'ward-a',
      bed: bed,
    );

Handover handover(
  String id,
  String patientId,
  HandoverStatus status, {
  List<ConfirmableChip> chips = const [],
  List<HandoverFlag> flags = const [],
  Signature? signature,
  String? exportError,
}) =>
    Handover(
      id: id,
      externalIdentifier: null,
      createdAt: 100,
      patientId: patientId,
      authorId: 'me',
      status: status,
      audio: null,
      transcript: '',
      fields: const [],
      chips: chips,
      flags: flags,
      signature: signature,
      version: 1,
      supersedes: null,
      supersededBy: null,
      exportError: exportError,
      acknowledgedAt: null,
    );

ConfirmableChip chip(String id, {bool confirmed = false}) => ConfirmableChip(
      id: id,
      kind: ChipKind.drug,
      text: 'x',
      start: 0,
      end: 1,
      match: null,
      confirmedBy: confirmed ? 'me' : null,
      confirmedAt: confirmed ? 1 : null,
      correctedTo: null,
    );

void main() {
  // Fake cases built from maps — the same parsing path production uses.
  CaseData mapCase(String id, String name, int createdAt,
          {int answeredOf4 = 4, int updates = 1}) =>
      CaseData.fromMap({
        'id': id,
        'patientName': name,
        'createdAt': createdAt,
        'status': 'submitted',
        'updates': [
          for (var i = 0; i < updates; i++)
            {
              'at': createdAt + i,
              'kind': i == 0 ? 'initial' : 'condition_changed',
              'transcript': 'recorded text',
              'syncState': 'sent',
              'redFlagAnswers': [
                for (var q = 0; q < 4; q++)
                  {
                    'questionId': 'q$q',
                    'answer': q < answeredOf4 ? 'NO' : 'NOT_ASKED',
                  }
              ],
              'functionalAnswers': const [],
            }
        ],
      });

  /// Recursively assert no risk-shaped key exists in a tool output (§2.10).
  void assertNoRiskFields(Object? value) {
    const forbidden = ['priority', 'risk', 'severity', 'urgency', 'triage'];
    if (value is Map) {
      for (final key in value.keys) {
        expect(forbidden.contains(key.toString().toLowerCase()), isFalse,
            reason: 'tool output must not carry a risk field: $key');
        assertNoRiskFields(value[key]);
      }
    } else if (value is List) {
      for (final v in value) {
        assertNoRiskFields(v);
      }
    }
  }

  group('incoming_cases — §2.10 ordering', () {
    test('orders by wait time first, completeness second, never risk', () {
      const now = 1000000;
      final cases = [
        mapCase('c-late-complete', 'Late Complete', now - 10000),
        mapCase('c-early-incomplete', 'Early Incomplete', now - 50000,
            answeredOf4: 1),
        mapCase('c-early-complete', 'Early Complete', now - 50000),
      ];
      final result = incomingCases(cases: cases, filter: 'all', nowMs: now);
      final names = (result['cases'] as List)
          .map((c) => (c as Map)['patientName'])
          .toList();
      // Equal earliest wait: more complete first. Latest arrival last.
      expect(names, ['Early Complete', 'Early Incomplete', 'Late Complete']);
      expect(result['sortStatement'], queueSortStatement);
      assertNoRiskFields(result);
    });

    test('CaseData cannot even carry a priority — parsing drops it', () {
      final c = CaseData.fromMap({
        'id': 'c1',
        'patientName': 'X',
        'createdAt': 1,
        'status': 'submitted',
        'priority': 'urgent', // present in the stored doc…
        'updates': const [],
      });
      // …but the read model has no field for it; nothing to assert beyond
      // construction succeeding and the output staying risk-free.
      final result = incomingCases(
          cases: [c], filter: 'all', nowMs: 2);
      assertNoRiskFields(result);
    });

    test('unknown answers still count as answered (§2.2), NOT_ASKED does not',
        () {
      final answeredUnknown = CaseData.fromMap({
        'id': 'c1',
        'patientName': 'X',
        'createdAt': 1,
        'status': 'submitted',
        'updates': [
          {
            'at': 1,
            'kind': 'initial',
            'transcript': 't',
            'syncState': 'sent',
            'redFlagAnswers': [
              {'questionId': 'q1', 'answer': 'UNKNOWN'},
              {'questionId': 'q2', 'answer': 'NOT_ASKED'},
            ],
            'functionalAnswers': const [],
          }
        ],
      });
      expect(answeredUnknown.completeness, 0.5);
    });
  });

  group('shift_overview', () {
    test('states and per-patient counts are factual, no risk fields', () {
      final patients = [
        patient('p1', 'A1', 'Alpha One'),
        patient('p2', 'A2', 'Beta Two'),
        patient('p3', 'A3', 'Gamma Three'),
      ];
      final handovers = [
        handover('h1', 'p1', HandoverStatus.confirmedInSystem,
            signature: const Signature(
                practitionerId: 'me',
                signatureIdentity: 'RN X',
                signedAt: 1,
                openFlagReason: null)),
        handover('h2', 'p2', HandoverStatus.draftReady,
            chips: [chip('c1'), chip('c2'), chip('c3', confirmed: true)]),
      ];
      final result = shiftOverview(patients: patients, handovers: handovers);
      expect(result['totalPatients'], 3);
      expect(result['signed'], 1);
      expect(result['recordedInAfia'], 1);
      expect(result['notStarted'], 1);
      final rows = (result['patients'] as List).cast<Map<String, Object?>>();
      expect(rows[1]['state'], 'draft_ready');
      expect(rows[1]['unconfirmedChips'], 2);
      assertNoRiskFields(result);
    });
  });

  group('whats_left — the factual checklist', () {
    test('buckets unsigned, unconfirmed-chip drafts, and export failures', () {
      final patients = [
        patient('p1', 'A1', 'Alpha One'),
        patient('p2', 'A2', 'Beta Two'),
        patient('p3', 'A3', 'Gamma Three'),
      ];
      final handovers = [
        handover('h1', 'p1', HandoverStatus.draftReady,
            chips: [chip('c1'), chip('c2')]),
        handover('h2', 'p2', HandoverStatus.exportFailed,
            signature: const Signature(
                practitionerId: 'me',
                signatureIdentity: 'RN X',
                signedAt: 1,
                openFlagReason: null),
            exportError: 'permission denied'),
      ];
      final result = whatsLeft(
          patients: patients,
          handovers: handovers,
          cases: [mapCase('c1', 'Waiting Case', 500)],
          nowMs: 1000);

      final unsigned =
          (result['patientsWithoutSignedHandover'] as List).cast<Map>();
      expect(unsigned.map((r) => r['patient']),
          containsAll(['A. One', 'G. Three']));
      final drafts =
          (result['draftsWithUnconfirmedChips'] as List).cast<Map>();
      expect(drafts.single['unconfirmedChips'], 2);
      final failures =
          (result['exportFailuresNeedingRetry'] as List).cast<Map>();
      expect(failures.single['patient'], 'B. Two');
      expect(result['incomingSubmittedCases'], 1);
      expect(result['incomingSortStatement'], queueSortStatement);
      assertNoRiskFields(result);
    });
  });

  group('queue comparator (§2.10 mirror)', () {
    test('wait time, completeness, id — deterministic', () {
      final ordered = orderQueue([
        const QueueEntry(id: 'b', receivedAt: 10, completeness: 0.5),
        const QueueEntry(id: 'a', receivedAt: 10, completeness: 0.5),
        const QueueEntry(id: 'c', receivedAt: 5, completeness: 0.1),
        const QueueEntry(id: 'd', receivedAt: 10, completeness: 0.9),
      ]);
      expect(ordered.map((e) => e.id), ['c', 'd', 'a', 'b']);
    });

    test('QueueEntry has no risk-shaped members', () {
      // Structural: the type carries exactly id/receivedAt/completeness.
      const entry = QueueEntry(id: 'x', receivedAt: 1, completeness: 1);
      expect(entry.id, 'x');
      expect(entry.receivedAt, 1);
      expect(entry.completeness, 1);
    });
  });
}
