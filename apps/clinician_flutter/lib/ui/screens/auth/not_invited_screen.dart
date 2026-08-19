/// The not-invited gate (D-012). The email account exists, but ACCESS exists
/// by invitation only — nothing in this app can grant it.
library;

import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../widgets/common.dart';

class NotInvitedScreen extends StatelessWidget {
  const NotInvitedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final email =
        AuthService.instance.currentUser?.email?.toLowerCase() ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            Icon(LucideIcons.userX, size: 34, color: c.warn),
            const SizedBox(height: 18),
            Text(t.notInvitedTitle,
                textAlign: TextAlign.center,
                style: sans(context, 22, weight: FontWeight.w500, color: c.text)),
            const SizedBox(height: 8),
            if (email.isNotEmpty)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(email,
                    textAlign: TextAlign.center,
                    style: mono(context, 15, color: c.textDim)),
              ),
            const SizedBox(height: 14),
            Text(t.notInvitedBody,
                textAlign: TextAlign.center,
                style: sans(context, 14, color: c.textDim, height: 1.55)),
            const Spacer(),
            OutlinedAction(
              onTap: () => AuthService.instance.signOut(null),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.logOut),
                const SizedBox(width: 10),
                Text(t.signOut),
              ]),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
