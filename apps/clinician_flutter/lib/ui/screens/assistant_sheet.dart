/// Afia Assistant (مساعد عافية) — full-screen chat behind the sparkle icon.
/// One question → one answer: the model's structured final_answer renders
/// natively (stat tiles, bordered sections, status lines, tappable patient
/// rows); intermediate tool rounds show only a quiet activity line. Latin
/// spans are BiDi-isolated so Arabic text never scrambles; numbers render
/// mono LTR. Fully usable in Arabic.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/handover.dart';
import '../../domain/teamwork.dart';
import '../../services/assistant/assistant_service.dart';
import '../widgets/request_kit.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'patient_detail_screen.dart';

void showAssistantSheet(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => const AssistantScreen(),
  ));
}

/// First-Strong-Isolate wrap (U+2068/U+2069, escaped so the analyzer can see
/// them): mixed Latin/Arabic runs resolve their own direction and never
/// scramble the surrounding line.
String bidi(String s) => '\u2068$s\u2069';

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
      ward: model.ward,
      formulary: model.formulary,
      presenceProvider: () => model.colleaguesPresent,
      wardOrderSetter: model.setWardOrder,
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
                          Icon(LucideIcons.brain,
                              size: 12, color: c.textFaint),
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
                // D-013 — suggested questions on the empty chat state.
                // Wait-time phrasing, never risk phrasing.
                if (_assistant.entries.isEmpty)
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final q in const [
                      'كم حالة عندي اليوم؟',
                      "What's left this shift?",
                      'من ينتظر أطول؟',
                    ])
                      InkWell(
                        onTap: _busy
                            ? null
                            : () {
                                _input.text = q;
                                _send();
                              },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: c.machine),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(q,
                              style: sans(context, 13, color: c.machine)),
                        ),
                      ),
                  ]),
                for (final entry in _assistant.entries) ...[
                  _entryWidget(entry),
                  const SizedBox(height: 10),
                ],
                // The single lightweight working indicator — intermediate
                // tool rounds never become bubbles (field feedback).
                if (_busy)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 4, top: 4),
                    child: Row(children: [
                      SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: c.machine)),
                      const SizedBox(width: 8),
                      Text(
                          _assistant.activity != null
                              ? t.assistantWorkingData
                              : t.assistantThinking,
                          style: sans(context, 12, color: c.textFaint)),
                      if (_assistant.activity != null) ...[
                        const SizedBox(width: 6),
                        Text(bidi(_assistant.activity!),
                            style: mono(context, 11, color: c.textFaint)),
                      ],
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

    if (entry.answer != null) return _answerCard(entry.answer!);

    final fromUser = entry.fromUser;
    return Align(
      alignment: fromUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
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
        child: Text(bidi(entry.text),
            style: sans(context, 14, color: c.text, height: 1.5)),
      ),
    );
  }

  /// The structured answer, in the app's design language: borders not cards,
  /// stat tiles with mono numbers, quiet section titles, standard status
  /// lines, tappable patient rows.
  Widget _answerCard(AssistantAnswer answer) {
    final c = context.afia;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (answer.intro != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 4),
            child: Text(bidi(answer.intro!),
                style: sans(context, 14, color: c.text, height: 1.5)),
          ),
        if (answer.stats.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 4),
            child: Row(children: [
              for (var i = 0; i < answer.stats.length; i++) ...[
                if (i > 0) Container(width: 1, height: 40, color: c.hairline),
                Expanded(
                  child: Column(children: [
                    Text(answer.stats[i].$2,
                        textDirection: TextDirection.ltr,
                        style: mono(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                    const SizedBox(height: 3),
                    Text(bidi(answer.stats[i].$1),
                        textAlign: TextAlign.center,
                        style: sans(context, 11, color: c.textFaint)),
                  ]),
                ),
              ],
            ]),
          ),
        for (final section in answer.sections) ...[
          if (section.title.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 2),
              child: Text(bidi(section.title).toUpperCase(),
                  style: sectionLabel(context)),
            ),
          for (final row in section.rows)
            InkWell(
              onTap: row.patientId == null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          PatientDetailScreen(patientId: row.patientId!))),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.hairline))),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(bidi(row.title),
                              style: sans(context, 14, color: c.text)),
                          if (row.state != null)
                            StatusLine(
                                status:
                                    HandoverStatusWire.parse(row.state!))
                          else if (row.subtitle != null)
                            Text(bidi(row.subtitle!),
                                style:
                                    sans(context, 12, color: c.textFaint)),
                        ]),
                  ),
                  if (row.trailingMono != null)
                    Text(row.trailingMono!,
                        textDirection: TextDirection.ltr,
                        style: mono(context, 13, color: c.textDim)),
                  if (row.patientId != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? LucideIcons.chevronLeft
                            : LucideIcons.chevronRight,
                        size: 14,
                        color: c.textFaint),
                  ],
                ]),
              ),
            ),
        ],
        // D-014 — the drafted request: assistant drafts, HUMAN sends.
        if (answer.requestDraft != null)
          _RequestDraftCard(draft: answer.requestDraft!),
        if (answer.note != null)
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 10),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.hairline))),
            child: Text(bidi(answer.note!),
                style: sans(context, 11, color: c.textFaint, height: 1.4)),
          )
        else
          const SizedBox(height: 10),
      ]),
    );
  }
}

/// The one-tap confirm card for an assistant-drafted request. Sending is
/// always this explicit human tap — the assistant never sends (D-014).
class _RequestDraftCard extends StatefulWidget {
  final RequestDraft draft;
  const _RequestDraftCard({required this.draft});

  @override
  State<_RequestDraftCard> createState() => _RequestDraftCardState();
}

class _RequestDraftCardState extends State<_RequestDraftCard> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _send() async {
    if (_sending || _sent) return;
    final model = AppModel.instance!;
    setState(() => _sending = true);
    try {
      await model.teamwork.sendRequest(
        from: RequestParty(uid: model.me.id, name: model.me.name),
        to: RequestParty(
            uid: widget.draft.toUid, name: widget.draft.toName),
        wardId: model.ward?.id ?? '',
        kind: widget.draft.kind,
        bed: widget.draft.bed,
        note: widget.draft.note,
      );
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n(context).errorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final draft = widget.draft;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 4),
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: c.machine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(kindIcon(draft.kind), size: 18, color: c.machine),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kindLabel(context, draft.kind),
                      style: sans(context, 15,
                          weight: FontWeight.w500, color: c.text)),
                  Text(
                    '${t.toLabel(draft.toName)}'
                    '${draft.bed != null ? ' · ${t.bed(draft.bed!)}' : ''}'
                    '${draft.note != null ? ' · ${bidi(draft.note!)}' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sans(context, 12, color: c.textFaint),
                  ),
                ]),
          ),
        ]),
        const SizedBox(height: 10),
        PrimaryButton(
          height: 48,
          onTap: _sent || _sending ? null : _send,
          child: _sending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.onAccent))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_sent ? LucideIcons.check : LucideIcons.send,
                      size: 16),
                  const SizedBox(width: 8),
                  Text(_sent ? t.requestSent : t.sendRequest),
                ]),
        ),
      ]),
    );
  }
}
