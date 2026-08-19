/// Full-screen EMERGENCY INTERRUPT (HANDOFF §6 / F-052) — the app's ONLY red
/// screen. Shown the moment a red-flag answer is YES — evaluated locally,
/// offline, instantly (§2.7) — and by the always-present emergency fixture.
/// Numbers are bundled constants: tel:999 primary, tel:444 (MOH health
/// line) secondary. The quiet "go back" path un-does nothing: the answer
/// stays recorded, and any escalated case priority stays raised (§2.1).
library;

import 'package:flutter/material.dart';

import '../../domain/red_flags.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/safety_layer.dart' show dial;

class EmergencyInterrupt extends StatelessWidget {
  const EmergencyInterrupt({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    final fromAnswer =
        model.interruptSource == InterruptSource.redFlagYes;
    const emergency = EmergencyNumbers.emergency;
    const advice = EmergencyNumbers.urgentAdvice;

    return Semantics(
      label: t.interruptTitle(emergency),
      child: Scaffold(
        backgroundColor: PatientColors.surface,
        body: Column(children: [
          // The red header — the first and only red this person sees.
          Container(
            width: double.infinity,
            color: PatientColors.emergency,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 24),
            child: Text(
              t.interruptTitle(emergency),
              style: sans(context, 34,
                  weight: FontWeight.w700,
                  color: PatientColors.onEmergency,
                  height: 1.2),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    Text(
                      fromAnswer
                          ? t.interruptLeadAnswer(emergency)
                          : t.interruptLeadFixture(emergency),
                      style: sans(context, 22,
                          weight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: t.callEmergency(emergency),
                      child: InkWell(
                        onTap: () => dial(emergency),
                        borderRadius:
                            BorderRadius.circular(PatientDimens.radius),
                        child: Container(
                          constraints:
                              const BoxConstraints(minHeight: 96),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: PatientColors.emergency,
                            borderRadius: BorderRadius.circular(
                                PatientDimens.radius),
                          ),
                          child: Text(t.callEmergency(emergency),
                              style: sans(context, 30,
                                  weight: FontWeight.w700,
                                  color: PatientColors.onEmergency)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GhostButton(
                      label: t.callAdviceLine(emergency, advice),
                      onTap: () => dial(advice),
                    ),
                    const SizedBox(height: 20),
                    if (fromAnswer)
                      BodyText(t.interruptMistake,
                          color: PatientColors.inkDim),
                    const SizedBox(height: 6),
                    GhostButton(
                      label: t.goBack,
                      onTap: model.dismissEmergency,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
