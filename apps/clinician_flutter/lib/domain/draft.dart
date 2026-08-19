/// Draft recomputation — the checkpoint-time pipeline of HANDOFF §5/§2.8.
/// Port of LocalStore.updateDraft from packages/core/src/store.ts: on every
/// save, chips are re-extracted deterministically (preserving confirmations
/// for unchanged chips) and gap detection re-runs against the template.
library;

import 'chips.dart';
import 'formulary.dart';
import 'gaps.dart';
import 'handover.dart';

Handover recomputeDraft(
  Handover h, {
  String? transcript,
  List<FieldContent>? fields,
  AudioRecordingData? audio,
  required List<FormularyEntry> formulary,
  required List<TemplateField> template,
}) {
  if (h.status != HandoverStatus.recording &&
      h.status != HandoverStatus.draftReady) {
    throw StateError(
        'Cannot edit a handover in state ${h.status.wire} — supersede it instead.');
  }

  final newTranscript = transcript ?? h.transcript;
  final newFields = fields ?? h.fields;
  final newAudio = audio ?? h.audio;

  final extracted = extractChips(newTranscript, formulary);
  final chips = extracted.map((chip) {
    ConfirmableChip? existing;
    for (final c in h.chips) {
      if (c.id == chip.id && c.text == chip.text) {
        existing = c;
        break;
      }
    }
    final base = ConfirmableChip.fromExtracted(chip);
    return existing != null
        ? base.copyWith(
            confirmedBy: existing.confirmedBy,
            confirmedAt: existing.confirmedAt,
            correctedTo: existing.correctedTo,
          )
        : base;
  }).toList();

  final gaps = detectGaps(template, newFields);
  final flags = gaps.map((g) {
    HandoverFlag? existing;
    for (final f in h.flags) {
      if (f.fieldId == g.fieldId) {
        existing = f;
        break;
      }
    }
    return existing != null
        ? HandoverFlag(
            id: existing.id,
            fieldId: g.fieldId,
            label: g.label,
            message: g.message,
            state: existing.state,
            signingNote: existing.signingNote,
          )
        : HandoverFlag(
            id: newId('flag'),
            fieldId: g.fieldId,
            label: g.label,
            message: g.message,
            state: FlagState.open,
            signingNote: null,
          );
  }).toList();

  return h.copyWith(
    transcript: newTranscript,
    fields: newFields,
    audio: newAudio,
    chips: chips,
    flags: flags,
  );
}
