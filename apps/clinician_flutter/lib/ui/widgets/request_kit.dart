/// D-014 — shared presentation for the preset request kinds: bilingual
/// labels (l10n) + lucide icons, and the status label/color mapping. One
/// place, used by the sheet, the requests list, and the assistant card.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/teamwork.dart';
import '../../theme/tokens.dart';
import 'common.dart';

IconData kindIcon(RequestKind kind) => switch (kind) {
      RequestKind.breakCover => LucideIcons.coffee,
      RequestKind.liftTurn => LucideIcons.moveVertical,
      RequestKind.medWitness => LucideIcons.eye,
      RequestKind.takeOver => LucideIcons.userCheck,
      RequestKind.ivHelp => LucideIcons.syringe,
      RequestKind.urgentReview => LucideIcons.stethoscope,
      RequestKind.supplies => LucideIcons.package,
      RequestKind.familyTalk => LucideIcons.messageCircle,
    };

String kindLabel(BuildContext context, RequestKind kind) {
  final t = l10n(context);
  return switch (kind) {
    RequestKind.breakCover => t.kindBreakCover,
    RequestKind.liftTurn => t.kindLiftTurn,
    RequestKind.medWitness => t.kindMedWitness,
    RequestKind.takeOver => t.kindTakeOver,
    RequestKind.ivHelp => t.kindIvHelp,
    RequestKind.urgentReview => t.kindUrgentReview,
    RequestKind.supplies => t.kindSupplies,
    RequestKind.familyTalk => t.kindFamilyTalk,
  };
}

String statusLabel(BuildContext context, RequestStatus status) {
  final t = l10n(context);
  return switch (status) {
    RequestStatus.pending => t.statusPending,
    RequestStatus.accepted => t.statusAccepted,
    RequestStatus.declined => t.statusDeclined,
    RequestStatus.done => t.statusDone,
  };
}

Color statusColor(BuildContext context, RequestStatus status) {
  final c = context.afia;
  return switch (status) {
    RequestStatus.pending => c.machine,
    RequestStatus.accepted => c.signedAccent,
    RequestStatus.declined => c.textFaint,
    RequestStatus.done => c.ok,
  };
}

/// Small live-presence dot (green) with the standard sizing.
class PresenceDot extends StatelessWidget {
  const PresenceDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: context.afia.ok,
        shape: BoxShape.circle,
      ),
    );
  }
}
