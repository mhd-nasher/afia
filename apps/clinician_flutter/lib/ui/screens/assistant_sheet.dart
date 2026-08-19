/// Afia Assistant (مساعد عافية) — full-screen chat behind the sparkle icon.
/// Tool results render as proper widgets: summary card, diff card, fields
/// card. Fully usable in Arabic. Needs connectivity; says so honestly when
/// offline.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/structuring.dart';
import '../../services/assistant/assistant_service.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

void showAssistantSheet(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => const AssistantScreen(),
  ));
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late final AssistantService _assistant;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final model = AppModel.instance!;
    _assistant = AssistantService(
      me: model.me,
      template: model.template,
      patients: model.patients,
      handovers: model.handovers,
    );
    _assistant.onChanged = () {
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      });
    };
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    await _assistant.send(text);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: Row(children: [
              Icon(LucideIcons.sparkles, size: 18, color: c.machine),
              const SizedBox(width: 8),
              Text(t.assistantTitle,
                  style: sans(context, 20,
                      weight: FontWeight.w500, color: c.text)),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsetsDirectional.all(16),
              children: [
                // Intro + memory note.
                Container(
                  padding: const EdgeInsetsDirectional.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.assistantIntro,
                            style: sans(context, 13,
                                color: c.textDim, height: 1.5)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(LucideIcons.brain, size: 12, color: c.textFaint),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(t.assistantMemoryNote,
                                style:
                                    sans(context, 11, color: c.textFaint)),
                          ),
                        ]),
                      ]),
                ),
                const SizedBox(height: 12),
                for (final entry in _assistant.entries) ...[
                  _entryWidget(entry),
                  const SizedBox(height: 10),
                ],
                if (_busy)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4, top: 4),
                    child: Row(children: [
                      SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: c.machine)),
                      const SizedBox(width: 8),
                      Text(t.assistantThinking,
                          style: sans(context, 12, color: c.textFaint)),
                    ]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 14),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border))),
            child: Row(children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    style: sans(context, 15, color: c.text),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: t.assistantHint,
                      hintStyle: sans(context, 15, color: c.textFaint),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _send,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.machine,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? LucideIcons.arrowLeft
                          : LucideIcons.arrowRight,
                      size: 20,
                      color: c.onAccent),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _entryWidget(AssistantEntry entry) {
    final c = context.afia;
    final t = l10n(context);

    if (entry.summary != null) {
      return _card(
        icon: LucideIcons.timer,
        title: '${t.tenSecondSummary} · ${entry.patientLabel}',
        child: Text(entry.summary!,
            style: sans(context, 14, color: c.text, height: 1.5)),
      );
    }
    if (entry.diff != null) {
      final changed =
          entry.diff!.where((d) => d.kind != DiffKind.unchanged).toList();
      return _card(
        icon: LucideIcons.gitCompare,
        title: '${t.whatChanged} · ${entry.patientLabel}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final d in changed)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      switch (d.kind) {
                        DiffKind.added => t.diffAdded,
                        DiffKind.changed => t.diffChanged,
                        DiffKind.nowEmpty => t.diffNowEmpty,
                        DiffKind.unchanged => '',
                      },
                      style: sans(context, 11, color: c.machine),
                    ),
                  ),
                  Expanded(
                    child: Text(
                        '${fieldLabel(context, d.fieldId, d.label)}${d.text.isEmpty ? '' : ' — ${d.text}'}',
                        style: sans(context, 13, color: c.text, height: 1.4)),
                  ),
                ]),
              ),
            if (changed.isEmpty)
              Text('—', style: sans(context, 13, color: c.textFaint)),
          ],
        ),
      );
    }
    if (entry.fields != null) {
      return _card(
        icon: LucideIcons.layoutList,
        title: t.structuring,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in entry.fields!)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fieldLabel(context, f.fieldId, f.fieldId)
                              .toUpperCase(),
                          style: sectionLabel(context)),
                      const SizedBox(height: 3),
                      Text(f.text,
                          style: sans(context, 13,
                              color: c.text, height: 1.4)),
                    ]),
              ),
          ],
        ),
      );
    }

    // Plain bubbles.
    final fromUser = entry.fromUser;
    return Align(
      alignment:
          fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromUser ? c.chipBg : null,
          border: fromUser ? null : Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(entry.text,
            style: sans(context, 14, color: c.text, height: 1.5)),
      ),
    );
  }

  Widget _card(
      {required IconData icon, required String title, required Widget child}) {
    final c = context.afia;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: c.machine),
          const SizedBox(width: 7),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sans(context, 12,
                    weight: FontWeight.w500, color: c.textDim)),
          ),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
