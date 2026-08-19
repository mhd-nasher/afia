/// The handover note — FHIR `DocumentReference`. Dart mirror of
/// packages/core/src/handover.ts: the row-state machine of HANDOFF §5, the
/// per-chip confirmation of §2.3, the never-blocking omission flags of §2.4,
/// and the supersede rule of §2.5. Field names match the seeded Firestore
/// documents exactly (camelCase).
library;

import 'chips.dart';
import 'entities.dart';
import 'formulary.dart';
import 'gaps.dart';

enum HandoverStatus {
  notStarted,
  recording,
  draftReady,
  signed,
  queued,
  confirmedInSystem,
  exportFailed,
}

extension HandoverStatusWire on HandoverStatus {
  String get wire => switch (this) {
        HandoverStatus.notStarted => 'not_started',
        HandoverStatus.recording => 'recording',
        HandoverStatus.draftReady => 'draft_ready',
        HandoverStatus.signed => 'signed',
        HandoverStatus.queued => 'queued',
        HandoverStatus.confirmedInSystem => 'confirmed_in_system',
        HandoverStatus.exportFailed => 'export_failed',
      };

  static HandoverStatus parse(String wire) => switch (wire) {
        'recording' => HandoverStatus.recording,
        'draft_ready' => HandoverStatus.draftReady,
        'signed' => HandoverStatus.signed,
        'queued' => HandoverStatus.queued,
        'confirmed_in_system' => HandoverStatus.confirmedInSystem,
        'export_failed' => HandoverStatus.exportFailed,
        _ => HandoverStatus.notStarted,
      };
}

/// HANDOFF §5 — `signed` and `confirmed_in_system` are distinct states.
/// confirmed_in_system is reachable only from queued, on POSITIVE
/// acknowledgement from the receiving system — never local send-completion.
const Map<HandoverStatus, List<HandoverStatus>> transitions = {
  HandoverStatus.notStarted: [HandoverStatus.recording],
  // recording→recording = checkpoint
  HandoverStatus.recording: [HandoverStatus.recording, HandoverStatus.draftReady],
  // may resume recording; sign() guards signing
  HandoverStatus.draftReady: [HandoverStatus.recording, HandoverStatus.signed],
  HandoverStatus.signed: [HandoverStatus.queued],
  HandoverStatus.queued: [
    HandoverStatus.confirmedInSystem,
    HandoverStatus.exportFailed
  ],
  // retry re-queues; no path back to draft without supersede
  HandoverStatus.exportFailed: [HandoverStatus.queued],
  HandoverStatus.confirmedInSystem: [],
};

class IllegalTransitionError extends Error {
  final HandoverStatus from;
  final HandoverStatus to;
  IllegalTransitionError(this.from, this.to);
  @override
  String toString() =>
      'Illegal handover transition: ${from.wire} → ${to.wire}';
}

class UnconfirmedChipsError extends Error {
  final List<String> chipIds;
  UnconfirmedChipsError(this.chipIds);
  @override
  String toString() =>
      'Signing is blocked: ${chipIds.length} drug/number chip(s) are not individually confirmed.';
}

class MissingFlagReasonError extends Error {
  final int openCount;
  MissingFlagReasonError(this.openCount);
  @override
  String toString() =>
      '$openCount omission flag(s) are open — signing proceeds, but a reason must be recorded.';
}

class ConfirmableChip {
  final String id;
  final ChipKind kind;
  final String text;
  final int start;
  final int end;
  final DrugMatch? match;

  /// §2.3 — each chip is confirmed individually. null = unconfirmed.
  final String? confirmedBy;
  final int? confirmedAt;

  /// Formulary name chosen in the correction picker (recognition, never recall).
  final String? correctedTo;

  const ConfirmableChip({
    required this.id,
    required this.kind,
    required this.text,
    required this.start,
    required this.end,
    required this.match,
    required this.confirmedBy,
    required this.confirmedAt,
    required this.correctedTo,
  });

  bool get confirmed => confirmedAt != null;

  ConfirmableChip copyWith({
    String? confirmedBy,
    int? confirmedAt,
    String? correctedTo,
    bool resetConfirmation = false,
  }) =>
      ConfirmableChip(
        id: id,
        kind: kind,
        text: text,
        start: start,
        end: end,
        match: match,
        confirmedBy: resetConfirmation ? null : (confirmedBy ?? this.confirmedBy),
        confirmedAt: resetConfirmation ? null : (confirmedAt ?? this.confirmedAt),
        correctedTo: resetConfirmation ? null : (correctedTo ?? this.correctedTo),
      );

  factory ConfirmableChip.fromExtracted(ExtractedChip c) => ConfirmableChip(
        id: c.id,
        kind: c.kind,
        text: c.text,
        start: c.start,
        end: c.end,
        match: c.match,
        confirmedBy: null,
        confirmedAt: null,
        correctedTo: null,
      );

  factory ConfirmableChip.fromMap(Map<String, dynamic> m) => ConfirmableChip(
        id: m['id'] as String,
        kind: m['kind'] == 'number' ? ChipKind.number : ChipKind.drug,
        text: m['text'] as String? ?? '',
        start: (m['start'] as num?)?.toInt() ?? 0,
        end: (m['end'] as num?)?.toInt() ?? 0,
        match: m['match'] == null
            ? null
            : DrugMatch.fromMap((m['match'] as Map).cast<String, dynamic>()),
        confirmedBy: m['confirmedBy'] as String?,
        confirmedAt: (m['confirmedAt'] as num?)?.toInt(),
        correctedTo: m['correctedTo'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'text': text,
        'start': start,
        'end': end,
        'match': match?.toMap(),
        'confirmedBy': confirmedBy,
        'confirmedAt': confirmedAt,
        'correctedTo': correctedTo,
      };
}

/// §2.1 / §2.4 — a flag is never dismissed. It stays open until signing
/// acknowledges it with a recorded reason; it exports visibly either way.
/// The state union has no 'dismissed' member — dismissal cannot be expressed.
enum FlagState { open, acknowledgedInSigning }

extension FlagStateWire on FlagState {
  String get wire => this == FlagState.open ? 'open' : 'acknowledged_in_signing';
  static FlagState parse(String w) =>
      w == 'acknowledged_in_signing' ? FlagState.acknowledgedInSigning : FlagState.open;
}

class HandoverFlag {
  final String id;
  final String fieldId;
  final String label;

  /// Always the neutral form "Not mentioned: X" — never importance language.
  final String message;
  final FlagState state;
  final String? signingNote;

  const HandoverFlag({
    required this.id,
    required this.fieldId,
    required this.label,
    required this.message,
    required this.state,
    required this.signingNote,
  });

  HandoverFlag copyWith({FlagState? state, String? signingNote, bool clearNote = false}) =>
      HandoverFlag(
        id: id,
        fieldId: fieldId,
        label: label,
        message: message,
        state: state ?? this.state,
        signingNote: clearNote ? null : (signingNote ?? this.signingNote),
      );

  factory HandoverFlag.fromMap(Map<String, dynamic> m) => HandoverFlag(
        id: m['id'] as String,
        fieldId: m['fieldId'] as String? ?? '',
        label: m['label'] as String? ?? '',
        message: m['message'] as String? ?? '',
        state: FlagStateWire.parse(m['state'] as String? ?? 'open'),
        signingNote: m['signingNote'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fieldId': fieldId,
        'label': label,
        'message': message,
        'state': state.wire,
        'signingNote': signingNote,
      };
}

class Signature {
  final String practitionerId;

  /// Copied from Practitioner.signatureIdentity — immutable (§2.5).
  final String signatureIdentity;
  final int signedAt;
  final String? openFlagReason;

  const Signature({
    required this.practitionerId,
    required this.signatureIdentity,
    required this.signedAt,
    required this.openFlagReason,
  });

  factory Signature.fromMap(Map<String, dynamic> m) => Signature(
        practitionerId: m['practitionerId'] as String? ?? '',
        signatureIdentity: m['signatureIdentity'] as String? ?? '',
        signedAt: (m['signedAt'] as num?)?.toInt() ?? 0,
        openFlagReason: m['openFlagReason'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'practitionerId': practitionerId,
        'signatureIdentity': signatureIdentity,
        'signedAt': signedAt,
        'openFlagReason': openFlagReason,
      };
}

class AudioRecordingData {
  final String id;

  /// §2.6 — persisted and delivered playable. Never transcript-only.
  /// A data: URI (AAC m4a, base64) so it plays back on any device that
  /// receives the document. Empty + urlOmittedReason when it exceeded the
  /// Firestore document limit (same convention as packages/core firebase.ts).
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

  factory AudioRecordingData.fromMap(Map<String, dynamic> m) =>
      AudioRecordingData(
        id: m['id'] as String? ?? '',
        url: m['url'] as String? ?? '',
        mimeType: m['mimeType'] as String? ?? '',
        durationSec: (m['durationSec'] as num?)?.toDouble() ?? 0,
        recordedAt: (m['recordedAt'] as num?)?.toInt() ?? 0,
        urlOmittedReason: m['urlOmittedReason'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'mimeType': mimeType,
        'durationSec': durationSec,
        'recordedAt': recordedAt,
        if (urlOmittedReason != null) 'urlOmittedReason': urlOmittedReason,
      };
}

class Handover {
  final String id;
  final String? externalIdentifier;
  final int createdAt;
  final String patientId;
  final String authorId;
  final HandoverStatus status;
  final AudioRecordingData? audio;
  final String transcript;
  final List<FieldContent> fields;
  final List<ConfirmableChip> chips;
  final List<HandoverFlag> flags;
  final Signature? signature;
  final int version;

  /// §2.5 — the original is never overwritten; both versions and both
  /// signatures persist.
  final String? supersedes;
  final String? supersededBy;
  final String? exportError;

  /// When the receiving system positively acknowledged (→ confirmed_in_system).
  final int? acknowledgedAt;

  const Handover({
    required this.id,
    required this.externalIdentifier,
    required this.createdAt,
    required this.patientId,
    required this.authorId,
    required this.status,
    required this.audio,
    required this.transcript,
    required this.fields,
    required this.chips,
    required this.flags,
    required this.signature,
    required this.version,
    required this.supersedes,
    required this.supersededBy,
    required this.exportError,
    required this.acknowledgedAt,
  });

  Handover copyWith({
    HandoverStatus? status,
    AudioRecordingData? audio,
    String? transcript,
    List<FieldContent>? fields,
    List<ConfirmableChip>? chips,
    List<HandoverFlag>? flags,
    Signature? signature,
    String? supersededBy,
    String? exportError,
    int? acknowledgedAt,
    bool clearExportError = false,
  }) =>
      Handover(
        id: id,
        externalIdentifier: externalIdentifier,
        createdAt: createdAt,
        patientId: patientId,
        authorId: authorId,
        status: status ?? this.status,
        audio: audio ?? this.audio,
        transcript: transcript ?? this.transcript,
        fields: fields ?? this.fields,
        chips: chips ?? this.chips,
        flags: flags ?? this.flags,
        signature: signature ?? this.signature,
        version: version,
        supersedes: supersedes,
        supersededBy: supersededBy ?? this.supersededBy,
        exportError: clearExportError ? null : (exportError ?? this.exportError),
        acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      );

  factory Handover.fromMap(Map<String, dynamic> m) => Handover(
        id: m['id'] as String,
        externalIdentifier: m['externalIdentifier'] as String?,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        patientId: m['patientId'] as String? ?? '',
        authorId: m['authorId'] as String? ?? '',
        status: HandoverStatusWire.parse(m['status'] as String? ?? 'not_started'),
        audio: m['audio'] == null
            ? null
            : AudioRecordingData.fromMap(
                (m['audio'] as Map).cast<String, dynamic>()),
        transcript: m['transcript'] as String? ?? '',
        fields: (m['fields'] as List<dynamic>? ?? const [])
            .map((f) => FieldContent.fromMap((f as Map).cast<String, dynamic>()))
            .toList(),
        chips: (m['chips'] as List<dynamic>? ?? const [])
            .map((c) =>
                ConfirmableChip.fromMap((c as Map).cast<String, dynamic>()))
            .toList(),
        flags: (m['flags'] as List<dynamic>? ?? const [])
            .map((f) => HandoverFlag.fromMap((f as Map).cast<String, dynamic>()))
            .toList(),
        signature: m['signature'] == null
            ? null
            : Signature.fromMap((m['signature'] as Map).cast<String, dynamic>()),
        version: (m['version'] as num?)?.toInt() ?? 1,
        supersedes: m['supersedes'] as String?,
        supersededBy: m['supersededBy'] as String?,
        exportError: m['exportError'] as String?,
        acknowledgedAt: (m['acknowledgedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'externalIdentifier': externalIdentifier,
        'createdAt': createdAt,
        'fhirResource': 'DocumentReference',
        'patientId': patientId,
        'authorId': authorId,
        'status': status.wire,
        'audio': audio?.toMap(),
        'transcript': transcript,
        'fields': fields.map((f) => f.toMap()).toList(),
        'chips': chips.map((c) => c.toMap()).toList(),
        'flags': flags.map((f) => f.toMap()).toList(),
        'signature': signature?.toMap(),
        'version': version,
        'supersedes': supersedes,
        'supersededBy': supersededBy,
        'exportError': exportError,
        'acknowledgedAt': acknowledgedAt,
      };
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
int _idCounter = 0;
String newId(String prefix) =>
    '${prefix}_${_nowMs().toRadixString(36)}_${(_idCounter++).toRadixString(36)}';

Handover transition(Handover h, HandoverStatus to) {
  if (!transitions[h.status]!.contains(to)) {
    throw IllegalTransitionError(h.status, to);
  }
  return h.copyWith(status: to);
}

/// HANDOFF §2.3 — confirmation is per chip. The signature of this function is
/// the enforcement: it accepts exactly ONE chip id. There is no variant that
/// accepts a list, and no confirmAll anywhere in this codebase.
Handover confirmChip(
  Handover h,
  String chipId,
  Practitioner practitioner, {
  String? correctedTo,
  int? now,
}) {
  final exists = h.chips.any((c) => c.id == chipId);
  if (!exists) throw ArgumentError('Unknown chip: $chipId');
  return h.copyWith(
    chips: h.chips
        .map((c) => c.id == chipId
            ? c.copyWith(
                confirmedBy: practitioner.id,
                confirmedAt: now ?? _nowMs(),
                correctedTo: correctedTo,
              )
            : c)
        .toList(),
  );
}

List<ConfirmableChip> unconfirmedChips(Handover h) =>
    h.chips.where((c) => c.confirmedAt == null).toList();

List<HandoverFlag> openFlags(Handover h) =>
    h.flags.where((f) => f.state == FlagState.open).toList();

/// Signing — the ONLY hard block in the clinician app, and it blocks on
/// exactly one thing: unconfirmed chips (§2.3). Open omission flags never
/// block (§2.4); they require a recorded reason and export visibly.
Handover sign(
  Handover h,
  Practitioner practitioner, {
  String? openFlagReason,
  int? now,
}) {
  if (h.status != HandoverStatus.draftReady) {
    throw IllegalTransitionError(h.status, HandoverStatus.signed);
  }

  final unconfirmed = unconfirmedChips(h);
  if (unconfirmed.isNotEmpty) {
    throw UnconfirmedChipsError(unconfirmed.map((c) => c.id).toList());
  }

  final open = openFlags(h);
  final reason = (openFlagReason?.trim().isEmpty ?? true) ? null : openFlagReason!.trim();
  if (open.isNotEmpty && reason == null) {
    throw MissingFlagReasonError(open.length);
  }

  return h.copyWith(
    status: HandoverStatus.signed,
    flags: h.flags
        .map((f) => f.state == FlagState.open
            ? f.copyWith(state: FlagState.acknowledgedInSigning, signingNote: reason)
            : f)
        .toList(),
    signature: Signature(
      practitionerId: practitioner.id,
      signatureIdentity: practitioner.signatureIdentity,
      signedAt: now ?? _nowMs(),
      openFlagReason: open.isNotEmpty ? reason : null,
    ),
  );
}

class SupersedeResult {
  final Handover original;
  final Handover draft;
  const SupersedeResult({required this.original, required this.draft});
}

/// HANDOFF §2.5 — post-signature edits invalidate the signature and require
/// explicit re-signing. The original is returned unchanged apart from the
/// supersededBy link; the new draft starts unsigned with every chip
/// confirmation reset (edited content must be re-verified).
SupersedeResult supersede(Handover original, {int? now}) {
  if (original.signature == null) {
    throw StateError(
        'Only a signed handover can be superseded — edit the draft directly.');
  }

  final draftId = newId('handover');
  return SupersedeResult(
    original: original.copyWith(supersededBy: draftId),
    draft: Handover(
      id: draftId,
      externalIdentifier: original.externalIdentifier,
      createdAt: now ?? _nowMs(),
      patientId: original.patientId,
      authorId: original.authorId,
      status: HandoverStatus.draftReady,
      audio: original.audio,
      transcript: original.transcript,
      fields: original.fields,
      chips: original.chips
          .map((c) => c.copyWith(resetConfirmation: true))
          .toList(),
      flags: original.flags
          .map((f) => f.copyWith(state: FlagState.open, clearNote: true))
          .toList(),
      signature: null,
      version: original.version + 1,
      supersedes: original.id,
      supersededBy: null,
      exportError: null,
      acknowledgedAt: null,
    ),
  );
}
