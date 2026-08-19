/// Screen 5 — Confirmation layer. THE ONLY HARD BLOCK in the app (§2.3):
/// every drug and number chip is confirmed one at a time. There is no
/// confirm-all anywhere — the screen says so at the bottom. "3 of 5
/// confirmed" progress in the header. Audio replay on the current item.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/chips.dart';
import '../../domain/formulary.dart';
import '../../domain/handover.dart';
import '../../services/playback.dart';
import '../../services/repo.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'correction_picker.dart';

class ConfirmScreen extends StatefulWidget {
  final String handoverId;
  const ConfirmScreen({super.key, required this.handoverId});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final PlaybackService _playback = PlaybackService();

  AppModel get model => AppModel.instance!;

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  Handover? get _handover {
    for (final h in model.handovers) {
      if (h.id == widget.handoverId) return h;
    }
    return null;
  }

  Future<void> _confirmCurrent(ConfirmableChip chip) async {
    final h = _handover;
    if (h == null) return;
    // §2.3 — exactly one chip id per call. No other path exists.
    final updated =
        await Repo.instance.confirmSingleChip(h, chip.id, model.me);
    if (!mounted) return;
    if (unconfirmedChips(updated).isEmpty) {
      Navigator.of(context).pop(); // back to the draft — sign is next
    }
  }

  Future<void> _correctCurrent(ConfirmableChip chip) async {
    final h = _handover;
    if (h == null) return;
    final corrected = await showCorrectionPicker(
      context,
      chip: chip,
      formulary: model.formulary,
      playback: _playback,
      audio: h.audio,
    );
    if (corrected == null || !mounted) return;
    final updated = await Repo.instance
        .confirmSingleChip(h, chip.id, model.me, correctedTo: corrected);
    if (!mounted) return;
    if (unconfirmedChips(updated).isEmpty) Navigator.of(context).pop();
  }

  Future<void> _replay() async {
    final h = _handover;
    if (h?.audio == null) return;
    final ok = await _playback.play(h!.audio!);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).audioKeptOnDevice)));
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
        if (h == null) return Scaffold(body: Center(child: Text(t.loading)));

        final remaining = unconfirmedChips(h);
        final done = h.chips.length - remaining.length;
        final current = remaining.isEmpty ? null : remaining.first;

        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              ScreenHeader(
                title: Text(t.confirmTitle,
                    style: sans(context, 20,
                        weight: FontWeight.w500, color: c.text)),
                trailing: RichText(
                  text: TextSpan(
                    style: mono(context, 20,
                        weight: FontWeight.w500, color: c.textDim),
                    children: [
                      TextSpan(
                          text: '$done',
                          style: mono(context, 20,
                              weight: FontWeight.w500, color: c.text)),
                      TextSpan(text: ' / ${h.chips.length}'),
                    ],
                  ),
                ),
              ),
              if (current != null)
                _CurrentChipCard(
                  chip: current,
                  onConfirm: () => _confirmCurrent(current),
                  onCorrect: current.kind == ChipKind.drug
                      ? () => _correctCurrent(current)
                      : null,
                  onReplay: h.audio != null ? _replay : null,
                ),
              Expanded(
                child: ListView(padding: EdgeInsets.zero, children: [
                  SectionHeader(
                      remaining.length > 1 ? t.stillToConfirm : t.allConfirmed,
                      height: 34),
                  for (final chip in remaining.skip(1))
                    _QueueRow(chip: chip),
                  for (final chip in h.chips.where((x) => x.confirmed))
                    _QueueRow(chip: chip, done: true),
                ]),
              ),
              // The structural statement, on screen (§2.3).
              Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border))),
                child: Text(t.noConfirmAll,
                    style: sans(context, 11, color: c.textFaint)),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _CurrentChipCard extends StatelessWidget {
  final ConfirmableChip chip;
  final VoidCallback onConfirm;
  final VoidCallback? onCorrect;
  final VoidCallback? onReplay;
  const _CurrentChipCard({
    required this.chip,
    required this.onConfirm,
    this.onCorrect,
    this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final match = chip.match;
    final isDrug = chip.kind == ChipKind.drug;

    final (confIcon, confLabel, confColor) = switch (match?.confidence) {
      MatchConfidence.high => (LucideIcons.checkCircle2, t.highConfidence, c.textFaint),
      MatchConfidence.low => (LucideIcons.alertCircle, t.lowConfidence, c.warn),
      _ => isDrug
          ? (LucideIcons.alertCircle, t.noFormularyMatch, c.warn)
          : (LucideIcons.checkCircle2, t.highConfidence, c.textFaint),
    };

    // Sound-alike partners to display side by side — the whole point (§4.4).
    final partners = (match?.candidates ?? const <String>[])
        .where((name) => name.toLowerCase() != chip.text.toLowerCase())
        .take(2)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
                (isDrug ? t.drugHeard : t.numberHeard).toUpperCase(),
                style: sectionLabel(context)),
          ),
          Icon(confIcon, size: 15, color: confColor),
          const SizedBox(width: 6),
          Text(confLabel, style: sans(context, 13, color: confColor)),
        ]),
        const SizedBox(height: 14),
        Text(chip.correctedTo ?? chip.text,
            textDirection: TextDirection.ltr,
            style: mono(context, 32, weight: FontWeight.w500, color: c.text)),
        if (chip.correctedTo != null) ...[
          const SizedBox(height: 4),
          Text(t.heardAs(chip.text),
              style: sans(context, 13, color: c.textFaint)),
        ],
        if (partners.isNotEmpty && isDrug) ...[
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(children: [
              for (var i = 0; i < partners.length; i++) ...[
                if (i > 0) Container(width: 1, height: 66, color: c.border),
                Expanded(
                  child: Container(
                    color: c.chipBg,
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.soundAlike,
                              style: sans(context, 11, color: c.warn)),
                          const SizedBox(height: 4),
                          Text(partners[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: mono(context, 16, color: c.text)),
                        ]),
                  ),
                ),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: PrimaryButton(
              onTap: onConfirm,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.check, size: 18),
                const SizedBox(width: 8),
                Text(t.confirmAction),
              ]),
            ),
          ),
          if (onCorrect != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onCorrect,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.edit3, size: 18, color: c.text),
                    const SizedBox(width: 8),
                    Text(t.correctAction,
                        style: sans(context, 16, color: c.text)),
                  ]),
                ),
              ),
            ),
          ],
          if (onReplay != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onReplay,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.fileAudio, size: 20, color: c.text),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final ConfirmableChip chip;
  final bool done;
  const _QueueRow({required this.chip, this.done = false});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final low = chip.match?.confidence == MatchConfidence.low;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 8),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: c.hairline))),
      child: Row(children: [
        Icon(
          done
              ? LucideIcons.checkCircle2
              : low
                  ? LucideIcons.alertCircle
                  : LucideIcons.circleDashed,
          size: 18,
          color: done
              ? c.ok
              : low
                  ? c.warn
                  : c.textFaint,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chip.correctedTo ?? chip.text,
                textDirection: TextDirection.ltr,
                style: sans(context, 15, color: c.text)),
            const SizedBox(height: 2),
            Text(
              done
                  ? (chip.correctedTo != null
                      ? t.correctedTo(chip.correctedTo!)
                      : t.confirmAction)
                  : low
                      ? t.lowConfidence
                      : t.highConfidence,
              style: sans(context, 13, color: low && !done ? c.warn : c.textFaint),
            ),
          ]),
        ),
        if (chip.kind == ChipKind.number)
          Text(chip.text,
              textDirection: TextDirection.ltr,
              style: mono(context, 16, color: c.text)),
      ]),
    );
  }
}
