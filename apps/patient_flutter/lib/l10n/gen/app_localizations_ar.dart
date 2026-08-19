// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get emergencyLabel => 'طوارئ';

  @override
  String get conditionChanged => 'حالتي تغيّرت';

  @override
  String callNurseLine(String number) {
    return 'خط التمريض — اتصل على $number';
  }

  @override
  String get entryTitle => 'أخبر فريق التمريض كيف حالك';

  @override
  String get entryBody1 =>
      'ستجيب عن بضعة أسئلة وتصف شعورك بكلماتك أنت. ما ترسله يذهب إلى فريق التمريض لتقرأه ممرضة.';

  @override
  String get entryBody2 =>
      'يستغرق الأمر دقائق قليلة. يمكنك التوقف في أي لحظة — لا يضيع شيء مما تدخله.';

  @override
  String get entryNameLabel => 'اسمك الأول (الاسم الأول يكفي)';

  @override
  String get entryTerms => 'أوافق على شروط الاستخدام';

  @override
  String get entryConsent => 'أوافق على مشاركة إجاباتي مع فريق التمريض';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get entryAgreeHint => 'للمتابعة، الرجاء الموافقة على العبارتين أعلاه.';

  @override
  String get resumeTitle => 'أهلاً بعودتك';

  @override
  String get resumeBody =>
      'لديك وصف غير مكتمل. إجاباتك محفوظة على هذا الهاتف — يمكنك المتابعة من حيث توقفت.';

  @override
  String get resumeContinue => 'المتابعة من حيث توقفت';

  @override
  String get startOver => 'البدء من جديد';

  @override
  String get safetyQuestionsEyebrow => 'أسئلة السلامة';

  @override
  String get safetyQuestionsRepeatEyebrow =>
      'أسئلة السلامة — نسألها مجدداً، للاطمئنان';

  @override
  String get answerYes => 'نعم';

  @override
  String get answerNo => 'لا';

  @override
  String get answerDontKnow => 'لا أعرف';

  @override
  String interruptTitle(String number) {
    return 'اتصل الآن على $number';
  }

  @override
  String interruptLeadAnswer(String number) {
    return 'بناءً على إجابتك، اتصل الآن على $number أو اطلب من شخص قريب منك أن يتصل.';
  }

  @override
  String interruptLeadFixture(String number) {
    return 'إذا كانت هذه حالة طارئة، اتصل الآن على $number أو اطلب من شخص قريب منك أن يتصل.';
  }

  @override
  String callEmergency(String number) {
    return 'اتصل على $number';
  }

  @override
  String callAdviceLine(String emergency, String advice) {
    return 'إذا لم تستطع الاتصال على $emergency، اتصل على $advice';
  }

  @override
  String get interruptMistake =>
      'إذا ضغطت \"نعم\" عن طريق الخطأ يمكنك الرجوع — تبقى إجابتك مسجلة.';

  @override
  String get goBack => 'رجوع';

  @override
  String get whoTitle => 'من يعبّئ هذا النموذج؟';

  @override
  String get whoSelf => 'أنا بنفسي';

  @override
  String get whoCarer => 'أساعد شخصاً آخر';

  @override
  String get voiceEyebrow => 'بكلماتك أنت';

  @override
  String get voiceTitle => 'صف شعورك';

  @override
  String get voiceLead =>
      'تحدث كما لو كنت تتحدث إلى ممرضة. لا توجد كلمات خاطئة.';

  @override
  String get startTalking => 'ابدأ الحديث';

  @override
  String get stopRecording => 'إيقاف التسجيل';

  @override
  String get recordAgain => 'سجّل من جديد';

  @override
  String get listeningHint => 'نستمع إليك — تحدث بشكل طبيعي وخذ وقتك.';

  @override
  String get typeInstead => 'اكتب بدلاً من ذلك إذا كان الكلام صعباً الآن';

  @override
  String get speechUnavailable =>
      'تحويل الصوت إلى نص غير متاح الآن. لا يزال بالإمكان تسجيل صوتك، والكتابة أدناه تفي بالغرض تماماً.';

  @override
  String get playRecording => 'استمع إلى تسجيلك';

  @override
  String get stopPlayback => 'إيقاف الاستماع';

  @override
  String get micPrimerTitle => 'استخدام صوتك';

  @override
  String get micPrimerBody =>
      'سيطلب هاتفك الآن إذن استخدام الميكروفون. تسجّل عافية صوتك وتحوّله إلى نص على هذه الشاشة لتراجعه قبل إرسال أي شيء. الحديث اختياري — والكتابة تعمل دائماً.';

  @override
  String get micPrimerOk => 'حسناً، اطلب الإذن';

  @override
  String get micPrimerSkip => 'سأكتب بدلاً من ذلك';

  @override
  String get functionalEyebrow => 'مقارنةً بوضعك المعتاد';

  @override
  String get fnSame => 'مثل وضعي المعتاد تقريباً';

  @override
  String get fnWorse => 'أسوأ من المعتاد';

  @override
  String get fnMuchWorse => 'أسوأ بكثير من المعتاد';

  @override
  String get reviewTitle => 'راجع ما سترسله';

  @override
  String get reviewLead =>
      'هذا كل ما أدخلته. أي شيء لم تجب عنه يظهر كـ\"لم تتم الإجابة\". يمكنك تغيير أي إجابة، أو الإرسال كما هو.';

  @override
  String get reviewSafetyHeading => 'أسئلة السلامة';

  @override
  String get reviewWhoHeading => 'من عبّأ النموذج';

  @override
  String get reviewDescriptionHeading => 'وصفك';

  @override
  String get reviewFunctionalHeading => 'مقارنةً بوضعك المعتاد';

  @override
  String get notAnswered => 'لم تتم الإجابة';

  @override
  String get voiceIncluded => 'يتضمن تسجيلاً صوتياً';

  @override
  String get edit => 'تعديل';

  @override
  String notMentioned(String item) {
    return 'لم يُذكر: $item';
  }

  @override
  String get notMentionedDescription => 'وصفك';

  @override
  String get sendToTeam => 'أرسل إلى فريق التمريض';

  @override
  String get tidyAction => 'رتّب كلماتي';

  @override
  String get tidySheetTitle => 'نسخة أكثر ترتيباً من كلماتك';

  @override
  String get tidySheetNote =>
      'أُنتجت آلياً من كلماتك أنت وغير مُتحقق منها — لم يُضف إليها شيء. استخدمها فقط إذا بدت صحيحة لك.';

  @override
  String get tidyOfflineNote => 'رُتّبت على هذا الهاتف، بدون إنترنت.';

  @override
  String get tidyUse => 'استخدم هذه النسخة';

  @override
  String get tidyKeep => 'أبقِ نسختي';

  @override
  String get tidyWorking => 'نرتّب كلماتك…';

  @override
  String get translateToArabic => 'اعرض بالعربية';

  @override
  String get translateToEnglish => 'اعرض بالإنجليزية';

  @override
  String get aiUnavailable => 'غير متاح الآن — تبقى كلماتك كما هي تماماً.';

  @override
  String get authTitle => 'سجّل الدخول للإرسال';

  @override
  String get authLead =>
      'إجاباتك جاهزة. لإرسالها إلى فريق التمريض، سجّل الدخول أو أنشئ حساباً. يبقى كل شيء محفوظاً على هذا الهاتف في هذه الأثناء.';

  @override
  String get emailSignInTitle => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get emailRegisterTitle => 'أنشئ حسابك';

  @override
  String get emailLabel => 'بريدك الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get resetTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetLead => 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.';

  @override
  String get sendResetLink => 'أرسل رابط إعادة التعيين';

  @override
  String get resetSent => 'تم الإرسال. تحقق من بريدك الإلكتروني.';

  @override
  String get haveAccount => 'لدي حساب بالفعل';

  @override
  String get noAccount => 'ليس لدي حساب بعد';

  @override
  String authError(String detail) {
    return 'حدث خطأ ما: $detail';
  }

  @override
  String get emailInvalid =>
      'البريد الإلكتروني لا يبدو صحيحاً. الرجاء التحقق منه.';

  @override
  String get passwordTooShort => 'الرجاء استخدام ٨ أحرف على الأقل.';

  @override
  String get emailInUse => 'يوجد حساب بهذا البريد بالفعل. جرّب تسجيل الدخول.';

  @override
  String get wrongPassword => 'البريد الإلكتروني وكلمة المرور غير متطابقين.';

  @override
  String get backLabel => 'رجوع';

  @override
  String get statusTitle => 'ما قمت بإرساله';

  @override
  String get caseRefLabel => 'رقم مرجع حالتك:';

  @override
  String get updateInitial => 'إجاباتك ووصفك';

  @override
  String get updateConditionChanged => 'تحديث الحالة';

  @override
  String get syncSent => 'أُرسل إلى فريق التمريض';

  @override
  String get syncQueued =>
      'محفوظ على هذا الهاتف. لم يُرسل بعد — سيُرسل عند عودة الاتصال بالإنترنت. فريق التمريض لم يطّلع عليه.';

  @override
  String get mandatoryStatusCopy =>
      'لا أحد يراقب حالتك بشكل مستمر. إذا ساءت الأمور، استخدم الزر أدناه، أو اتصل بخط التمريض، أو اتصل بخدمات الطوارئ.';

  @override
  String get statusChangeHint =>
      'إذا تغيّر أي شيء، اضغط \"حالتي تغيّرت\" أدناه. ينضم تحديثك إلى هذه الحالة نفسها — لن تبدأ من جديد أبداً.';

  @override
  String get yourAccount => 'حسابك';

  @override
  String get offlineStrip => 'غير متصل — تُحفظ إجاباتك على هذا الهاتف';

  @override
  String get statusCaseGoneTitle => 'حالتك لم تعد متوفرة';

  @override
  String get statusCaseGoneBody =>
      'حالتك المحفوظة لم تعد متوفرة. يمكنك البدء من جديد.';

  @override
  String get startAgain => 'ابدأ من جديد';

  @override
  String get updateEyebrow => 'تحديثك';

  @override
  String get updateTitle => 'ما الذي تغيّر منذ آخر مرة؟';

  @override
  String get updateLead => 'تحدث أو اكتب — أيهما أسهل لك الآن.';

  @override
  String get addToCase => 'أضف هذا إلى حالتي';

  @override
  String get updateAddedTitle => 'أُضيف التحديث';

  @override
  String get updateAddedBody =>
      'أُضيف تحديثك إلى حالتك القائمة. لم تفقد مكانك، ولا تحتاج إلى البدء من جديد.';

  @override
  String caseRefStill(String ref) {
    return 'رقم مرجع حالتك لا يزال $ref.';
  }

  @override
  String get backToCase => 'عودة إلى حالتك';

  @override
  String get accountTitle => 'حسابك';

  @override
  String get accountName => 'الاسم';

  @override
  String get accountContact => 'وسيلة التواصل';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutNote =>
      'تسجيل الخروج يمسح ما هو محفوظ على هذا الهاتف. ما أرسلته بالفعل يبقى لدى فريق التمريض.';

  @override
  String get deleteMyData => 'احذف بياناتي';

  @override
  String get deleteConfirmTitle => 'حذف بياناتك؟';

  @override
  String get deleteConfirmBody =>
      'سيحذف هذا حسابك وتفضيلاتك المحفوظة، ويسحب موافقتك على المشاركة، ويزيل كل ما هو محفوظ على هذا الهاتف. ما أرسلته بالفعل يبقى لدى فريق التمريض حتى لا تتأثر رعايتك.';

  @override
  String get deleteConfirmYes => 'احذف بياناتي';

  @override
  String get cancel => 'إلغاء';

  @override
  String get languageChoiceTitle => 'اللغة · Language';

  @override
  String get chooseEnglish => 'Continue in English';

  @override
  String get chooseArabic => 'المتابعة بالعربية';

  @override
  String get errorGeneric =>
      'حدث خطأ ما. إجاباتك لا تزال محفوظة على هذا الهاتف.';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get smsRegionBlocked =>
      'إرسال الرسائل لهذه الدولة محجوب حاليًا بسياسة مناطق الرسائل / الحصة اليومية للمشروع. للتجربة: أضف رقمك كرقم اختبار في وحدة تحكم Firebase (Authentication ← Sign-in method ← Phone ← Phone numbers for testing) وادخل بالكود الثابت — بدون رسائل. للرسائل الحقيقية: فعّل الدولة من Authentication ← Settings ← SMS region policy وأضف الفوترة.\n\nSMS to this country is currently blocked by the project\'s SMS region policy / daily quota. For testing: add your number as a TEST phone number in Firebase console (Authentication → Sign-in method → Phone → Phone numbers for testing) and sign in with its fixed code — no SMS needed. For real SMS: enable the country in Authentication → Settings → SMS region policy, and add billing.';
}
