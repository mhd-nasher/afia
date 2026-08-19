/// D-014 — the shift-teamwork data contracts, pure and unit-testable.
/// Payload shapes mirror /database.rules.json exactly. OPERATIONAL data only:
/// presence, preset request kind, bed label, short note — clinical records
/// stay in Firestore (me-central2); RTDB is europe-west1.
library;

/// The preset request kinds — the things nurses/doctors actually ask each
/// other. No free-form clinical content; the kind IS the message.
enum RequestKind {
  breakCover,
  liftTurn,
  medWitness,
  takeOver,
  ivHelp,
  urgentReview,
  supplies,
  familyTalk,
}

extension RequestKindWire on RequestKind {
  String get wire => switch (this) {
        RequestKind.breakCover => 'break_cover',
        RequestKind.liftTurn => 'lift_turn',
        RequestKind.medWitness => 'med_witness',
        RequestKind.takeOver => 'take_over',
        RequestKind.ivHelp => 'iv_help',
        RequestKind.urgentReview => 'urgent_review',
        RequestKind.supplies => 'supplies',
        RequestKind.familyTalk => 'family_talk',
      };

  static RequestKind? parse(String wire) {
    for (final k in RequestKind.values) {
      if (k.wire == wire) return k;
    }
    return null;
  }
}

enum RequestStatus { pending, accepted, declined, done }

extension RequestStatusWire on RequestStatus {
  String get wire => name;
  static RequestStatus parse(String wire) => RequestStatus.values
      .firstWhere((s) => s.name == wire, orElse: () => RequestStatus.pending);
}

/// The request lifecycle: pending → accepted | declined; accepted → done.
/// declined and done are terminal. Anything else is rejected before a write
/// is even attempted (the RTDB rules constrain writers; this constrains
/// transitions).
bool canTransition(RequestStatus from, RequestStatus to) => switch (from) {
      RequestStatus.pending =>
        to == RequestStatus.accepted || to == RequestStatus.declined,
      RequestStatus.accepted => to == RequestStatus.done,
      RequestStatus.declined || RequestStatus.done => false,
    };

class PresenceEntry {
  final String uid;
  final String name;
  final String role;
  final String wardId;
  final int lastSeen;

  const PresenceEntry({
    required this.uid,
    required this.name,
    required this.role,
    required this.wardId,
    required this.lastSeen,
  });

  factory PresenceEntry.fromMap(String uid, Map<Object?, Object?> m) =>
      PresenceEntry(
        uid: uid,
        name: (m['name'] ?? '').toString(),
        role: (m['role'] ?? '').toString(),
        wardId: (m['wardId'] ?? '').toString(),
        lastSeen: (m['lastSeen'] as num?)?.toInt() ?? 0,
      );
}

class RequestParty {
  final String uid;
  final String name;
  const RequestParty({required this.uid, required this.name});

  Map<String, Object?> toMap() => {'uid': uid, 'name': name};
  factory RequestParty.fromMap(Map<Object?, Object?> m) => RequestParty(
      uid: (m['uid'] ?? '').toString(), name: (m['name'] ?? '').toString());
}

class ShiftRequest {
  final String id;
  final String wardId;
  final RequestParty from;
  final RequestParty to;
  final RequestKind kind;
  final String? bed;
  final String? note;
  final int createdAt;
  final RequestStatus status;
  final int? respondedAt;

  const ShiftRequest({
    required this.id,
    required this.wardId,
    required this.from,
    required this.to,
    required this.kind,
    required this.bed,
    required this.note,
    required this.createdAt,
    required this.status,
    required this.respondedAt,
  });

  factory ShiftRequest.fromMap(
          String id, String wardId, Map<Object?, Object?> m) =>
      ShiftRequest(
        id: id,
        wardId: wardId,
        from: RequestParty.fromMap(
            (m['from'] as Map<Object?, Object?>?) ?? const {}),
        to: RequestParty.fromMap(
            (m['to'] as Map<Object?, Object?>?) ?? const {}),
        kind: RequestKindWire.parse((m['kind'] ?? '').toString()) ??
            RequestKind.supplies,
        bed: m['bed']?.toString(),
        note: m['note']?.toString(),
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        status: RequestStatusWire.parse((m['status'] ?? 'pending').toString()),
        respondedAt: (m['respondedAt'] as num?)?.toInt(),
      );
}

/// The exact creation payload the rules validate: from/to/kind/createdAt/
/// status required; bed and note optional and short. [serverTimestamp] is
/// injected by the backend ({'.sv': 'timestamp'} live, a plain int in fakes).
Map<String, Object?> buildRequestPayload({
  required RequestParty from,
  required RequestParty to,
  required RequestKind kind,
  String? bed,
  String? note,
  required Object serverTimestamp,
}) {
  final trimmedNote = note?.trim();
  return {
    'from': from.toMap(),
    'to': to.toMap(),
    'kind': kind.wire,
    if (bed != null && bed.trim().isNotEmpty) 'bed': bed.trim(),
    if (trimmedNote != null && trimmedNote.isNotEmpty)
      // Operational note only — kept short by construction.
      'note': trimmedNote.length > 80
          ? trimmedNote.substring(0, 80)
          : trimmedNote,
    'createdAt': serverTimestamp,
    'status': RequestStatus.pending.wire,
  };
}

/// The presence payload the rules validate (name/role/wardId/lastSeen).
Map<String, Object?> buildPresencePayload({
  required String name,
  required String role,
  required String wardId,
  required Object serverTimestamp,
}) =>
    {
      'name': name,
      'role': role,
      'wardId': wardId,
      'lastSeen': serverTimestamp,
      'state': 'online',
    };
