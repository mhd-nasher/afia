// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تسليم عافية';

  @override
  String get chooseLanguage => 'اللغة · Language';

  @override
  String get chooseLanguageBody =>
      'اختر لغة هذا الجهاز. يمكنك تغييرها لاحقًا من صفحة الحساب.';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get phoneEntryTitle => 'رقم الهاتف';

  @override
  String get phoneEntryBody =>
      'تُنشأ الحسابات من إدارة الجناح. سجّل الدخول برقم الهاتف الذي أُرسلت إليه دعوتك.';

  @override
  String get phoneHint => '5X XXX XXXX';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get phoneInvalid => 'أدخل رقم هاتف صحيحًا.';

  @override
  String get phoneAuthUnavailable =>
      'تسجيل الدخول بالهاتف غير مفعّل بعد لهذا المشروع. اطلب من المشرف تفعيل مزوّد الهاتف في وحدة تحكم Firebase.\n\nPhone sign-in is not enabled yet. Ask the administrator to enable the Phone provider in the Firebase console.';

  @override
  String authError(String message) {
    return 'تعذّر تسجيل الدخول: $message';
  }

  @override
  String get otpTitle => 'أدخل الرمز';

  @override
  String otpSentTo(String phone) {
    return 'أُرسل رمز من 6 أرقام إلى $phone';
  }

  @override
  String get otpInvalid => 'الرمز غير صحيح. تحقق منه وحاول مرة أخرى.';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get verifying => 'جارٍ التحقق…';

  @override
  String get notInvitedTitle => 'هذا الرقم لا يملك دعوة';

  @override
  String get notInvitedBody =>
      'تُنشأ الحسابات من إدارة الجناح وليس من التطبيق. إن كان يحق لك الدخول، فاطلب من مدير الجناح إرسال دعوة إلى هذا الرقم ثم سجّل الدخول مجددًا.';

  @override
  String get checkingInvitation => 'جارٍ التحقق من دعوتك…';

  @override
  String get tabPatients => 'المرضى';

  @override
  String get tabReceived => 'الوارد';

  @override
  String get tabShift => 'الوردية';

  @override
  String get tabAccount => 'الحساب';

  @override
  String get wardFallback => 'الجناح';

  @override
  String listAt(String time) {
    return 'القائمة $time';
  }

  @override
  String get notStarted => 'لم يبدأ';

  @override
  String get recordingLabel => 'جارٍ التسجيل';

  @override
  String get draftReadyNotSigned => 'مسودة جاهزة · غير موقّعة';

  @override
  String get interrupted => 'متوقف مؤقتًا';

  @override
  String get signedQueued => 'موقّع · في انتظار الإرسال';

  @override
  String get confirmedInSystem => 'مسجَّل في عافية';

  @override
  String get exportFailedRetry => 'فشل التصدير · أعد المحاولة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get resume => 'استئناف';

  @override
  String get noPatients => 'لا يوجد مرضى في هذا الجناح بعد.';

  @override
  String get noPatientsBody => 'يُضاف المرضى من لوحة تحكم الإدارة.';

  @override
  String get synced => 'متزامن';

  @override
  String queuedCount(int n) {
    return '$n في الانتظار';
  }

  @override
  String get offlineSavedOnDevice => 'دون اتصال · محفوظ على الجهاز';

  @override
  String get offlineBannerTitle => 'لا اتصال بشبكة الجناح';

  @override
  String get offlineBannerBody => 'كل ما تسجّله محفوظ على هذا الجهاز';

  @override
  String get patientTitle => 'المريض';

  @override
  String bed(String bed) {
    return 'سرير $bed';
  }

  @override
  String dob(String date) {
    return 'تاريخ الميلاد $date';
  }

  @override
  String get admitted => 'تاريخ الدخول';

  @override
  String get allergy => 'حساسية';

  @override
  String get activeMedications => 'الأدوية الحالية';

  @override
  String get lastHandover => 'آخر تسليم';

  @override
  String get noHandoverYet => 'لم يُسجَّل تسليم لهذا المريض بعد.';

  @override
  String get recordHandover => 'تسجيل التسليم';

  @override
  String get vitalsBp => 'الضغط';

  @override
  String get vitalsHr => 'النبض';

  @override
  String get vitalsSpo2 => 'الأكسجين';

  @override
  String get vitalsTemp => 'الحرارة';

  @override
  String get micPrimerTitle => 'التسجيل يستخدم الميكروفون';

  @override
  String get micPrimerBody =>
      'يُحوَّل صوتك إلى نص على هذا الجهاز، ويرافق التسجيلُ الأصلي التسليمَ ليتمكن الممرض التالي من سماعك. لا يُرفع شيء إلى أي مكان آخر.';

  @override
  String get micPrimerAllow => 'السماح بالميكروفون';

  @override
  String get micDenied =>
      'الوصول إلى الميكروفون مغلق. يمكنك كتابة التسليم، أو السماح بالميكروفون من إعدادات النظام.';

  @override
  String get typeInstead => 'الكتابة بدلًا من ذلك';

  @override
  String get typeHandoverHint => 'اكتب ما كنت ستقوله…';

  @override
  String get tapToStopHoldToPause =>
      'اضغط للإيقاف · اضغط مطولًا للإيقاف المؤقت';

  @override
  String get paused => 'متوقف مؤقتًا · اضغط للمتابعة';

  @override
  String get structuring => 'جارٍ التنظيم في القالب…';

  @override
  String structuredBy(String engine) {
    return 'نُظِّم بواسطة $engine';
  }

  @override
  String get draftTitle => 'مسودة';

  @override
  String get handoverTitle => 'التسليم';

  @override
  String get draftBand => 'مسودة — غير موقّعة';

  @override
  String get producedBySystem => 'أنتجها النظام';

  @override
  String signedBand(String identity, String time) {
    return 'موقّع — $identity · $time';
  }

  @override
  String get verifiedByHuman => 'تحقق منها إنسان';

  @override
  String get verified => 'مُتحقَّق';

  @override
  String get replay => 'إعادة الاستماع';

  @override
  String recordedAt(String time) {
    return 'سُجِّل $time';
  }

  @override
  String get sideNote => 'ملاحظة جانبية';

  @override
  String notMentioned(String label) {
    return 'لم يُذكر: $label';
  }

  @override
  String get addField => 'إضافة';

  @override
  String confirmChipsButton(int n) {
    return 'تأكيد $n من الأدوية والأرقام';
  }

  @override
  String reviewChipsButton(int n) {
    return 'مراجعة $n عنصرًا مؤكَّدًا';
  }

  @override
  String get signButton => 'توقيع';

  @override
  String get flagsNeverBlock => 'التوقيع لا تعيقه أبدًا الإشارات المفتوحة';

  @override
  String get audioKeptOnDevice =>
      'بقي التسجيل على جهاز التسجيل — أكبر من أن يُزامن.';

  @override
  String get confirmTitle => 'التأكيد';

  @override
  String chipCounter(int done, int total) {
    return '$done / $total';
  }

  @override
  String get drugHeard => 'دواء · سُمع في التسجيل';

  @override
  String get numberHeard => 'رقم · سُمع في التسجيل';

  @override
  String get lowConfidence => 'ثقة منخفضة';

  @override
  String get highConfidence => 'ثقة عالية';

  @override
  String get noFormularyMatch => 'لا تطابق في قائمة الأدوية — أكِّد صراحةً';

  @override
  String get soundAlike => 'متشابه لفظًا';

  @override
  String get confirmAction => 'تأكيد';

  @override
  String get correctAction => 'تصحيح';

  @override
  String get stillToConfirm => 'بانتظار التأكيد';

  @override
  String get allConfirmed => 'أُكِّدت كل العناصر';

  @override
  String get noConfirmAll => 'يُؤكَّد كل عنصر على حدة — لا يوجد تأكيد جماعي';

  @override
  String correctedTo(String name) {
    return 'صُحِّح إلى $name';
  }

  @override
  String get correctDrugName => 'تصحيح اسم الدواء';

  @override
  String heardAs(String term) {
    return 'سُمع «$term»';
  }

  @override
  String get searchDrugName => 'ابحث عن اسم الدواء';

  @override
  String get soundsAlikeCheck => 'متشابه لفظًا — تحقق بعناية';

  @override
  String get wardFormulary => 'قائمة أدوية الجناح';

  @override
  String get currentEntry => 'الإدخال الحالي';

  @override
  String get recognitionNotRecall =>
      'اختر من القائمة — لا يُكتب الاسم من الذاكرة أبدًا';

  @override
  String get signingAs => 'التوقيع باسم';

  @override
  String openFlagsCount(int n) {
    return '$n إشارات مفتوحة';
  }

  @override
  String get flagNotApplicable => 'لا ينطبق';

  @override
  String get flagAskedNoAnswer => 'سُئل ولم يُجب';

  @override
  String get flagWillAddLater => 'سيُضاف لاحقًا';

  @override
  String get flagEndOfShift => 'نهاية الوردية — سُلِّم لفريق النهار';

  @override
  String get holdToSign => 'اضغط مطولًا للتوقيع';

  @override
  String get flagsTravelNote =>
      'التوقيع لا تعيقه الإشارات المفتوحة — بل ترافق التسليم';

  @override
  String get chooseFlagReason => 'اختر سببًا لكل إشارة مفتوحة — بلمسة واحدة';

  @override
  String get receivedTitle => 'الوارد';

  @override
  String get receivedSubtitle => 'من الوردية السابقة';

  @override
  String newCount(int n) {
    return '$n جديد';
  }

  @override
  String get newLabel => 'جديد';

  @override
  String get readLabel => 'مقروء';

  @override
  String get noIncoming => 'لم يصل شيء بعد.';

  @override
  String get noIncomingBody =>
      'ستظهر هنا التسليمات الموقّعة من الوردية السابقة.';

  @override
  String get tenSecondSummary => 'ملخص عشر ثوانٍ';

  @override
  String get openFlagsSection => 'إشارات مفتوحة';

  @override
  String get whatChanged => 'ما تغيّر منذ التسليم السابق';

  @override
  String get diffAdded => 'أُضيف';

  @override
  String get diffChanged => 'تغيّر';

  @override
  String get diffNowEmpty => 'أصبح فارغًا';

  @override
  String get playOriginal => 'تشغيل التسجيل الأصلي';

  @override
  String get stopPlayback => 'إيقاف';

  @override
  String get audioUnavailable =>
      'بقي التسجيل على جهاز التسجيل (أكبر من أن يُزامن). النص والحقول أدناه كاملة.';

  @override
  String get acknowledgeRead => 'إقرار بالاستلام';

  @override
  String get acknowledged => 'تم الإقرار';

  @override
  String get fhirReady => 'سجل جاهز لـ FHIR';

  @override
  String get fhirNote =>
      '‏JSON صالح من نوع DocumentReference وفق FHIR، يُولَّد عند الطلب ويُعرض هنا. لا يُرسل شيء إلى أي مكان — هذا الإصدار جاهز لـ FHIR وليس متكاملًا.';

  @override
  String get copyJson => 'نسخ JSON';

  @override
  String get copyText => 'نسخ كنص';

  @override
  String get copied => 'نُسخ إلى الحافظة';

  @override
  String get shiftBoardTitle => 'لوحة الوردية';

  @override
  String get recordedStat => 'سُجِّل';

  @override
  String get signedStat => 'وُقِّع';

  @override
  String get confirmedStat => 'مسجَّل في عافية';

  @override
  String get patientCol => 'المريض';

  @override
  String get signedCol => 'التوقيع';

  @override
  String get inSystemCol => 'مسجَّل';

  @override
  String get yes => 'نعم';

  @override
  String get queuedLabel => 'بالانتظار';

  @override
  String get failedLabel => 'فشل';

  @override
  String get receipt => 'الإيصال';

  @override
  String get acceptedBy => 'مسجَّل في عافية — إقرار الخادم';

  @override
  String ackRef(String time, String ref) {
    return '$time · مرجع $ref';
  }

  @override
  String get notReachedBanner => 'تسليم واحد لم يُسجَّل بعد في عافية';

  @override
  String notReachedBannerMany(int n) {
    return '$n تسليمات لم تُسجَّل بعد في عافية';
  }

  @override
  String lastTried(String bed, String time) {
    return 'سرير $bed · آخر محاولة $time';
  }

  @override
  String get safeOnDevice => 'وهو محفوظ بأمان على هذا الجهاز';

  @override
  String get endShift => 'إنهاء الوردية';

  @override
  String shiftCompleteTitle(String n) {
    return '$n مريضًا سُلِّموا.';
  }

  @override
  String get shiftCompleteBody => 'كل شيء موقّع وبين يدي الجناح.';

  @override
  String get handedOverStat => 'سُلِّم';

  @override
  String get itemsConfirmedStat => 'عنصرًا أُكِّد';

  @override
  String get leftUnsentStat => 'لم يُرسل';

  @override
  String get howWasIt => 'كيف كانت؟ — اختياري';

  @override
  String get moodSteady => 'هادئة';

  @override
  String get moodHeavy => 'ثقيلة';

  @override
  String get moodShortStaffed => 'نقص كادر';

  @override
  String get moodGoodShift => 'وردية جيدة';

  @override
  String get goRest => 'اذهب وارتح.';

  @override
  String get accountTitle => 'الحساب';

  @override
  String get yourSignature => 'توقيعك';

  @override
  String get signatureLockNote =>
      'يظهر هذا على كل تسليم توقّعه. لا يمكن تعديله من الجهاز.';

  @override
  String get wardRow => 'الجناح';

  @override
  String get templateRow => 'القالب';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get themeDay => 'نهاري';

  @override
  String get themeNight => 'ليلي';

  @override
  String get languageRow => 'اللغة';

  @override
  String get viewTemplateRow => 'قالب التسليم';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get sharedDeviceNote =>
      'هذا الجهاز مشترك — سجّل الخروج في نهاية ورديتك';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج من هذا الجهاز؟';

  @override
  String get signOutConfirmBody =>
      'الممرض التالي يسجّل الدخول برقمه الخاص. يبقى العمل غير المتزامن محفوظًا بأمان على هذا الجهاز.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get syncErrorTitle => 'تعذّرت المزامنة';

  @override
  String get syncErrorBody =>
      'التغييرات محفوظة على هذا الجهاز وستتزامن عند عودة الاتصال.';

  @override
  String get templateTitle => 'قالب التسليم';

  @override
  String get templateSubtitle => 'يُطبَّق على كل تسليم في هذا الجناح';

  @override
  String get fieldsSection => 'الحقول · التحرير من لوحة التحكم';

  @override
  String get requiredLabel => 'إلزامي · يظهر أثناء التسجيل';

  @override
  String get optionalLabel => 'اختياري';

  @override
  String templateEditedBy(String name) {
    return 'حرّره $name';
  }

  @override
  String get templateRoleGate => 'القالب متاح لرؤساء التمريض والمديرين.';

  @override
  String get amendHandover => 'تعديل — يُبطل التوقيع';

  @override
  String get amendNote =>
      'التعديل ينشئ نسخة جديدة غير موقّعة. تُحفظ النسخة الأصلية وتوقيعها. يجب تأكيد كل دواء ورقم من جديد.';

  @override
  String versionLabel(int n) {
    return 'ن$n';
  }

  @override
  String get supersededBy => 'حلّت محلها نسخة أحدث';

  @override
  String get fieldSituation => 'الحالة';

  @override
  String get fieldBackground => 'الخلفية';

  @override
  String get fieldMedications => 'الأدوية المعطاة';

  @override
  String get fieldVitals => 'أحدث العلامات الحيوية';

  @override
  String get fieldPain => 'الألم';

  @override
  String get fieldMobility => 'الحركة والسقوط';

  @override
  String get fieldDiet => 'التغذية والسوائل';

  @override
  String get fieldPlan => 'خطة الوردية القادمة';

  @override
  String get fieldFamily => 'التواصل مع الأسرة';

  @override
  String get errorGeneric => 'حدث خطأ ما. عملك محفوظ على هذا الجهاز.';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get assistantTitle => 'مساعد عافية';

  @override
  String get assistantIntro =>
      'أعيد تنظيم ما سجّله فريق الرعاية — ملخصات عشر ثوانٍ، ما تغيّر، تنظيم الإملاء، وإيجاد التفاصيل المسجّلة. القرار السريري يبقى لك.';

  @override
  String get assistantHint => 'اسأل عن المعلومات المسجّلة…';

  @override
  String get assistantSend => 'إرسال';

  @override
  String get assistantThinking => 'جارٍ العمل…';

  @override
  String get assistantMemoryNote => 'يتذكّر تفضيلاتك · تُحفظ بشكل خاص في حسابك';
}
