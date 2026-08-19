/// THE EMERGENCY FIXTURE (design law / §2.7 / F-051 / D-015 invariant).
///
/// Composed ABOVE the app's entire route hierarchy — in the MaterialApp
/// builder, outside every screen, keyboard inset and loading state — so
/// nothing can ever occlude it, and it exists on EVERY screen INCLUDING the
/// welcome/auth screens: a person in distress at the login wall still
/// reaches 999 in one tap, with no account and no connectivity.
///
/// It is NOT red — red is spent entirely on the interrupt screen, so the
/// first red the person sees means something absolute. 64px, top-right.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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
        return Stack(children: [
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
                  side: const BorderSide(color: PatientColors.ink, width: 2),
                ),
                child: InkWell(
                  onTap: model.openEmergency,
                  borderRadius: BorderRadius.circular(PatientDimens.radius),
                  child: Container(
                    constraints: const BoxConstraints(
                        minHeight: PatientDimens.touch,
                        minWidth: PatientDimens.touch),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.phone,
                          size: 20, color: PatientColors.ink),
                      const SizedBox(width: 8),
                      Text(t.emergencyLabel,
                          style: sans(context, 17, weight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
