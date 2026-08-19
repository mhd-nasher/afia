/// THE EMERGENCY FIXTURE (design law / §2.7 / F-051).
///
/// This layer is composed ABOVE the app's entire step hierarchy — in the
/// MaterialApp builder, outside every screen, overlay, keyboard inset and
/// loading state — so nothing can ever occlude it. It is structural: a step
/// screen cannot remove it, cover it, or forget it.
///
/// · The Emergency control: 64px, top-right, on EVERY screen. It is NOT red
///   — red is spent entirely on the interrupt screen, so the first red the
///   person sees means something absolute. It works BEFORE any account
///   exists and with no connectivity: it opens the interrupt, whose numbers
///   are bundled constants (§2.7).
/// · After first submission, a second persistent control appears at the
///   bottom: "My condition has changed" (plus a quiet nurse-line call).
///   It rides above the keyboard via the view insets.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/red_flags.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

Future<void> dial(String number) async {
  final uri = Uri(scheme: 'tel', path: number);
  try {
    await launchUrl(uri);
  } catch (_) {
    // A device without a dialler (simulator): nothing safe to do here —
    // the number itself is on screen for a bystander to dial.
  }
}

class SafetyLayer extends StatelessWidget {
  const SafetyLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final model = EpisodeModel.instance;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        // On the interrupt screen the emergency actions ARE the screen —
        // the fixture (whose only job is opening that screen) yields to it.
        if (model.episode.emergency) return const SizedBox.shrink();
        final insets = MediaQuery.of(context).viewInsets.bottom;
        return Stack(children: [
          // ── the fixture: 64px · top-right · never red ──────────────────
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 10,
            end: 12,
            child: Semantics(
              button: true,
              label: t.emergencyLabel,
              child: Material(
                color: PatientColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PatientDimens.radius),
                  side: const BorderSide(
                      color: PatientColors.ink, width: 2),
                ),
                child: InkWell(
                  onTap: model.openEmergency,
                  borderRadius:
                      BorderRadius.circular(PatientDimens.radius),
                  child: Container(
                    constraints: const BoxConstraints(
                        minHeight: PatientDimens.touch,
                        minWidth: PatientDimens.touch),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.phone,
                          size: 20, color: PatientColors.ink),
                      const SizedBox(width: 8),
                      Text(t.emergencyLabel,
                          style: sans(context, 17,
                              weight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          // ── the dock: appears after first submission ───────────────────
          if (model.hasCase)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.only(bottom: insets),
                // This layer lives ABOVE the Navigator (outside any
                // Scaffold), so the ink surface must be provided here.
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                  decoration: const BoxDecoration(
                    color: PatientColors.surface,
                    border: Border(
                        top: BorderSide(
                            color: PatientColors.border, width: 2)),
                  ),
                  padding: EdgeInsets.fromLTRB(16, 12, 16,
                      12 + MediaQuery.of(context).padding.bottom),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Semantics(
                      button: true,
                      label: t.conditionChanged,
                      child: InkWell(
                        onTap: model.startConditionChanged,
                        borderRadius:
                            BorderRadius.circular(PatientDimens.radius),
                        child: Container(
                          constraints: const BoxConstraints(
                              minHeight: PatientDimens.touch),
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: PatientColors.action,
                            borderRadius: BorderRadius.circular(
                                PatientDimens.radius),
                          ),
                          child: Text(t.conditionChanged,
                              style: sans(context, 19,
                                  weight: FontWeight.w600,
                                  color: PatientColors.onAction)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => dial(EmergencyNumbers.urgentAdvice),
                      child: Container(
                        constraints: const BoxConstraints(
                            minHeight: PatientDimens.touch),
                        alignment: Alignment.center,
                        child: Text(
                          t.callNurseLine(EmergencyNumbers.urgentAdvice),
                          style: sans(context, 17,
                                  weight: FontWeight.w600,
                                  color: PatientColors.inkDim)
                              .copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: PatientColors.inkDim),
                        ),
                      ),
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
