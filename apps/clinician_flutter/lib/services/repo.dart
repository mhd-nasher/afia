/// The data seam. Every §2 constraint is enforced by the pure domain
/// functions this repository calls — never by UI. Note what is absent: no
/// method lowers a priority, dismisses a flag, deletes anything, edits a
/// signature identity, or confirms more than one chip per call. Firestore
/// security rules enforce the sharpest constraints a second time at the
/// database boundary.
///
/// Offline: cloud_firestore's local persistence is on by default on mobile —
/// the app stays fully usable from cache, and [syncStatus] tells the UI the
/// truth about what has actually reached the server.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/audit.dart';
import '../domain/draft.dart';
import '../domain/entities.dart';
import '../domain/formulary.dart';
import '../domain/gaps.dart';
import '../domain/handover.dart' as domain;

class SyncStatus {
  final bool fromCache;
  final bool hasPendingWrites;
  const SyncStatus({required this.fromCache, required this.hasPendingWrites});
}

class Repo {
  final FirebaseFirestore _db;
  Repo(this._db);

  static Repo? _instance;
  static Repo get instance => _instance ??= Repo(FirebaseFirestore.instance);

  // ── streams ──────────────────────────────────────────────────────────────

  Stream<List<Ward>> watchWards() => _db.collection('wards').snapshots().map(
      (s) => s.docs.map((d) => Ward.fromMap(d.data())).toList()
        ..sort((a, b) => a.id.compareTo(b.id)));

  Stream<List<Patient>> watchPatients(String wardId) => _db
      .collection('patients')
      .where('wardId', isEqualTo: wardId)
      .snapshots()
      .map((s) => s.docs.map((d) => Patient.fromMap(d.data())).toList()
        ..sort((a, b) => _bedOrder(a.bed).compareTo(_bedOrder(b.bed))));

  static int _bedOrder(String bed) {
    final n = int.tryParse(bed.replaceAll(RegExp(r'[^0-9]'), ''));
    return n ?? 0;
  }

  Stream<List<domain.Handover>> watchHandovers() => _db
      .collection('handovers')
      .snapshots(includeMetadataChanges: true)
      .map((s) =>
          s.docs.map((d) => domain.Handover.fromMap(d.data())).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  Stream<SyncStatus> watchSyncStatus() => _db
      .collection('handovers')
      .snapshots(includeMetadataChanges: true)
      .map((s) => SyncStatus(
            fromCache: s.metadata.isFromCache,
            hasPendingWrites: s.metadata.hasPendingWrites,
          ));

  Stream<List<FormularyEntry>> watchFormulary() =>
      _db.collection('formulary').snapshots().map((s) =>
          s.docs.map((d) => FormularyEntry.fromMap(d.data())).toList()
            ..sort((a, b) => a.name.compareTo(b.name)));

  /// Latest template version — field ids drive structuring and gap detection.
  Stream<TemplateVersionData?> watchTemplate() =>
      _db.collection('templateVersions').snapshots().map((s) {
        final versions =
            s.docs.map((d) => TemplateVersionData.fromMap(d.data())).toList()
              ..sort((a, b) => a.version.compareTo(b.version));
        return versions.isEmpty ? null : versions.last;
      });

  Stream<List<TemplateVersionData>> watchTemplateVersions() =>
      _db.collection('templateVersions').snapshots().map((s) =>
          s.docs.map((d) => TemplateVersionData.fromMap(d.data())).toList()
            ..sort((a, b) => a.version.compareTo(b.version)));

  Stream<Practitioner?> watchPractitioner(String uid) =>
      _db.collection('practitioners').doc(uid).snapshots().map(
          (d) => d.data() == null ? null : Practitioner.fromMap(d.data()!));

  Future<Practitioner?> getPractitioner(String uid) async {
    final d = await _db.collection('practitioners').doc(uid).get();
    return d.data() == null ? null : Practitioner.fromMap(d.data()!);
  }

  // ── audit (§3.4 — append-only; rules deny update/delete) ────────────────

  Future<void> appendAudit({
    required String actor,
    required String action,
    required String entityId,
    Object? previousValue,
    String? detail,
  }) async {
    assert(auditActions.contains(action), 'unknown audit action: $action');
    final event = AuditEvent(
      id: domain.newId('audit'),
      at: DateTime.now().millisecondsSinceEpoch,
      actor: actor,
      action: action,
      entityId: entityId,
      previousValue: previousValue,
      detail: detail,
    );
    // Offline-first: applied to the local cache instantly; the server ack
    // arrives whenever connectivity allows. Append-only either way (§3.4).
    unawaited(_db
        .collection('audit')
        .doc(event.id)
        .set(event.toMap())
        .catchError((Object e) => debugPrint('[afia] audit write: $e')));
  }

  // ── handover lifecycle ───────────────────────────────────────────────────

  Future<domain.Handover> createHandover(
      String patientId, String authorId) async {
    final h = domain.Handover(
      id: domain.newId('handover'),
      externalIdentifier: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      patientId: patientId,
      authorId: authorId,
      status: domain.HandoverStatus.recording,
      audio: null,
      transcript: '',
      fields: const [],
      chips: const [],
      flags: const [],
      signature: null,
      version: 1,
      supersedes: null,
      supersededBy: null,
      exportError: null,
      acknowledgedAt: null,
    );
    await _put(h);
    await appendAudit(actor: authorId, action: 'created', entityId: h.id);
    await appendAudit(
        actor: authorId,
        action: 'recorded',
        entityId: h.id,
        detail: 'recording started');
    return h;
  }

  /// Auto-checkpoint (§5): safe to call every few seconds. Chips are
  /// re-extracted deterministically (confirmations preserved for unchanged
  /// chips) and §2.8 gap detection re-runs on every save.
  Future<domain.Handover> checkpointDraft(
    domain.Handover h, {
    String? transcript,
    List<FieldContent>? fields,
    domain.AudioRecordingData? audio,
    required List<FormularyEntry> formulary,
    required List<TemplateField> template,
  }) async {
    final updated = recomputeDraft(
      h,
      transcript: transcript,
      fields: fields,
      audio: audio,
      formulary: formulary,
      template: template,
    );
    await _put(updated);
    return updated;
  }

  Future<domain.Handover> setStatus(
      domain.Handover h, domain.HandoverStatus to, String actor) async {
    final updated = domain.transition(h, to);
    await _put(updated);
    return updated;
  }

  /// §2.3 — one chip per call. No bulk variant exists anywhere in this app.
  Future<domain.Handover> confirmSingleChip(
    domain.Handover h,
    String chipId,
    Practitioner practitioner, {
    String? correctedTo,
  }) async {
    final previous =
        h.chips.where((c) => c.id == chipId).map((c) => c.text).firstOrNull;
    final updated =
        domain.confirmChip(h, chipId, practitioner, correctedTo: correctedTo);
    await _put(updated);
    await appendAudit(
      actor: practitioner.id,
      action: correctedTo != null ? 'corrected' : 'chip_confirmed',
      entityId: h.id,
      previousValue: previous,
      detail: correctedTo != null
          ? 'corrected to $correctedTo'
          : 'confirmed chip $chipId',
    );
    return updated;
  }

  /// Sign and immediately queue for export (§5 — export fires automatically
  /// on signature; there is no manual export button anywhere).
  Future<domain.Handover> signAndQueue(
    domain.Handover h,
    Practitioner practitioner, {
    String? openFlagReason,
  }) async {
    final signed =
        domain.sign(h, practitioner, openFlagReason: openFlagReason);
    final queued = domain.transition(signed, domain.HandoverStatus.queued);
    await _put(queued);
    await appendAudit(
      actor: practitioner.id,
      action: 'signed',
      entityId: h.id,
      detail: 'v${h.version} signed as ${practitioner.signatureIdentity}',
    );
    await appendAudit(
      actor: practitioner.id,
      action: 'exported',
      entityId: h.id,
      detail: 'export queued automatically on signature',
    );
    return queued;
  }

  /// §5 + A1.2 — confirmed_in_system ("Recorded in Afia") requires POSITIVE
  /// acknowledgement: the Firestore server has persisted the signed record.
  /// The state machine still refuses this transition from anywhere but
  /// queued, and local send-completion can never trigger it.
  Future<domain.Handover> acknowledgeExport(domain.Handover h,
      {required bool ok, String? error}) async {
    final domain.Handover updated;
    if (ok) {
      updated = domain
          .transition(h, domain.HandoverStatus.confirmedInSystem)
          .copyWith(
              acknowledgedAt: DateTime.now().millisecondsSinceEpoch,
              clearExportError: true);
    } else {
      updated = domain
          .transition(h, domain.HandoverStatus.exportFailed)
          .copyWith(exportError: error ?? 'No acknowledgement received.');
    }
    await _put(updated);
    await appendAudit(
      actor: 'system',
      action: ok ? 'confirmed' : 'export_failed',
      entityId: h.id,
      previousValue: h.status.wire,
      detail: ok ? 'positive acknowledgement received' : (error ?? ''),
    );
    return updated;
  }

  Future<domain.Handover> retryExport(domain.Handover h, String actor) async {
    final updated = domain.transition(h, domain.HandoverStatus.queued);
    await _put(updated);
    await appendAudit(
      actor: actor,
      action: 'exported',
      entityId: h.id,
      previousValue: 'export_failed',
      detail: 'export retried',
    );
    return updated;
  }

  /// §2.5 — post-signature edit: both versions and both signatures persist.
  /// The original document is only ever touched to set supersededBy; its
  /// signature bytes are unchanged (the rules verify this).
  Future<domain.SupersedeResult> supersedeHandover(
      domain.Handover h, String actor) async {
    final result = domain.supersede(h);
    await _put(result.original);
    await _put(result.draft);
    await appendAudit(
      actor: actor,
      action: 'superseded',
      entityId: h.id,
      detail: 'superseded by ${result.draft.id} (v${result.draft.version})',
    );
    return result;
  }

  /// Offline-first (§5): cloud_firestore applies the write to the local
  /// cache immediately, but the returned future resolves only on SERVER
  /// acknowledgement — awaiting it would freeze every flow while offline.
  /// UI paths therefore fire-and-forget; [awaitServerPersistence] is the one
  /// place that honestly waits for the server (HANDOFF A1.2).
  Future<void> _put(domain.Handover h) async {
    unawaited(_db
        .collection('handovers')
        .doc(h.id)
        .set(h.toMap())
        .catchError((Object e) => debugPrint('[afia] handover write: $e')));
  }

  /// HANDOFF A1.2 — the REAL export acknowledgement: resolves only when a
  /// snapshot of this handover arrives FROM THE SERVER with no pending
  /// writes (not cache, not a timer). Offline, this simply keeps waiting —
  /// the handover stays honestly queued until the server truly has it.
  Future<domain.Handover> awaitServerPersistence(String handoverId) async {
    final snap = await _db
        .collection('handovers')
        .doc(handoverId)
        .snapshots(includeMetadataChanges: true)
        .firstWhere((s) =>
            s.exists &&
            !s.metadata.hasPendingWrites &&
            !s.metadata.isFromCache);
    return domain.Handover.fromMap(snap.data()!);
  }

  // ── account ──────────────────────────────────────────────────────────────

  Future<void> recordSignEvent(
      String practitionerId, String kind, String device) async {
    final id = domain.newId('signin');
    unawaited(_db.collection('signInLog').doc(id).set({
      'id': id,
      'practitionerId': practitionerId,
      'at': DateTime.now().millisecondsSinceEpoch,
      'kind': kind,
      'device': device,
    }).catchError((Object e) => debugPrint('[afia] signInLog write: $e')));
    await appendAudit(
        actor: practitionerId,
        action: kind,
        entityId: practitionerId,
        detail: device);
  }

  /// §2.9 — wellbeing is aggregate and anonymous only: an unattributed score
  /// appended to the ward's list. No per-person record exists. (Read-append-
  /// write rather than arrayUnion: equal scores must still count.)
  Future<void> addWellbeingScore(String wardId, int score) async {
    final ref = _db.collection('wellbeing').doc(wardId);
    final snap = await ref.get();
    final scores =
        ((snap.data()?['scores'] as List<dynamic>?) ?? const []).toList()
          ..add(score);
    await ref.set({'id': wardId, 'scores': scores});
  }
}
