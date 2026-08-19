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
import '../domain/teamwork.dart';
import '../domain/ward_order.dart';
import '../services/assistant/memory_service.dart';
import '../services/export_engine.dart';
import '../services/prefs.dart';
import '../services/repo.dart';
import '../services/teamwork/teamwork_service.dart';

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

  // ── D-014 teamwork state ──────────────────────────────────────────────
  final TeamworkService teamwork;
  List<PresenceEntry> presence = [];
  List<ShiftRequest> requests = [];
  WardOrder wardOrder = WardOrder.defaultOrder;

  final List<StreamSubscription> _subs = [];
  StreamSubscription? _patientSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _requestsSub;
  String? _wardId;
  bool _presenceStarted = false;

  AppModel({required this.me, Repo? repo, TeamworkService? teamwork})
      : repo = repo ?? Repo.instance,
        teamwork = teamwork ?? TeamworkService(RtdbBackend()) {
    wardOrder = WardOrder.deserialize(Prefs.instance.wardOrder);
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
        _startTeamwork(wardId);
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

  /// D-014 — go online for presence and follow the ward's request stream.
  /// Failures are silent (instance not created yet / offline): the app works
  /// fully without the teamwork layer.
  void _startTeamwork(String wardId) {
    if (_presenceStarted) return;
    _presenceStarted = true;
    teamwork
        .goOnline(
            uid: me.id, name: me.name, role: me.role.wire, wardId: wardId)
        .catchError((_) {});
    _presenceSub = teamwork.wardPresence(wardId).listen((p) {
      presence = p;
      notifyListeners();
    }, onError: (_) {});
    _requestsSub = teamwork.wardRequests(wardId).listen((r) {
      requests = r;
      notifyListeners();
    }, onError: (_) {});
  }

  /// Colleagues present now (me excluded — I don't request from myself).
  List<PresenceEntry> get colleaguesPresent =>
      presence.where((p) => p.uid != me.id).toList();

  /// Incoming requests awaiting my response — the Received-tab badge.
  int get pendingRequestCount => requests
      .where((r) => r.to.uid == me.id && r.status == RequestStatus.pending)
      .length;

  /// Requests involving me: incoming pending first, then everything else,
  /// each group newest first (never any computed judgement).
  List<ShiftRequest> get myRequests {
    final mine = requests
        .where((r) => r.to.uid == me.id || r.from.uid == me.id)
        .toList();
    final incomingPending = mine
        .where((r) => r.to.uid == me.id && r.status == RequestStatus.pending)
        .toList();
    final rest = mine
        .where(
            (r) => !(r.to.uid == me.id && r.status == RequestStatus.pending))
        .toList();
    return [...incomingPending, ...rest];
  }

  /// D-014 feature 1 — the nurse's own ordering, applied deterministically.
  List<Patient> get orderedPatients =>
      applyWardOrder(wardOrder, patients, latestFor);

  Future<void> setWardOrder(WardOrder order) async {
    wardOrder = order;
    notifyListeners();
    await Prefs.instance.setWardOrder(order.serialize());
    try {
      // Account copy — owner-only per rules; survives device changes.
      await MemoryService.instance
          .setPreference(me.id, 'wardOrder', order.serialize());
    } catch (_) {}
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
    _presenceSub?.cancel();
    _requestsSub?.cancel();
    teamwork.goOffline();
    super.dispose();
  }
}
