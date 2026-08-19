/// تقاريري — the history: every case this account sent, newest first.
/// Date, honest status, updates count. Tap → the report detail. The empty
/// state explains where to start (D-015).
///
/// No priority, no risk language anywhere — a patient never sees a clinical
/// number or urgency level (§11).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/patient_case.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'report_detail_screen.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  /// Equality filter only — sorted client-side so no composite index is
  /// needed. A patient's own case list is small.
  static Stream<List<PatientCase>> _watchMyCases() {
    try {
      final uid = PatientAuthService.instance.currentUser?.uid;
      if (uid == null) return Stream.value(const []);
      return FirebaseFirestore.instance
          .collection('cases')
          .where('accountUid', isEqualTo: uid)
          .snapshots(includeMetadataChanges: true)
          .map((s) {
        final cases =
            s.docs.map((d) => PatientCase.fromMap(d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return cases;
      });
    } catch (_) {
      return Stream.value(const []);
    }
  }

  String _dateOf(BuildContext context, int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final l = MaterialLocalizations.of(context);
    return '${l.formatShortDate(d)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StreamBuilder<List<PatientCase>>(
      stream: _watchMyCases(),
      builder: (context, snapshot) {
        final cases = snapshot.data;
        if (cases == null) {
          return StepPage(children: [
            PageTitle(t.tabReports),
            const SizedBox(height: 20),
            Center(child: BodyText(t.loading)),
          ]);
        }
        if (cases.isEmpty) {
          return StepPage(children: [
            PageTitle(t.tabReports),
            const SizedBox(height: 12),
            Center(
              child: Icon(LucideIcons.clipboardList,
                  size: 48, color: PatientColors.inkFaint),
            ),
            const SizedBox(height: 12),
            Center(
                child: Text(t.reportsEmptyTitle,
                    textAlign: TextAlign.center,
                    style: sans(context, 21, weight: FontWeight.w600))),
            const SizedBox(height: 6),
            Center(
                child: Text(t.reportsEmptyBody,
                    textAlign: TextAlign.center,
                    style: sans(context, 18,
                        color: PatientColors.inkDim, height: 1.5))),
          ]);
        }
        return StepPage(children: [
          PageTitle(t.tabReports),
          for (final c in cases)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                button: true,
                label: '${t.detailTitle} ${shortRef(c.id)}',
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              ReportDetailScreen(caseId: c.id))),
                  borderRadius:
                      BorderRadius.circular(PatientDimens.radius),
                  child: Container(
                    constraints: const BoxConstraints(
                        minHeight: PatientDimens.touch),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PatientColors.surface,
                      border: Border.all(
                          color: PatientColors.border, width: 1.5),
                      borderRadius:
                          BorderRadius.circular(PatientDimens.radius),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_dateOf(context, c.createdAt),
                                style: sans(context, 17,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(
                              c.updates.isNotEmpty &&
                                      c.updates.every((u) =>
                                          u.syncState == SyncState.sent)
                                  ? t.syncSentShort
                                  : t.syncQueuedShort,
                              style: sans(
                                context,
                                16,
                                weight: FontWeight.w600,
                                color: c.updates.isNotEmpty &&
                                        c.updates.every((u) =>
                                            u.syncState == SyncState.sent)
                                    ? PatientColors.ok
                                    : PatientColors.warn,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(t.reportRowUpdates(c.updates.length),
                                style: sans(context, 16,
                                    color: PatientColors.inkDim)),
                          ],
                        ),
                      ),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? LucideIcons.chevronLeft
                            : LucideIcons.chevronRight,
                        size: 22,
                        color: PatientColors.inkFaint,
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
