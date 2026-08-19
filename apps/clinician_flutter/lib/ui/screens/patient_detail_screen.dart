/// Screen 2 — Patient detail. Every number mono and aligned; the record
/// button owns the bottom third. Vitals in tabular IBM Plex Mono.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/handover.dart';
import '../../services/prefs.dart';
import '../../services/recorder.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'draft_review_screen.dart';
import 'mic_primer_screen.dart';
import 'recording_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  Future<void> _record(BuildContext context) async {
    final model = AppModel.instance!;
    final patient = model.patientById(patientId);
    if (patient == null) return;

    final latest = model.latestFor(patientId);
    if (latest != null &&
        (latest.status == HandoverStatus.recording ||
            latest.status == HandoverStatus.draftReady)) {
      // Resume the in-flight work rather than starting a second draft.
      if (latest.status == HandoverStatus.recording) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RecordingScreen(patient: patient, resume: latest)));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DraftReviewScreen(handoverId: latest.id)));
      }
      return;
    }

    if (!Prefs.instance.micPrimerSeen) {
      final proceed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const MicPrimerScreen()));
      if (proceed != true || !context.mounted) return;
    } else {
      // Permission may have been revoked since the primer.
      final ok = await RecorderService().hasPermission();
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n(context).micDenied)));
      }
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecordingScreen(patient: patient)));
  }

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        final patient = model.patientById(patientId);
        if (patient == null) {
          return Scaffold(body: Center(child: Text(t.errorGeneric)));
        }
        final latest = model.latestFor(patientId);
        final lastSigned = model.handovers
            .where((h) => h.patientId == patientId && h.signature != null)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              ScreenHeader(
                title: Text(t.patientTitle,
                    style: sans(context, 20,
                        weight: FontWeight.w500, color: c.text)),
                trailing: Text(t.bed(patient.bed),
                    style: mono(context, 16,
                        weight: FontWeight.w500, color: c.textDim)),
              ),
              // Identity block.
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name,
                          style: sans(context, 20,
                              weight: FontWeight.w500, color: c.text)),
                      const SizedBox(height: 5),
                      Text(
                        '${t.dob(patient.dateOfBirth)} · ${patient.externalIdentifier ?? 'MRN —'}',
                        style: mono(context, 13, color: c.textDim),
                      ),
                    ]),
              ),
              // Vitals strip — tabular mono. Seed data carries no vitals
              // collection; render the strip from the latest handover's
              // recorded numbers where present, honestly empty otherwise.
              Container(
                decoration: BoxDecoration(
                  color: c.raised,
                  border: Border(
                    top: BorderSide(color: c.border),
                    bottom: BorderSide(color: c.border),
                  ),
                ),
                child: Row(children: [
                  _vital(context, t.vitalsBp, _findNumber(latest, RegExp(r'\b\d{2,3}/\d{2,3}\b'))),
                  _vitalDivider(context),
                  _vital(context, t.vitalsHr, _findLabelled(latest, ['hr', 'heart rate', 'النبض'])),
                  _vitalDivider(context),
                  _vital(context, t.vitalsSpo2, _findNumber(latest, RegExp(r'\b\d{2,3}%'))),
                  _vitalDivider(context),
                  _vital(context, t.vitalsTemp, _findNumber(latest, RegExp(r'\b3[5-9]\.\d\b'))),
                ]),
              ),
              // Last handover summary block.
              Expanded(
                child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SectionHeader(t.lastHandover, height: 34),
                      if (lastSigned.isEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16),
                          child: Text(t.noHandoverYet,
                              style: sans(context, 14,
                                  color: c.textDim, height: 1.5)),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _summaryText(lastSigned.last),
                                style: sans(context, 14,
                                    color: c.textDim, height: 1.5),
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(LucideIcons.edit3,
                                    size: 14, color: c.signedAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    lastSigned
                                        .last.signature!.signatureIdentity,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: sans(context, 13,
                                        color: c.signedAccent),
                                  ),
                                ),
                                Text(hhmm(lastSigned.last.signature!.signedAt),
                                    style: mono(context, 14,
                                        color: c.signedAccent)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => DraftReviewScreen(
                                      handoverId: lastSigned.last.id))),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: c.hairline),
                                bottom: BorderSide(color: c.hairline),
                              ),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Text(t.handoverTitle,
                                    style: sans(context, 14, color: c.text)),
                              ),
                              StatusLine(status: lastSigned.last.status),
                            ]),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ]),
              ),
              // Record button — owns the bottom third.
              Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border))),
                child: PrimaryButton(
                  height: 72,
                  onTap: () => _record(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.mic, size: 24),
                    const SizedBox(width: 12),
                    Text(t.recordHandover,
                        style: sans(context, 17,
                            weight: FontWeight.w500, color: c.onAccent)),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _summaryText(Handover h) {
    final firstFilled = h.fields.where((f) => f.text.trim().isNotEmpty);
    if (firstFilled.isEmpty) return h.transcript;
    return firstFilled.take(2).map((f) => f.text.trim()).join(' ');
  }

  String _findNumber(Handover? h, RegExp pattern) {
    if (h == null) return '—';
    final m = pattern.firstMatch(h.transcript);
    return m?.group(0) ?? '—';
  }

  String _findLabelled(Handover? h, List<String> cues) {
    if (h == null) return '—';
    final lower = h.transcript.toLowerCase();
    for (final cue in cues) {
      final i = lower.indexOf(cue);
      if (i >= 0) {
        final m = RegExp(r'\d{2,3}').firstMatch(lower.substring(i));
        if (m != null) return m.group(0)!;
      }
    }
    return '—';
  }

  Widget _vital(BuildContext context, String label, String value) {
    final c = context.afia;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          Text(value,
              textDirection: TextDirection.ltr,
              style:
                  mono(context, 19, weight: FontWeight.w500, color: c.text)),
          const SizedBox(height: 4),
          Text(label, style: sans(context, 11, color: c.textFaint)),
        ]),
      ),
    );
  }

  Widget _vitalDivider(BuildContext context) =>
      Container(width: 1, height: 56, color: context.afia.border);
}
