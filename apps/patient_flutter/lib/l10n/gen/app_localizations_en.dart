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
  String get entryTitle => 'Tell the nursing team how you are';

  @override
  String get entryBody1 =>
      'You answer a few questions and describe how you feel, in your own words. What you send goes to the nursing team for a nurse to read.';

  @override
  String get entryBody2 =>
      'It takes a few minutes. You can stop at any point — nothing you enter is lost.';

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
  String get entryAgreeHint =>
      'To continue, please agree to both statements above.';

  @override
  String get resumeTitle => 'Welcome back';

  @override
  String get resumeBody =>
      'You have an unfinished description. Your answers are saved on this phone — you can continue where you left off.';

  @override
  String get resumeContinue => 'Continue where you left off';

  @override
  String get startOver => 'Start again from the beginning';

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
  String get authTitle => 'Sign in to send';

  @override
  String get authLead =>
      'Your answers are ready. To send them to the nursing team, sign in or create an account. Everything stays saved on this phone while you do.';

  @override
  String get authPhone => 'Use my phone number';

  @override
  String get authEmail => 'Use my email';

  @override
  String get phoneEntryTitle => 'Your phone number';

  @override
  String get phoneHint => '3300 0000';

  @override
  String get sendCode => 'Send me a code';

  @override
  String get phoneInvalid =>
      'That phone number does not look complete. Please check it.';

  @override
  String get phoneAuthUnavailable =>
      'Phone sign-in is not available right now. You can use email instead.';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSentTo(String phone) {
    return 'We sent a code to $phone';
  }

  @override
  String get otpInvalid => 'That code did not match. Please try again.';

  @override
  String get verifying => 'Checking…';

  @override
  String resendIn(int seconds) {
    return 'You can resend in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend code';

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
  String get statusTitle => 'What you have sent';

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
  String get yourAccount => 'Your account';

  @override
  String get offlineStrip => 'Offline — your answers save on this phone';

  @override
  String get statusCaseGoneTitle => 'Your case is no longer available';

  @override
  String get statusCaseGoneBody =>
      'Your saved case is no longer available. You can start again.';

  @override
  String get startAgain => 'Start again';

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
}
