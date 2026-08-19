/// HANDOFF §4.4 — Drug name safety layer. The highest-value component in the
/// system: a sound-alike substitution (furosemide/fluoxetine) is the most
/// dangerous failure this product can produce, and this layer is the only
/// interception.
///
/// Correction is recognition, never recall: the picker searches the formulary
/// and shows sound-alike pairs together. Free-text spelling is never offered.
/// Dart mirror of packages/rules/src/formulary.ts.
library;

class FormularyEntry {
  final String id;
  final String name;

  /// Entries sharing a group are sound-alikes and are always displayed together.
  final String? soundAlikeGroup;

  const FormularyEntry(
      {required this.id, required this.name, this.soundAlikeGroup});

  factory FormularyEntry.fromMap(Map<String, dynamic> m) => FormularyEntry(
        id: m['id'] as String,
        name: m['name'] as String,
        soundAlikeGroup: m['soundAlikeGroup'] as String?,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'soundAlikeGroup': soundAlikeGroup};
}

enum MatchConfidence { high, low, none }

class DrugMatch {
  /// The term exactly as transcribed.
  final String term;
  final String? entryId;
  final String? entryName;
  final MatchConfidence confidence;

  /// Nearby formulary names (incl. sound-alike partners), nearest first.
  final List<String> candidates;

  const DrugMatch({
    required this.term,
    required this.entryId,
    required this.entryName,
    required this.confidence,
    required this.candidates,
  });

  Map<String, dynamic> toMap() => {
        'term': term,
        'entryId': entryId,
        'entryName': entryName,
        'confidence': confidence.name,
        'candidates': candidates,
      };

  factory DrugMatch.fromMap(Map<String, dynamic> m) => DrugMatch(
        term: m['term'] as String,
        entryId: m['entryId'] as String?,
        entryName: m['entryName'] as String?,
        confidence: MatchConfidence.values.firstWhere(
            (c) => c.name == m['confidence'],
            orElse: () => MatchConfidence.none),
        candidates:
            (m['candidates'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

/// Plain Levenshtein distance — deterministic, dependency-free.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final curr = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        curr[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = curr;
  }
  return prev[b.length];
}

String _norm(String s) => s.trim().toLowerCase();

List<FormularyEntry> _soundAlikePartners(
    FormularyEntry entry, List<FormularyEntry> formulary) {
  if (entry.soundAlikeGroup == null) return const [];
  return formulary
      .where((e) => e.id != entry.id && e.soundAlikeGroup == entry.soundAlikeGroup)
      .toList();
}

/// Match one transcribed term against the formulary.
/// distance 0 → high · distance ≤ 2 → low (flagged for review) · else none.
/// Candidates always include the sound-alike partners of anything close.
DrugMatch matchDrug(String term, List<FormularyEntry> formulary) {
  final t = _norm(term);
  final scored = formulary
      .map((entry) => (entry: entry, d: levenshtein(t, _norm(entry.name))))
      .toList()
    ..sort((a, b) {
      final byD = a.d.compareTo(b.d);
      return byD != 0 ? byD : a.entry.name.compareTo(b.entry.name);
    });

  if (scored.isEmpty) {
    return DrugMatch(
        term: term,
        entryId: null,
        entryName: null,
        confidence: MatchConfidence.none,
        candidates: const []);
  }
  final best = scored.first;

  final near = scored.where((s) => s.d <= 3).map((s) => s.entry);
  final withPartners = <String, FormularyEntry>{};
  for (final e in near) {
    withPartners[e.id] = e;
    for (final p in _soundAlikePartners(e, formulary)) {
      withPartners[p.id] = p;
    }
  }
  final candidates = withPartners.values.map((e) => e.name).toList();

  if (best.d == 0) {
    return DrugMatch(
        term: term,
        entryId: best.entry.id,
        entryName: best.entry.name,
        confidence: MatchConfidence.high,
        candidates: candidates);
  }
  if (best.d <= 2) {
    return DrugMatch(
        term: term,
        entryId: best.entry.id,
        entryName: best.entry.name,
        confidence: MatchConfidence.low,
        candidates: candidates);
  }
  return DrugMatch(
      term: term,
      entryId: null,
      entryName: null,
      confidence: MatchConfidence.none,
      candidates: const []);
}

/// Formulary picker search (screen 6). Returns clusters: each cluster is
/// either a sound-alike group (displayed together, always complete) or a
/// singleton. Clusters are ordered by their best match to the query.
List<List<FormularyEntry>> searchFormulary(
    String query, List<FormularyEntry> formulary) {
  final q = _norm(query);
  final matches = formulary.where((e) {
    final n = _norm(e.name);
    return q.isEmpty || n.contains(q) || levenshtein(q, n) <= 2;
  });

  final clusters = <String, List<FormularyEntry>>{};
  final order = <String>[];
  for (final e in matches) {
    final key = e.soundAlikeGroup ?? 'solo:${e.id}';
    if (!clusters.containsKey(key)) {
      // A sound-alike cluster is always shown complete, even if only one
      // member matched the query — the near-miss is what must be visible.
      final members = e.soundAlikeGroup == null
          ? [e]
          : formulary
              .where((f) => f.soundAlikeGroup == e.soundAlikeGroup)
              .toList();
      members.sort((a, b) => a.name.compareTo(b.name));
      clusters[key] = members;
      order.add(key);
    }
  }
  return order.map((k) => clusters[k]!).toList();
}
