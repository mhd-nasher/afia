/// HANDOFF §2.3 — drug names and numeric values become chips that each
/// require INDIVIDUAL confirmation before signing. Extraction is
/// deterministic text processing (no model): same transcript + same
/// formulary → same chips. Dart mirror of packages/rules/src/chips.ts.
library;

import 'formulary.dart';

enum ChipKind { drug, number }

class ExtractedChip {
  /// Deterministic id derived from kind + character offset.
  final String id;
  final ChipKind kind;

  /// Exact source text from the transcript.
  final String text;
  final int start;
  final int end;
  final DrugMatch? match;

  const ExtractedChip({
    required this.id,
    required this.kind,
    required this.text,
    required this.start,
    required this.end,
    required this.match,
  });
}

final RegExp _numberPattern = RegExp(
  r'\b\d+(?:\.\d+)?\s?(?:mg|mcg|micrograms?|milligrams?|g|ml|mls|l|units?|mmol(?:\/l)?|bpm|%|degrees|°c)\b|\b\d{2,3}\/\d{2,3}\b',
  caseSensitive: false,
);

final RegExp _wordPattern = RegExp(r'[a-zA-Z][a-zA-Z-]{3,}');

List<ExtractedChip> extractChips(
    String transcript, List<FormularyEntry> formulary) {
  final chips = <ExtractedChip>[];

  for (final m in _numberPattern.allMatches(transcript)) {
    chips.add(ExtractedChip(
      id: 'number-${m.start}',
      kind: ChipKind.number,
      text: m.group(0)!,
      start: m.start,
      end: m.end,
      match: null,
    ));
  }

  for (final m in _wordPattern.allMatches(transcript)) {
    final word = m.group(0)!;
    final match = matchDrug(word, formulary);
    // A word becomes a drug chip when it is exactly a formulary name or a
    // near-miss of one (the dangerous case). Unrelated words never match.
    if (match.confidence == MatchConfidence.high ||
        match.confidence == MatchConfidence.low) {
      chips.add(ExtractedChip(
        id: 'drug-${m.start}',
        kind: ChipKind.drug,
        text: word,
        start: m.start,
        end: m.end,
        match: match,
      ));
    }
  }

  chips.sort((a, b) => a.start.compareTo(b.start));
  return chips;
}
