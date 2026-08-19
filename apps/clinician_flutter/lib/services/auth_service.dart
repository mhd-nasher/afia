/// Sign-in = PHONE NUMBER + OTP ONLY (HANDOFF §5/§11: no email, no password,
/// no self-registration anywhere). Registration happens from the admin
/// dashboard via INVITATIONS only: the first OTP sign-in claims
/// invitations/{phoneE164}, creating practitioners/{uid} with the invited
/// identity. signatureIdentity is copied once and is immutable (§2.5 — the
/// rules enforce it; this app never renders an editor for it).
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

  /// Starts the firebase_auth phone flow. Callbacks mirror verifyPhoneNumber.
  Future<void> startPhoneSignIn({
    required String phoneE164,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function() onAutoSignedIn,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-retrieval — signs in without typing the code.
        try {
          await _auth.signInWithCredential(credential);
          onAutoSignedIn();
        } on FirebaseAuthException catch (e) {
          onFailed(e);
        }
      },
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> confirmOtp(
      String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(credential);
  }

  /// The invitation contract (§5 + firestore.rules):
  /// - invitations/{phone} exists, claimedBy == null → create
  ///   practitioners/{uid} copying {name, role, signatureIdentity, invitedBy}
  ///   plus externalIdentifier: null, createdAt, fhirResource — then update
  ///   the invitation setting ONLY claimedBy (the rules forbid touching any
  ///   other field).
  /// - claimedBy == uid already → proceed (recreate the practitioner doc if
  ///   it is somehow missing).
  /// - anything else → not invited. No registration path exists.
  Future<ClaimOutcome> ensurePractitioner(User user) async {
    final uid = user.uid;
    final existing = await _db.collection('practitioners').doc(uid).get();
    if (existing.exists) {
      await Repo.instance.recordSignEvent(uid, 'sign_in', 'clinician app');
      return ClaimOutcome.practitionerReady;
    }

    final phone = user.phoneNumber;
    if (phone == null || phone.isEmpty) return ClaimOutcome.notInvited;

    final invitationRef = _db.collection('invitations').doc(phone);
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
      detail: 'practitioner created from invitation $phone',
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
