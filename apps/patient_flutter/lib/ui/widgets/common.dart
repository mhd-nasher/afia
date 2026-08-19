/// Shared design-system parts for the patient app. Warm cream surfaces,
/// borders never cards, 64px touch targets, 17px body floor. One question,
/// one action, one screen — no tab bar, no progress, no step counter
/// (F-050): note the ABSENCE of any progress affordance here.
library;

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

/// The standard step page: scrolling column, warm page background, top
/// clearance for the emergency fixture, bottom clearance for the dock.
class StepPage extends StatelessWidget {
  final List<Widget> children;
  const StepPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  PatientDimens.pagePadding,
                  88, // clears the 64px emergency fixture
                  PatientDimens.pagePadding,
                  200), // clears the safety dock
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  final String text;
  const PageTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: sans(context, 28, weight: FontWeight.w600, height: 1.25)),
      );
}

class BodyText extends StatelessWidget {
  final String text;
  final Color? color;
  const BodyText(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: sans(context, 18, height: 1.5, color: color)),
      );
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(), style: eyebrow(context)),
      );
}

/// 64px filled primary action (deep indigo — never red).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  const PrimaryButton(
      {super.key, required this.label, required this.onTap, this.leading});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PatientDimens.radius),
        child: Container(
          constraints:
              const BoxConstraints(minHeight: PatientDimens.touch),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: onTap == null
                ? PatientColors.action.withValues(alpha: 0.35)
                : PatientColors.action,
            borderRadius: BorderRadius.circular(PatientDimens.radius),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[
              IconTheme(
                  data: const IconThemeData(
                      color: PatientColors.onAction, size: 22),
                  child: leading!),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: sans(context, 21,
                      weight: FontWeight.w600, color: PatientColors.onAction)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 64px outlined secondary action.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const GhostButton(
      {super.key, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? PatientColors.ink;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PatientDimens.radius),
        child: Container(
          constraints:
              const BoxConstraints(minHeight: PatientDimens.touch),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            border: Border.all(color: fg, width: 2),
            borderRadius: BorderRadius.circular(PatientDimens.radius),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style:
                  sans(context, 19, weight: FontWeight.w600, color: fg)),
        ),
      ),
    );
  }
}

/// An answer option. ALL answers on a screen are styled IDENTICALLY — same
/// size, same weight, same shape (F-053). "I don't know" is never smaller,
/// never grey, never last-class.
class AnswerButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const AnswerButton(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PatientDimens.radius),
          child: Container(
            constraints:
                const BoxConstraints(minHeight: PatientDimens.touch),
            alignment: Alignment.center,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: PatientColors.surface,
              border: Border.all(color: PatientColors.ink, width: 2),
              borderRadius: BorderRadius.circular(PatientDimens.radius),
              boxShadow: selected
                  ? [
                      const BoxShadow(
                          color: PatientColors.action,
                          spreadRadius: 3,
                          blurRadius: 0)
                    ]
                  : null,
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: sans(context, 20, weight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

/// Labelled text field, 64px minimum, warm surface.
class BigField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final int minLines;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final TextDirection? fieldDirection;
  const BigField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
    this.minLines = 1,
    this.onChanged,
    this.hint,
    this.fieldDirection,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      minLines: minLines,
      maxLines: obscure ? 1 : (minLines > 1 ? minLines + 6 : 1),
      onChanged: onChanged,
      style: sans(context, 19, height: 1.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: sans(context, 19, color: PatientColors.inkFaint),
        filled: true,
        fillColor: PatientColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PatientDimens.radius),
          borderSide:
              const BorderSide(color: PatientColors.inkDim, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PatientDimens.radius),
          borderSide:
              const BorderSide(color: PatientColors.action, width: 3),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label,
              style: sans(context, 18, weight: FontWeight.w600)),
        ),
        if (fieldDirection != null)
          Directionality(textDirection: fieldDirection!, child: field)
        else
          field,
      ]),
    );
  }
}

/// Big accessible toggle row (entry: terms + consent are SEPARATE records).
class ToggleRow extends StatelessWidget {
  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;
  const ToggleRow(
      {super.key,
      required this.checked,
      required this.label,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final border = checked ? PatientColors.action : PatientColors.inkDim;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        toggled: checked,
        label: label,
        child: InkWell(
          onTap: () => onChanged(!checked),
          borderRadius: BorderRadius.circular(PatientDimens.radius),
          child: Container(
            constraints:
                const BoxConstraints(minHeight: PatientDimens.touch),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: PatientColors.surface,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(PatientDimens.radius),
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked
                      ? PatientColors.action
                      : PatientColors.surface,
                  border: Border.all(
                      color: checked
                          ? PatientColors.action
                          : PatientColors.ink,
                      width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: checked
                    ? const Icon(Icons.check,
                        size: 22, color: PatientColors.onAction)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: sans(context, 18,
                        weight: FontWeight.w600, height: 1.4)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Quiet underlined link — still a 64px target.
class QuietLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const QuietLink({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
            minHeight: PatientDimens.touch, minWidth: PatientDimens.touch),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(label,
            textAlign: TextAlign.center,
            style: sans(context, 17, color: PatientColors.inkDim).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: PatientColors.inkDim,
            )),
      ),
    );
  }
}
