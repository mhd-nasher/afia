/// Sign-in = EMAIL + PASSWORD ONLY (D-012 / RULES W7 — phone/OTP does not
/// exist in this product). Creating an email account grants NO access:
/// access exists by invitation only. The first sign-in claims
/// invitations/{lowercase-email}, creating practitioners/{uid} with the
/// invited identity. signatureIdentity is copied once and is immutable
/// (§2.5 — the rules enforce it; this app never renders an editor for it).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entities.dart';
import 'repo.dart';

enum ClaimOutcome { practitionerReady, notInvited }

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AuthService(this._auth, this._db);

  static AuthService? _instance;
  static AuthService get instance =>
      _instance ??= AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password);

  /// Creates the AUTH account only — access still requires an invitation
  /// (D-012). The invitation gate runs in [ensurePractitioner].
  Future<UserCredential> createAccount(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  /// The invitation contract (D-012 + firestore.rules):
  /// - invitations/{lowercase(email)} exists, claimedBy == null → create
  ///   practitioners/{uid} copying {name, role, signatureIdentity, invitedBy}
  ///   plus externalIdentifier: null, createdAt, fhirResource — then update
  ///   the invitation setting ONLY claimedBy (the rules forbid touching any
  ///   other field).
  /// - claimedBy == uid already → proceed (recreate the practitioner doc if
  ///   it is somehow missing).
  /// - anything else → not invited: the auth account exists but has NO
  ///   access, and no path in this app can grant it.
  Future<ClaimOutcome> ensurePractitioner(User user) async {
    final uid = user.uid;
    final existing = await _db.collection('practitioners').doc(uid).get();
    if (existing.exists) {
      await Repo.instance.recordSignEvent(uid, 'sign_in', 'clinician app');
      return ClaimOutcome.practitionerReady;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return ClaimOutcome.notInvited;

    final invitationRef = _db.collection('invitations').doc(email);
    final snapshot = await invitationRef.get();
    if (!snapshot.exists) return ClaimOutcome.notInvited;

    final invitation = Invitation.fromMap(snapshot.data()!);
    if (invitation.claimedBy != null && invitation.claimedBy != uid) {
      return ClaimOutcome.notInvited; // claimed by someone else
    }

    final practitioner = Practitioner(
      id: uid,
      externalIdentifier: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      name: invitation.name,
      role: PractitionerRoleWire.parse(invitation.role),
      signatureIdentity: invitation.signatureIdentity,
      invitedBy: invitation.invitedBy,
    );
    await _db.collection('practitioners').doc(uid).set(practitioner.toMap());

    if (invitation.claimedBy == null) {
      // ONLY claimedBy — the rules reject any write touching identity fields.
      await invitationRef.update({'claimedBy': uid});
    }

    await Repo.instance.recordSignEvent(uid, 'sign_in', 'clinician app');
    await Repo.instance.appendAudit(
      actor: uid,
      action: 'created',
      entityId: uid,
      detail: 'practitioner created from invitation $email',
    );
    return ClaimOutcome.practitionerReady;
  }

  Future<Practitioner?> currentPractitioner() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final d = await _db.collection('practitioners').doc(uid).get();
    return d.data() == null ? null : Practitioner.fromMap(d.data()!);
  }

  Future<void> signOut(String? practitionerId) async {
    if (practitionerId != null) {
      try {
        await Repo.instance
            .recordSignEvent(practitionerId, 'sign_out', 'clinician app');
      } catch (_) {
        // Offline sign-out still signs out; the event syncs when it can.
      }
    }
    await _auth.signOut();
  }
}
