/// In-progress episode state — current step plus every partial answer.
/// Persisted to SharedPreferences on EVERY change, so killing the app or a
/// crash resumes exactly where the person was. No unsaved state exists
/// (HANDOFF §6 / F-055).
library;

import 'dart:convert';

import 'answer.dart';
import 'patient_case.dart';
import 'red_flags.dart';

enum StepKind {
  entry,
  redflag,
  who,
  voice,
  functional,
  review,
  auth, // account gate — AFTER the safety questions, by design
  status,
  account,
  updateRedflag,
  updateDelta,
  updateConfirm;

  static StepKind parse(String name) => StepKind.values.firstWhere(
        (v) => v.name == name,
        orElse: () => StepKind.entry,
      );
}

class Step {
  final StepKind kind;

  /// Question index for redflag / functional / updateRedflag; 0 otherwise.
  final int index;
  const Step(this.kind, [this.index = 0]);

  Map<String, dynamic> toMap() => {'kind': kind.name, 'index': index};

  factory Step.fromMap(Map<String, dynamic> m) => Step(
        StepKind.parse(m['kind'] as String? ?? 'entry'),
        (m['index'] as num?)?.toInt() ?? 0,
      );
}

/// Draft of a "my condition has changed" update — fresh red-flag answers +
/// the delta description.
class UpdateDraft {
  final Map<String, AnswerState> redFlagAnswers;
  final String transcript;
  final AudioRecordingData? audio;

  const UpdateDraft({
    this.redFlagAnswers = const {},
    this.transcript = '',
    this.audio,
  });

  UpdateDraft copyWith({
    Map<String, AnswerState>? redFlagAnswers,
    String? transcript,
    AudioRecordingData? audio,
  }) =>
      UpdateDraft(
        redFlagAnswers: redFlagAnswers ?? this.redFlagAnswers,
        transcript: transcript ?? this.transcript,
        audio: audio ?? this.audio,
      );

  Map<String, dynamic> toMap() => {
        'redFlagAnswers':
            redFlagAnswers.map((k, v) => MapEntry(k, v.wire)),
        'transcript': transcript,
        'audio': audio?.toMap(),
      };

  factory UpdateDraft.fromMap(Map<String, dynamic> m) => UpdateDraft(
        redFlagAnswers: (m['redFlagAnswers'] as Map<dynamic, dynamic>? ?? {})
            .map((k, v) => MapEntry(k.toString(), AnswerState.parse(v as String))),
        transcript: m['transcript'] as String? ?? '',
        audio: m['audio'] == null
            ? null
            : AudioRecordingData.fromMap(
                Map<String, dynamic>.from(m['audio'] as Map)),
      );
}

class EpisodeState {
  final Step step;

  /// Set when an Edit button on the review screen jumped back to a question.
  final bool returnToReview;
  final String name;
  final bool termsAccepted;
  final bool consentGiven;
  final String? consentId;
  final String? completedBy; // 'self' | 'carer'
  final Map<String, AnswerState> redFlagAnswers;
  final String transcript;
  final AudioRecordingData? audio;
  final Map<String, FunctionalValue> functionalAnswers;
  final String? caseId;

  /// True while the emergency interrupt is shown; persisted so a restart
  /// resumes it.
  final bool emergency;
  final UpdateDraft? update;

  const EpisodeState({
    this.step = const Step(StepKind.entry),
    this.returnToReview = false,
    this.name = '',
    this.termsAccepted = false,
    this.consentGiven = false,
    this.consentId,
    this.completedBy,
    this.redFlagAnswers = const {},
    this.transcript = '',
    this.audio,
    this.functionalAnswers = const {},
    this.caseId,
    this.emergency = false,
    this.update,
  });

  static const _sentinel = Object();

  EpisodeState copyWith({
    Step? step,
    bool? returnToReview,
    String? name,
    bool? termsAccepted,
    bool? consentGiven,
    Object? consentId = _sentinel,
    Object? completedBy = _sentinel,
    Map<String, AnswerState>? redFlagAnswers,
    String? transcript,
    Object? audio = _sentinel,
    Map<String, FunctionalValue>? functionalAnswers,
    Object? caseId = _sentinel,
    bool? emergency,
    Object? update = _sentinel,
  }) =>
      EpisodeState(
        step: step ?? this.step,
        returnToReview: returnToReview ?? this.returnToReview,
        name: name ?? this.name,
        termsAccepted: termsAccepted ?? this.termsAccepted,
        consentGiven: consentGiven ?? this.consentGiven,
        consentId:
            identical(consentId, _sentinel) ? this.consentId : consentId as String?,
        completedBy: identical(completedBy, _sentinel)
            ? this.completedBy
            : completedBy as String?,
        redFlagAnswers: redFlagAnswers ?? this.redFlagAnswers,
        transcript: transcript ?? this.transcript,
        audio: identical(audio, _sentinel)
            ? this.audio
            : audio as AudioRecordingData?,
        functionalAnswers: functionalAnswers ?? this.functionalAnswers,
        caseId: identical(caseId, _sentinel) ? this.caseId : caseId as String?,
        emergency: emergency ?? this.emergency,
        update: identical(update, _sentinel)
            ? this.update
            : update as UpdateDraft?,
      );

  Map<String, dynamic> toMap() => {
        'step': step.toMap(),
        'returnToReview': returnToReview,
        'name': name,
        'termsAccepted': termsAccepted,
        'consentGiven': consentGiven,
        'consentId': consentId,
        'completedBy': completedBy,
        'redFlagAnswers': redFlagAnswers.map((k, v) => MapEntry(k, v.wire)),
        'transcript': transcript,
        'audio': audio?.toMap(),
        'functionalAnswers':
            functionalAnswers.map((k, v) => MapEntry(k, v.wire)),
        'caseId': caseId,
        'emergency': emergency,
        'update': update?.toMap(),
      };

  factory EpisodeState.fromMap(Map<String, dynamic> m) => EpisodeState(
        step: Step.fromMap(Map<String, dynamic>.from(m['step'] as Map? ?? {})),
        returnToReview: m['returnToReview'] as bool? ?? false,
        name: m['name'] as String? ?? '',
        termsAccepted: m['termsAccepted'] as bool? ?? false,
        consentGiven: m['consentGiven'] as bool? ?? false,
        consentId: m['consentId'] as String?,
        completedBy: m['completedBy'] as String?,
        redFlagAnswers: (m['redFlagAnswers'] as Map<dynamic, dynamic>? ?? {})
            .map((k, v) => MapEntry(k.toString(), AnswerState.parse(v as String))),
        transcript: m['transcript'] as String? ?? '',
        audio: m['audio'] == null
            ? null
            : AudioRecordingData.fromMap(
                Map<String, dynamic>.from(m['audio'] as Map)),
        functionalAnswers:
            (m['functionalAnswers'] as Map<dynamic, dynamic>? ?? {}).map(
                (k, v) => MapEntry(k.toString(), FunctionalValue.parse(v as String))),
        caseId: m['caseId'] as String?,
        emergency: m['emergency'] as bool? ?? false,
        update: m['update'] == null
            ? null
            : UpdateDraft.fromMap(Map<String, dynamic>.from(m['update'] as Map)),
      );

  String toJson() => jsonEncode(toMap());

  static EpisodeState fromJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return const EpisodeState();
      return EpisodeState.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const EpisodeState();
    }
  }

  /// A description is "unfinished" when the person got past entry but has
  /// not submitted — the entry screen shows its resume variant (§6 entry).
  bool get hasUnfinishedDescription =>
      caseId == null && step.kind != StepKind.entry;

  List<RedFlagAnswer> redFlagPairs() => redFlagAnswers.entries
      .map((e) => RedFlagAnswer(questionId: e.key, answer: e.value))
      .toList();

  List<FunctionalAnswer> functionalPairs() => functionalAnswers.entries
      .map((e) => FunctionalAnswer(questionId: e.key, value: e.value))
      .toList();
}
