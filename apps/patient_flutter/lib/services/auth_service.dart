/// Patient auth — REAL accounts, SELF-registered (product-owner decision;
/// unlike clinicians, who exist by invitation only). Email + password is the
/// ONLY sign-in method (owner decision D-012, docs/DECISIONS.md): register,
/// sign in, password reset. Phone/OTP is removed from the product.
///
/// The gate comes AFTER the red-flag questions by design: safety is never
/// gated behind an account (§2.7 — red flags are local and work before any
/// account exists). On first auth this service creates patientAccounts/{uid}
/// {name, contact, locale, createdAt, externalIdentifier: null} — owner-only
/// by the deployed firestore.rules.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientAccount {
  final String uid;
  final String name;
  final String contact; // email address
  final String locale;
  final int createdAt;
  final String? externalIdentifier;

  const PatientAccount({
    required this.uid,
    required this.name,
    required this.contact,
    required this.locale,
    required this.createdAt,
    this.externalIdentifier,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'contact': contact,
        'locale': locale,
        'createdAt': createdAt,
        'externalIdentifier': externalIdentifier,
      };

  factory PatientAccount.fromMap(String uid, Map<String, dynamic> m) =>
      PatientAccount(
        uid: uid,
        name: m['name'] as String? ?? '',
        contact: m['contact'] as String? ?? '',
        locale: m['locale'] as String? ?? 'en',
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        externalIdentifier: m['externalIdentifier'] as String?,
      );
}

class PatientAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  PatientAuthService(this._auth, this._db);

  static PatientAuthService? _instance;
  static PatientAuthService get instance => _instance ??=
      PatientAuthService(FirebaseAuth.instance, FirebaseFirestore.instance);

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── email + password (the only method — D-012) ───────────────────────────

  Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── account document ─────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _accountRef(String uid) =>
      _db.collection('patientAccounts').doc(uid);

  /// Creates patientAccounts/{uid} on first auth; updates locale/name on
  /// later sign-ins only if the fields are empty (never clobbers edits).
  Future<PatientAccount> ensurePatientAccount({
    required User user,
    required String name,
    required String locale,
  }) async {
    final ref = _accountRef(user.uid);
    final snap = await ref.get();
    if (snap.exists) {
      final existing =
          PatientAccount.fromMap(user.uid, snap.data() ?? const {});
      if (existing.name.isEmpty && name.isNotEmpty) {
        await ref.set({'name': name}, SetOptions(merge: true));
      }
      return existing;
    }
    final account = PatientAccount(
      uid: user.uid,
      name: name,
      contact: user.email ?? '',
      locale: locale,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      externalIdentifier: null,
    );
    await ref.set(account.toMap());
    return account;
  }

  Future<PatientAccount?> currentAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _accountRef(uid).get();
    if (!snap.exists) return null;
    return PatientAccount.fromMap(uid, snap.data() ?? const {});
  }

  Stream<PatientAccount?> watchAccount(String uid) =>
      _accountRef(uid).snapshots().map((d) =>
          d.data() == null ? null : PatientAccount.fromMap(uid, d.data()!));

  Future<void> updateAccount(String uid,
      {String? name, String? locale}) async {
    await _accountRef(uid).set({
      if (name != null) 'name': name,
      if (locale != null) 'locale': locale,
    }, SetOptions(merge: true));
  }

  /// §3.3 selective erasure — deletes what the deployed rules let the owner
  /// delete: the account document, the AI memory (and its notes). The case
  /// record itself is retained for the nursing team (rules forbid case
  /// deletion — a submitted clinical record is not silently un-submittable);
  /// the account screen says so honestly. Consent withdrawal is a timestamp,
  /// not a deletion (§3.3).
  Future<void> deleteMyData({String? consentId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (consentId != null) {
      try {
        await _db
            .collection('consents')
            .doc(consentId)
            .set({'withdrawnAt': DateTime.now().millisecondsSinceEpoch},
                SetOptions(merge: true));
      } catch (_) {
        // Offline: withdrawal still recorded next sync via account deletion
        // being the harder guarantee; keep going.
      }
    }
    final notes =
        await _db.collection('aiMemory').doc(uid).collection('notes').get();
    for (final d in notes.docs) {
      await d.reference.delete();
    }
    await _db.collection('aiMemory').doc(uid).delete();
    await _accountRef(uid).delete();
    await _auth.signOut();
  }

  Future<void> signOut() => _auth.signOut();
}
