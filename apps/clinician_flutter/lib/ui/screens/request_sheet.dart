/// D-014 feature 3 — the one-tap request sheet. Pick a preset kind →
/// optional bed → optional short note → one SEND tap. No typing required;
/// no clinical content beyond the preset kind + bed label + short note.
/// Design language: borders not cards, 56px targets, quiet.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/teamwork.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/request_kit.dart';

Future<void> showRequestSheet(BuildContext context, PresenceEntry colleague) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.afia.raised,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _RequestSheet(colleague: colleague),
  );
}

class _RequestSheet extends StatefulWidget {
  final PresenceEntry colleague;
  const _RequestSheet({required this.colleague});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  RequestKind? _kind;
  String? _bed;
  final TextEditingController _note = TextEditingController();
  bool _sending = false;

  AppModel get model => AppModel.instance!;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final kind = _kind;
    if (kind == null || _sending) return;
    setState(() => _sending = true);
    try {
      await model.teamwork.sendRequest(
        from: RequestParty(uid: model.me.id, name: model.me.name),
        to: RequestParty(
            uid: widget.colleague.uid, name: widget.colleague.name),
        wardId: model.ward?.id ?? widget.colleague.wardId,
        kind: kind,
        bed: _bed,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).requestSent)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final beds = model.patients.map((p) => p.bed).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
              child: Row(children: [
                const PresenceDot(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.requestTo(widget.colleague.name),
                      style: sans(context, 18,
                          weight: FontWeight.w500, color: c.text)),
                ),
                Text(widget.colleague.role,
                    style: sans(context, 12, color: c.textFaint)),
              ]),
            ),
            // Kind grid — 2 columns, 56px targets, icon + bilingual label.
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Column(children: [
                for (var i = 0; i < RequestKind.values.length; i += 2)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 8),
                    child: Row(children: [
                      Expanded(child: _kindCell(RequestKind.values[i])),
                      const SizedBox(width: 8),
                      Expanded(
                        child: i + 1 < RequestKind.values.length
                            ? _kindCell(RequestKind.values[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ]),
                  ),
              ]),
            ),
            // Optional bed picker.
            if (beds.isNotEmpty) ...[
              Container(
                height: 30,
                width: double.infinity,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                alignment: AlignmentDirectional.centerStart,
                child:
                    Text(t.pickBed.toUpperCase(), style: sectionLabel(context)),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 16),
                  children: [
                    for (final bed in beds)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: InkWell(
                          onTap: () => setState(
                              () => _bed = _bed == bed ? null : bed),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      _bed == bed ? c.machine : c.border),
                              color: _bed == bed ? c.chipBg : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(bed,
                                textDirection: TextDirection.ltr,
                                style: mono(context, 14,
                                    color: _bed == bed
                                        ? c.machine
                                        : c.textDim)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            // Optional short note.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
              child: Container(
                padding:
                    const EdgeInsetsDirectional.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _note,
                  maxLength: 80,
                  style: sans(context, 14, color: c.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: t.noteOptional,
                    hintStyle: sans(context, 14, color: c.textFaint),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: PrimaryButton(
                onTap: _kind == null || _sending ? null : _send,
                child: _sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.onAccent))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.send, size: 18),
                        const SizedBox(width: 8),
                        Text(t.sendRequest),
                      ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _kindCell(RequestKind kind) {
    final c = context.afia;
    final selected = _kind == kind;
    return InkWell(
      onTap: () => setState(() => _kind = kind),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 56,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? c.machine : c.border),
          color: selected ? c.chipBg : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(kindIcon(kind),
              size: 18, color: selected ? c.machine : c.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(kindLabel(context, kind),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: sans(context, 13,
                    color: selected ? c.machine : c.text)),
          ),
        ]),
      ),
    );
  }
}
