/// D-014 feature 1 — per-nurse ward-list ordering. Every mode is either a
/// FACTS order (bed, unsigned-first, unconfirmed-chips-first) or the nurse's
/// OWN manual order. §2.10 intact: no mode exists that ranks by clinical
/// risk, and none can be added without extending this enum.
library;

import 'dart:convert';

import 'entities.dart';
import 'handover.dart';

enum WardOrderMode { bed, unsignedFirst, unconfirmedChipsFirst, manual }

extension WardOrderModeWire on WardOrderMode {
  String get wire => switch (this) {
        WardOrderMode.bed => 'bed',
        WardOrderMode.unsignedFirst => 'unsigned_first',
        WardOrderMode.unconfirmedChipsFirst => 'unconfirmed_chips_first',
        WardOrderMode.manual => 'manual',
      };

  static WardOrderMode? parse(String wire) {
    for (final m in WardOrderMode.values) {
      if (m.wire == wire) return m;
    }
    return null;
  }
}

class WardOrder {
  final WardOrderMode mode;

  /// Only for [WardOrderMode.manual] — the nurse's own dictated order.
  final List<String> manualIds;

  const WardOrder({required this.mode, this.manualIds = const []});

  static const WardOrder defaultOrder = WardOrder(mode: WardOrderMode.bed);

  bool get isDefault => mode == WardOrderMode.bed;

  String serialize() =>
      jsonEncode({'mode': mode.wire, 'ids': manualIds});

  static WardOrder deserialize(String? raw) {
    if (raw == null || raw.isEmpty) return defaultOrder;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final mode = WardOrderModeWire.parse(m['mode'] as String? ?? 'bed') ??
          WardOrderMode.bed;
      return WardOrder(
        mode: mode,
        manualIds:
            (m['ids'] as List<dynamic>? ?? const []).cast<String>(),
      );
    } catch (_) {
      return defaultOrder;
    }
  }
}

int _bedOrder(String bed) =>
    int.tryParse(bed.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Deterministic application of the nurse's chosen order. Ties inside every
/// grouping fall back to bed order — never to any computed judgement.
List<Patient> applyWardOrder(
  WardOrder order,
  List<Patient> patients,
  Handover? Function(String patientId) latestFor,
) {
  final byBed = [...patients]
    ..sort((a, b) => _bedOrder(a.bed).compareTo(_bedOrder(b.bed)));

  switch (order.mode) {
    case WardOrderMode.bed:
      return byBed;

    case WardOrderMode.unsignedFirst:
      final unsigned = <Patient>[];
      final signed = <Patient>[];
      for (final p in byBed) {
        (latestFor(p.id)?.signature == null ? unsigned : signed).add(p);
      }
      return [...unsigned, ...signed];

    case WardOrderMode.unconfirmedChipsFirst:
      int chips(Patient p) {
        final h = latestFor(p.id);
        return h == null ? 0 : unconfirmedChips(h).length;
      }
      final withChips = byBed.where((p) => chips(p) > 0).toList()
        ..sort((a, b) {
          final byCount = chips(b).compareTo(chips(a));
          return byCount != 0
              ? byCount
              : _bedOrder(a.bed).compareTo(_bedOrder(b.bed));
        });
      final rest = byBed.where((p) => chips(p) == 0).toList();
      return [...withChips, ...rest];

    case WardOrderMode.manual:
      final index = <String, int>{
        for (var i = 0; i < order.manualIds.length; i++)
          order.manualIds[i]: i,
      };
      final listed = byBed.where((p) => index.containsKey(p.id)).toList()
        ..sort((a, b) => index[a.id]!.compareTo(index[b.id]!));
      final unlisted =
          byBed.where((p) => !index.containsKey(p.id)).toList();
      return [...listed, ...unlisted];
  }
}
