/// §5 + HANDOFF A1.2 — export fires AUTOMATICALLY on signature; there is no
/// manual export button anywhere in this app. The system of record is Afia's
/// own backend: `confirmed_in_system` ("Recorded in Afia") is reached ONLY
/// on a real Firestore SERVER acknowledgement that the signed record is
/// persisted — never from cache, never from a timer, never from local
/// send-completion. Offline, a signed handover stays honestly queued until
/// the server truly has it. Failures surface as export_failed with the real
/// error and a retry on the shift board.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/handover.dart';
import 'repo.dart';

class ExportEngine {
  final Repo _repo;
  ExportEngine(this._repo);

  static ExportEngine? _instance;
  static ExportEngine get instance => _instance ??= ExportEngine(Repo.instance);

  final Set<String> _inFlight = {};

  /// Await the server's acknowledgement of the queued record, then — and
  /// only then — transition to confirmed_in_system with acknowledgedAt.
  void scheduleAck(Handover queued) {
    if (queued.status != HandoverStatus.queued) return;
    if (!_inFlight.add(queued.id)) return;
    () async {
      try {
        final onServer = await _repo.awaitServerPersistence(queued.id);
        if (onServer.status == HandoverStatus.queued) {
          await _repo.acknowledgeExport(onServer, ok: true);
        }
        // Any other status: another session already moved it — nothing to do.
      } on FirebaseException catch (e) {
        // A real failure (rules rejection, permission, data) — the honest
        // failed state, with the real error, and a retry path.
        try {
          await _repo.acknowledgeExport(queued,
              ok: false, error: e.message ?? e.code);
        } catch (_) {}
      } on IllegalTransitionError {
        // Raced with another device's transition — already resolved.
      } finally {
        _inFlight.remove(queued.id);
      }
    }();
  }

  Future<void> retry(Handover failed, String actor) async {
    final queued = await _repo.retryExport(failed, actor);
    scheduleAck(queued);
  }
}
