/// Mic-permission primer — shown once before the first recording, explaining
/// why the microphone is needed and what happens to the audio (§2.6).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/prefs.dart';
import '../../services/recorder.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class MicPrimerScreen extends StatefulWidget {
  const MicPrimerScreen({super.key});

  @override
  State<MicPrimerScreen> createState() => _MicPrimerScreenState();
}

class _MicPrimerScreenState extends State<MicPrimerScreen> {
  bool _denied = false;

  Future<void> _allow() async {
    final granted = await RecorderService().hasPermission();
    await Prefs.instance.setMicPrimerSeen();
    if (!mounted) return;
    if (granted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _denied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            Icon(LucideIcons.mic, size: 34, color: c.machine),
            const SizedBox(height: 18),
            Text(t.micPrimerTitle,
                textAlign: TextAlign.center,
                style: sans(context, 22, weight: FontWeight.w500, color: c.text)),
            const SizedBox(height: 12),
            Text(t.micPrimerBody,
                textAlign: TextAlign.center,
                style: sans(context, 14, color: c.textDim, height: 1.55)),
            if (_denied) ...[
              const SizedBox(height: 16),
              Text(t.micDenied,
                  textAlign: TextAlign.center,
                  style: sans(context, 13, color: c.warn, height: 1.5)),
            ],
            const Spacer(),
            PrimaryButton(onTap: _allow, child: Text(t.micPrimerAllow)),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: TextButton(
                onPressed: () async {
                  await Prefs.instance.setMicPrimerSeen();
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: Text(t.typeInstead,
                    style: sans(context, 14, color: c.textFaint)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
