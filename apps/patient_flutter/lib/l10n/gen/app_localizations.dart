import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @emergencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyLabel;

  /// No description provided for @conditionChanged.
  ///
  /// In en, this message translates to:
  /// **'My condition has changed'**
  String get conditionChanged;

  /// No description provided for @callNurseLine.
  ///
  /// In en, this message translates to:
  /// **'Nurse line — call {number}'**
  String callNurseLine(String number);

  /// No description provided for @entryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your first name (first name is enough)'**
  String get entryNameLabel;

  /// No description provided for @entryTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms of use'**
  String get entryTerms;

  /// No description provided for @entryConsent.
  ///
  /// In en, this message translates to:
  /// **'I agree that my answers are shared with the nursing team'**
  String get entryConsent;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @resumeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get resumeContinue;

  /// No description provided for @safetyQuestionsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Safety questions'**
  String get safetyQuestionsEyebrow;

  /// No description provided for @safetyQuestionsRepeatEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Safety questions — asked again, to be safe'**
  String get safetyQuestionsRepeatEyebrow;

  /// No description provided for @answerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get answerYes;

  /// No description provided for @answerNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get answerNo;

  /// No description provided for @answerDontKnow.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know'**
  String get answerDontKnow;

  /// No description provided for @interruptTitle.
  ///
  /// In en, this message translates to:
  /// **'Call {number} now'**
  String interruptTitle(String number);

  /// No description provided for @interruptLeadAnswer.
  ///
  /// In en, this message translates to:
  /// **'Based on your answer, call {number} now or ask someone near you to call.'**
  String interruptLeadAnswer(String number);

  /// No description provided for @interruptLeadFixture.
  ///
  /// In en, this message translates to:
  /// **'If this is an emergency, call {number} now or ask someone near you to call.'**
  String interruptLeadFixture(String number);

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callEmergency(String number);

  /// No description provided for @callAdviceLine.
  ///
  /// In en, this message translates to:
  /// **'If you cannot call {emergency}, call {advice}'**
  String callAdviceLine(String emergency, String advice);

  /// No description provided for @interruptMistake.
  ///
  /// In en, this message translates to:
  /// **'If you tapped Yes by mistake you can go back — your answer stays recorded.'**
  String get interruptMistake;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @whoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is filling this in?'**
  String get whoTitle;

  /// No description provided for @whoSelf.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get whoSelf;

  /// No description provided for @whoCarer.
  ///
  /// In en, this message translates to:
  /// **'I\'m helping someone else'**
  String get whoCarer;

  /// No description provided for @voiceEyebrow.
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get voiceEyebrow;

  /// No description provided for @voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Describe how you feel'**
  String get voiceTitle;

  /// No description provided for @voiceLead.
  ///
  /// In en, this message translates to:
  /// **'Talk the way you would to a nurse. There are no wrong words.'**
  String get voiceLead;

  /// No description provided for @startTalking.
  ///
  /// In en, this message translates to:
  /// **'Start talking'**
  String get startTalking;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @listeningHint.
  ///
  /// In en, this message translates to:
  /// **'Listening — speak naturally, take your time.'**
  String get listeningHint;

  /// No description provided for @typeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead if talking is hard right now'**
  String get typeInstead;

  /// No description provided for @speechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice-to-text is not available right now. Your voice can still be recorded, and typing below works just as well.'**
  String get speechUnavailable;

  /// No description provided for @playRecording.
  ///
  /// In en, this message translates to:
  /// **'Play your recording'**
  String get playRecording;

  /// No description provided for @stopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stop playing'**
  String get stopPlayback;

  /// No description provided for @micPrimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Using your voice'**
  String get micPrimerTitle;

  /// No description provided for @micPrimerBody.
  ///
  /// In en, this message translates to:
  /// **'Next, your phone will ask permission to use the microphone. Afia records your voice and turns it into text on this screen, so you can check it before anything is sent. Talking is optional — typing always works.'**
  String get micPrimerBody;

  /// No description provided for @micPrimerOk.
  ///
  /// In en, this message translates to:
  /// **'OK, ask me'**
  String get micPrimerOk;

  /// No description provided for @micPrimerSkip.
  ///
  /// In en, this message translates to:
  /// **'I\'ll type instead'**
  String get micPrimerSkip;

  /// No description provided for @functionalEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Compared with your normal'**
  String get functionalEyebrow;

  /// No description provided for @fnSame.
  ///
  /// In en, this message translates to:
  /// **'About the same as normal'**
  String get fnSame;

  /// No description provided for @fnWorse.
  ///
  /// In en, this message translates to:
  /// **'Worse than normal'**
  String get fnWorse;

  /// No description provided for @fnMuchWorse.
  ///
  /// In en, this message translates to:
  /// **'Much worse than normal'**
  String get fnMuchWorse;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check what you are sending'**
  String get reviewTitle;

  /// No description provided for @reviewLead.
  ///
  /// In en, this message translates to:
  /// **'This is everything you entered. Anything you did not answer is shown as \"Not answered\". You can change any answer, or send it as it is.'**
  String get reviewLead;

  /// No description provided for @reviewSafetyHeading.
  ///
  /// In en, this message translates to:
  /// **'Safety questions'**
  String get reviewSafetyHeading;

  /// No description provided for @reviewWhoHeading.
  ///
  /// In en, this message translates to:
  /// **'Who filled this in'**
  String get reviewWhoHeading;

  /// No description provided for @reviewDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'Your description'**
  String get reviewDescriptionHeading;

  /// No description provided for @reviewFunctionalHeading.
  ///
  /// In en, this message translates to:
  /// **'Compared with your normal'**
  String get reviewFunctionalHeading;

  /// No description provided for @notAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get notAnswered;

  /// No description provided for @voiceIncluded.
  ///
  /// In en, this message translates to:
  /// **'Voice recording included'**
  String get voiceIncluded;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @notMentioned.
  ///
  /// In en, this message translates to:
  /// **'Not mentioned: {item}'**
  String notMentioned(String item);

  /// No description provided for @notMentionedDescription.
  ///
  /// In en, this message translates to:
  /// **'your description'**
  String get notMentionedDescription;

  /// No description provided for @sendToTeam.
  ///
  /// In en, this message translates to:
  /// **'Send to the nursing team'**
  String get sendToTeam;

  /// No description provided for @tidyAction.
  ///
  /// In en, this message translates to:
  /// **'Tidy up my words'**
  String get tidyAction;

  /// No description provided for @tidySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'A tidier version of your words'**
  String get tidySheetTitle;

  /// No description provided for @tidySheetNote.
  ///
  /// In en, this message translates to:
  /// **'Machine-made from your own words and unverified — nothing was added. Use it only if it reads right to you.'**
  String get tidySheetNote;

  /// No description provided for @tidyOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Tidied on this phone, without the internet.'**
  String get tidyOfflineNote;

  /// No description provided for @tidyUse.
  ///
  /// In en, this message translates to:
  /// **'Use this version'**
  String get tidyUse;

  /// No description provided for @tidyKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my version'**
  String get tidyKeep;

  /// No description provided for @tidyWorking.
  ///
  /// In en, this message translates to:
  /// **'Tidying your words…'**
  String get tidyWorking;

  /// No description provided for @translateToArabic.
  ///
  /// In en, this message translates to:
  /// **'Show in Arabic'**
  String get translateToArabic;

  /// No description provided for @translateToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Show in English'**
  String get translateToEnglish;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available right now — your own words stay exactly as they are.'**
  String get aiUnavailable;

  /// No description provided for @emailSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get emailSignInTitle;

  /// No description provided for @emailRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get emailRegisterTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get passwordLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password'**
  String get forgotPassword;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetTitle;

  /// No description provided for @resetLead.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a reset link.'**
  String get resetLead;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Check your email for the reset link.'**
  String get resetSent;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have an account yet'**
  String get noAccount;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {detail}'**
  String authError(String detail);

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That email does not look right. Please check it.'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'There is already an account with this email. Try signing in.'**
  String get emailInUse;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That email and password did not match.'**
  String get wrongPassword;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @caseRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Your case reference:'**
  String get caseRefLabel;

  /// No description provided for @updateInitial.
  ///
  /// In en, this message translates to:
  /// **'Your answers and description'**
  String get updateInitial;

  /// No description provided for @updateConditionChanged.
  ///
  /// In en, this message translates to:
  /// **'Condition update'**
  String get updateConditionChanged;

  /// No description provided for @syncSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the nursing team'**
  String get syncSent;

  /// No description provided for @syncQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. NOT yet sent — it will send when you\'re back online. The nursing team has NOT seen it.'**
  String get syncQueued;

  /// No description provided for @mandatoryStatusCopy.
  ///
  /// In en, this message translates to:
  /// **'No one is watching your condition continuously. If things get worse, use the button below, call the nurse line, or call emergency services.'**
  String get mandatoryStatusCopy;

  /// No description provided for @statusChangeHint.
  ///
  /// In en, this message translates to:
  /// **'If anything changes, tap \"My condition has changed\" below. Your update joins this same case — you never start again.'**
  String get statusChangeHint;

  /// No description provided for @offlineStrip.
  ///
  /// In en, this message translates to:
  /// **'Offline — your answers save on this phone'**
  String get offlineStrip;

  /// No description provided for @statusCaseGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your case is no longer available'**
  String get statusCaseGoneTitle;

  /// No description provided for @statusCaseGoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved case is no longer available. You can start again.'**
  String get statusCaseGoneBody;

  /// No description provided for @updateEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your update'**
  String get updateEyebrow;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'What has changed since last time?'**
  String get updateTitle;

  /// No description provided for @updateLead.
  ///
  /// In en, this message translates to:
  /// **'Talk or type — whichever is easier right now.'**
  String get updateLead;

  /// No description provided for @addToCase.
  ///
  /// In en, this message translates to:
  /// **'Add this to my case'**
  String get addToCase;

  /// No description provided for @updateAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update added'**
  String get updateAddedTitle;

  /// No description provided for @updateAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Your update was added to your existing case. You have not lost your place, and you do not need to start again.'**
  String get updateAddedBody;

  /// No description provided for @caseRefStill.
  ///
  /// In en, this message translates to:
  /// **'Your case reference is still {ref}.'**
  String caseRefStill(String ref);

  /// No description provided for @backToCase.
  ///
  /// In en, this message translates to:
  /// **'Back to your case'**
  String get backToCase;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get accountTitle;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @accountContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get accountContact;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutNote.
  ///
  /// In en, this message translates to:
  /// **'Signing out clears what is saved on this phone. What you already sent stays with the nursing team.'**
  String get signOutNote;

  /// No description provided for @deleteMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteMyData;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your data?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your account and your saved preferences, withdraws your sharing consent, and removes everything saved on this phone. What you already sent stays with the nursing team so your care is not interrupted.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteConfirmYes;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @languageChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'اللغة · Language'**
  String get languageChoiceTitle;

  /// No description provided for @chooseEnglish.
  ///
  /// In en, this message translates to:
  /// **'Continue in English'**
  String get chooseEnglish;

  /// No description provided for @chooseArabic.
  ///
  /// In en, this message translates to:
  /// **'المتابعة بالعربية'**
  String get chooseArabic;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Your answers are still saved on this phone.'**
  String get errorGeneric;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @smsRegionBlocked.
  ///
  /// In en, this message translates to:
  /// **'SMS to this country is currently blocked by the project\'s SMS region policy / daily quota. For testing: add your number as a TEST phone number in Firebase console (Authentication → Sign-in method → Phone → Phone numbers for testing) and sign in with its fixed code — no SMS needed. For real SMS: enable the country in Authentication → Settings → SMS region policy, and add billing.\n\nإرسال الرسائل لهذه الدولة محجوب حاليًا بسياسة مناطق الرسائل / الحصة اليومية للمشروع. للتجربة: أضف رقمك كرقم اختبار في وحدة تحكم Firebase (Authentication ← Sign-in method ← Phone ← Phone numbers for testing) وادخل بالكود الثابت — بدون رسائل. للرسائل الحقيقية: فعّل الدولة من Authentication ← Settings ← SMS region policy وأضف الفوترة.'**
  String get smsRegionBlocked;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell the nursing team how you are'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'You describe how you feel, from home, and a nurse reads it. Create an account so the team knows who is writing, or sign in if you already have one.'**
  String get welcomeBody;

  /// No description provided for @registerLead.
  ///
  /// In en, this message translates to:
  /// **'One email and one password — that is all you need.'**
  String get registerLead;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your name?'**
  String get profileTitle;

  /// No description provided for @profileLead.
  ///
  /// In en, this message translates to:
  /// **'Your first name is enough. The nursing team sees it with what you send.'**
  String get profileLead;

  /// No description provided for @profileHint.
  ///
  /// In en, this message translates to:
  /// **'To continue, write your name and agree to the terms.'**
  String get profileHint;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get tabReports;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreetingNoName;

  /// No description provided for @homeLead.
  ///
  /// In en, this message translates to:
  /// **'This is your place to tell the nursing team how you are.'**
  String get homeLead;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report my condition'**
  String get reportAction;

  /// No description provided for @resumeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish your report'**
  String get resumeCardTitle;

  /// No description provided for @resumeCardBody.
  ///
  /// In en, this message translates to:
  /// **'Your report is saved on this phone. You can continue from where you stopped.'**
  String get resumeCardBody;

  /// No description provided for @discardDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete the draft and start over'**
  String get discardDraft;

  /// No description provided for @activeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your current report'**
  String get activeCardTitle;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @reportRowUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates: {count}'**
  String reportRowUpdates(int count);

  /// No description provided for @helpCardTitle.
  ///
  /// In en, this message translates to:
  /// **'If you need help now'**
  String get helpCardTitle;

  /// No description provided for @emergencyInfoLine.
  ///
  /// In en, this message translates to:
  /// **'For an emergency, call {number} or use the Emergency button at the top of the screen.'**
  String emergencyInfoLine(String number);

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start from Home — tap “Report my condition”.'**
  String get reportsEmptyBody;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Your report'**
  String get detailTitle;

  /// No description provided for @syncSentShort.
  ///
  /// In en, this message translates to:
  /// **'Sent to the nursing team'**
  String get syncSentShort;

  /// No description provided for @syncQueuedShort.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone — not sent yet'**
  String get syncQueuedShort;

  /// No description provided for @activeGateTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have an open report'**
  String get activeGateTitle;

  /// No description provided for @activeGateBody.
  ///
  /// In en, this message translates to:
  /// **'The nursing team already has your report. Anything new joins the SAME report as an update — you never start again and nothing is lost.'**
  String get activeGateBody;

  /// No description provided for @activeGateUpdate.
  ///
  /// In en, this message translates to:
  /// **'Add an update to my report'**
  String get activeGateUpdate;

  /// No description provided for @activeGateNewLead.
  ///
  /// In en, this message translates to:
  /// **'Is this a completely different, new situation?'**
  String get activeGateNewLead;

  /// No description provided for @activeGateNew.
  ///
  /// In en, this message translates to:
  /// **'Start a separate new report'**
  String get activeGateNew;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @consentHint.
  ///
  /// In en, this message translates to:
  /// **'To send, please agree to share your answers with the nursing team.'**
  String get consentHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
