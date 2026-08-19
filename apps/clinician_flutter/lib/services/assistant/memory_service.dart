/// Afia Assistant per-user memory (owner-only by deployed rules):
///   aiMemory/{uid}                — { preferences: map, updatedAt }
///   aiMemory/{uid}/notes/{noteId} — { text, topic, createdAt }
/// Plus learned corrections read from the append-only audit trail (the
/// user's own 'corrected' events) — usage genuinely teaches the structurer.
/// Nothing clinical is ever judged here; memory stores workflow preferences
/// and distilled notes only.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryNote {
  final String id;
  final String text;
  final String topic;
  final int createdAt;
  const MemoryNote(
      {required this.id,
      required this.text,
      required this.topic,
      required this.createdAt});
}

class AssistantMemory {
  final Map<String, String> preferences;
  final List<MemoryNote> notes;

  /// term → corrected formulary name, with counts, from this user's own
  /// audit 'corrected' events. E.g. {"enoxaparin": "dalteparin (×3)"}.
  final Map<String, String> frequentCorrections;

  const AssistantMemory({
    required this.preferences,
    required this.notes,
    required this.frequentCorrections,
  });

  bool get isEmpty =>
      preferences.isEmpty && notes.isEmpty && frequentCorrections.isEmpty;

  /// Rendered into the system context at session start.
  String toContext() {
    final b = StringBuffer();
    if (preferences.isNotEmpty) {
      b.writeln('Stored preferences:');
      preferences.forEach((k, v) => b.writeln('- $k: $v'));
    }
    if (frequentCorrections.isNotEmpty) {
      b.writeln('Drug names this user frequently corrects '
          '(prefer the corrected form when structuring):');
      frequentCorrections.forEach((k, v) => b.writeln('- heard "$k" → $v'));
    }
    if (notes.isNotEmpty) {
      b.writeln('Memory notes (newest first):');
      for (final n in notes) {
        b.writeln('- [${n.topic}] ${n.text}');
      }
    }
    return b.toString();
  }
}

class MemoryService {
  final FirebaseFirestore _db;
  MemoryService(this._db);

  static MemoryService? _instance;
  static MemoryService get instance =>
      _instance ??= MemoryService(FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>> _root(String uid) =>
      _db.collection('aiMemory').doc(uid);

  Future<AssistantMemory> load(String uid) async {
    Map<String, String> preferences = {};
    final notes = <MemoryNote>[];
    final corrections = <String, String>{};

    try {
      final rootSnap = await _root(uid).get();
      final prefs = rootSnap.data()?['preferences'];
      if (prefs is Map) {
        preferences =
            prefs.map((k, v) => MapEntry(k.toString(), v.toString()));
      }

      final noteSnap = await _root(uid)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      for (final d in noteSnap.docs) {
        final m = d.data();
        notes.add(MemoryNote(
          id: d.id,
          text: m['text'] as String? ?? '',
          topic: m['topic'] as String? ?? 'general',
          createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        ));
      }

      // Learn from usage: this user's own correction events in the audit
      // trail (append-only, §3.4). counts term → most frequent correction.
      final auditSnap = await _db
          .collection('audit')
          .where('actor', isEqualTo: uid)
          .where('action', isEqualTo: 'corrected')
          .limit(200)
          .get();
      final counts = <String, Map<String, int>>{};
      for (final d in auditSnap.docs) {
        final m = d.data();
        final heard = (m['previousValue'] ?? '').toString().toLowerCase();
        final detail = (m['detail'] ?? '').toString();
        final to = detail.startsWith('corrected to ')
            ? detail.substring('corrected to '.length)
            : null;
        if (heard.isEmpty || to == null || to.isEmpty) continue;
        ((counts[heard] ??= {})[to] =
            (counts[heard]?[to] ?? 0) + 1);
      }
      counts.forEach((heard, tos) {
        final best = tos.entries.reduce((a, b) => a.value >= b.value ? a : b);
        if (best.value >= 2) {
          corrections[heard] = '${best.key} (×${best.value})';
        }
      });
    } catch (_) {
      // Offline or rules mismatch: the assistant works without memory.
    }

    return AssistantMemory(
        preferences: preferences,
        notes: notes,
        frequentCorrections: corrections);
  }

  Future<void> remember(String uid, String text, String topic) async {
    await _root(uid).collection('notes').add({
      'text': text,
      'topic': topic,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> setPreference(String uid, String key, String value) async {
    await _root(uid).set({
      'preferences': {key: value},
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
