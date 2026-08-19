/// Screen 8 — Incoming list (Received tab). Read state carries an icon and a
/// word, never colour alone.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'assistant_sheet.dart';
import 'received_screen.dart';

class IncomingScreen extends StatelessWidget {
  const IncomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        final incoming = model.incoming;
        final unread = incoming
            .where((h) => !model.readHandoverIds.contains(h.id))
            .length;

        return Column(children: [
          Container(
            height: 56,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border))),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.receivedTitle,
                        style: sans(context, 19,
                            weight: FontWeight.w500, color: c.text)),
                    const SizedBox(height: 2),
                    Text(t.receivedSubtitle,
                        style: sans(context, 11, color: c.textFaint)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => showAssistantSheet(context),
                icon: Icon(LucideIcons.sparkles, size: 20, color: c.machine),
                tooltip: t.assistantTitle,
              ),
              RichText(
                text: TextSpan(
                  style: mono(context, 20,
                      weight: FontWeight.w500, color: c.textDim),
                  children: [
                    TextSpan(
                        text: '$unread',
                        style: mono(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                    TextSpan(text: ' ${t.newLabel.toLowerCase()}'),
                  ],
                ),
              ),
            ]),
          ),
          Expanded(
            child: incoming.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.inbox, size: 28, color: c.textFaint),
                      const SizedBox(height: 12),
                      Text(t.noIncoming,
                          style: sans(context, 15, color: c.textDim)),
                      const SizedBox(height: 4),
                      Text(t.noIncomingBody,
                          textAlign: TextAlign.center,
                          style: sans(context, 13, color: c.textFaint)),
                    ]),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: incoming.length,
                    itemBuilder: (context, i) {
                      final h = incoming[i];
                      final patient = model.patientById(h.patientId);
                      final read = model.readHandoverIds.contains(h.id);
                      final hasFlags = h.flags.isNotEmpty;
                      return InkWell(
                        onTap: () {
                          model.markRead(h.id);
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  ReceivedScreen(handoverId: h.id)));
                        },
                        child: Container(
                          height: 68,
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16),
                          decoration: BoxDecoration(
                            color: read ? null : c.raised,
                            border: Border(
                                bottom: BorderSide(color: c.hairline)),
                          ),
                          child: Row(children: [
                            SizedBox(
                              width: 34,
                              child: Text(
                                patient?.bed ?? '—',
                                textDirection: TextDirection.ltr,
                                style: mono(context, 15,
                                    weight: FontWeight.w500,
                                    color: read ? c.textDim : c.text),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(patient?.shortName ?? h.patientId,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sans(context, 15,
                                          color: c.text)),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    if (hasFlags) ...[
                                      Icon(LucideIcons.helpCircle,
                                          size: 13, color: c.textDim),
                                      const SizedBox(width: 5),
                                      Text(
                                          t.openFlagsCount(h.flags.length),
                                          style: sans(context, 13,
                                              color: c.textDim)),
                                      Text(' · ',
                                          style: sans(context, 13,
                                              color: c.textFaint)),
                                    ],
                                    Flexible(
                                      child: Text(
                                        h.signature?.signatureIdentity ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: sans(context, 13,
                                            color: c.textFaint),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(children: [
                              Icon(
                                  read
                                      ? LucideIcons.mailOpen
                                      : LucideIcons.mail,
                                  size: 15,
                                  color: read ? c.textFaint : c.machine),
                              const SizedBox(width: 5),
                              Text(read ? t.readLabel : t.newLabel,
                                  style: sans(context, 13,
                                      color: read ? c.textFaint : c.machine)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}
