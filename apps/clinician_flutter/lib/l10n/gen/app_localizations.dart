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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Afia Handover'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language · اللغة'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for this device. You can change it later in Account.'**
  String get chooseLanguageBody;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in: {message}'**
  String authError(String message);

  /// No description provided for @notInvitedTitle.
  ///
  /// In en, this message translates to:
  /// **'This email has no invitation'**
  String get notInvitedTitle;

  /// No description provided for @notInvitedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account exists but has no access. Access is granted by invitation from ward management — ask your ward manager to send an invitation to this email, then sign in again.'**
  String get notInvitedBody;

  /// No description provided for @checkingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Checking your invitation…'**
  String get checkingInvitation;

  /// No description provided for @tabPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get tabPatients;

  /// No description provided for @tabReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get tabReceived;

  /// No description provided for @tabShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get tabShift;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @wardFallback.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get wardFallback;

  /// No description provided for @listAt.
  ///
  /// In en, this message translates to:
  /// **'list {time}'**
  String listAt(String time);

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingLabel;

  /// No description provided for @draftReadyNotSigned.
  ///
  /// In en, this message translates to:
  /// **'Draft ready · not signed'**
  String get draftReadyNotSigned;

  /// No description provided for @interrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get interrupted;

  /// No description provided for @signedQueued.
  ///
  /// In en, this message translates to:
  /// **'Signed · queued to send'**
  String get signedQueued;

  /// No description provided for @confirmedInSystem.
  ///
  /// In en, this message translates to:
  /// **'Recorded in Afia'**
  String get confirmedInSystem;

  /// No description provided for @exportFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Export failed · retry'**
  String get exportFailedRetry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @noPatients.
  ///
  /// In en, this message translates to:
  /// **'No patients on this ward yet.'**
  String get noPatients;

  /// No description provided for @noPatientsBody.
  ///
  /// In en, this message translates to:
  /// **'Patients are added from the admin dashboard.'**
  String get noPatientsBody;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @queuedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} queued'**
  String queuedCount(int n);

  /// No description provided for @offlineSavedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Offline · saved on device'**
  String get offlineSavedOnDevice;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection to the ward network'**
  String get offlineBannerTitle;

  /// No description provided for @offlineBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you record is saved on this device'**
  String get offlineBannerBody;

  /// No description provided for @patientTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientTitle;

  /// No description provided for @bed.
  ///
  /// In en, this message translates to:
  /// **'Bed {bed}'**
  String bed(String bed);

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'DOB {date}'**
  String dob(String date);

  /// No description provided for @admitted.
  ///
  /// In en, this message translates to:
  /// **'Admitted'**
  String get admitted;

  /// No description provided for @allergy.
  ///
  /// In en, this message translates to:
  /// **'Allergy'**
  String get allergy;

  /// No description provided for @activeMedications.
  ///
  /// In en, this message translates to:
  /// **'Active medications'**
  String get activeMedications;

  /// No description provided for @lastHandover.
  ///
  /// In en, this message translates to:
  /// **'Last handover'**
  String get lastHandover;

  /// No description provided for @noHandoverYet.
  ///
  /// In en, this message translates to:
  /// **'No handover recorded yet for this patient.'**
  String get noHandoverYet;

  /// No description provided for @recordHandover.
  ///
  /// In en, this message translates to:
  /// **'Record handover'**
  String get recordHandover;

  /// No description provided for @vitalsBp.
  ///
  /// In en, this message translates to:
  /// **'BP'**
  String get vitalsBp;

  /// No description provided for @vitalsHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get vitalsHr;

  /// No description provided for @vitalsSpo2.
  ///
  /// In en, this message translates to:
  /// **'SpO₂'**
  String get vitalsSpo2;

  /// No description provided for @vitalsTemp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get vitalsTemp;

  /// No description provided for @micPrimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording uses the microphone'**
  String get micPrimerTitle;

  /// No description provided for @micPrimerBody.
  ///
  /// In en, this message translates to:
  /// **'Your voice is transcribed on this device and the original recording travels with the handover so the next nurse can hear you. Nothing is uploaded anywhere else.'**
  String get micPrimerBody;

  /// No description provided for @micPrimerAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone'**
  String get micPrimerAllow;

  /// No description provided for @micDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. You can still type the handover, or allow the microphone in system settings.'**
  String get micDenied;

  /// No description provided for @typeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get typeInstead;

  /// No description provided for @typeHandoverHint.
  ///
  /// In en, this message translates to:
  /// **'Type what you would have said…'**
  String get typeHandoverHint;

  /// No description provided for @tapToStopHoldToPause.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop · hold to pause'**
  String get tapToStopHoldToPause;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused · tap to continue'**
  String get paused;

  /// No description provided for @structuring.
  ///
  /// In en, this message translates to:
  /// **'Organising into the template…'**
  String get structuring;

  /// No description provided for @structuredBy.
  ///
  /// In en, this message translates to:
  /// **'Organised by {engine}'**
  String structuredBy(String engine);

  /// No description provided for @draftTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftTitle;

  /// No description provided for @handoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover'**
  String get handoverTitle;

  /// No description provided for @draftBand.
  ///
  /// In en, this message translates to:
  /// **'DRAFT — NOT SIGNED'**
  String get draftBand;

  /// No description provided for @producedBySystem.
  ///
  /// In en, this message translates to:
  /// **'Produced by the system'**
  String get producedBySystem;

  /// No description provided for @signedBand.
  ///
  /// In en, this message translates to:
  /// **'SIGNED — {identity} · {time}'**
  String signedBand(String identity, String time);

  /// No description provided for @verifiedByHuman.
  ///
  /// In en, this message translates to:
  /// **'Verified by a human'**
  String get verifiedByHuman;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @recordedAt.
  ///
  /// In en, this message translates to:
  /// **'recorded {time}'**
  String recordedAt(String time);

  /// No description provided for @sideNote.
  ///
  /// In en, this message translates to:
  /// **'Side note'**
  String get sideNote;

  /// No description provided for @notMentioned.
  ///
  /// In en, this message translates to:
  /// **'Not mentioned: {label}'**
  String notMentioned(String label);

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addField;

  /// No description provided for @confirmChipsButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm {n} drugs & numbers'**
  String confirmChipsButton(int n);

  /// No description provided for @reviewChipsButton.
  ///
  /// In en, this message translates to:
  /// **'Review {n} confirmed items'**
  String reviewChipsButton(int n);

  /// No description provided for @signButton.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get signButton;

  /// No description provided for @flagsNeverBlock.
  ///
  /// In en, this message translates to:
  /// **'Signing is never blocked by open flags'**
  String get flagsNeverBlock;

  /// No description provided for @audioKeptOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Recording kept on the recording device — too large to sync.'**
  String get audioKeptOnDevice;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTitle;

  /// No description provided for @chipCounter.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total}'**
  String chipCounter(int done, int total);

  /// No description provided for @drugHeard.
  ///
  /// In en, this message translates to:
  /// **'Drug · heard in the recording'**
  String get drugHeard;

  /// No description provided for @numberHeard.
  ///
  /// In en, this message translates to:
  /// **'Number · heard in the recording'**
  String get numberHeard;

  /// No description provided for @lowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get lowConfidence;

  /// No description provided for @highConfidence.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get highConfidence;

  /// No description provided for @noFormularyMatch.
  ///
  /// In en, this message translates to:
  /// **'No formulary match — confirm explicitly'**
  String get noFormularyMatch;

  /// No description provided for @soundAlike.
  ///
  /// In en, this message translates to:
  /// **'Sound-alike'**
  String get soundAlike;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @correctAction.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctAction;

  /// No description provided for @stillToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Still to confirm'**
  String get stillToConfirm;

  /// No description provided for @allConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Every item confirmed'**
  String get allConfirmed;

  /// No description provided for @noConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Every item is confirmed on its own — there is no confirm-all'**
  String get noConfirmAll;

  /// No description provided for @correctedTo.
  ///
  /// In en, this message translates to:
  /// **'Corrected to {name}'**
  String correctedTo(String name);

  /// No description provided for @correctDrugName.
  ///
  /// In en, this message translates to:
  /// **'Correct drug name'**
  String get correctDrugName;

  /// No description provided for @heardAs.
  ///
  /// In en, this message translates to:
  /// **'Heard as “{term}”'**
  String heardAs(String term);

  /// No description provided for @searchDrugName.
  ///
  /// In en, this message translates to:
  /// **'Search drug name'**
  String get searchDrugName;

  /// No description provided for @soundsAlikeCheck.
  ///
  /// In en, this message translates to:
  /// **'Sounds alike — check carefully'**
  String get soundsAlikeCheck;

  /// No description provided for @wardFormulary.
  ///
  /// In en, this message translates to:
  /// **'Ward formulary'**
  String get wardFormulary;

  /// No description provided for @currentEntry.
  ///
  /// In en, this message translates to:
  /// **'current entry'**
  String get currentEntry;

  /// No description provided for @recognitionNotRecall.
  ///
  /// In en, this message translates to:
  /// **'Pick from the formulary — spelling is never typed from memory'**
  String get recognitionNotRecall;

  /// No description provided for @signingAs.
  ///
  /// In en, this message translates to:
  /// **'Signing as'**
  String get signingAs;

  /// No description provided for @openFlagsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} open flags'**
  String openFlagsCount(int n);

  /// No description provided for @flagNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get flagNotApplicable;

  /// No description provided for @flagAskedNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'Asked, no answer'**
  String get flagAskedNoAnswer;

  /// No description provided for @flagWillAddLater.
  ///
  /// In en, this message translates to:
  /// **'Will add later'**
  String get flagWillAddLater;

  /// No description provided for @flagEndOfShift.
  ///
  /// In en, this message translates to:
  /// **'End of shift — handed to day team'**
  String get flagEndOfShift;

  /// No description provided for @holdToSign.
  ///
  /// In en, this message translates to:
  /// **'Hold to sign'**
  String get holdToSign;

  /// No description provided for @flagsTravelNote.
  ///
  /// In en, this message translates to:
  /// **'Signing is never blocked by open flags — they travel with the handover'**
  String get flagsTravelNote;

  /// No description provided for @chooseFlagReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason for each open flag — one tap'**
  String get chooseFlagReason;

  /// No description provided for @receivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedTitle;

  /// No description provided for @receivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From the previous shift'**
  String get receivedSubtitle;

  /// No description provided for @newCount.
  ///
  /// In en, this message translates to:
  /// **'{n} new'**
  String newCount(int n);

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @readLabel.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readLabel;

  /// No description provided for @noIncoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing received yet.'**
  String get noIncoming;

  /// No description provided for @noIncomingBody.
  ///
  /// In en, this message translates to:
  /// **'Handovers signed by the previous shift will appear here.'**
  String get noIncomingBody;

  /// No description provided for @tenSecondSummary.
  ///
  /// In en, this message translates to:
  /// **'Ten-second summary'**
  String get tenSecondSummary;

  /// No description provided for @openFlagsSection.
  ///
  /// In en, this message translates to:
  /// **'Open flags'**
  String get openFlagsSection;

  /// No description provided for @whatChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed since the previous handover'**
  String get whatChanged;

  /// No description provided for @diffAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get diffAdded;

  /// No description provided for @diffChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get diffChanged;

  /// No description provided for @diffNowEmpty.
  ///
  /// In en, this message translates to:
  /// **'Now empty'**
  String get diffNowEmpty;

  /// No description provided for @playOriginal.
  ///
  /// In en, this message translates to:
  /// **'Play original recording'**
  String get playOriginal;

  /// No description provided for @stopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPlayback;

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The recording stayed on the recording device (too large to sync). The transcript and fields below are complete.'**
  String get audioUnavailable;

  /// No description provided for @acknowledgeRead.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledgeRead;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @fhirReady.
  ///
  /// In en, this message translates to:
  /// **'FHIR-ready record'**
  String get fhirReady;

  /// No description provided for @fhirNote.
  ///
  /// In en, this message translates to:
  /// **'Valid FHIR DocumentReference JSON, generated on demand and displayed here. Nothing is sent anywhere — this build is FHIR-ready, not integrated.'**
  String get fhirNote;

  /// No description provided for @copyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get copyJson;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get copyText;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @shiftBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift board'**
  String get shiftBoardTitle;

  /// No description provided for @recordedStat.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get recordedStat;

  /// No description provided for @signedStat.
  ///
  /// In en, this message translates to:
  /// **'signed'**
  String get signedStat;

  /// No description provided for @confirmedStat.
  ///
  /// In en, this message translates to:
  /// **'recorded in Afia'**
  String get confirmedStat;

  /// No description provided for @patientCol.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientCol;

  /// No description provided for @signedCol.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get signedCol;

  /// No description provided for @inSystemCol.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get inSystemCol;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @queuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queuedLabel;

  /// No description provided for @failedLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedLabel;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @acceptedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded in Afia — server acknowledgement'**
  String get acceptedBy;

  /// No description provided for @ackRef.
  ///
  /// In en, this message translates to:
  /// **'{time} · ref {ref}'**
  String ackRef(String time, String ref);

  /// No description provided for @notReachedBanner.
  ///
  /// In en, this message translates to:
  /// **'One handover is not yet recorded in Afia'**
  String get notReachedBanner;

  /// No description provided for @notReachedBannerMany.
  ///
  /// In en, this message translates to:
  /// **'{n} handovers are not yet recorded in Afia'**
  String notReachedBannerMany(int n);

  /// No description provided for @lastTried.
  ///
  /// In en, this message translates to:
  /// **'Bed {bed} · last tried {time}'**
  String lastTried(String bed, String time);

  /// No description provided for @safeOnDevice.
  ///
  /// In en, this message translates to:
  /// **'it is safe on this device'**
  String get safeOnDevice;

  /// No description provided for @endShift.
  ///
  /// In en, this message translates to:
  /// **'End shift'**
  String get endShift;

  /// No description provided for @shiftCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{n} patients handed over.'**
  String shiftCompleteTitle(String n);

  /// No description provided for @shiftCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Everything is signed and the ward has it.'**
  String get shiftCompleteBody;

  /// No description provided for @handedOverStat.
  ///
  /// In en, this message translates to:
  /// **'handed over'**
  String get handedOverStat;

  /// No description provided for @itemsConfirmedStat.
  ///
  /// In en, this message translates to:
  /// **'items confirmed'**
  String get itemsConfirmedStat;

  /// No description provided for @leftUnsentStat.
  ///
  /// In en, this message translates to:
  /// **'left unsent'**
  String get leftUnsentStat;

  /// No description provided for @howWasIt.
  ///
  /// In en, this message translates to:
  /// **'How was it? — optional'**
  String get howWasIt;

  /// No description provided for @moodSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get moodSteady;

  /// No description provided for @moodHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get moodHeavy;

  /// No description provided for @moodShortStaffed.
  ///
  /// In en, this message translates to:
  /// **'Short-staffed'**
  String get moodShortStaffed;

  /// No description provided for @moodGoodShift.
  ///
  /// In en, this message translates to:
  /// **'Good shift'**
  String get moodGoodShift;

  /// No description provided for @goRest.
  ///
  /// In en, this message translates to:
  /// **'Go rest.'**
  String get goRest;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @yourSignature.
  ///
  /// In en, this message translates to:
  /// **'Your signature'**
  String get yourSignature;

  /// No description provided for @signatureLockNote.
  ///
  /// In en, this message translates to:
  /// **'This appears on every handover you sign. It cannot be edited on the device.'**
  String get signatureLockNote;

  /// No description provided for @wardRow.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get wardRow;

  /// No description provided for @templateRow.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get templateRow;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeDay;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @languageRow.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageRow;

  /// No description provided for @viewTemplateRow.
  ///
  /// In en, this message translates to:
  /// **'Handover template'**
  String get viewTemplateRow;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @sharedDeviceNote.
  ///
  /// In en, this message translates to:
  /// **'This device is shared — sign out at the end of your shift'**
  String get sharedDeviceNote;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The next nurse signs in with their own number. Unsynced work stays safely on this device.'**
  String get signOutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @syncErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not sync'**
  String get syncErrorTitle;

  /// No description provided for @syncErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Changes are saved on this device and will sync when the connection returns.'**
  String get syncErrorBody;

  /// No description provided for @templateTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover template'**
  String get templateTitle;

  /// No description provided for @templateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to every handover on this ward'**
  String get templateSubtitle;

  /// No description provided for @fieldsSection.
  ///
  /// In en, this message translates to:
  /// **'Fields · editing lives in the dashboard'**
  String get fieldsSection;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required · prompts while recording'**
  String get requiredLabel;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @templateEditedBy.
  ///
  /// In en, this message translates to:
  /// **'Edited by {name}'**
  String templateEditedBy(String name);

  /// No description provided for @templateRoleGate.
  ///
  /// In en, this message translates to:
  /// **'The template is visible to charge nurses and managers.'**
  String get templateRoleGate;

  /// No description provided for @amendHandover.
  ///
  /// In en, this message translates to:
  /// **'Amend — invalidates the signature'**
  String get amendHandover;

  /// No description provided for @amendNote.
  ///
  /// In en, this message translates to:
  /// **'Amending creates a new unsigned version. The original and its signature are kept. Every drug and number must be confirmed again.'**
  String get amendNote;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'v{n}'**
  String versionLabel(int n);

  /// No description provided for @supersededBy.
  ///
  /// In en, this message translates to:
  /// **'Superseded by a later version'**
  String get supersededBy;

  /// No description provided for @fieldSituation.
  ///
  /// In en, this message translates to:
  /// **'Situation'**
  String get fieldSituation;

  /// No description provided for @fieldBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get fieldBackground;

  /// No description provided for @fieldMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications given'**
  String get fieldMedications;

  /// No description provided for @fieldVitals.
  ///
  /// In en, this message translates to:
  /// **'Latest vitals'**
  String get fieldVitals;

  /// No description provided for @fieldPain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get fieldPain;

  /// No description provided for @fieldMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility & falls'**
  String get fieldMobility;

  /// No description provided for @fieldDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet & fluids'**
  String get fieldDiet;

  /// No description provided for @fieldPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan for next shift'**
  String get fieldPlan;

  /// No description provided for @fieldFamily.
  ///
  /// In en, this message translates to:
  /// **'Family communication'**
  String get fieldFamily;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Your work is saved on this device.'**
  String get errorGeneric;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Afia Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantIntro.
  ///
  /// In en, this message translates to:
  /// **'I reorganise what the care team has recorded — ten-second summaries, what changed, structuring a dictation, finding recorded details. Clinical judgement stays with you.'**
  String get assistantIntro;

  /// No description provided for @assistantHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about recorded information…'**
  String get assistantHint;

  /// No description provided for @assistantSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get assistantSend;

  /// No description provided for @assistantThinking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get assistantThinking;

  /// No description provided for @assistantMemoryNote.
  ///
  /// In en, this message translates to:
  /// **'Remembers your preferences · stored privately to your account'**
  String get assistantMemoryNote;

  /// No description provided for @smsRegionBlocked.
  ///
  /// In en, this message translates to:
  /// **'SMS to this country is currently blocked by the project\'s SMS region policy / daily quota. For testing: add your number as a TEST phone number in Firebase console (Authentication → Sign-in method → Phone → Phone numbers for testing) and sign in with its fixed code — no SMS needed. For real SMS: enable the country in Authentication → Settings → SMS region policy, and add billing.\n\nإرسال الرسائل لهذه الدولة محجوب حاليًا بسياسة مناطق الرسائل / الحصة اليومية للمشروع. للتجربة: أضف رقمك كرقم اختبار في وحدة تحكم Firebase (Authentication ← Sign-in method ← Phone ← Phone numbers for testing) وادخل بالكود الثابت — بدون رسائل. للرسائل الحقيقية: فعّل الدولة من Authentication ← Settings ← SMS region policy وأضف الفوترة.'**
  String get smsRegionBlocked;

  /// No description provided for @emailEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Accounts are created by ward management. Sign in with the email your invitation was sent to.'**
  String get emailEntryBody;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @createAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountAction;

  /// No description provided for @createAccountSwitch.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get createAccountSwitch;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a password reset link.'**
  String get resetPasswordBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}. Check your inbox.'**
  String resetSent(String email);

  /// No description provided for @authBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authBadCredentials;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists — sign in instead.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authWeakPassword;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authPasswordMismatch;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection — try again when you are back online.'**
  String get authNetwork;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts — wait a moment and try again.'**
  String get authTooManyRequests;
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
