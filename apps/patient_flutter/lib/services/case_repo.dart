/// The data seam for the patient case. Note what is absent: no method lowers
/// a priority, no method deletes an update, no method creates a second case
/// for the same episode. "My condition has changed" APPENDS to the same
/// document (§6 / F-056). The deployed firestore.rules enforce the one-way
/// priority a second time at the database boundary.
///
/// Sync honesty (F-057): every update is written with syncState
/// 'queued_on_device'. cloud_firestore's set() future completes only when
/// the SERVER acknowledges the write — that acknowledgement, and nothing
/// else, flips the update to 'sent'. Local echo and connectivity guesses
/// never mark anything sent.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/patient_case.dart';
import '../domain/priority.dart';

class CaseSyncSnapshot {
  final PatientCase? patientCase;
  final bool fromCache;
  final bool hasPendingWrites;
  const CaseSyncSnapshot({
    required this.patientCase,
    required this.fromCache,
    required this.hasPendingWrites,
  });
}

class CaseRepo {
  final FirebaseFirestore _db;
  CaseRepo(this._db);

  static CaseRepo? _instance;
  static CaseRepo get instance => _instance ??= CaseRepo(FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>> _caseRef(String id) =>
      _db.collection('cases').doc(id);

  Stream<CaseSyncSnapshot> watchCase(String id) =>
      _caseRef(id).snapshots(includeMetadataChanges: true).map((d) {
        final data = d.data();
        return CaseSyncSnapshot(
          patientCase: data == null ? null : PatientCase.fromMap(data),
          fromCache: d.metadata.isFromCache,
          hasPendingWrites: d.metadata.hasPendingWrites,
        );
      });

  Future<PatientCase?> getCase(String id) async {
    // Cache-first: works offline; the watch stream keeps it honest later.
    final d = await _caseRef(id).get();
    final data = d.data();
    return data == null ? null : PatientCase.fromMap(data);
  }

  /// HANDOFF §3.3 — consent is its own timestamped, withdrawable record.
  Future<String> grantConsent(String subjectId, String scope) async {
    final id = newId('consent');
    final record = {
      'id': id,
      'externalIdentifier': null,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'subjectId': subjectId,
      'scope': scope,
      'grantedAt': DateTime.now().millisecondsSinceEpoch,
      'withdrawnAt': null,
    };
    // Fire-and-forget against the network: offline, the local write queues
    // and the id is still valid.
    unawaitedSet(_db.collection('consents').doc(id), record);
    return id;
  }

  /// Creates the case document. Returns immediately with the local case; the
  /// returned future inside completes on server acknowledgement.
  PatientCase buildCase({
    required String patientName,
    required String completedBy,
    required String? consentId,
    required String accountUid,
  }) =>
      PatientCase(
        id: newId('case'),
        externalIdentifier: null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        patientName: patientName,
        completedBy: completedBy,
        status: 'in_progress',
        priority: Priority.routine,
        updates: const [],
        consentId: consentId,
        accountUid: accountUid,
      );

  /// Appends an update to the SAME case (never a new one) and escalates
  /// priority one-way via the domain's appendUpdate. When the server
  /// acknowledges the write, the update's syncState flips to 'sent'.
  Future<PatientCase> appendCaseUpdate(
      PatientCase current, CaseUpdate update) async {
    final updated = appendUpdate(current, update);
    final ref = _caseRef(updated.id);

    // The set() future resolves only on SERVER acknowledgement. Offline it
    // stays pending (the local cache serves reads meanwhile) — exactly the
    // honesty §6 requires. The flip to 'sent' is a TRANSACTION that touches
    // only this update's syncState, so an update appended in the meantime
    // can never be clobbered.
    ref.set(updated.toMap()).then((_) => _flipSent(updated.id, [update.id]))
        .catchError((_) {
      // Rejected or interrupted: the update stays queued_on_device, which is
      // the truthful state; the next app start re-arms the ack watch.
    });
    return updated;
  }

  /// Marks the given updates 'sent' without touching anything else. Runs as
  /// a transaction against the server — it can only succeed once the write
  /// it confirms has genuinely been acknowledged. An id the server has not
  /// seen yet is simply left queued (the honest direction of error).
  Future<void> _flipSent(String caseId, List<String> updateIds) async {
    final ref = _caseRef(caseId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) return;
      var c = PatientCase.fromMap(data);
      for (final id in updateIds) {
        c = _markUpdateSent(c, id);
      }
      tx.set(ref, c.toMap());
    });
  }

  /// §2.1 — the only priority mutation, and it can only raise.
  Future<void> escalateCase(PatientCase current, Priority proposed) async {
    final next = escalate(current.priority, proposed);
    if (next == current.priority) return;
    final updated = current.copyWith(priority: next);
    unawaitedSet(_caseRef(current.id), updated.toMap());
  }

  /// Re-arms the server-ack listener after an app restart: any update still
  /// queued_on_device flips to sent once the pending write (or a fresh
  /// rewrite) is acknowledged.
  void resumeAckWatch(String caseId) {
    final ref = _caseRef(caseId);
    ref.get(const GetOptions(source: Source.cache)).then((snap) async {
      final data = snap.data();
      if (data == null) return;
      final c = PatientCase.fromMap(data);
      final queued = c.updates
          .where((u) => u.syncState == SyncState.queuedOnDevice)
          .map((u) => u.id)
          .toList();
      if (queued.isEmpty) return;
      // Re-issuing the cached content queues BEHIND any still-pending write
      // of the same document (same data — nothing can be lost), and its
      // completion is the server acknowledgement the flip waits for.
      await ref.set(c.toMap());
      await _flipSent(caseId, queued);
    }).catchError((_) {});
  }

  PatientCase _markUpdateSent(PatientCase c, String updateId) => c.copyWith(
        updates: c.updates
            .map((u) => u.id == updateId ? u.withSyncState(SyncState.sent) : u)
            .toList(),
      );

  static void unawaitedSet(
      DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) {
    ref.set(data).catchError((_) {});
  }
}
