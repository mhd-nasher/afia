// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Afia Handover';

  @override
  String get chooseLanguage => 'Language · اللغة';

  @override
  String get chooseLanguageBody =>
      'Choose the language for this device. You can change it later in Account.';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get continueLabel => 'Continue';

  @override
  String get signInTitle => 'Sign in';

  @override
  String authError(String message) {
    return 'Could not sign in: $message';
  }

  @override
  String get notInvitedTitle => 'This email has no invitation';

  @override
  String get notInvitedBody =>
      'Your account exists but has no access. Access is granted by invitation from ward management — ask your ward manager to send an invitation to this email, then sign in again.';

  @override
  String get checkingInvitation => 'Checking your invitation…';

  @override
  String get tabPatients => 'Patients';

  @override
  String get tabReceived => 'Received';

  @override
  String get tabShift => 'Shift';

  @override
  String get tabAccount => 'Account';

  @override
  String get wardFallback => 'Ward';

  @override
  String listAt(String time) {
    return 'list $time';
  }

  @override
  String get notStarted => 'Not started';

  @override
  String get recordingLabel => 'Recording';

  @override
  String get draftReadyNotSigned => 'Draft ready · not signed';

  @override
  String get interrupted => 'Interrupted';

  @override
  String get signedQueued => 'Signed · queued to send';

  @override
  String get confirmedInSystem => 'Recorded in Afia';

  @override
  String get exportFailedRetry => 'Export failed · retry';

  @override
  String get retry => 'Retry';

  @override
  String get resume => 'Resume';

  @override
  String get noPatients => 'No patients on this ward yet.';

  @override
  String get noPatientsBody => 'Patients are added from the admin dashboard.';

  @override
  String get synced => 'Synced';

  @override
  String queuedCount(int n) {
    return '$n queued';
  }

  @override
  String get offlineSavedOnDevice => 'Offline · saved on device';

  @override
  String get offlineBannerTitle => 'No connection to the ward network';

  @override
  String get offlineBannerBody =>
      'Everything you record is saved on this device';

  @override
  String get patientTitle => 'Patient';

  @override
  String bed(String bed) {
    return 'Bed $bed';
  }

  @override
  String dob(String date) {
    return 'DOB $date';
  }

  @override
  String get admitted => 'Admitted';

  @override
  String get allergy => 'Allergy';

  @override
  String get activeMedications => 'Active medications';

  @override
  String get lastHandover => 'Last handover';

  @override
  String get noHandoverYet => 'No handover recorded yet for this patient.';

  @override
  String get recordHandover => 'Record handover';

  @override
  String get vitalsBp => 'BP';

  @override
  String get vitalsHr => 'HR';

  @override
  String get vitalsSpo2 => 'SpO₂';

  @override
  String get vitalsTemp => 'Temp';

  @override
  String get micPrimerTitle => 'Recording uses the microphone';

  @override
  String get micPrimerBody =>
      'Your voice is transcribed on this device and the original recording travels with the handover so the next nurse can hear you. Nothing is uploaded anywhere else.';

  @override
  String get micPrimerAllow => 'Allow microphone';

  @override
  String get micDenied =>
      'Microphone access is off. You can still type the handover, or allow the microphone in system settings.';

  @override
  String get typeInstead => 'Type instead';

  @override
  String get typeHandoverHint => 'Type what you would have said…';

  @override
  String get tapToStopHoldToPause => 'Tap to stop · hold to pause';

  @override
  String get paused => 'Paused · tap to continue';

  @override
  String get structuring => 'Organising into the template…';

  @override
  String structuredBy(String engine) {
    return 'Organised by $engine';
  }

  @override
  String get draftTitle => 'Draft';

  @override
  String get handoverTitle => 'Handover';

  @override
  String get draftBand => 'DRAFT — NOT SIGNED';

  @override
  String get producedBySystem => 'Produced by the system';

  @override
  String signedBand(String identity, String time) {
    return 'SIGNED — $identity · $time';
  }

  @override
  String get verifiedByHuman => 'Verified by a human';

  @override
  String get verified => 'Verified';

  @override
  String get replay => 'Replay';

  @override
  String recordedAt(String time) {
    return 'recorded $time';
  }

  @override
  String get sideNote => 'Side note';

  @override
  String notMentioned(String label) {
    return 'Not mentioned: $label';
  }

  @override
  String get addField => 'Add';

  @override
  String confirmChipsButton(int n) {
    return 'Confirm $n drugs & numbers';
  }

  @override
  String reviewChipsButton(int n) {
    return 'Review $n confirmed items';
  }

  @override
  String get signButton => 'Sign';

  @override
  String get flagsNeverBlock => 'Signing is never blocked by open flags';

  @override
  String get audioKeptOnDevice =>
      'Recording kept on the recording device — too large to sync.';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String chipCounter(int done, int total) {
    return '$done / $total';
  }

  @override
  String get drugHeard => 'Drug · heard in the recording';

  @override
  String get numberHeard => 'Number · heard in the recording';

  @override
  String get lowConfidence => 'Low confidence';

  @override
  String get highConfidence => 'High confidence';

  @override
  String get noFormularyMatch => 'No formulary match — confirm explicitly';

  @override
  String get soundAlike => 'Sound-alike';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get correctAction => 'Correct';

  @override
  String get stillToConfirm => 'Still to confirm';

  @override
  String get allConfirmed => 'Every item confirmed';

  @override
  String get noConfirmAll =>
      'Every item is confirmed on its own — there is no confirm-all';

  @override
  String correctedTo(String name) {
    return 'Corrected to $name';
  }

  @override
  String get correctDrugName => 'Correct drug name';

  @override
  String heardAs(String term) {
    return 'Heard as “$term”';
  }

  @override
  String get searchDrugName => 'Search drug name';

  @override
  String get soundsAlikeCheck => 'Sounds alike — check carefully';

  @override
  String get wardFormulary => 'Ward formulary';

  @override
  String get currentEntry => 'current entry';

  @override
  String get recognitionNotRecall =>
      'Pick from the formulary — spelling is never typed from memory';

  @override
  String get signingAs => 'Signing as';

  @override
  String openFlagsCount(int n) {
    return '$n open flags';
  }

  @override
  String get flagNotApplicable => 'Not applicable';

  @override
  String get flagAskedNoAnswer => 'Asked, no answer';

  @override
  String get flagWillAddLater => 'Will add later';

  @override
  String get flagEndOfShift => 'End of shift — handed to day team';

  @override
  String get holdToSign => 'Hold to sign';

  @override
  String get flagsTravelNote =>
      'Signing is never blocked by open flags — they travel with the handover';

  @override
  String get chooseFlagReason => 'Choose a reason for each open flag — one tap';

  @override
  String get receivedTitle => 'Received';

  @override
  String get receivedSubtitle => 'From the previous shift';

  @override
  String newCount(int n) {
    return '$n new';
  }

  @override
  String get newLabel => 'New';

  @override
  String get readLabel => 'Read';

  @override
  String get noIncoming => 'Nothing received yet.';

  @override
  String get noIncomingBody =>
      'Handovers signed by the previous shift will appear here.';

  @override
  String get tenSecondSummary => 'Ten-second summary';

  @override
  String get openFlagsSection => 'Open flags';

  @override
  String get whatChanged => 'Changed since the previous handover';

  @override
  String get diffAdded => 'Added';

  @override
  String get diffChanged => 'Changed';

  @override
  String get diffNowEmpty => 'Now empty';

  @override
  String get playOriginal => 'Play original recording';

  @override
  String get stopPlayback => 'Stop';

  @override
  String get audioUnavailable =>
      'The recording stayed on the recording device (too large to sync). The transcript and fields below are complete.';

  @override
  String get acknowledgeRead => 'Acknowledge';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get fhirReady => 'FHIR-ready record';

  @override
  String get fhirNote =>
      'Valid FHIR DocumentReference JSON, generated on demand and displayed here. Nothing is sent anywhere — this build is FHIR-ready, not integrated.';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get copyText => 'Copy as text';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get shiftBoardTitle => 'Shift board';

  @override
  String get recordedStat => 'recorded';

  @override
  String get signedStat => 'signed';

  @override
  String get confirmedStat => 'recorded in Afia';

  @override
  String get patientCol => 'Patient';

  @override
  String get signedCol => 'Signed';

  @override
  String get inSystemCol => 'Recorded';

  @override
  String get yes => 'Yes';

  @override
  String get queuedLabel => 'Queued';

  @override
  String get failedLabel => 'Failed';

  @override
  String get receipt => 'Receipt';

  @override
  String get acceptedBy => 'Recorded in Afia — server acknowledgement';

  @override
  String ackRef(String time, String ref) {
    return '$time · ref $ref';
  }

  @override
  String get notReachedBanner => 'One handover is not yet recorded in Afia';

  @override
  String notReachedBannerMany(int n) {
    return '$n handovers are not yet recorded in Afia';
  }

  @override
  String lastTried(String bed, String time) {
    return 'Bed $bed · last tried $time';
  }

  @override
  String get safeOnDevice => 'it is safe on this device';

  @override
  String get endShift => 'End shift';

  @override
  String shiftCompleteTitle(String n) {
    return '$n patients handed over.';
  }

  @override
  String get shiftCompleteBody => 'Everything is signed and the ward has it.';

  @override
  String get handedOverStat => 'handed over';

  @override
  String get itemsConfirmedStat => 'items confirmed';

  @override
  String get leftUnsentStat => 'left unsent';

  @override
  String get howWasIt => 'How was it? — optional';

  @override
  String get moodSteady => 'Steady';

  @override
  String get moodHeavy => 'Heavy';

  @override
  String get moodShortStaffed => 'Short-staffed';

  @override
  String get moodGoodShift => 'Good shift';

  @override
  String get goRest => 'Go rest.';

  @override
  String get accountTitle => 'Account';

  @override
  String get yourSignature => 'Your signature';

  @override
  String get signatureLockNote =>
      'This appears on every handover you sign. It cannot be edited on the device.';

  @override
  String get wardRow => 'Ward';

  @override
  String get templateRow => 'Template';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeDay => 'Day';

  @override
  String get themeNight => 'Night';

  @override
  String get languageRow => 'Language';

  @override
  String get viewTemplateRow => 'Handover template';

  @override
  String get signOut => 'Sign out';

  @override
  String get sharedDeviceNote =>
      'This device is shared — sign out at the end of your shift';

  @override
  String get signOutConfirmTitle => 'Sign out of this device?';

  @override
  String get signOutConfirmBody =>
      'The next nurse signs in with their own number. Unsynced work stays safely on this device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get syncErrorTitle => 'Could not sync';

  @override
  String get syncErrorBody =>
      'Changes are saved on this device and will sync when the connection returns.';

  @override
  String get templateTitle => 'Handover template';

  @override
  String get templateSubtitle => 'Applies to every handover on this ward';

  @override
  String get fieldsSection => 'Fields · editing lives in the dashboard';

  @override
  String get requiredLabel => 'Required · prompts while recording';

  @override
  String get optionalLabel => 'Optional';

  @override
  String templateEditedBy(String name) {
    return 'Edited by $name';
  }

  @override
  String get templateRoleGate =>
      'The template is visible to charge nurses and managers.';

  @override
  String get amendHandover => 'Amend — invalidates the signature';

  @override
  String get amendNote =>
      'Amending creates a new unsigned version. The original and its signature are kept. Every drug and number must be confirmed again.';

  @override
  String versionLabel(int n) {
    return 'v$n';
  }

  @override
  String get supersededBy => 'Superseded by a later version';

  @override
  String get fieldSituation => 'Situation';

  @override
  String get fieldBackground => 'Background';

  @override
  String get fieldMedications => 'Medications given';

  @override
  String get fieldVitals => 'Latest vitals';

  @override
  String get fieldPain => 'Pain';

  @override
  String get fieldMobility => 'Mobility & falls';

  @override
  String get fieldDiet => 'Diet & fluids';

  @override
  String get fieldPlan => 'Plan for next shift';

  @override
  String get fieldFamily => 'Family communication';

  @override
  String get errorGeneric =>
      'Something went wrong. Your work is saved on this device.';

  @override
  String get loading => 'Loading…';

  @override
  String get assistantTitle => 'Afia Assistant';

  @override
  String get assistantIntro =>
      'I reorganise what the care team has recorded — ten-second summaries, what changed, structuring a dictation, finding recorded details. Clinical judgement stays with you.';

  @override
  String get assistantHint => 'Ask about recorded information…';

  @override
  String get assistantSend => 'Send';

  @override
  String get assistantThinking => 'Working…';

  @override
  String get assistantMemoryNote =>
      'Remembers your preferences · stored privately to your account';

  @override
  String get smsRegionBlocked =>
      'SMS to this country is currently blocked by the project\'s SMS region policy / daily quota. For testing: add your number as a TEST phone number in Firebase console (Authentication → Sign-in method → Phone → Phone numbers for testing) and sign in with its fixed code — no SMS needed. For real SMS: enable the country in Authentication → Settings → SMS region policy, and add billing.\n\nإرسال الرسائل لهذه الدولة محجوب حاليًا بسياسة مناطق الرسائل / الحصة اليومية للمشروع. للتجربة: أضف رقمك كرقم اختبار في وحدة تحكم Firebase (Authentication ← Sign-in method ← Phone ← Phone numbers for testing) وادخل بالكود الثابت — بدون رسائل. للرسائل الحقيقية: فعّل الدولة من Authentication ← Settings ← SMS region policy وأضف الفوترة.';

  @override
  String get emailEntryBody =>
      'Accounts are created by ward management. Sign in with the email your invitation was sent to.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get createAccountAction => 'Create account';

  @override
  String get createAccountSwitch => 'New here? Create an account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we will send a password reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String resetSent(String email) {
    return 'Reset link sent to $email. Check your inbox.';
  }

  @override
  String get authBadCredentials => 'Email or password is incorrect.';

  @override
  String get authEmailInUse =>
      'An account with this email already exists — sign in instead.';

  @override
  String get authWeakPassword => 'Password must be at least 8 characters.';

  @override
  String get authPasswordMismatch => 'Passwords do not match.';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authNetwork =>
      'No connection — try again when you are back online.';

  @override
  String get authTooManyRequests =>
      'Too many attempts — wait a moment and try again.';
}
