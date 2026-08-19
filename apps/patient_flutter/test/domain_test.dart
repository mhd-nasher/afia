/// Constraint tests — Dart mirrors of T-001 / T-002 / T-007 for the patient
/// app's ported rules. These are the tests a regulator would read: escalation
/// is one-way, UNKNOWN is first-class and never coerced, and red-flag
/// evaluation is pure, deterministic, and works with the network poisoned
/// (airplane-mode test).
library;

import 'dart:io';

import 'package:afia_patient/domain/answer.dart';
import 'package:afia_patient/domain/episode.dart';
import 'package:afia_patient/domain/patient_case.dart';
import 'package:afia_patient/domain/priority.dart';
import 'package:afia_patient/domain/red_flags.dart';
import 'package:flutter_test/flutter_test.dart';

// ── helpers ────────────────────────────────────────────────────────────────

PatientCase _case({Priority priority = Priority.routine}) => PatientCase(
      id: 'case-t',
      externalIdentifier: null,
      createdAt: 0,
      patientName: 'T',
      completedBy: 'self',
      status: 'submitted',
      priority: priority,
      updates: const [],
      consentId: null,
      accountUid: 'uid-t',
    );

CaseUpdate _update({
  List<RedFlagAnswer> redFlagAnswers = const [],
  List<FunctionalAnswer> functionalAnswers = const [],
}) =>
    CaseUpdate(
      id: 'u-t',
      at: 1,
      kind: UpdateKind.conditionChanged,
      transcript: '',
      audio: null,
      redFlagAnswers: redFlagAnswers,
      redFlags: evaluateRedFlags(bundledRedFlagQuestions, redFlagAnswers),
      functionalAnswers: functionalAnswers,
      syncState: SyncState.queuedOnDevice,
    );

/// An HttpOverrides that fails EVERY socket — the network is poisoned.
class _AirplaneMode extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException('airplane mode — all networking disabled');
  }
}

void main() {
  // ── T-001 mirror — escalation is one-way (§2.1 / F-001) ──────────────────
  group('T-001 · escalate() is monotonic, no downgrade path exists', () {
    test('escalate returns the higher of the two values, always', () {
      expect(escalate(Priority.routine, Priority.urgent), Priority.urgent);
      expect(escalate(Priority.urgent, Priority.routine), Priority.urgent);
      expect(escalate(Priority.elevated, Priority.routine), Priority.elevated);
      expect(escalate(Priority.elevated, Priority.urgent), Priority.urgent);
      for (final a in Priority.values) {
        for (final b in Priority.values) {
          expect(escalate(a, b).rank, greaterThanOrEqualTo(a.rank));
          expect(escalate(a, b).rank, greaterThanOrEqualTo(b.rank));
        }
      }
    });

    test('a calm later update never lowers an urgent case', () {
      final urgent = _case(priority: Priority.urgent);
      final calm = _update(
        redFlagAnswers: [
          for (final q in bundledRedFlagQuestions)
            RedFlagAnswer(questionId: q.id, answer: AnswerState.no),
        ],
        functionalAnswers: [
          for (final q in bundledFunctionalQuestions)
            FunctionalAnswer(
                questionId: q.id, value: FunctionalValue.sameAsNormal),
        ],
      );
      final after = appendUpdate(urgent, calm);
      expect(after.priority, Priority.urgent);
      expect(after.updates.length, 1); // appended, never replaced
    });

    test('appendUpdate raises: red-flag YES → urgent, MUCH_WORSE → elevated',
        () {
      final yes = _update(redFlagAnswers: [
        RedFlagAnswer(
            questionId: bundledRedFlagQuestions.first.id,
            answer: AnswerState.yes),
      ]);
      expect(appendUpdate(_case(), yes).priority, Priority.urgent);

      final worse = _update(functionalAnswers: [
        FunctionalAnswer(
            questionId: bundledFunctionalQuestions.first.id,
            value: FunctionalValue.muchWorse),
      ]);
      expect(appendUpdate(_case(), worse).priority, Priority.elevated);

      // elevated proposal on an urgent case stays urgent (max-only).
      expect(appendUpdate(_case(priority: Priority.urgent), worse).priority,
          Priority.urgent);
    });

    test('condition-changed appends to the SAME case — never resets (F-056)',
        () {
      var c = appendUpdate(_case(), _update());
      final firstId = c.id;
      c = appendUpdate(c, _update());
      expect(c.id, firstId);
      expect(c.updates.length, 2);
      expect(c.status, 'submitted');
    });

    test('unrecognised wire priority parses defensively upward, never down',
        () {
      expect(Priority.parse('garbage'), Priority.urgent);
    });
  });

  // ── T-002 mirror — absent is not normal (§2.2 / F-002) ───────────────────
  group('T-002 · UNKNOWN is first-class and never coerced', () {
    test('UNKNOWN and NOT_ASKED are unanswered — distinct from NO', () {
      expect(isUnanswered(AnswerState.unknown), isTrue);
      expect(isUnanswered(AnswerState.notAsked), isTrue);
      expect(isUnanswered(AnswerState.no), isFalse);
      expect(isAffirmative(AnswerState.unknown), isFalse);
    });

    test('an unparseable answer becomes UNKNOWN, never NO', () {
      expect(AnswerState.parse('garbage'), AnswerState.unknown);
      expect(FunctionalValue.parse('garbage'), FunctionalValue.unknown);
    });

    test('UNKNOWN red-flag answers are listed, do not trigger', () {
      final result = evaluateRedFlags(bundledRedFlagQuestions, [
        RedFlagAnswer(
            questionId: bundledRedFlagQuestions[0].id,
            answer: AnswerState.unknown),
        RedFlagAnswer(
            questionId: bundledRedFlagQuestions[1].id,
            answer: AnswerState.no),
      ]);
      expect(result.triggered, isFalse);
      expect(result.unanswered, contains(bundledRedFlagQuestions[0].id));
      // Not asked at all → also unanswered, never silently NO.
      expect(result.unanswered, contains(bundledRedFlagQuestions[2].id));
      expect(result.unanswered, isNot(contains(bundledRedFlagQuestions[1].id)));
    });

    test('UNKNOWN functional answers never raise and never reduce priority',
        () {
      final unknowns = _update(functionalAnswers: [
        for (final q in bundledFunctionalQuestions)
          FunctionalAnswer(questionId: q.id, value: FunctionalValue.unknown),
      ]);
      expect(functionalEscalation(unknowns.functionalAnswers),
          FunctionalEscalation.none);
      expect(appendUpdate(_case(), unknowns).priority, Priority.routine);
      expect(appendUpdate(_case(priority: Priority.urgent), unknowns).priority,
          Priority.urgent);
    });

    test('episode round-trip preserves UNKNOWN exactly (never a default)',
        () {
      final e = EpisodeState(
        step: const Step(StepKind.review),
        redFlagAnswers: {'rf-chest-pain': AnswerState.unknown},
        functionalAnswers: {'fn-sleep': FunctionalValue.unknown},
      );
      final back = EpisodeState.fromJson(e.toJson());
      expect(back.redFlagAnswers['rf-chest-pain'], AnswerState.unknown);
      expect(back.functionalAnswers['fn-sleep'], FunctionalValue.unknown);
      expect(back.step.kind, StepKind.review);
    });
  });

  // ── T-007 mirror — local, deterministic, offline (§2.7 / F-007) ──────────
  group('T-007 · red-flag evaluation is pure, instant, airplane-mode safe',
      () {
    final answers = [
      RedFlagAnswer(
          questionId: bundledRedFlagQuestions[1].id, answer: AnswerState.yes),
      RedFlagAnswer(
          questionId: bundledRedFlagQuestions[3].id,
          answer: AnswerState.unknown),
    ];

    test('same input → same output, repeatedly', () {
      final a = evaluateRedFlags(bundledRedFlagQuestions, answers);
      final b = evaluateRedFlags(bundledRedFlagQuestions, answers);
      expect(a.toMap(), b.toMap());
      expect(a.triggered, isTrue);
      expect(a.triggeredBy, [bundledRedFlagQuestions[1].id]);
    });

    test('AIRPLANE MODE: with every socket poisoned, output is identical',
        () async {
      final before = evaluateRedFlags(bundledRedFlagQuestions, answers);
      final poisoned = await HttpOverrides.runZoned(
        () async {
          // Any attempted HTTP client creation inside this zone throws —
          // if evaluation touched the network, this test would fail.
          return evaluateRedFlags(bundledRedFlagQuestions, answers);
        },
        createHttpClient: (c) => _AirplaneMode().createHttpClient(c),
      );
      expect(poisoned.toMap(), before.toMap());
      expect(poisoned.triggered, isTrue);
    });

    test('emergency numbers are bundled constants (999 / 444)', () {
      expect(EmergencyNumbers.emergency, '999');
      expect(EmergencyNumbers.urgentAdvice, '444');
    });

    test('the questions are bundled at build — never fetched', () {
      expect(bundledRedFlagQuestions, hasLength(5));
      expect(bundledFunctionalQuestions, hasLength(4));
      for (final q in bundledRedFlagQuestions) {
        expect(q.textEn, isNotEmpty);
        expect(q.textAr, isNotEmpty);
      }
    });
  });

  // ── completeness / neutral gaps (§2.8 / F-008 adjacent) ──────────────────
  group('episode gaps are deterministic rules, neutrally shaped', () {
    test('unanswered items are listed in question order, no ranking field',
        () {
      final gaps = episodeGaps(
        redFlagQuestions: bundledRedFlagQuestions,
        redFlagAnswers: {
          bundledRedFlagQuestions[0].id: AnswerState.no,
          bundledRedFlagQuestions[2].id: AnswerState.unknown,
        },
        functionalQuestions: bundledFunctionalQuestions,
        functionalAnswers: {
          bundledFunctionalQuestions[0].id: FunctionalValue.worse,
        },
        transcript: '',
      );
      expect(gaps.unansweredRedFlags, [
        bundledRedFlagQuestions[1].id,
        bundledRedFlagQuestions[2].id,
        bundledRedFlagQuestions[3].id,
        bundledRedFlagQuestions[4].id,
      ]);
      expect(gaps.unansweredFunctional, hasLength(3));
      expect(gaps.descriptionMissing, isTrue);
      // Completeness is a share, 0..1 — the queue's only second key.
      final c = gaps.completeness(5, 4);
      expect(c, closeTo((10 - 8) / 10, 0.0001));
    });

    test('fully answered episode has no gaps', () {
      final gaps = episodeGaps(
        redFlagQuestions: bundledRedFlagQuestions,
        redFlagAnswers: {
          for (final q in bundledRedFlagQuestions) q.id: AnswerState.no,
        },
        functionalQuestions: bundledFunctionalQuestions,
        functionalAnswers: {
          for (final q in bundledFunctionalQuestions)
            q.id: FunctionalValue.sameAsNormal,
        },
        transcript: 'I feel weak.',
      );
      expect(gaps.isEmpty, isTrue);
      expect(gaps.completeness(5, 4), 1.0);
    });
  });

  // ── wire-shape parity with packages/core/src/case.ts ─────────────────────
  group('Firestore shapes mirror the shared core', () {
    test('case round-trip keeps every field and wire string', () {
      final c = appendUpdate(
        _case(),
        _update(redFlagAnswers: [
          RedFlagAnswer(
              questionId: bundledRedFlagQuestions[0].id,
              answer: AnswerState.yes),
        ]),
      );
      final map = c.toMap();
      expect(map['priority'], 'urgent');
      expect(
          (map['updates'] as List).first['syncState'], 'queued_on_device');
      expect((map['updates'] as List).first['kind'], 'condition_changed');
      expect(
          ((map['updates'] as List).first['redFlagAnswers'] as List)
              .first['answer'],
          'YES');
      final back = PatientCase.fromMap(map);
      expect(back.priority, Priority.urgent);
      expect(back.updates.single.redFlags.triggered, isTrue);
      expect(back.accountUid, 'uid-t');
    });

    test('sent flip changes only syncState', () {
      final u = _update();
      final sent = u.withSyncState(SyncState.sent);
      expect(sent.syncState, SyncState.sent);
      expect(sent.id, u.id);
      expect(sent.kind, u.kind);
      expect(sent.redFlags.toMap(), u.redFlags.toMap());
    });
  });
}
