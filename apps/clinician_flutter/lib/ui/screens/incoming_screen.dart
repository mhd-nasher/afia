/// Screen 8 — Incoming (Received tab), split into two calm segments
/// (D-014): التسليم (Handovers) | الطلبات (Requests). Read state carries an
/// icon and a word, never colour alone; request actions follow the
/// pending→accepted/declined→done lifecycle.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/teamwork.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/request_kit.dart';
import 'assistant_sheet.dart';
import 'received_screen.dart';

class IncomingScreen extends StatefulWidget {
  const IncomingScreen({super.key});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  int _segment = 0;

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
          // The two calm segments — a quiet underline, not a control bar.
          Container(
            height: 44,
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.hairline))),
            child: Row(children: [
              _segmentTab(0, t.segHandovers, unread),
              _segmentTab(1, t.segRequests, model.pendingRequestCount),
            ]),
          ),
          if (_segment == 1)
            Expanded(child: _RequestsList(model: model))
          else
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

  Widget _segmentTab(int index, String label, int badge) {
    final c = context.afia;
    final selected = _segment == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _segment = index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? c.machine : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: sans(context, 14,
                    weight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected ? c.machine : c.textDim)),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: c.machine,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge',
                    textDirection: TextDirection.ltr,
                    style: mono(context, 11,
                        weight: FontWeight.w500, color: c.onAccent)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// The requests segment — incoming pending first with Accept/Decline, then
/// everything involving me with its status. Ages in mono; borders not cards.
class _RequestsList extends StatelessWidget {
  final AppModel model;
  const _RequestsList({required this.model});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final requests = model.myRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.helpingHand, size: 28, color: c.textFaint),
          const SizedBox(height: 12),
          Text(t.noRequests, style: sans(context, 15, color: c.textDim)),
          const SizedBox(height: 4),
          Text(t.noRequestsBody,
              textAlign: TextAlign.center,
              style: sans(context, 13, color: c.textFaint)),
        ]),
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final r = requests[i];
        final toMe = r.to.uid == model.me.id;
        final ageMin = ((now - r.createdAt) / 60000).clamp(0, 5999).round();
        final actionable = toMe && r.status != RequestStatus.declined &&
            r.status != RequestStatus.done;

        return Container(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: toMe && r.status == RequestStatus.pending ? c.raised : null,
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(kindIcon(r.kind), size: 18, color: c.machine),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kindLabel(context, r.kind),
                          style: sans(context, 15, color: c.text)),
                      const SizedBox(height: 2),
                      Text(
                        '${toMe ? t.fromLabel(r.from.name) : t.toLabel(r.to.name)}'
                        '${r.bed != null ? ' · ${t.bed(r.bed!)}' : ''}'
                        '${r.note != null ? ' · ${r.note}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sans(context, 12, color: c.textFaint),
                      ),
                    ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(t.minutesShort(ageMin),
                    textDirection: TextDirection.ltr,
                    style: mono(context, 13, color: c.textDim)),
                const SizedBox(height: 2),
                Text(statusLabel(context, r.status),
                    style: sans(context, 11,
                        color: statusColor(context, r.status))),
              ]),
            ]),
            if (actionable) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (r.status == RequestStatus.pending) ...[
                  Expanded(
                    child: Pill(
                      label: t.accept,
                      icon: LucideIcons.check,
                      color: c.machine,
                      onTap: () => _respond(context, r, RequestStatus.accepted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Pill(
                      label: t.decline,
                      icon: LucideIcons.x,
                      onTap: () => _respond(context, r, RequestStatus.declined),
                    ),
                  ),
                ] else if (r.status == RequestStatus.accepted)
                  Expanded(
                    child: Pill(
                      label: t.markDone,
                      icon: LucideIcons.checkCircle2,
                      color: c.ok,
                      onTap: () => _respond(context, r, RequestStatus.done),
                    ),
                  ),
              ]),
            ],
          ]),
        );
      },
    );
  }

  Future<void> _respond(
      BuildContext context, ShiftRequest r, RequestStatus to) async {
    try {
      await model.teamwork.respond(r, to);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n(context).errorGeneric)));
      }
    }
  }
}
