/// D-014 — presence + preset requests over Firebase Realtime Database
/// (europe-west1; OPERATIONAL data only — clinical records stay in
/// Firestore me-central2). The backend is abstracted so the whole layer is
/// unit-testable with an in-memory fake.
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../domain/teamwork.dart';

/// The owner-chosen RTDB instance (being created in the console; rules at
/// /database.rules.json deploy the moment it exists).
const String rtdbUrl =
    'https://afia-12f38-default-rtdb.europe-west1.firebasedatabase.app';

/// The seam. Everything the teamwork layer needs from RTDB, fake-able.
abstract class TeamworkBackend {
  Future<void> setPresence(String uid, Map<String, Object?> payload);
  Future<void> heartbeat(String uid, Object serverTimestamp);
  Future<void> removePresence(String uid);
  Stream<List<PresenceEntry>> presenceStream();
  Future<String> pushRequest(String wardId, Map<String, Object?> payload);
  Future<void> updateRequestStatus(
      String wardId, String requestId, RequestStatus status, Object respondedAt);
  Stream<List<ShiftRequest>> requestsStream(String wardId);
  Object get serverTimestamp;
}

class RtdbBackend implements TeamworkBackend {
  final FirebaseDatabase _db;

  RtdbBackend({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instanceFor(
            app: Firebase.app(), databaseURL: rtdbUrl);

  @override
  Object get serverTimestamp => ServerValue.timestamp;

  DatabaseReference _presence(String uid) => _db.ref('presence/$uid');

  @override
  Future<void> setPresence(String uid, Map<String, Object?> payload) async {
    final ref = _presence(uid);
    // Presence is truthful: the server removes the node when the connection
    // drops, whatever the app was doing at the time.
    await ref.onDisconnect().remove();
    await ref.set(payload);
  }

  @override
  Future<void> heartbeat(String uid, Object serverTimestamp) =>
      _presence(uid).update({'lastSeen': serverTimestamp});

  @override
  Future<void> removePresence(String uid) => _presence(uid).remove();

  @override
  Stream<List<PresenceEntry>> presenceStream() =>
      _db.ref('presence').onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return const <PresenceEntry>[];
        return [
          for (final entry in value.entries)
            if (entry.value is Map)
              PresenceEntry.fromMap(entry.key.toString(),
                  (entry.value as Map).cast<Object?, Object?>()),
        ];
      });

  @override
  Future<String> pushRequest(
      String wardId, Map<String, Object?> payload) async {
    final ref = _db.ref('requests/$wardId').push();
    await ref.set(payload);
    return ref.key!;
  }

  @override
  Future<void> updateRequestStatus(String wardId, String requestId,
          RequestStatus status, Object respondedAt) =>
      _db.ref('requests/$wardId/$requestId').update({
        'status': status.wire,
        'respondedAt': respondedAt,
      });

  @override
  Stream<List<ShiftRequest>> requestsStream(String wardId) =>
      _db.ref('requests/$wardId').onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return const <ShiftRequest>[];
        return [
          for (final entry in value.entries)
            if (entry.value is Map)
              ShiftRequest.fromMap(entry.key.toString(), wardId,
                  (entry.value as Map).cast<Object?, Object?>()),
        ];
      });
}

class TeamworkService {
  final TeamworkBackend backend;
  TeamworkService(this.backend);

  Timer? _heartbeat;
  String? _presenceUid;

  /// Go online: write my presence node (rules: only my own), arm the
  /// server-side disconnect cleanup, heartbeat lastSeen every ~60 s.
  Future<void> goOnline({
    required String uid,
    required String name,
    required String role,
    required String wardId,
  }) async {
    _presenceUid = uid;
    await backend.setPresence(
        uid,
        buildPresencePayload(
            name: name,
            role: role,
            wardId: wardId,
            serverTimestamp: backend.serverTimestamp));
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) {
      backend.heartbeat(uid, backend.serverTimestamp).catchError((_) {});
    });
  }

  void pauseHeartbeat() => _heartbeat?.cancel();

  void resumeHeartbeat() {
    final uid = _presenceUid;
    if (uid == null) return;
    _heartbeat?.cancel();
    backend.heartbeat(uid, backend.serverTimestamp).catchError((_) {});
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) {
      backend.heartbeat(uid, backend.serverTimestamp).catchError((_) {});
    });
  }

  Future<void> goOffline() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    final uid = _presenceUid;
    _presenceUid = null;
    if (uid != null) {
      try {
        await backend.removePresence(uid);
      } catch (_) {
        // The armed onDisconnect cleans up server-side regardless.
      }
    }
  }

  /// Colleagues present in MY ward, newest heartbeat first. Only people with
  /// a live presence node — never a staff directory.
  Stream<List<PresenceEntry>> wardPresence(String wardId) =>
      backend.presenceStream().map((all) {
        final ward = all.where((p) => p.wardId == wardId).toList()
          ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        return ward;
      });

  Future<String> sendRequest({
    required RequestParty from,
    required RequestParty to,
    required String wardId,
    required RequestKind kind,
    String? bed,
    String? note,
  }) =>
      backend.pushRequest(
          wardId,
          buildRequestPayload(
              from: from,
              to: to,
              kind: kind,
              bed: bed,
              note: note,
              serverTimestamp: backend.serverTimestamp));

  /// Status transitions are validated here (pending→accepted/declined,
  /// accepted→done); the RTDB rules constrain WHO may write.
  Future<void> respond(ShiftRequest request, RequestStatus to) async {
    if (!canTransition(request.status, to)) {
      throw StateError(
          'Illegal request transition: ${request.status.wire} → ${to.wire}');
    }
    await backend.updateRequestStatus(
        request.wardId, request.id, to, backend.serverTimestamp);
  }

  Stream<List<ShiftRequest>> wardRequests(String wardId) =>
      backend.requestsStream(wardId).map((list) {
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
      });
}
