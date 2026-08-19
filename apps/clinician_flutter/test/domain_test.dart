/// Dart mirrors of T-001..T-006 from packages/core/src/core.test.ts, plus the
/// state-machine and gap-wording checks. These prove the ten §2 constraints
/// hold structurally in this app's domain layer.
library;

import 'package:afia_clinician/domain/answer.dart';
import 'package:afia_clinician/domain/chips.dart';
import 'package:afia_clinician/domain/draft.dart';
import 'package:afia_clinician/domain/entities.dart';
import 'package:afia_clinician/domain/export.dart';
import 'package:afia_clinician/domain/formulary.dart';
import 'package:afia_clinician/domain/gaps.dart';
import 'package:afia_clinician/domain/handover.dart';
import 'package:afia_clinician/domain/priority.dart';
import 'package:afia_clinician/domain/structuring.dart';
import 'package:flutter_test/flutter_test.dart';

const nurse = Practitioner(
  id: 'prac-test',
  externalIdentifier: null,
  createdAt: 0,
  name: 'Test Nurse',
  role: PractitionerRole.nurse,
  signatureIdentity: 'RN 00-0001 · Test Nurse',
  invitedBy: 'system',
);

const formulary = [
  FormularyEntry(id: 'drug-furosemide', name: 'furosemide', soundAlikeGroup: 'furo-fluo'),
  FormularyEntry(id: 'drug-fluoxetine', name: 'fluoxetine', soundAlikeGroup: 'furo-fluo'),
  FormularyEntry(id: 'drug-paracetamol', name: 'paracetamol'),
];

const template = [
  TemplateField(id: 'situation', label: 'Situation', required: true, keywords: ['situation', 'admitted', 'day']),
  TemplateField(id: 'medications', label: 'Medications given', required: true, keywords: ['medication', 'given', 'mg']),
  TemplateField(id: 'plan', label: 'Plan for next shift', required: true, keywords: ['plan', 'monitor', 'review']),
  TemplateField(id: 'family', label: 'Family communication', required: false, keywords: ['family', 'daughter']),
];

Handover draft({
  HandoverStatus status = HandoverStatus.draftReady,
  List<ConfirmableChip> chips = const [],
  List<HandoverFlag> flags = const [],
  Signature? signature,
}) =>
    Handover(
      id: 'h1',
      externalIdentifier: null,
      createdAt: 0,
      patientId: 'p1',
      authorId: nurse.id,
      status: status,
      audio: const AudioRecordingData(
        id: 'a1',
        url: 'data:audio/mp4;base64,AAAA',
        mimeType: 'audio/mp4',
        durationSec: 2,
        recordedAt: 0,
      ),
      transcript: '',
      fields: const [],
      chips: chips,
      flags: flags,
      signature: signature,
      version: 1,
      supersedes: null,
      supersededBy: null,
      exportError: null,
      acknowledgedAt: null,
    );

ConfirmableChip chip(String id, {bool confirmed = false}) => ConfirmableChip(
      id: id,
      kind: ChipKind.drug,
      text: 'furosemide',
      start: 0,
      end: 10,
      match: null,
      confirmedBy: confirmed ? nurse.id : null,
      confirmedAt: confirmed ? 1 : null,
      correctedTo: null,
    );

HandoverFlag openFlag(String id) => HandoverFlag(
      id: id,
      fieldId: 'medications',
      label: 'Medications given',
      message: 'Not mentioned: Medications given',
      state: FlagState.open,
      signingNote: null,
    );

void main() {
  group('T-001 — escalation is one-way (§2.1)', () {
    test('escalate() only ever raises', () {
      expect(escalate(Priority.routine, Priority.urgent), Priority.urgent);
      expect(escalate(Priority.urgent, Priority.routine), Priority.urgent);
      expect(escalate(Priority.elevated, Priority.routine), Priority.elevated);
      expect(escalate(Priority.elevated, Priority.elevated), Priority.elevated);
    });

    test('flag states cannot express dismissal — no dismissed member exists', () {
      expect(FlagState.values.map((s) => s.name),
          unorderedEquals(['open', 'acknowledgedInSigning']));
    });

    test('unknown wire priority never lowers (§2.2 companion)', () {
      expect(PriorityWire.parse('garbage'), Priority.urgent);
    });
  });

  group('T-002 — UNKNOWN never coerced (§2.2)', () {
    test('AnswerState has UNKNOWN and NOT_ASKED as first-class values', () {
      expect(AnswerState.values.length, 4);
      expect(isUnanswered(AnswerState.unknown), isTrue);
      expect(isUnanswered(AnswerState.notAsked), isTrue);
      expect(isUnanswered(AnswerState.no), isFalse);
    });

    test('unrecognised wire value parses to UNKNOWN, never NO', () {
      expect(AnswerStateWire.parse(''), AnswerState.unknown);
      expect(AnswerStateWire.parse('MAYBE'), AnswerState.unknown);
    });
  });

  group('T-003 — no bulk confirmation; unconfirmed chips block signing (§2.3)', () {
    test('sign() throws while any chip is unconfirmed, listing the ids', () {
      final h = draft(chips: [chip('c1', confirmed: true), chip('c2')]);
      expect(() => sign(h, nurse), throwsA(isA<UnconfirmedChipsError>()));
      try {
        sign(h, nurse);
      } on UnconfirmedChipsError catch (e) {
        expect(e.chipIds, ['c2']);
      }
    });

    test('signing succeeds only after each chip is individually confirmed', () {
      var h = draft(chips: [chip('c1'), chip('c2')]);
      h = confirmChip(h, 'c1', nurse);
      expect(() => sign(h, nurse), throwsA(isA<UnconfirmedChipsError>()));
      h = confirmChip(h, 'c2', nurse);
      final signed = sign(h, nurse);
      expect(signed.status, HandoverStatus.signed);
      expect(signed.signature?.signatureIdentity, 'RN 00-0001 · Test Nurse');
    });

    test('confirmChip accepts exactly one chip id — unknown id throws', () {
      final h = draft(chips: [chip('c1')]);
      expect(() => confirmChip(h, 'nope', nurse), throwsArgumentError);
    });
  });

  group('T-004 — omission flags never block signing (§2.4)', () {
    test('open flags + recorded reason → signs; flags carry the note', () {
      final h = draft(flags: [openFlag('f1'), openFlag('f2')]);
      final signed =
          sign(h, nurse, openFlagReason: 'End of shift — night team to complete.');
      expect(signed.status, HandoverStatus.signed);
      expect(signed.signature?.openFlagReason,
          'End of shift — night team to complete.');
      for (final f in signed.flags) {
        expect(f.state, FlagState.acknowledgedInSigning);
        expect(f.signingNote, 'End of shift — night team to complete.');
      }
    });

    test('open flags without a reason ask for one — chips remain the only hard block',
        () {
      final h = draft(flags: [openFlag('f1')]);
      expect(() => sign(h, nurse), throwsA(isA<MissingFlagReasonError>()));
      expect(sign(h, nurse, openFlagReason: 'Handed to day team').status,
          HandoverStatus.signed);
    });

    test('flags export visibly with the note in every exporter', () {
      final signed = sign(draft(flags: [openFlag('f1')]), nurse,
          openFlagReason: 'Handed to day team');
      const patient = Patient(
          id: 'p1',
          externalIdentifier: null,
          createdAt: 0,
          name: 'Test Patient',
          dateOfBirth: '1950-01-01',
          wardId: 'w1',
          bed: 'A1');
      final clip = const ClipboardExporter().export(signed, patient);
      expect(clip.payload, contains('Not mentioned: Medications given'));
      expect(clip.payload, contains('Handed to day team'));
      final fhir = const FhirExporter().export(signed, patient);
      expect(fhir.payload, contains('Not mentioned: Medications given'));
      // A1.1 — no demo labels appear in any surface or export.
      expect(fhir.payload, isNot(contains('SYNTHETIC')));
      expect(clip.payload, isNot(contains('SYNTHETIC')));
    });
  });

  group('T-005 — signature immutable; supersede keeps both versions (§2.5)', () {
    test('supersede preserves the original + signature, resets confirmations', () {
      final signed = sign(draft(chips: [chip('c1', confirmed: true)]), nurse);
      final result = supersede(signed);

      expect(result.original.id, 'h1');
      expect(result.original.signature?.signatureIdentity,
          nurse.signatureIdentity);
      expect(result.original.supersededBy, result.draft.id);

      expect(result.draft.version, 2);
      expect(result.draft.signature, isNull);
      expect(result.draft.supersedes, 'h1');
      expect(result.draft.chips.every((c) => c.confirmedAt == null), isTrue);
      expect(result.draft.flags.every((f) => f.state == FlagState.open), isTrue);
    });

    test('signature identity comes from the practitioner record, never input', () {
      final signed = sign(draft(), nurse);
      expect(signed.signature?.signatureIdentity, 'RN 00-0001 · Test Nurse');
    });

    test('an unsigned draft cannot be superseded', () {
      expect(() => supersede(draft()), throwsStateError);
    });
  });

  group('T-006 — raw audio is stored and survives supersede (§2.6)', () {
    test('audio data URI persists through sign and supersede', () {
      final signed = sign(draft(), nurse);
      final result = supersede(signed);
      expect(result.draft.audio?.url, startsWith('data:audio/'));
      expect(result.draft.audio?.url, signed.audio?.url);
    });
  });

  group('state machine — signed ≠ confirmed_in_system (§5)', () {
    test('confirmed_in_system is reachable only from queued', () {
      final signed = sign(draft(), nurse);
      expect(() => transition(signed, HandoverStatus.confirmedInSystem),
          throwsA(isA<IllegalTransitionError>()));
      final queued = transition(signed, HandoverStatus.queued);
      final confirmed = transition(queued, HandoverStatus.confirmedInSystem);
      expect(confirmed.status, HandoverStatus.confirmedInSystem);
    });

    test('export_failed can only retry back to queued, never to draft', () {
      final failed = transition(
          transition(sign(draft(), nurse), HandoverStatus.queued),
          HandoverStatus.exportFailed);
      expect(() => transition(failed, HandoverStatus.draftReady),
          throwsA(isA<IllegalTransitionError>()));
      expect(transition(failed, HandoverStatus.queued).status,
          HandoverStatus.queued);
    });

    test('confirmed_in_system is terminal', () {
      expect(transitions[HandoverStatus.confirmedInSystem], isEmpty);
    });
  });

  group('chips — deterministic extraction (§4.4)', () {
    test('same transcript + formulary → identical chips, sorted by offset', () {
      const t = 'Gave furosemide 40 mg and paracetamol 1 g. BP 120/80.';
      final a = extractChips(t, formulary);
      final b = extractChips(t, formulary);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].id, b[i].id);
        expect(a[i].text, b[i].text);
      }
      expect(a.map((c) => c.text),
          containsAll(['furosemide', '40 mg', 'paracetamol', '1 g', '120/80']));
    });

    test('sound-alike near-miss is flagged low confidence with partners visible',
        () {
      final m = matchDrug('ferosemide', formulary);
      expect(m.confidence, MatchConfidence.low);
      expect(m.entryName, 'furosemide');
      expect(m.candidates, contains('fluoxetine')); // the dangerous partner
    });

    test('formulary search clusters sound-alikes together, always complete', () {
      final clusters = searchFormulary('furos', formulary);
      final cluster = clusters.firstWhere((c) => c.length > 1);
      expect(cluster.map((e) => e.name),
          unorderedEquals(['furosemide', 'fluoxetine']));
    });
  });

  group('gaps — deterministic, neutral wording (§2.8 / §4.3)', () {
    test('missing required field → "Not mentioned: X", template order', () {
      final flags = detectGaps(template, const [
        FieldContent(fieldId: 'situation', text: 'Day 3.'),
        FieldContent(fieldId: 'medications', text: '  '),
      ]);
      expect(flags.map((f) => f.message),
          ['Not mentioned: Medications given', 'Not mentioned: Plan for next shift']);
      for (final f in flags) {
        expect(f.message.toLowerCase(), isNot(contains('critical')));
        expect(f.message.toLowerCase(), isNot(contains('important')));
        expect(f.message.toLowerCase(), isNot(contains('urgent')));
      }
    });

    test('same input → same output (property check over checkpoints)', () {
      const contents = [FieldContent(fieldId: 'plan', text: 'Monitor overnight.')];
      final first = detectGaps(template, contents);
      for (var i = 0; i < 50; i++) {
        final again = detectGaps(template, contents);
        expect(again.map((f) => f.message), first.map((f) => f.message));
      }
    });

    test('optional fields never flag', () {
      final flags = detectGaps(template, const [
        FieldContent(fieldId: 'situation', text: 'x'),
        FieldContent(fieldId: 'medications', text: 'x'),
        FieldContent(fieldId: 'plan', text: 'x'),
      ]);
      expect(flags, isEmpty);
    });
  });

  group('draft recomputation preserves confirmations (§5 checkpointing)', () {
    test('unchanged chips keep their confirmation across a checkpoint', () {
      var h = draft(status: HandoverStatus.recording);
      h = recomputeDraft(h,
          transcript: 'Gave furosemide 40 mg.',
          formulary: formulary,
          template: template);
      final id = h.chips.first.id;
      h = confirmChip(h, id, nurse);
      h = recomputeDraft(h,
          transcript: 'Gave furosemide 40 mg. Plan to monitor.',
          formulary: formulary,
          template: template);
      final kept = h.chips.firstWhere((c) => c.id == id);
      expect(kept.confirmedAt, isNotNull);
    });

    test('signed handovers cannot be edited — supersede is the only path', () {
      final signed = sign(draft(), nurse);
      expect(
          () => recomputeDraft(signed,
              transcript: 'x', formulary: formulary, template: template),
          throwsStateError);
    });
  });

  group('structurer — deterministic fallback (§4.1/§4.2)', () {
    test('keyword router is deterministic and routes side notes to fields', () {
      const structurer = KeywordStructurer();
      const t =
          'Admitted on day 3 with pneumonia. Given 40 mg this morning. Plan to monitor overnight. Daughter called and was updated.';
      final a = structurer.structureSync(t, template);
      final b = structurer.structureSync(t, template);
      expect(a.length, b.length);
      expect(a.firstWhere((f) => f.fieldId == 'family').text,
          contains('Daughter called'));
    });

    test('validateStructured drops unknown fieldIds and untraceable content', () {
      const t = 'Given 40 mg this morning.';
      final out = validateStructured(
        const [
          FieldContent(fieldId: 'medications', text: 'Given 40 mg this morning.'),
          FieldContent(fieldId: 'invented-field', text: 'Given 40 mg this morning.'),
          FieldContent(fieldId: 'plan', text: 'Patient is critically unwell.'),
        ],
        t,
        template,
      );
      expect(out.length, 1);
      expect(out.single.fieldId, 'medications');
    });

    test('ten-second summary reorganises, never judges', () {
      final s = tenSecondSummary(
        const [
          FieldContent(fieldId: 'situation', text: 'Day 3 of pneumonia.'),
          FieldContent(fieldId: 'medications', text: 'furosemide 40 mg IV.'),
          FieldContent(fieldId: 'plan', text: 'Wean oxygen.'),
        ],
        template,
      );
      expect(s, 'Day 3 of pneumonia. · furosemide 40 mg IV. · Wean oxygen.');
    });

    test('diff states changes neutrally', () {
      final d = diffHandovers(
        const [FieldContent(fieldId: 'situation', text: 'Day 2.')],
        const [
          FieldContent(fieldId: 'situation', text: 'Day 3.'),
          FieldContent(fieldId: 'plan', text: 'Monitor.'),
        ],
        template,
      );
      expect(d.firstWhere((x) => x.fieldId == 'situation').kind, DiffKind.changed);
      expect(d.firstWhere((x) => x.fieldId == 'plan').kind, DiffKind.added);
      expect(d.firstWhere((x) => x.fieldId == 'medications').kind,
          DiffKind.nowEmpty.index == 3 ? DiffKind.unchanged : DiffKind.unchanged);
    });
  });

  group('queue completeness (§2.10 companion)', () {
    test('fileCompleteness is share of filled template fields', () {
      expect(
          fileCompleteness(template, const [
            FieldContent(fieldId: 'situation', text: 'x'),
            FieldContent(fieldId: 'plan', text: 'x'),
          ]),
          0.5);
    });
  });
}
