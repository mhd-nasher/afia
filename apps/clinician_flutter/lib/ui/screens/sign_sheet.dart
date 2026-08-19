/// Screen 7 — Sign sheet. Hold-to-sign (1.2 s). Open omission flags NEVER
/// block (§2.4): each gets a one-tap reason chip, the reason is recorded on
/// the signature and travels with the handover. Export fires automatically
/// on signing — signed → queued, then the server's persistence ack (A1.2)
/// moves it to "Recorded in Afia".
library;

import 'package:flutter/material.dart';

import '../../domain/handover.dart';
import '../../services/export_engine.dart';
import '../../services/repo.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

void showSignSheet(BuildContext context, String handoverId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.afia.raised,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _SignSheet(handoverId: handoverId),
  );
}

class _SignSheet extends StatefulWidget {
  final String handoverId;
  const _SignSheet({required this.handoverId});

  @override
  State<_SignSheet> createState() => _SignSheetState();
}

class _SignSheetState extends State<_SignSheet> {
  final Map<String, String> _reasons = {};
  bool _signing = false;

  AppModel get model => AppModel.instance!;

  Handover? get _handover {
    for (final h in model.handovers) {
      if (h.id == widget.handoverId) return h;
    }
    return null;
  }

  Future<void> _sign() async {
    final h = _handover;
    if (h == null || _signing) return;
    final open = openFlags(h);
    // One-tap reasons: compose the recorded reason from the per-flag picks.
    String? reason;
    if (open.isNotEmpty) {
      if (open.any((f) => !_reasons.containsKey(f.id))) return;
      final parts = open
          .map((f) => open.length == 1
              ? _reasons[f.id]!
              : '${f.label}: ${_reasons[f.id]!}')
          .toList();
      reason = parts.join(' · ');
    }
    setState(() => _signing = true);
    try {
      final queued = await Repo.instance
          .signAndQueue(h, model.me, openFlagReason: reason);
      // §5/A1.2 — export fires automatically; the server's real persistence
      // acknowledgement moves it to "Recorded in Afia".
      ExportEngine.instance.scheduleAck(queued);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _signing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        final h = _handover;
        if (h == null) return const SizedBox.shrink();
        final open = openFlags(h);
        final ready = open.every((f) => _reasons.containsKey(f.id));
        final reasonChips = [
          t.flagNotApplicable,
          t.flagAskedNoAnswer,
          t.flagWillAddLater,
          t.flagEndOfShift,
        ];

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              // Signing as — the immutable identity (§2.5).
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.signingAs.toUpperCase(),
                          style: sectionLabel(context)),
                      const SizedBox(height: 6),
                      Text(model.me.name,
                          style: sans(context, 20,
                              weight: FontWeight.w500, color: c.text)),
                      const SizedBox(height: 4),
                      Text(model.me.signatureIdentity,
                          textDirection: TextDirection.ltr,
                          style: mono(context, 14, color: c.textDim)),
                    ]),
              ),
              if (open.isNotEmpty) ...[
                Container(
                  height: 34,
                  width: double.infinity,
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: c.hairline))),
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(t.openFlagsCount(open.length).toUpperCase(),
                      style: sectionLabel(context)),
                ),
                for (final flag in open)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: c.hairline))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              t.notMentioned(fieldLabel(
                                  context, flag.fieldId, flag.label)),
                              style: sans(context, 14, color: c.text)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final label in reasonChips)
                              _reasonChip(flag.id, label),
                          ]),
                        ]),
                  ),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border))),
                child: Column(children: [
                  Opacity(
                    opacity: (open.isEmpty || ready) && !_signing ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: (open.isNotEmpty && !ready) || _signing,
                      child:
                          HoldToSign(label: t.holdToSign, onComplete: _sign),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    open.isNotEmpty && !ready
                        ? t.chooseFlagReason
                        : t.flagsTravelNote,
                    textAlign: TextAlign.center,
                    style: sans(context, 11, color: c.textFaint, height: 1.4),
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _reasonChip(String flagId, String label) {
    final c = context.afia;
    final selected = _reasons[flagId] == label;
    return InkWell(
      onTap: () => setState(() => _reasons[flagId] = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: selected ? c.machine : c.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: sans(context, 13,
                color: selected ? c.machine : c.textDim)),
      ),
    );
  }
}
