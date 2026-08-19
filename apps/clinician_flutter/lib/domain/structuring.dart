/// HANDOFF §4 — the AI layer, deterministic half. Everything here
/// REORGANISES information a human already provided. Nothing here classifies
/// severity, suggests a diagnosis or medication, or ranks importance — those
/// are clinical judgements and are forbidden (§4.3).
///
/// Dart mirror of packages/ai/src/index.ts: KeywordStructurer (the
/// deterministic fallback used automatically when Gemini is unavailable or
/// offline), the ten-second summary, the field diff, and segment merging.
library;

import 'gaps.dart';

/// §4.1 — the inference layer is swappable behind this interface. A hospital
/// can replace the hosted model with a local one without touching business
/// logic. Implementations: [KeywordStructurer] (deterministic, offline) and
/// GeminiStructurer in services/ (Firebase AI Logic).
abstract class Structurer {
  String get kind;
  Future<List<FieldContent>> structure(
      String transcript, List<TemplateField> template);
}

/// Deterministic keyword router: splits speech into sentences, scores each
/// against the template's configured keywords, and routes it to the
/// best-matching field. A sentence with no match follows the previous
/// sentence's field (speech flows in topics) — that is the "side note routed
/// to its correct field" behaviour of §4.2, with zero model inference.
class KeywordStructurer implements Structurer {
  @override
  final String kind = 'keyword-router';

  const KeywordStructurer();

  /// Synchronous core so tests can property-test determinism directly.
  List<FieldContent> structureSync(
      String transcript, List<TemplateField> template) {
    if (template.isEmpty) return const [];
    final sentences = transcript
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final buckets = <String, List<String>>{};
    var currentField = template.first.id;

    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      String? bestId;
      var bestScore = 0;
      for (final field in template) {
        var score = 0;
        for (final kw in field.keywords) {
          if (lower.contains(kw.toLowerCase())) score += 1;
        }
        if (score > 0 && score > bestScore) {
          bestScore = score;
          bestId = field.id;
        }
      }
      if (bestId != null) currentField = bestId;
      (buckets[currentField] ??= []).add(sentence);
    }

    return template
        .where((f) => buckets.containsKey(f.id))
        .map((f) => FieldContent(fieldId: f.id, text: buckets[f.id]!.join(' ')))
        .toList();
  }

  @override
  Future<List<FieldContent>> structure(
          String transcript, List<TemplateField> template) async =>
      structureSync(transcript, template);
}

/// Ten-second summary: the situation, medications, and plan the author
/// already stated — reorganisation, never judgement (§4.2).
String tenSecondSummary(
    List<FieldContent> fields, List<TemplateField> template) {
  String pick(String id) => fields
      .firstWhere((f) => f.fieldId == id,
          orElse: () => const FieldContent(fieldId: '', text: ''))
      .text
      .trim();

  final preferred = ['situation', 'medications', 'plan']
      .map(pick)
      .where((t) => t.isNotEmpty)
      .toList();
  if (preferred.isNotEmpty) return preferred.join(' · ');
  for (final t in template) {
    final text = pick(t.id);
    if (text.isNotEmpty) return text;
  }
  return '';
}

enum DiffKind { added, changed, unchanged, nowEmpty }

class FieldDiff {
  final String fieldId;
  final String label;
  final DiffKind kind;
  final String text;
  const FieldDiff(
      {required this.fieldId,
      required this.label,
      required this.kind,
      required this.text});
}

/// Diff against the previous handover — what changed, stated neutrally.
List<FieldDiff> diffHandovers(
  List<FieldContent> previous,
  List<FieldContent> current,
  List<TemplateField> template,
) {
  final prev = {for (final f in previous) f.fieldId: f.text.trim()};
  final curr = {for (final f in current) f.fieldId: f.text.trim()};
  return template.map((field) {
    final p = prev[field.id] ?? '';
    final c = curr[field.id] ?? '';
    final kind = p == c
        ? DiffKind.unchanged
        : p.isEmpty
            ? DiffKind.added
            : c.isEmpty
                ? DiffKind.nowEmpty
                : DiffKind.changed;
    return FieldDiff(fieldId: field.id, label: field.label, kind: kind, text: c);
  }).toList();
}

/// Merge interrupted recording segments in order (§4.2).
String mergeSegments(List<String> segments) =>
    segments.map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');

/// §4.2 output validation for ANY structurer (model-backed ones included):
/// only known fieldIds survive, and every output field's content must be
/// traceable to the transcript — a normalised-substring check per sentence.
/// Fields that fail validation are dropped; callers fall back to the
/// deterministic structurer when nothing valid remains.
List<FieldContent> validateStructured(
  List<FieldContent> output,
  String transcript,
  List<TemplateField> template,
) {
  final knownIds = template.map((t) => t.id).toSet();
  String norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9؀-ۿ]+'), ' ').trim();
  final haystack = norm(transcript);

  final valid = <FieldContent>[];
  for (final f in output) {
    if (!knownIds.contains(f.fieldId)) continue;
    if (f.text.trim().isEmpty) continue;
    final sentences = f.text
        .split(RegExp(r'(?<=[.!?؟])\s+|\n+'))
        .map(norm)
        .where((s) => s.isNotEmpty);
    final traceable = sentences.every((s) => haystack.contains(s));
    if (traceable) valid.add(f);
  }
  return valid;
}
