// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get emergencyLabel => 'Emergency';

  @override
  String get conditionChanged => 'My condition has changed';

  @override
  String callNurseLine(String number) {
    return 'Nurse line — call $number';
  }

  @override
  String get entryNameLabel => 'Your first name (first name is enough)';

  @override
  String get entryTerms => 'I agree to the terms of use';

  @override
  String get entryConsent =>
      'I agree that my answers are shared with the nursing team';

  @override
  String get continueLabel => 'Continue';

  @override
  String get resumeContinue => 'Continue where you left off';

  @override
  String get safetyQuestionsEyebrow => 'Safety questions';

  @override
  String get safetyQuestionsRepeatEyebrow =>
      'Safety questions — asked again, to be safe';

  @override
  String get answerYes => 'Yes';

  @override
  String get answerNo => 'No';

  @override
  String get answerDontKnow => 'I don\'t know';

  @override
  String interruptTitle(String number) {
    return 'Call $number now';
  }

  @override
  String interruptLeadAnswer(String number) {
    return 'Based on your answer, call $number now or ask someone near you to call.';
  }

  @override
  String interruptLeadFixture(String number) {
    return 'If this is an emergency, call $number now or ask someone near you to call.';
  }

  @override
  String callEmergency(String number) {
    return 'Call $number';
  }

  @override
  String callAdviceLine(String emergency, String advice) {
    return 'If you cannot call $emergency, call $advice';
  }

  @override
  String get interruptMistake =>
      'If you tapped Yes by mistake you can go back — your answer stays recorded.';

  @override
  String get goBack => 'Go back';

  @override
  String get whoTitle => 'Who is filling this in?';

  @override
  String get whoSelf => 'Myself';

  @override
  String get whoCarer => 'I\'m helping someone else';

  @override
  String get voiceEyebrow => 'In your own words';

  @override
  String get voiceTitle => 'Describe how you feel';

  @override
  String get voiceLead =>
      'Talk the way you would to a nurse. There are no wrong words.';

  @override
  String get startTalking => 'Start talking';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get recordAgain => 'Record again';

  @override
  String get listeningHint => 'Listening — speak naturally, take your time.';

  @override
  String get typeInstead => 'Type instead if talking is hard right now';

  @override
  String get speechUnavailable =>
      'Voice-to-text is not available right now. Your voice can still be recorded, and typing below works just as well.';

  @override
  String get playRecording => 'Play your recording';

  @override
  String get stopPlayback => 'Stop playing';

  @override
  String get micPrimerTitle => 'Using your voice';

  @override
  String get micPrimerBody =>
      'Next, your phone will ask permission to use the microphone. Afia records your voice and turns it into text on this screen, so you can check it before anything is sent. Talking is optional — typing always works.';

  @override
  String get micPrimerOk => 'OK, ask me';

  @override
  String get micPrimerSkip => 'I\'ll type instead';

  @override
  String get functionalEyebrow => 'Compared with your normal';

  @override
  String get fnSame => 'About the same as normal';

  @override
  String get fnWorse => 'Worse than normal';

  @override
  String get fnMuchWorse => 'Much worse than normal';

  @override
  String get reviewTitle => 'Check what you are sending';

  @override
  String get reviewLead =>
      'This is everything you entered. Anything you did not answer is shown as \"Not answered\". You can change any answer, or send it as it is.';

  @override
  String get reviewSafetyHeading => 'Safety questions';

  @override
  String get reviewWhoHeading => 'Who filled this in';

  @override
  String get reviewDescriptionHeading => 'Your description';

  @override
  String get reviewFunctionalHeading => 'Compared with your normal';

  @override
  String get notAnswered => 'Not answered';

  @override
  String get voiceIncluded => 'Voice recording included';

  @override
  String get edit => 'Edit';

  @override
  String notMentioned(String item) {
    return 'Not mentioned: $item';
  }

  @override
  String get notMentionedDescription => 'your description';

  @override
  String get sendToTeam => 'Send to the nursing team';

  @override
  String get tidyAction => 'Tidy up my words';

  @override
  String get tidySheetTitle => 'A tidier version of your words';

  @override
  String get tidySheetNote =>
      'Machine-made from your own words and unverified — nothing was added. Use it only if it reads right to you.';

  @override
  String get tidyOfflineNote => 'Tidied on this phone, without the internet.';

  @override
  String get tidyUse => 'Use this version';

  @override
  String get tidyKeep => 'Keep my version';

  @override
  String get tidyWorking => 'Tidying your words…';

  @override
  String get translateToArabic => 'Show in Arabic';

  @override
  String get translateToEnglish => 'Show in English';

  @override
  String get aiUnavailable =>
      'Not available right now — your own words stay exactly as they are.';

  @override
  String get emailSignInTitle => 'Sign in with email';

  @override
  String get emailRegisterTitle => 'Create your account';

  @override
  String get emailLabel => 'Your email';

  @override
  String get passwordLabel => 'Your password';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get forgotPassword => 'I forgot my password';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetLead => 'Enter your email and we will send you a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetSent => 'Sent. Check your email for the reset link.';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get noAccount => 'I don\'t have an account yet';

  @override
  String authError(String detail) {
    return 'Something went wrong: $detail';
  }

  @override
  String get emailInvalid => 'That email does not look right. Please check it.';

  @override
  String get passwordTooShort => 'Please use at least 8 characters.';

  @override
  String get emailInUse =>
      'There is already an account with this email. Try signing in.';

  @override
  String get wrongPassword => 'That email and password did not match.';

  @override
  String get backLabel => 'Back';

  @override
  String get caseRefLabel => 'Your case reference:';

  @override
  String get updateInitial => 'Your answers and description';

  @override
  String get updateConditionChanged => 'Condition update';

  @override
  String get syncSent => 'Sent to the nursing team';

  @override
  String get syncQueued =>
      'Saved on this phone. NOT yet sent — it will send when you\'re back online. The nursing team has NOT seen it.';

  @override
  String get mandatoryStatusCopy =>
      'No one is watching your condition continuously. If things get worse, use the button below, call the nurse line, or call emergency services.';

  @override
  String get statusChangeHint =>
      'If anything changes, tap \"My condition has changed\" below. Your update joins this same case — you never start again.';

  @override
  String get offlineStrip => 'Offline — your answers save on this phone';

  @override
  String get statusCaseGoneTitle => 'Your case is no longer available';

  @override
  String get statusCaseGoneBody =>
      'Your saved case is no longer available. You can start again.';

  @override
  String get updateEyebrow => 'Your update';

  @override
  String get updateTitle => 'What has changed since last time?';

  @override
  String get updateLead => 'Talk or type — whichever is easier right now.';

  @override
  String get addToCase => 'Add this to my case';

  @override
  String get updateAddedTitle => 'Update added';

  @override
  String get updateAddedBody =>
      'Your update was added to your existing case. You have not lost your place, and you do not need to start again.';

  @override
  String caseRefStill(String ref) {
    return 'Your case reference is still $ref.';
  }

  @override
  String get backToCase => 'Back to your case';

  @override
  String get accountTitle => 'Your account';

  @override
  String get accountName => 'Name';

  @override
  String get accountContact => 'Contact';

  @override
  String get accountLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutNote =>
      'Signing out clears what is saved on this phone. What you already sent stays with the nursing team.';

  @override
  String get deleteMyData => 'Delete my data';

  @override
  String get deleteConfirmTitle => 'Delete your data?';

  @override
  String get deleteConfirmBody =>
      'This deletes your account and your saved preferences, withdraws your sharing consent, and removes everything saved on this phone. What you already sent stays with the nursing team so your care is not interrupted.';

  @override
  String get deleteConfirmYes => 'Delete my data';

  @override
  String get cancel => 'Cancel';

  @override
  String get languageChoiceTitle => 'اللغة · Language';

  @override
  String get chooseEnglish => 'Continue in English';

  @override
  String get chooseArabic => 'المتابعة بالعربية';

  @override
  String get errorGeneric =>
      'Something went wrong. Your answers are still saved on this phone.';

  @override
  String get loading => 'Loading…';

  @override
  String get smsRegionBlocked =>
      'SMS to this country is currently blocked by the project\'s SMS region policy / daily quota. For testing: add your number as a TEST phone number in Firebase console (Authentication → Sign-in method → Phone → Phone numbers for testing) and sign in with its fixed code — no SMS needed. For real SMS: enable the country in Authentication → Settings → SMS region policy, and add billing.\n\nإرسال الرسائل لهذه الدولة محجوب حاليًا بسياسة مناطق الرسائل / الحصة اليومية للمشروع. للتجربة: أضف رقمك كرقم اختبار في وحدة تحكم Firebase (Authentication ← Sign-in method ← Phone ← Phone numbers for testing) وادخل بالكود الثابت — بدون رسائل. للرسائل الحقيقية: فعّل الدولة من Authentication ← Settings ← SMS region policy وأضف الفوترة.';

  @override
  String get welcomeTitle => 'Tell the nursing team how you are';

  @override
  String get welcomeBody =>
      'You describe how you feel, from home, and a nurse reads it. Create an account so the team knows who is writing, or sign in if you already have one.';

  @override
  String get registerLead =>
      'One email and one password — that is all you need.';

  @override
  String get profileTitle => 'What is your name?';

  @override
  String get profileLead =>
      'Your first name is enough. The nursing team sees it with what you send.';

  @override
  String get profileHint =>
      'To continue, write your name and agree to the terms.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabReports => 'My reports';

  @override
  String get tabAccount => 'Account';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeGreetingNoName => 'Hello';

  @override
  String get homeLead =>
      'This is your place to tell the nursing team how you are.';

  @override
  String get reportAction => 'Report my condition';

  @override
  String get resumeCardTitle => 'Finish your report';

  @override
  String get resumeCardBody =>
      'Your report is saved on this phone. You can continue from where you stopped.';

  @override
  String get discardDraft => 'Delete the draft and start over';

  @override
  String get activeCardTitle => 'Your current report';

  @override
  String get viewDetails => 'View details';

  @override
  String reportRowUpdates(int count) {
    return 'Updates: $count';
  }

  @override
  String get helpCardTitle => 'If you need help now';

  @override
  String emergencyInfoLine(String number) {
    return 'For an emergency, call $number or use the Emergency button at the top of the screen.';
  }

  @override
  String get reportsEmptyTitle => 'No reports yet';

  @override
  String get reportsEmptyBody => 'Start from Home — tap “Report my condition”.';

  @override
  String get detailTitle => 'Your report';

  @override
  String get syncSentShort => 'Sent to the nursing team';

  @override
  String get syncQueuedShort => 'Saved on this phone — not sent yet';

  @override
  String get activeGateTitle => 'You already have an open report';

  @override
  String get activeGateBody =>
      'The nursing team already has your report. Anything new joins the SAME report as an update — you never start again and nothing is lost.';

  @override
  String get activeGateUpdate => 'Add an update to my report';

  @override
  String get activeGateNewLead =>
      'Is this a completely different, new situation?';

  @override
  String get activeGateNew => 'Start a separate new report';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get accountEmail => 'Email';

  @override
  String get consentHint =>
      'To send, please agree to share your answers with the nursing team.';
}
