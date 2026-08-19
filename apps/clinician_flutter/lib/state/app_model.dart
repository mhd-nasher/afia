/// Live app state after sign-in: the signed-in practitioner and the ward's
/// synced collections. A single ChangeNotifier fed by Firestore streams —
/// screens rebuild via ListenableBuilder. Constraint enforcement stays in
/// the domain layer; this class only carries data.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities.dart';
import '../domain/formulary.dart';
import '../domain/gaps.dart';
import '../domain/handover.dart';
import '../services/export_engine.dart';
import '../services/repo.dart';

class AppModel extends ChangeNotifier {
  static AppModel? instance;

  final Practitioner me;
  final Repo repo;

  List<Ward> wards = [];
  List<Patient> patients = [];
  List<Handover> handovers = [];
  List<FormularyEntry> formulary = [];
  TemplateVersionData? templateVersion;
  SyncStatus syncStatus = const SyncStatus(fromCache: true, hasPendingWrites: false);

  /// Received-handover ids the user opened this session (read state).
  final Set<String> readHandoverIds = {};

  final List<StreamSubscription> _subs = [];
  StreamSubscription? _patientSub;
  String? _wardId;

  AppModel({required this.me, Repo? repo}) : repo = repo ?? Repo.instance {
    _subs.add(this.repo.watchWards().listen((w) {
      wards = w;
      final wardId = w.isEmpty ? null : w.first.id;
      if (wardId != null && wardId != _wardId) {
        _wardId = wardId;
        _patientSub?.cancel();
        _patientSub = this.repo.watchPatients(wardId).listen((p) {
          patients = p;
          notifyListeners();
        });
      }
      notifyListeners();
    }));
    _subs.add(this.repo.watchHandovers().listen((h) {
      handovers = h;
      // Re-arm the server-acknowledgement wait for anything left queued
      // (e.g. app relaunched between signing and the server ack — A1.2).
      for (final ho in h.where((x) => x.status == HandoverStatus.queued)) {
        ExportEngine.instance.scheduleAck(ho);
      }
      notifyListeners();
    }));
    _subs.add(this.repo.watchFormulary().listen((f) {
      formulary = f;
      notifyListeners();
    }));
    _subs.add(this.repo.watchTemplate().listen((t) {
      templateVersion = t;
      notifyListeners();
    }));
    _subs.add(this.repo.watchSyncStatus().listen((s) {
      syncStatus = s;
      notifyListeners();
    }));
  }

  Ward? get ward => wards.isEmpty ? null : wards.first;

  List<TemplateField> get template => (templateVersion?.fields ?? const [])
      .map(TemplateField.fromMap)
      .toList();

  /// The latest (non-superseded) handover per patient.
  Handover? latestFor(String patientId) {
    Handover? latest;
    for (final h in handovers) {
      if (h.patientId != patientId) continue;
      if (h.supersededBy != null) continue;
      if (latest == null || h.createdAt > latest.createdAt) latest = h;
    }
    return latest;
  }

  /// Previous version chain / previous handover for diffing.
  Handover? previousFor(Handover current) {
    final versions = handovers
        .where((h) => h.patientId == current.patientId && h.id != current.id)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return versions.isEmpty ? null : versions.last;
  }

  /// An interrupted recording by me — reopen goes straight back to it (§5).
  Handover? get interruptedDraft {
    for (final h in handovers.reversed) {
      if (h.authorId == me.id && h.status == HandoverStatus.recording) return h;
    }
    return null;
  }

  /// Received tab: signed handovers authored by someone else.
  List<Handover> get incoming => handovers
      .where((h) =>
          h.signature != null &&
          h.authorId != me.id &&
          h.supersededBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Patient? patientById(String id) {
    for (final p in patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  void markRead(String handoverId) {
    if (readHandoverIds.add(handoverId)) notifyListeners();
  }

  void markChanged() => notifyListeners();

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _patientSub?.cancel();
    super.dispose();
  }
}
