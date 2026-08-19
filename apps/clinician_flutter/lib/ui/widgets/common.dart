/// Shared design-system parts: status lines, pills, primary buttons, section
/// labels, sync strip, hold-to-sign. Borders, never cards. 56px targets.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/handover.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

String hhmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}';
}

/// The 22px sync strip: "Synced · 2 queued  05:14" / offline state.
class SyncStrip extends StatelessWidget {
  final bool offline;
  final int queued;
  const SyncStrip({super.key, required this.offline, required this.queued});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final label = offline
        ? t.offlineSavedOnDevice
        : queued > 0
            ? '${t.synced} · ${t.queuedCount(queued)}'
            : t.synced;
    return Container(
      height: 22,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: Row(children: [
        Icon(offline ? LucideIcons.wifiOff : LucideIcons.circle,
            size: 10, color: c.textFaint),
        const SizedBox(width: 6),
        Text(label, style: sans(context, 11, color: c.textFaint)),
        const Spacer(),
        Text(hhmm(DateTime.now().millisecondsSinceEpoch),
            style: mono(context, 12, color: c.textFaint)),
      ]),
    );
  }
}

/// Row-state line: icon + word + optional mono time. Never colour alone.
class StatusLine extends StatelessWidget {
  final HandoverStatus status;
  final int? timeMs;
  const StatusLine({super.key, required this.status, this.timeMs});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final (icon, label, color) = switch (status) {
      HandoverStatus.notStarted => (
          LucideIcons.circleDashed,
          t.notStarted,
          c.textFaint
        ),
      HandoverStatus.recording => (
          LucideIcons.activity,
          t.recordingLabel,
          c.machine
        ),
      HandoverStatus.draftReady => (
          LucideIcons.fileText,
          t.draftReadyNotSigned,
          c.draft
        ),
      HandoverStatus.signed => (
          LucideIcons.arrowUpCircle,
          t.signedQueued,
          c.signedAccent
        ),
      HandoverStatus.queued => (
          LucideIcons.arrowUpCircle,
          t.signedQueued,
          c.signedAccent
        ),
      HandoverStatus.confirmedInSystem => (
          LucideIcons.checkCircle2,
          t.confirmedInSystem,
          c.ok
        ),
      HandoverStatus.exportFailed => (
          LucideIcons.rotateCw,
          t.exportFailedRetry,
          c.text
        ),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sans(context, 13, color: color)),
      ),
      if (timeMs != null) ...[
        const SizedBox(width: 6),
        Text(hhmm(timeMs!), style: mono(context, 14, color: c.textFaint)),
      ],
    ]);
  }
}

/// 36px bordered pill (Retry / Resume / Add / Replay …).
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  const Pill({super.key, required this.label, this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final fg = color ?? c.text;
    final borderColor = color ?? c.border;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label, style: sans(context, 13, color: fg)),
          ]),
        ),
      ),
    );
  }
}

/// 56px filled primary action (periwinkle in dark, action blue in light).
class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  const PrimaryButton(
      {super.key, required this.child, this.onTap, this.height = 56});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? c.machine.withValues(alpha: 0.4) : c.machine,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: sans(context, 16, weight: FontWeight.w500, color: c.onAccent),
          child: IconTheme(
            data: IconThemeData(color: c.onAccent, size: 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 64px outlined action (Sign out).
class OutlinedAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  const OutlinedAction({super.key, required this.child, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final fg = color ?? c.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: fg),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: sans(context, 17, weight: FontWeight.w500, color: fg),
          child: IconTheme(
            data: IconThemeData(color: fg, size: 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Uppercase 11px section header band.
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final double height;
  const SectionHeader(this.label, {super.key, this.trailing, this.height = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: Text(label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sectionLabel(context)),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

/// Screen header: 56px, back chevron + title (+ trailing).
class ScreenHeader extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  final bool showBack;
  const ScreenHeader(
      {super.key, required this.title, this.trailing, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return Container(
      height: 56,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(children: [
        if (showBack)
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: SizedBox(
              width: 40,
              height: 56,
              child: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? LucideIcons.chevronRight
                    : LucideIcons.chevronLeft,
                size: 22,
                color: c.text,
              ),
            ),
          ),
        Expanded(child: title),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// The inverted system-failure banner. Colour means the patient; an inverted
/// banner means the system — never clinical red.
class InvertedBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const InvertedBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return Container(
      color: c.invertBg,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 22, color: c.invertText),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: sans(context, 15,
                    weight: FontWeight.w500, color: c.invertText)),
            const SizedBox(height: 3),
            Text(subtitle, style: sans(context, 13, color: c.invertTextDim)),
          ]),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 36,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                border: Border.all(color: c.invertText),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(actionLabel!,
                  style: sans(context, 13, color: c.invertText)),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Hold-to-sign: 1.2 s press-and-hold with a fill + bottom progress bar.
class HoldToSign extends StatefulWidget {
  final VoidCallback onComplete;
  final String label;
  const HoldToSign({super.key, required this.onComplete, required this.label});

  @override
  State<HoldToSign> createState() => _HoldToSignState();
}

class _HoldToSignState extends State<HoldToSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
        _controller.reset();
      }
    });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.machine, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              FractionallySizedBox(
                widthFactor: _controller.value,
                heightFactor: 1,
                alignment: AlignmentDirectional.centerStart,
                child: Container(color: c.chipBg),
              ),
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.edit3, size: 22, color: c.text),
                  const SizedBox(width: 10),
                  Text(widget.label,
                      style: sans(context, 18,
                          weight: FontWeight.w500, color: c.text)),
                ]),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 5,
                  color: c.hairline,
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: _controller.value,
                    child: Container(color: c.machine),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

/// Localized template field label — clinical labels are bilingual for the
/// seeded field ids; unknown ids fall back to the stored label.
String fieldLabel(BuildContext context, String fieldId, String storedLabel) {
  final t = l10n(context);
  return switch (fieldId) {
    'situation' => t.fieldSituation,
    'background' => t.fieldBackground,
    'medications' => t.fieldMedications,
    'vitals' => t.fieldVitals,
    'pain' => t.fieldPain,
    'mobility' => t.fieldMobility,
    'diet' => t.fieldDiet,
    'plan' => t.fieldPlan,
    'family' => t.fieldFamily,
    _ => storedLabel,
  };
}
