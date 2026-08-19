/// Per-user AI preferences at aiMemory/{uid} (owner-only by the deployed
/// rules; deletable by the owner — §3.3). This app stores WORKFLOW
/// preferences only: interface language and how the person prefers to give
/// their description (voice vs typing). Nothing clinical is ever judged or
/// stored here.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMemoryService {
  final FirebaseFirestore _db;
  PatientMemoryService(this._db);

  static PatientMemoryService? _instance;
  static PatientMemoryService get instance =>
      _instance ??= PatientMemoryService(FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>> _root(String uid) =>
      _db.collection('aiMemory').doc(uid);

  Future<void> rememberPreferences(
    String uid, {
    String? language,
    String? inputHabit, // 'voice' | 'typed'
  }) async {
    try {
      await _root(uid).set({
        'preferences': {
          if (language != null) 'language': language,
          if (inputHabit != null) 'dictation': inputHabit,
        },
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or rules mismatch: preferences are a convenience, never a
      // dependency.
    }
  }

  Future<Map<String, String>> loadPreferences(String uid) async {
    try {
      final snap = await _root(uid).get();
      final prefs = snap.data()?['preferences'];
      if (prefs is Map) {
        return prefs.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return const {};
  }
}
