/// Screen 11 — Shift complete. The one warm screen. No patient data, no
/// elapsed time. Appears once per shift. The optional mood chips feed the
/// anonymous, aggregate-only wellbeing store (§2.9).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/handover.dart';
import '../../services/repo.dart';
import '../../state/app_model.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class ShiftCompleteScreen extends StatefulWidget {
  const ShiftCompleteScreen({super.key});

  @override
  State<ShiftCompleteScreen> createState() => _ShiftCompleteScreenState();
}

class _ShiftCompleteScreenState extends State<ShiftCompleteScreen> {
  String? _mood;

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    final t = l10n(context);
    final handed = model.patients
        .where((p) => model.latestFor(p.id)?.signature != null)
        .length;
    final itemsConfirmed = model.handovers
        .where((h) => h.authorId == model.me.id)
        .fold<int>(0, (sum, h) => sum + h.chips.where((c) => c.confirmed).length);
    final unsent = model.patients
        .where((p) =>
            model.latestFor(p.id) != null &&
            model.latestFor(p.id)!.signature != null &&
            model.latestFor(p.id)!.status != HandoverStatus.confirmedInSystem)
        .length;

    final moods = [
      (t.moodSteady, 3),
      (t.moodHeavy, 1),
      (t.moodShortStaffed, 2),
      (t.moodGoodShift, 4),
    ];

    TextStyle warmSans(double size, {FontWeight w = FontWeight.w400, Color? color}) =>
        TextStyle(
            fontSize: size,
            fontWeight: w,
            color: color ?? AfiaColors.warmText,
            height: 1.3);

    return Scaffold(
      backgroundColor: AfiaColors.warmBg,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.sunrise,
                      size: 72, color: AfiaColors.warmAccent),
                  const SizedBox(height: 28),
                  Text(t.shiftCompleteTitle('$handed'),
                      textAlign: TextAlign.center,
                      style: warmSans(26, w: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Text(t.shiftCompleteBody,
                      textAlign: TextAlign.center,
                      style: warmSans(14, color: AfiaColors.warmTextDim)),
                  const SizedBox(height: 30),
                  Container(
                    decoration: const BoxDecoration(
                      color: AfiaColors.warmRaised,
                      border: Border(
                        top: BorderSide(color: AfiaColors.warmBorder),
                        bottom: BorderSide(color: AfiaColors.warmBorder),
                      ),
                    ),
                    child: Row(children: [
                      _stat('$handed', t.handedOverStat, warmSans),
                      Container(
                          width: 1,
                          height: 64,
                          color: AfiaColors.warmBorder),
                      _stat('$itemsConfirmed', t.itemsConfirmedStat, warmSans),
                      Container(
                          width: 1,
                          height: 64,
                          color: AfiaColors.warmBorder),
                      _stat('$unsent', t.leftUnsentStat, warmSans),
                    ]),
                  ),
                  const SizedBox(height: 30),
                  Text(t.howWasIt,
                      style: warmSans(13, color: AfiaColors.warmTextDim)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (label, score) in moods)
                        InkWell(
                          onTap: () {
                            setState(() => _mood = label);
                            final wardId = model.ward?.id;
                            if (wardId != null) {
                              // Anonymous aggregate only (§2.9).
                              Repo.instance.addWellbeingScore(wardId, score);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: _mood == label
                                      ? AfiaColors.warmAccent
                                      : AfiaColors.warmBorder),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label,
                                style: warmSans(14,
                                    color: _mood == label
                                        ? AfiaColors.warmAccent
                                        : AfiaColors.warmText)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 28),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 64,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AfiaColors.warmAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t.goRest,
                    style: warmSans(18,
                        w: FontWeight.w500, color: AfiaColors.warmBg)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String value, String label,
      TextStyle Function(double, {FontWeight w, Color? color}) warmSans) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(value, style: warmSans(22, w: FontWeight.w500)),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: warmSans(11, color: AfiaColors.warmTextDim)),
        ]),
      ),
    );
  }
}
