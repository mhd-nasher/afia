/// A patient-app episode. One case per attendance; "my condition has changed"
/// APPENDS an update to the same case (HANDOFF §6 / F-056) — it never
/// re-queues, never resets, never creates a second case. Shapes mirror
/// packages/core/src/case.ts so all three surfaces read the same Firestore
/// documents; `accountUid` is additive (patient accounts are a product-owner
/// decision on top of the original spec).
library;

import 'dart:math';

import 'answer.dart';
import 'priority.dart';
import 'red_flags.dart';

String newId(String prefix) {
  final r = Random();
  final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final s = List.generate(8, (_) => r.nextInt(36).toRadixString(36)).join();
  return '$prefix-$t$s';
}

/// Short human-readable case reference from a case id.
String shortRef(String caseId) {
  final cleaned = caseId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  final tail = cleaned.length <= 6 ? cleaned : cleaned.substring(cleaned.length - 6);
  return tail.toUpperCase();
}

class AudioRecordingData {
  final String id;

  /// base64 data URI — same <900KB convention as the clinician app; oversized
  /// audio stays on-device with url '' and [urlOmittedReason] set.
  final String url;
  final String mimeType;
  final double durationSec;
  final int recordedAt;
  final String? urlOmittedReason;

  const AudioRecordingData({
    required this.id,
    required this.url,
    required this.mimeType,
    required this.durationSec,
    required this.recordedAt,
    this.urlOmittedReason,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'mimeType': mimeType,
        'durationSec': durationSec,
        'recordedAt': recordedAt,
        if (urlOmittedReason != null) 'urlOmittedReason': urlOmittedReason,
      };

  factory AudioRecordingData.fromMap(Map<String, dynamic> m) =>
      AudioRecordingData(
        id: m['id'] as String? ?? '',
        url: m['url'] as String? ?? '',
        mimeType: m['mimeType'] as String? ?? 'audio/mp4',
        durationSec: (m['durationSec'] as num?)?.toDouble() ?? 0,
        recordedAt: (m['recordedAt'] as num?)?.toInt() ?? 0,
        urlOmittedReason: m['urlOmittedReason'] as String?,
      );
}

enum UpdateKind {
  initial('initial'),
  conditionChanged('condition_changed');

  final String wire;
  const UpdateKind(this.wire);

  static UpdateKind parse(String wire) =>
      wire == 'condition_changed' ? UpdateKind.conditionChanged : UpdateKind.initial;
}

/// §6 offline honesty — 'queued_on_device' renders as "saved on this phone,
/// NOT yet sent"; the UI never implies a nurse has seen it (F-057). The flip
/// to 'sent' happens only after the Firestore write is ACKNOWLEDGED by the
/// server — never on local echo, never on navigator connectivity.
enum SyncState {
  queuedOnDevice('queued_on_device'),
  sent('sent');

  final String wire;
  const SyncState(this.wire);

  static SyncState parse(String wire) =>
      wire == 'sent' ? SyncState.sent : SyncState.queuedOnDevice;
}

class CaseUpdate {
  final String id;
  final int at;
  final UpdateKind kind;
  final String transcript;
  final AudioRecordingData? audio;
  final List<RedFlagAnswer> redFlagAnswers;
  final RedFlagResult redFlags;
  final List<FunctionalAnswer> functionalAnswers;
  final SyncState syncState;

  const CaseUpdate({
    required this.id,
    required this.at,
    required this.kind,
    required this.transcript,
    required this.audio,
    required this.redFlagAnswers,
    required this.redFlags,
    required this.functionalAnswers,
    required this.syncState,
  });

  CaseUpdate withSyncState(SyncState s) => CaseUpdate(
        id: id,
        at: at,
        kind: kind,
        transcript: transcript,
        audio: audio,
        redFlagAnswers: redFlagAnswers,
        redFlags: redFlags,
        functionalAnswers: functionalAnswers,
        syncState: s,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'at': at,
        'kind': kind.wire,
        'transcript': transcript,
        'audio': audio?.toMap(),
        'redFlagAnswers': redFlagAnswers.map((a) => a.toMap()).toList(),
        'redFlags': redFlags.toMap(),
        'functionalAnswers': functionalAnswers.map((a) => a.toMap()).toList(),
        'syncState': syncState.wire,
      };

  factory CaseUpdate.fromMap(Map<String, dynamic> m) => CaseUpdate(
        id: m['id'] as String? ?? '',
        at: (m['at'] as num?)?.toInt() ?? 0,
        kind: UpdateKind.parse(m['kind'] as String? ?? 'initial'),
        transcript: m['transcript'] as String? ?? '',
        audio: m['audio'] == null
            ? null
            : AudioRecordingData.fromMap(
                Map<String, dynamic>.from(m['audio'] as Map)),
        redFlagAnswers: (m['redFlagAnswers'] as List<dynamic>? ?? const [])
            .map((e) => RedFlagAnswer.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        redFlags: RedFlagResult.fromMap(
            Map<String, dynamic>.from(m['redFlags'] as Map? ?? const {})),
        functionalAnswers: (m['functionalAnswers'] as List<dynamic>? ?? const [])
            .map((e) =>
                FunctionalAnswer.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        syncState: SyncState.parse(m['syncState'] as String? ?? 'queued_on_device'),
      );
}

class PatientCase {
  final String id;
  final String? externalIdentifier; // §3.1 — future hospital MRN link
  final int createdAt;
  final String patientName;
  final String completedBy; // 'self' | 'carer'
  final String status; // 'in_progress' | 'submitted'
  final Priority priority;

  /// Append-only. updates[0] is the initial submission.
  final List<CaseUpdate> updates;
  final String? consentId;

  /// Additive to the shared shape: the self-registered patient account that
  /// owns this case (product-owner auth decision).
  final String? accountUid;

  const PatientCase({
    required this.id,
    required this.externalIdentifier,
    required this.createdAt,
    required this.patientName,
    required this.completedBy,
    required this.status,
    required this.priority,
    required this.updates,
    required this.consentId,
    required this.accountUid,
  });

  PatientCase copyWith({
    String? status,
    Priority? priority,
    List<CaseUpdate>? updates,
  }) =>
      PatientCase(
        id: id,
        externalIdentifier: externalIdentifier,
        createdAt: createdAt,
        patientName: patientName,
        completedBy: completedBy,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        updates: updates ?? this.updates,
        consentId: consentId,
        accountUid: accountUid,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'externalIdentifier': externalIdentifier,
        'createdAt': createdAt,
        'patientName': patientName,
        'completedBy': completedBy,
        'status': status,
        'priority': priority.wire,
        'updates': updates.map((u) => u.toMap()).toList(),
        'consentId': consentId,
        'accountUid': accountUid,
      };

  factory PatientCase.fromMap(Map<String, dynamic> m) => PatientCase(
        id: m['id'] as String? ?? '',
        externalIdentifier: m['externalIdentifier'] as String?,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        patientName: m['patientName'] as String? ?? '',
        completedBy: m['completedBy'] as String? ?? 'self',
        status: m['status'] as String? ?? 'in_progress',
        priority: Priority.parse(m['priority'] as String? ?? 'routine'),
        updates: (m['updates'] as List<dynamic>? ?? const [])
            .map((e) => CaseUpdate.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        consentId: m['consentId'] as String?,
        accountUid: m['accountUid'] as String?,
      );
}

/// The only way case state advances. Priority moves through escalate() — a
/// red-flag YES raises to urgent, a MUCH_WORSE functional answer raises to
/// elevated, and nothing in this app (or the deployed rules) lowers it
/// (§2.1). UNKNOWN answers change nothing: they never reduce priority (§2.2).
PatientCase appendUpdate(PatientCase c, CaseUpdate update) {
  var priority = c.priority;
  if (update.redFlags.triggered) priority = escalate(priority, Priority.urgent);
  if (functionalEscalation(update.functionalAnswers) ==
      FunctionalEscalation.elevated) {
    priority = escalate(priority, Priority.elevated);
  }
  return c.copyWith(
    status: 'submitted',
    priority: priority,
    updates: [...c.updates, update],
  );
}

/// Deterministic completeness of an episode's answers (rules, not a model —
/// §2.8). Returns the ids of red-flag and functional questions left
/// unanswered plus whether a description exists. The UI phrases this
/// NEUTRALLY: "Not mentioned: X" — never importance language (§4.3).
class EpisodeGaps {
  final List<String> unansweredRedFlags;
  final List<String> unansweredFunctional;
  final bool descriptionMissing;
  const EpisodeGaps({
    required this.unansweredRedFlags,
    required this.unansweredFunctional,
    required this.descriptionMissing,
  });

  bool get isEmpty =>
      unansweredRedFlags.isEmpty &&
      unansweredFunctional.isEmpty &&
      !descriptionMissing;

  /// 0..1 share of items with content — the queue's second sort key.
  double completeness(int redFlagCount, int functionalCount) {
    final total = redFlagCount + functionalCount + 1;
    final missing = unansweredRedFlags.length +
        unansweredFunctional.length +
        (descriptionMissing ? 1 : 0);
    return (total - missing) / total;
  }
}

EpisodeGaps episodeGaps({
  required List<RedFlagQuestion> redFlagQuestions,
  required Map<String, AnswerState> redFlagAnswers,
  required List<FunctionalQuestion> functionalQuestions,
  required Map<String, FunctionalValue> functionalAnswers,
  required String transcript,
}) {
  final unansweredRf = <String>[];
  for (final q in redFlagQuestions) {
    final a = redFlagAnswers[q.id] ?? AnswerState.notAsked;
    if (isUnanswered(a)) unansweredRf.add(q.id);
  }
  final unansweredFn = <String>[];
  for (final q in functionalQuestions) {
    final v = functionalAnswers[q.id] ?? FunctionalValue.notAsked;
    if (v == FunctionalValue.unknown || v == FunctionalValue.notAsked) {
      unansweredFn.add(q.id);
    }
  }
  return EpisodeGaps(
    unansweredRedFlags: unansweredRf,
    unansweredFunctional: unansweredFn,
    descriptionMissing: transcript.trim().isEmpty,
  );
}
