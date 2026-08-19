/// D-013 — the shift-assistant tool layer, pure and unit-testable.
///
/// Every function here REORGANISES recorded facts: handover states, wait
/// times, completeness, counts. No function accepts or emits a severity,
/// urgency, priority, or risk value — the input types cannot carry one
/// (see CaseData), and ordering goes through the §2.10 queue comparator
/// (wait time, then completeness) exclusively.
library;

import '../../domain/case_data.dart';
import '../../domain/entities.dart';
import '../../domain/formulary.dart';
import '../../domain/handover.dart';
import '../../domain/queue.dart';

class _CaseQueueEntry extends QueueEntry {
  final CaseData data;
  _CaseQueueEntry(this.data)
      : super(
            id: data.id,
            receivedAt: data.createdAt,
            completeness: data.completeness);
}

/// Per-patient handover state + what still needs attention on it.
Map<String, Object?> shiftOverview({
  required List<Patient> patients,
  required List<Handover> handovers,
}) {
  Handover? latestFor(String patientId) {
    Handover? latest;
    for (final h in handovers) {
      if (h.patientId != patientId || h.supersededBy != null) continue;
      if (latest == null || h.createdAt > latest.createdAt) latest = h;
    }
    return latest;
  }

  final rows = <Map<String, Object?>>[];
  var signed = 0, recorded = 0, notStarted = 0;
  for (final p in patients) {
    final h = latestFor(p.id);
    final status = h?.status ?? HandoverStatus.notStarted;
    if (h?.signature != null) signed += 1;
    if (status == HandoverStatus.confirmedInSystem) recorded += 1;
    if (status == HandoverStatus.notStarted) notStarted += 1;
    rows.add({
      'patientId': p.id,
      'patient': p.shortName,
      'bed': p.bed,
      'state': status.wire,
      'unconfirmedChips': h == null ? 0 : unconfirmedChips(h).length,
      'openFlags': h == null ? 0 : openFlags(h).length,
    });
  }

  return {
    'totalPatients': patients.length,
    'signed': signed,
    'recordedInAfia': recorded,
    'notStarted': notStarted,
    'patients': rows,
  };
}

/// Incoming patient-app cases — ordered by the §2.10 comparator ONLY.
/// filter: 'today' | 'all' | 'unreviewed'. There is no per-case reviewed
/// marker in the schema; 'unreviewed' returns submitted cases and says so.
Map<String, Object?> incomingCases({
  required List<CaseData> cases,
  required String filter,
  required int nowMs,
}) {
  final startOfDay = DateTime.fromMillisecondsSinceEpoch(nowMs);
  final dayStartMs =
      DateTime(startOfDay.year, startOfDay.month, startOfDay.day)
          .millisecondsSinceEpoch;

  Iterable<CaseData> selected = cases.where((c) => c.status == 'submitted');
  String? note;
  switch (filter) {
    case 'today':
      selected = selected.where((c) => c.createdAt >= dayStartMs);
    case 'unreviewed':
      note = 'Per-case review is not tracked in the schema; this lists all '
          'submitted cases.';
    default: // 'all'
      break;
  }

  final ordered = orderQueue(selected.map(_CaseQueueEntry.new).toList());

  return {
    'count': ordered.length,
    'sortStatement': queueSortStatement,
    if (note != null) 'note': note,
    'cases': [
      for (final entry in ordered)
        {
          'patientName': entry.data.patientName,
          'receivedAt': entry.data.createdAt,
          'waitMinutes': ((nowMs - entry.data.createdAt) / 60000).round(),
          'completeness':
              double.parse(entry.data.completeness.toStringAsFixed(2)),
          'updates': entry.data.updates.length,
          'conditionChangedUpdates': entry.data.conditionChangedCount,
        }
    ],
  };
}

/// The shift checklist, derived from facts only. Order within each bucket is
/// bed order / wait order — never a clinical judgement.
Map<String, Object?> whatsLeft({
  required List<Patient> patients,
  required List<Handover> handovers,
  required List<CaseData> cases,
  required int nowMs,
}) {
  Handover? latestFor(String patientId) {
    Handover? latest;
    for (final h in handovers) {
      if (h.patientId != patientId || h.supersededBy != null) continue;
      if (latest == null || h.createdAt > latest.createdAt) latest = h;
    }
    return latest;
  }

  final noSignedHandover = <Map<String, Object?>>[];
  final draftsWithChips = <Map<String, Object?>>[];
  final exportFailures = <Map<String, Object?>>[];

  for (final p in patients) {
    final h = latestFor(p.id);
    if (h?.signature == null) {
      noSignedHandover.add({
        'patientId': p.id,
        'patient': p.shortName,
        'bed': p.bed,
        'state': (h?.status ?? HandoverStatus.notStarted).wire,
      });
    }
    if (h != null && h.status == HandoverStatus.draftReady) {
      final unconfirmed = unconfirmedChips(h).length;
      if (unconfirmed > 0) {
        draftsWithChips.add({
          'patientId': p.id,
          'patient': p.shortName,
          'bed': p.bed,
          'unconfirmedChips': unconfirmed,
        });
      }
    }
    if (h != null && h.status == HandoverStatus.exportFailed) {
      exportFailures.add({
        'patientId': p.id,
        'patient': p.shortName,
        'bed': p.bed,
        'error': h.exportError,
      });
    }
  }

  final incoming = incomingCases(cases: cases, filter: 'all', nowMs: nowMs);

  return {
    'patientsWithoutSignedHandover': noSignedHandover,
    'draftsWithUnconfirmedChips': draftsWithChips,
    'exportFailuresNeedingRetry': exportFailures,
    'incomingSubmittedCases': incoming['count'],
    'incomingSortStatement': queueSortStatement,
  };
}

Map<String, Object?> wardInfo({
  required Ward? ward,
  required List<Patient> patients,
}) {
  if (ward == null) return {'error': 'no ward configured'};
  return {
    'ward': ward.name,
    'committedReviewMinutes': ward.committedReviewMinutes,
    'reviewOwner': ward.reviewOwner,
    'patients': [
      for (final p in patients)
        {'bed': p.bed, 'patient': p.shortName, 'patientId': p.id}
    ],
  };
}

Map<String, Object?> formularyLookup({
  required String term,
  required List<FormularyEntry> formulary,
}) {
  final match = matchDrug(term, formulary);
  final clusters = searchFormulary(term, formulary);
  return {
    'term': term,
    'confidence': match.confidence.name,
    'bestMatch': match.entryName,
    'soundAlikesShownTogether': [
      for (final cluster in clusters.take(3))
        cluster.map((e) => e.name).toList()
    ],
  };
}
