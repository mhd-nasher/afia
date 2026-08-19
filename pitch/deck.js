// AFIA — hackathon pitch deck (full). Board-arranged narrative, approved template.
// Every slide carries speaker notes with the judges' anticipated Q&A (PR/FAQ style).
const pptxgen = require('pptxgenjs')

const C = {
  dark: '100F0E', darkSoft: '1A1817', light: 'FAF9F7', ink: '1A2438', dim: '5A6478',
  cream: 'F2EFEA', creamDim: 'A8A29B', peri: '8FA9D9', indigo: '2D4A8A',
  coral: 'E8785C', green: '58C48F', amber: 'F2B44C', border: 'E2DFD9', card: 'FFFFFF',
}
const SANS = 'Arial', MONO = 'Courier New'
const W = 13.33
const SHOT_R = 2.174 // h/w of all phone screenshots

const pres = new pptxgen()
pres.layout = 'LAYOUT_WIDE'
pres.rtlMode = true
const ar = (o = {}) => ({ fontFace: SANS, align: 'right', lang: 'ar-SA', ...o })

const icon = (s, path, x, y, size, circleColor, outline) => {
  s.addShape(pres.shapes.OVAL, {
    x, y, w: size, h: size,
    fill: outline ? { color: C.darkSoft } : { color: circleColor },
    line: outline ? { color: circleColor, width: 1.5 } : { color: circleColor, width: 0 },
  })
  s.addImage({ path, x: x + size * 0.24, y: y + size * 0.24, w: size * 0.52, h: size * 0.52 })
}
const phone = (s, path, x, y, h) => s.addImage({ path, x, y, w: h / SHOT_R, h })

const divider = (num, title, sub, notes) => {
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText(num, { x: 0.9, y: 1.7, w: 4, h: 2.2, fontFace: MONO, fontSize: 130, bold: true, color: C.peri, align: 'left' })
  s.addText(title, ar({ x: 5.4, y: 2.05, w: 7, h: 1.2, fontSize: 54, bold: true, color: C.cream }))
  s.addText(sub, ar({ x: 5.4, y: 3.3, w: 7, h: 0.9, fontSize: 18, color: C.creamDim }))
  s.addImage({ path: 'pulse-faint.png', x: 2.15, y: 4.85, w: 9, h: 2.36 })
  if (notes) s.addNotes(notes)
  return s
}

// ═══ 1 · COVER ═══════════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addImage({ path: 'pulse-periwinkle.png', x: 2.17, y: 3.05, w: 9, h: 2.36 })
  s.addText('عافية', ar({ x: 0, y: 1.1, w: W, h: 1.5, align: 'center', fontSize: 80, bold: true, color: C.cream }))
  s.addText('Afia', { x: 0, y: 2.58, w: W, h: 0.5, align: 'center', fontFace: MONO, fontSize: 18, color: C.peri })
  s.addText('تسليم مناوبات صوتي آمن — ووصول أسرع للرعاية', ar({ x: 0, y: 5.35, w: W, h: 0.6, align: 'center', fontSize: 24, color: C.creamDim }))
  s.addText('منصة مبنية ومنشورة ومُتحقَّق منها — تعمل الآن', ar({ x: 0, y: 6.05, w: W, h: 0.5, align: 'center', fontSize: 16, color: C.peri }))
  s.addNotes('الافتتاح (١٥ ثانية): "قبل أن أريكم شيئًا — كل ما ستشاهدونه اليوم يعمل الآن، منشور فعليًا، وخلفه ١١٤ اختبارًا آليًا ناجحًا. هذا ليس نموذجًا."\nس: هل هذا عرض تصوري؟ ج: لا — تطبيقان iOS جاهزان على TestFlight ولوحة تحكم منشورة على الويب وقاعدة بيانات حية.')
}

// ═══ 2 · THE MOMENT (hook) ═══════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('السادسة صباحًا.', ar({ x: 0.9, y: 1.5, w: 11.5, h: 1.1, fontSize: 44, bold: true, color: C.cream }))
  s.addText('ممرضة أنهت ١٢ ساعة على ١٢ مريضًا، وبقيت عليها أخطر عشر دقائق في الوردية كلها:\nتسليم كل ما تعرفه إلى الوردية القادمة — من الذاكرة، شفهيًا، تحت الإرهاق.', ar({ x: 0.9, y: 2.8, w: 11.5, h: 1.7, fontSize: 22, color: C.creamDim, lineSpacingMultiple: 1.35 }))
  s.addText('معلومة واحدة تسقط هنا… لا تعود.', ar({ x: 0.9, y: 5.0, w: 11.5, h: 0.9, fontSize: 28, bold: true, color: C.coral }))
  s.addImage({ path: 'pulse-faint.png', x: 0.9, y: 6.0, w: 6, h: 1.57 })
  s.addNotes('لغة الجسد: بطء وثقل. هذه شريحة الشعور — لا أرقام.\nس: ما مصدر هذه المشكلة؟ ج: تسليم المناوبات موثق عالميًا كأحد أكثر لحظات الرعاية عرضة لفقدان المعلومات؛ حلولنا صُممت مع هذه اللحظة كنقطة الصفر.')
}

// ═══ 3 · DIVIDER 01 ══════════════════════════════════════════════════════════
divider('01', 'الألم', 'ممرض يغرق في المهام الجانبية · ومريض ينتظر أكثر مما يجب',
  'انتقال: "الألم وجهان لعملة واحدة — داخل الجناح وخارجه."')

// ═══ 4 · PAIN 1: NURSE ═══════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('الوجه الأول: وقت الممرض وجودة التسليم', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const rows = [
    ['ic-clock.png', C.indigo, 'التوثيق يلتهم الوردية', 'ساعات من كل وردية تذهب للكتابة اليدوية وإعادة النسخ بين الأنظمة — على حساب الوقت السريري مع المريض.'],
    ['ic-mic.png', C.indigo, 'التسليم الشفهي يفقد الحرج', 'ما لم يُقل لا يُسلَّم. الإرهاق والمقاطعات تعني معلومات ناقصة تعبر إلى الوردية التالية بصمت.'],
    ['ic-cross.png', C.coral, 'أخطاء الأدوية المتشابهة', 'furosemide و fluoxetine — اسمان متشابهان صوتيًا لدواءين مختلفين تمامًا. هذا أخطر فشل يمكن أن ينتجه أي نظام تسليم.'],
  ]
  rows.forEach((r, i) => {
    const y = 1.75 + i * 1.75
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.72, y, w: 11.9, h: 1.5, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    icon(s, r[0], 11.55, y + 0.44, 0.62, r[1])
    s.addText(r[2], ar({ x: 6.1, y: y + 0.15, w: 5.25, h: 0.5, fontSize: 18, bold: true, color: C.ink, margin: 0 }))
    s.addText(r[3], ar({ x: 1.0, y: y + 0.62, w: 10.35, h: 0.82, fontSize: 14, color: C.dim, valign: 'top', margin: 0 }))
  })
  s.addNotes('س: ما حجم المشكلة بالأرقام؟ ج: نستهدف قياسها في التجربة الميدانية نفسها — التزامنا: أرقام مقاسة لا مزاعم. المؤشر الأدبي العالمي أن التوثيق يستهلك ما يصل لثلث وقت التمريض.\nس: لماذا التركيز على الأدوية المتشابهة؟ ج: لأنها الفشل الوحيد الذي قد يقتل مباشرة — لذلك بنينا لها طبقة اعتراض مخصصة سترونها.')
}

// ═══ 5 · PAIN 2: PATIENT ═════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('الوجه الثاني: وصول المريض للرعاية', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const rows = [
    ['ic-users.png', C.coral, 'القصة تُروى ثلاث مرات', 'المريض يصف حالته في الهاتف، ثم في الاستقبال، ثم للطاقم — والمعلومة تتآكل مع كل إعادة.'],
    ['ic-building.png', C.coral, 'الطوارئ مزدحمة بمن لا يحتاجها', 'حالات كان يمكن توجيهها مبكرًا للمسار الصحيح تنتظر في طابور الطوارئ — والحالات الحرجة تدفع الثمن.'],
    ['ic-heart.png', C.indigo, 'لا شفافية بعد الإرسال', 'أرسل المريض حالته… ثم ماذا؟ صمت. لا يعرف هل وصلت، ولا متى يتصرف إذا ساءت حالته.'],
  ]
  rows.forEach((r, i) => {
    const y = 1.75 + i * 1.75
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.72, y, w: 11.9, h: 1.5, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    icon(s, r[0], 11.55, y + 0.44, 0.62, r[1])
    s.addText(r[2], ar({ x: 6.1, y: y + 0.15, w: 5.25, h: 0.5, fontSize: 18, bold: true, color: C.ink, margin: 0 }))
    s.addText(r[3], ar({ x: 1.0, y: y + 0.62, w: 10.35, h: 0.82, fontSize: 14, color: C.dim, valign: 'top', margin: 0 }))
  })
  s.addNotes('س: كيف تسرّعون الوصول فعليًا؟ ج: المريض يصف حالته صوتيًا من بيته مرة واحدة، النظام يبنيها كملف منظم يصل للممرض قبل وصول المريض — فيبدأ العلاج من معلومات جاهزة لا من الصفر. وأسئلة الأعلام الحمراء توجه الحالة الحرجة للاتصال بالطوارئ فورًا.')
}

// ═══ 6 · DIVIDER 02 ══════════════════════════════════════════════════════════
divider('02', 'الحل: عافية', 'منظومة واحدة — ثلاث واجهات — قاعدة حية واحدة',
  'انتقال: "بنينا المنظومة كاملة. وسأريكم ثلاث لحظات فقط منها — الثلاث التي تغيّر كل شيء."')

// ═══ 7 · SOLUTION OVERVIEW ═══════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('منظومة واحدة، ثلاث واجهات', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const cards = [
    ['ic-cross.png', C.indigo, 'تطبيق الممرض', 'iOS · جاهز على TestFlight', 'تكلم — والنظام يحوّل الكلام إلى تسليم منظم بقالب الجناح، يكشف النواقص، ويؤمّن الأدوية، ويوقَّع ويُسجَّل.'],
    ['ic-heart.png', C.coral, 'تطبيق المريض', 'iOS · جاهز على TestFlight', 'حساب بسيط، «أبلغ عن حالتي» بزر واحد، أعلام حمراء فورية بدون إنترنت، وسجل تقارير واضح.'],
    ['ic-building.png', C.green, 'لوحة الإدارة', 'ويب · منشورة الآن', 'مراقبة حية لتجاوزات وقت المراجعة، إنشاء حسابات الطاقم، إدارة القوالب والأسئلة بسجل حوكمة.'],
  ]
  cards.forEach((c0, i) => {
    const x = 0.72 + i * 4.02
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.7, w: 3.86, h: 4.6, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    icon(s, c0[0], x + 3.86 / 2 - 0.36, 2.0, 0.72, c0[1])
    s.addText(c0[2], ar({ x: x + 0.2, y: 2.9, w: 3.46, h: 0.5, align: 'center', fontSize: 20, bold: true, color: C.ink }))
    s.addText(c0[3], { x: x + 0.2, y: 3.42, w: 3.46, h: 0.35, align: 'center', fontFace: MONO, fontSize: 11, color: c0[1] })
    s.addText(c0[4], ar({ x: x + 0.3, y: 3.9, w: 3.26, h: 2.2, align: 'center', fontSize: 13.5, color: C.dim, valign: 'top' }))
  })
  s.addText('قاعدة المبدأ: الذكاء الاصطناعي يعيد تنظيم ما قاله الإنسان — ولا يُصدر حكمًا سريريًا أبدًا', ar({ x: 0.7, y: 6.55, w: 12, h: 0.5, align: 'center', fontSize: 15, bold: true, color: C.indigo }))
  s.addNotes('س: من يكتب البيانات الطبية إذن؟ ج: البشر فقط. الذكاء الاصطناعي منظِّم وموزِّع — والممرض المرخص يراجع ويوقع. هذا قرار معماري وتنظيمي واعٍ.')
}

// ═══ 8 · CLINICIAN WALKTHROUGH ═══════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('اللحظة الأولى: الكلام يصبح تسليمًا', ar({ x: 0.7, y: 0.5, w: 12, h: 0.7, fontSize: 32, bold: true, color: C.cream }))
  phone(s, 'shots/c-03-ward-list.png', 9.6, 1.5, 5.5)
  phone(s, 'shots/c-04-draft-review.png', 6.7, 1.5, 5.5)
  const rows = [
    ['١٢', 'مريضًا في شاشة واحدة بلا تمرير — لمحة الوردية كاملة'],
    ['ic-mic.png', 'الممرض يتكلم طبيعيًا — والقالب يمتلئ ويُحفظ كل ٤ ثوانٍ'],
    ['ic-check.png', 'النواقص تُعلَن بحيادية: «غير مذكور: وقت آخر مسكّن» — ولا تمنع التوقيع أبدًا'],
  ]
  rows.forEach((r, i) => {
    const y = 1.9 + i * 1.5
    if (r[0].endsWith('.png')) icon(s, r[0], 5.7, y, 0.6, C.peri, true)
    else {
      s.addShape(pres.shapes.OVAL, { x: 5.7, y, w: 0.6, h: 0.6, fill: { color: C.darkSoft }, line: { color: C.peri, width: 1.5 } })
      s.addText(r[0], { x: 5.7, y, w: 0.6, h: 0.6, align: 'center', valign: 'middle', fontSize: 16, bold: true, color: C.peri, margin: 0 })
    }
    s.addText(r[1], ar({ x: 0.55, y: y - 0.18, w: 4.95, h: 1.0, fontSize: 14.5, color: C.creamDim, valign: 'middle' }))
  })
  s.addNotes('اليسار: قائمة الجناح (١٢ صف). اليمين: مراجعة المسودة — النص الآلي بلون البريوينكل حتى يوقّعه إنسان.\nس: ماذا لو أخطأ التفريغ؟ ج: النص غير الموثق مميز بصريًا، والصوت الأصلي محفوظ قابل للتشغيل دائمًا، والأرقام والأدوية تُعزل كرقاقات تتطلب تأكيدًا فرديًا — التالي.')
}

// ═══ 9 · DRUG SAFETY (THE PEAK) ══════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('اللحظة الثانية: اعتراض الخطأ القاتل', ar({ x: 0.7, y: 0.5, w: 12, h: 0.7, fontSize: 32, bold: true, color: C.cream }))
  phone(s, 'shots/c-05-confirm-chip.png', 9.6, 1.5, 5.5)
  phone(s, 'shots/c-06-sign-sheet.png', 6.7, 1.5, 5.5)
  const rows = [
    ['ic-shield.png', 'كل دواء وكل جرعة رقاقة مستقلة — تأكيد فردي إجباري، ولا يوجد «تأكيد الكل» في النظام أصلًا'],
    ['ic-zap.png', 'المتشابهات الصوتية تُعرض معًا عمدًا (furosemide / fluoxetine) مع إعادة سماع الصوت الأصلي'],
    ['ic-check.png', 'التوقيع بالضغط المطوّل — وهوية الموقّع محفورة لا يعدّلها أحد'],
  ]
  rows.forEach((r, i) => {
    const y = 1.9 + i * 1.5
    icon(s, r[0], 5.7, y, 0.6, C.coral, true)
    s.addText(r[1], ar({ x: 0.55, y: y - 0.18, w: 4.95, h: 1.0, fontSize: 14.5, color: C.creamDim, valign: 'middle' }))
  })
  s.addNotes('هذه ذروة العرض — أبطئ هنا.\nس: لماذا لا يوجد "تأكيد الكل"؟ أليس أسرع؟ ج: لأن استبدال دواء متشابه صوتيًا هو أخطر فشل ممكن، وطبقة التأكيد الفردي هي خط الاعتراض الوحيد. حذفنا الزر من الوجود — القاعدة مفروضة في الكود وقاعدة البيانات معًا، لا في الواجهة فقط.\nس: وماذا عن النواقص؟ ج: عكسها تمامًا — لا تمنع التوقيع أبدًا (البيانات الخاطئة تقتل، الناقصة تُوثَّق وتُمرَّر) — هذه فلسفة النظام.')
}

// ═══ 10 · AI ASSISTANT ═══════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('اللحظة الثالثة: مساعد عافية — رفيق الوردية', ar({ x: 0.7, y: 0.5, w: 12, h: 0.7, fontSize: 32, bold: true, color: C.cream }))
  phone(s, 'shots/c-07-ward-list-ar.png', 9.9, 1.5, 5.5)
  const rows = [
    ['«كم حالة عندي اليوم؟»', 'يعدّ من القاعدة الحية ويجيب ببطاقات منظمة — أرقام حقيقية، ليست نصًا منسوخًا'],
    ['«وش باقي عليّ بالوردية؟»', 'قائمة مهام مشتقة من الواقع: تسليمات بلا توقيع، أدوية بلا تأكيد، طلبات معلقة'],
    ['«رتب لي مرضاي: غير الموقَّع أولًا»', 'يرتب القائمة ويحفظ ترتيبك الشخصي — ويقترح طلب مساعدة زميل حاضر، والإرسال بلمستك أنت'],
  ]
  rows.forEach((r, i) => {
    const y = 1.75 + i * 1.65
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.55, y, w: 8.9, h: 1.42, fill: { color: C.darkSoft }, line: { color: C.peri, width: 1 }, rectRadius: 0.08 })
    s.addText(r[0], ar({ x: 0.85, y: y + 0.12, w: 8.3, h: 0.5, fontSize: 16, bold: true, color: C.peri, margin: 0 }))
    s.addText(r[1], ar({ x: 0.85, y: y + 0.62, w: 8.3, h: 0.72, fontSize: 13.5, color: C.creamDim, valign: 'top', margin: 0 }))
  })
  s.addText('يتعلم تفضيلات كل ممرض من استخدامه — بذاكرة خاصة به لا يراها غيره', ar({ x: 0.55, y: 6.85, w: 8.9, h: 0.45, fontSize: 13, italic: true, color: C.peri }))
  s.addNotes('س: ماذا لو طلب منه الممرض ترتيب المرضى بالأخطر؟ ج: يرفض ويشرح: الترتيب بالحقائق فقط (وقت الانتظار، الاكتمال، حالة التوقيع) — ترتيب الخطورة حكم سريري والنظام لا يصدره بنيويًا: لا توجد أداة تحمل حقل خطورة أصلًا.\nس: أي نموذج؟ ج: Gemini Flash عبر Firebase AI Logic — بلا خادم وسيط، ومع بديل حتمي يعمل بلا إنترنت فلا يتعطل التطبيق أبدًا.')
}

// ═══ 11 · TEAMWORK ═══════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('طبقة الفريق: الوردية تتعاون بلمسة', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const cards = [
    ['ic-users.png', C.green, 'من في الوردية الآن', 'حضور لحظي حقيقي — يظهر الموجودون فعلًا فقط، ويختفون تلقائيًا عند الانقطاع'],
    ['ic-zap.png', C.indigo, 'طلبات جاهزة بلا كتابة', '٨ طلبات بلمسة: شاهد دواء · تغطية استراحة · رفع مريض · كانيولا · مراجعة عاجلة…'],
    ['ic-check.png', C.coral, 'وارد بقسمين', 'التسليم | الطلبات — بعدّاد معلّق، وقبول/إنجاز موثّق الطرفين'],
  ]
  cards.forEach((c0, i) => {
    const x = 0.72 + i * 4.02
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.8, w: 3.86, h: 3.9, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    icon(s, c0[0], x + 3.86 / 2 - 0.36, 2.1, 0.72, c0[1])
    s.addText(c0[2], ar({ x: x + 0.2, y: 3.0, w: 3.46, h: 0.55, align: 'center', fontSize: 18, bold: true, color: C.ink }))
    s.addText(c0[3], ar({ x: x + 0.3, y: 3.6, w: 3.26, h: 1.9, align: 'center', fontSize: 13.5, color: C.dim, valign: 'top' }))
  })
  s.addText('مبنية على Firebase Realtime Database — انسيابية لحظية بقواعد أمان تمنع انتحال الحضور', ar({ x: 0.7, y: 6.0, w: 12, h: 0.5, align: 'center', fontSize: 14, color: C.dim }))
  s.addNotes('س: لماذا قاعدتا بيانات؟ ج: فصل مقصود — السجلات السريرية في Firestore (منطقة الشرق الأوسط)، وبيانات التشغيل اللحظية (حضور/طلبات — لا محتوى سريري) في Realtime DB. لكل عبء أداته.\nس: هل الطلبات موثقة؟ ج: نعم، بحالة معلّق→مقبول→منجز لا يعدلها إلا طرفا الطلب.')
}

// ═══ 12 · PATIENT APP ════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('تطبيق المريض: بسيط لدرجة أن الخوف لا يضيع فيه', ar({ x: 0.7, y: 0.5, w: 12, h: 0.7, fontSize: 30, bold: true, color: C.cream }))
  phone(s, 'shots/p-02-home.png', 10.3, 1.45, 5.35)
  phone(s, 'shots/p-03-red-flag.png', 7.5, 1.45, 5.35)
  phone(s, 'shots/p-04-emergency-interrupt.png', 4.7, 1.45, 5.35)
  const pts = [
    'رئيسية بزر واحد كبير + شريط تنقل واضح + سجل تقاريرك',
    'أعلام حمراء فورية بدون إنترنت — و«لا أعرف» إجابة محترمة لا تُخفّض شيئًا',
    'الأحمر يُصرف كله في شاشة واحدة: ٩٩٩ فورًا — وزر الطوارئ حاضر في كل شاشة حتى قبل الدخول',
  ]
  pts.forEach((t, i) => {
    s.addText(t, ar({ x: 0.5, y: 1.85 + i * 1.6, w: 3.95, h: 1.4, fontSize: 13.5, color: C.creamDim, valign: 'top', bullet: { code: '2022' } }))
  })
  s.addNotes('س: لماذا الحساب أولًا؟ ج: اختبرناه — البساطة والوضوح فازا؛ ومع ذلك الطوارئ لا تحتاج حسابًا أبدًا: الزر يعمل من شاشة الدخول نفسها وبلا إنترنت.\nس: ماذا يرى المريض بعد الإرسال؟ ج: بطاقة حالة صادقة + نص إلزامي: "لا أحد يراقب حالتك باستمرار — إذا ساءت اتصل…" — منتج أمين لا يبيع شعورًا زائفًا بالأمان.')
}

// ═══ 13 · DASHBOARD ══════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('لوحة الإدارة: العين التي تُبقي الوعد صادقًا', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const rows = [
    ['ic-clock.png', C.coral, 'إنذار تجاوز وقت المراجعة', 'كل جناح يلتزم بوقت مراجعة باسم مسؤول — واللوحة تفضح أي ملف تجاوزه. لوحة الخرق تظهر حتى وهي فارغة وتقول ذلك.'],
    ['ic-users.png', C.indigo, 'حسابات الطاقم بالدعوات', 'الممرض لا يسجل نفسه — الإدارة تدعوه بالإيميل بهوية توقيع دائمة. سجل دخول للأجهزة المشتركة.'],
    ['ic-shield.png', C.green, 'حوكمة الأسئلة السريرية', 'كل قاعدة علم أحمر تحمل اسم معتمِدها ودوره وتاريخه — وتعديلها يتطلب اسم المعتمد. الجودة كلها مجمّعة بلا أي قياس فردي.'],
  ]
  rows.forEach((r, i) => {
    const y = 1.75 + i * 1.72
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.72, y, w: 11.9, h: 1.5, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    icon(s, r[0], 11.55, y + 0.44, 0.62, r[1])
    s.addText(r[2], ar({ x: 6.1, y: y + 0.15, w: 5.25, h: 0.5, fontSize: 18, bold: true, color: C.ink, margin: 0 }))
    s.addText(r[3], ar({ x: 1.0, y: y + 0.62, w: 10.35, h: 0.82, fontSize: 13.5, color: C.dim, valign: 'top', margin: 0 }))
  })
  s.addText('منشورة الآن: afia-dashboard.vercel.app', { x: 0.7, y: 6.95, w: 12, h: 0.4, align: 'center', fontFace: MONO, fontSize: 13, color: C.indigo })
  s.addNotes('س: لماذا لا تقيسون أداء الممرض الفرد؟ ج: قرار مبدئي محفور: لا سرعة فردية، لا ترتيب، لا مقارنات — القياس الفردي يفسد الثقة ويشوه السلوك. كل الجودة مجمّعة على مستوى الجناح.\nس: هل اللوحة في المسار السريري؟ ج: لا — تراقب وتضبط فقط؛ ملف المريض يذهب للممرض مباشرة.')
}

// ═══ 14 · DIVIDER 03 ═════════════════════════════════════════════════════════
divider('03', 'التقنية والذكاء', 'بنية تفرض السلامة — وذكاء لا يستطيع أن يخطئ سريريًا',
  'انتقال: "الآن الجزء الذي يجعل كل ما سبق غير قابل للكسر."')

// ═══ 15 · ARCHITECTURE + INTEGRATION ═════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('البنية: القواعد محفورة في كل طبقة', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  // three surface chips → one core
  const surf = [['تطبيق الممرض', C.indigo], ['تطبيق المريض', C.coral], ['لوحة الإدارة', C.green]]
  surf.forEach((t, i) => {
    const x = 1.2 + i * 3.85
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.6, w: 3.1, h: 0.75, fill: { color: C.card }, line: { color: t[1], width: 1.5 }, rectRadius: 0.1 })
    s.addText(t[0], ar({ x, y: 1.6, w: 3.1, h: 0.75, align: 'center', valign: 'middle', fontSize: 15, bold: true, color: C.ink, margin: 0 }))
    s.addShape(pres.shapes.LINE, { x: x + 1.55, y: 2.35, w: 0, h: 0.55, line: { color: C.dim, width: 1.5 } })
  })
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 1.2, y: 2.95, w: 10.8, h: 1.15, fill: { color: C.ink }, rectRadius: 0.1 })
  s.addText([
    { text: 'Firebase — قاعدة حية واحدة    ', options: { bold: true, color: 'FFFFFF' } },
    { text: 'Firestore (السجلات · الشرق الأوسط)  ·  Realtime DB (التشغيل اللحظي)  ·  AI Logic (Gemini)', options: { color: C.peri } },
  ], ar({ x: 1.5, y: 2.95, w: 10.2, h: 1.15, align: 'center', valign: 'middle', fontSize: 14 }))
  const pillars = [
    'قواعد أمان على مستوى القاعدة: لا تخفيض أولوية، لا تعديل توقيع، سجل تدقيق لا يُمحى — حتى لو عُدّل التطبيق نفسه',
    'التصعيد أحادي الاتجاه و«غير معروف» قيمة من الدرجة الأولى — عشرة قيود سلامة مفروضة في الأنواع والاختبارات',
    'جاهز للتكامل: النظام يولّد FHIR DocumentReference صالحًا — ربط أي نظام مستشفى (HIS/EMR) يعني كتابة مُصدِّر واحد، لا إعادة بناء',
  ]
  pillars.forEach((t, i) => {
    s.addText(t, ar({ x: 1.0, y: 4.4 + i * 0.85, w: 11.3, h: 0.8, fontSize: 14, color: C.dim, bullet: { code: '2022' }, valign: 'top' }))
  })
  s.addNotes('س: هل أنتم متكاملون مع Epic/Cerner اليوم؟ ج: بدقة: نحن FHIR-ready — نولّد سجلات DocumentReference صالحة بمعيار المستشفيات العالمي؛ التكامل الفعلي مع أي نظام = مُصدِّر واحد يُكتب في التجربة الميدانية. لا نبيعكم تكاملًا لم يحدث.\nس: أين البيانات؟ ج: السجلات السريرية في منطقة الشرق الأوسط (me-central2)، محكومة بقواعد وصول صارمة، وللمريض حق حذف بياناته.')
}

// ═══ 16 · THE AI SECRET ══════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('سرّنا: الذكاء الآمن ليس وعدًا — بل بنية', ar({ x: 0.7, y: 0.6, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.cream }))
  icon(s, 'ic-sparkle.png', 11.7, 0.62, 0.72, C.peri)
  s.addText('كل حلول الذكاء الطبي تَعِد: «سنحاول ألا نخطئ».\nعافية بُنيت مختلفة: الحكم السريري ليس ممنوعًا بسياسة — بل مستحيل بنيويًا.', ar({ x: 0.9, y: 1.7, w: 11.5, h: 1.3, fontSize: 20, color: C.creamDim, lineSpacingMultiple: 1.3 }))
  const rows = [
    ['أدوات المساعد لا تحتوي أداة تشخيص أو تقييم خطورة — لا يمكن استدعاء ما هو غير موجود', 'ic-shield.png'],
    ['أنواع البيانات نفسها لا تحمل حقل خطورة — تُسقطه عند القراءة قبل أن يصل للنموذج', 'ic-zap.png'],
    ['مخرجات تطبيق المريض تُطابَق كلمة-بكلمة مع كلامه هو — أي إضافة من النموذج تُرمى', 'ic-check.png'],
    ['وإن غاب الإنترنت أو النموذج: بديل حتمي يكمل العمل — التطبيق لا يتعطل أبدًا', 'ic-heart.png'],
  ]
  rows.forEach((r, i) => {
    const y = 3.35 + i * 0.92
    icon(s, r[1], 11.85, y, 0.52, C.peri, true)
    s.addText(r[0], ar({ x: 0.9, y: y - 0.05, w: 10.7, h: 0.75, fontSize: 15, color: C.cream, valign: 'middle' }))
  })
  s.addNotes('هذه شريحة التميّز — ما من فريق آخر سيقولها.\nس: لماذا تقيدون الذكاء لهذه الدرجة؟ ج: لأن خط "الجهاز الطبي" التنظيمي يبدأ حيث يبدأ الحكم السريري الآلي. بالبقاء خلفه بنيويًا: نشر أسرع، ثقة أعلى، ومسؤولية واضحة — الإنسان المرخص هو من يحكم دائمًا.\nس: أي نموذج ولماذا؟ ج: Gemini Flash عبر Firebase AI Logic — درجة حرارة صفر، مخرجات ببنية مفروضة، ويتعلم تفضيلات الاستخدام (لا الطب).')
}

// ═══ 17 · EVIDENCE ═══════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('لا نطلب تصديقنا — هذه الأدلة', ar({ x: 0.7, y: 0.55, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const tiles = [
    ['114', 'اختبارًا آليًا ناجحًا عبر المنظومة', C.indigo],
    ['10', 'قيود سلامة مفروضة بنيويًا', C.coral],
    ['3', 'واجهات تعمل على قاعدة حية واحدة', C.indigo],
    ['0', 'حكم سريري يصدر من الذكاء الاصطناعي', C.green],
  ]
  tiles.forEach((t, i) => {
    const x = 0.72 + i * 3.02
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.95, w: 2.86, h: 3.0, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    s.addText(t[0], { x, y: 2.3, w: 2.86, h: 1.45, align: 'center', fontFace: MONO, fontSize: 62, bold: true, color: t[2], margin: 0 })
    s.addText(t[1], ar({ x: x + 0.18, y: 3.85, w: 2.5, h: 0.95, align: 'center', fontSize: 13.5, color: C.dim, valign: 'top' }))
  })
  s.addText('ومصارحةً للجنة: دقة التفريغ على لهجات الأجنحة الحقيقية لم تُقس بعد، وتكامل المستشفيات لم يُثبت ميدانيًا — هذان بالضبط هدفا تجربتنا الميدانية الأولى. نظام يعرف حدوده نظامٌ يمكن الوثوق به.', ar({ x: 0.9, y: 5.35, w: 11.5, h: 1.3, fontSize: 15, italic: true, color: C.dim, lineSpacingMultiple: 1.3 }))
  s.addNotes('الصدق هنا سلاح وليس اعترافًا — لجنة فيها أطباء ستحترم فريقًا يعرف حدود نظامه.\nس: كم استغرق البناء؟ ج: جلسة تطوير مكثفة واحدة بمنهجية وكلاء ذكاء اصطناعي متوازين تحت حوكمة صارمة — والدليل: كل commit موثق وكل ميزة وراءها اختبار.')
}

// ═══ 18 · DIVIDER 04 ═════════════════════════════════════════════════════════
divider('04', 'السوق والفرصة', 'من يحتاج عافية — ولماذا الخليج أولًا',
  'انتقال سريع — الجمهور ثم SWOT ثم الإغلاق.')

// ═══ 19 · TARGET AUDIENCE ════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('الجمهور المستهدف — بدقة', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const rows = [
    ['المستخدم الأول', 'ممرضو ومشرفو أجنحة التنويم (Acute/Medical) في المستشفيات الحكومية والخاصة — يسلّمون ٨-١٢ مريضًا كل وردية، أجهزتهم مشتركة، ووقتهم أثمن مورد بالمنشأة', C.indigo],
    ['المستخدم الثاني', 'المرضى وذووهم قبل القدوم للمنشأة — خصوصًا كبار السن ومرافقوهم: واجهة ٦٤ بكسل، عربي/إنجليزي، و«لا أعرف» إجابة محترمة', C.coral],
    ['صاحب القرار (المشتري)', 'إدارات التمريض والجودة وتحول الصحة الرقمية — في البحرين أولًا (وزارة الصحة والمستشفيات الخاصة)، ثم الخليج: نفس اللغة، نفس أنماط التشغيل، وأنظمة صحية تتحول رقميًا بميزانيات نشطة', C.green],
    ['شريك التوسع', 'مزوّدو أنظمة المستشفيات (HIS) المحليون — عافية لا تنافسهم بل تكمل أخطر فجوة عندهم، وتتصل بهم عبر FHIR', C.amber],
  ]
  rows.forEach((r, i) => {
    const y = 1.6 + i * 1.35
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.72, y, w: 11.9, h: 1.18, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.85, y: y + 0.25, w: 2.5, h: 0.68, fill: { color: r[2] }, rectRadius: 0.34 })
    s.addText(r[0], ar({ x: 9.85, y: y + 0.25, w: 2.5, h: 0.68, align: 'center', valign: 'middle', fontSize: 13.5, bold: true, color: 'FFFFFF', margin: 0 }))
    s.addText(r[1], ar({ x: 1.0, y: y + 0.12, w: 8.6, h: 0.98, fontSize: 12.5, color: C.dim, valign: 'middle', margin: 0 }))
  })
  s.addNotes('س: لماذا البحرين أولًا؟ ج: قاعدة بياناتنا أصلًا في المنطقة، أرقام الطوارئ مدمجة (٩٩٩/٤٤٤)، حجم سوق يسمح بتجربة سريعة مع وصول مباشر لصناع القرار — ثم التوسع الخليجي بنفس المنتج حرفيًا.\nس: النموذج الربحي؟ ج: اشتراك سنوي لكل سرير + رسوم تفعيل مؤسسية — يُسعَّر بعد قياس وفر الوقت في التجربة الأولى.')
}

// ═══ 20 · SWOT ═══════════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('SWOT — بعيون مفتوحة', ar({ x: 0.7, y: 0.45, w: 12, h: 0.7, fontSize: 34, bold: true, color: C.ink }))
  const q = (x, y, title, color, items) => {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w: 5.9, h: 2.85, fill: { color: C.card }, line: { color, width: 1.5 }, rectRadius: 0.08 })
    s.addText(title, ar({ x: x + 0.25, y: y + 0.12, w: 5.4, h: 0.45, fontSize: 17, bold: true, color }))
    s.addText(items.map((t, i) => ({ text: t, options: { bullet: { code: '2022' }, breakLine: i < items.length - 1, paraSpaceAfter: 5 } })),
      ar({ x: x + 0.3, y: y + 0.62, w: 5.35, h: 2.1, fontSize: 12, color: C.dim, valign: 'top' }))
  }
  q(6.72, 1.35, 'القوة', C.green, [
    'منتج مكتمل يعمل الآن — لا فكرة على ورق',
    'سلامة مفروضة بنيويًا + ١١٤ اختبارًا',
    'عربي/إنجليزي أصيل بتصميم يحترم الميدان',
    'FHIR-ready — طريق تكامل واضح',
  ])
  q(0.72, 1.35, 'الضعف', C.coral, [
    'دقة التفريغ على لهجات الأجنحة غير مقاسة بعد',
    'لا تجربة ميدانية في مستشفى حتى الآن',
    'iOS أولًا — أندرويد لاحق',
    'فريق صغير — التوسع يحتاج شركاء',
  ])
  q(6.72, 4.35, 'الفرص', C.indigo, [
    'تحول رقمي صحي خليجي بميزانيات نشطة',
    'نقص التمريض عالميًا يرفع قيمة كل دقيقة',
    'شراكات HIS المحلية عبر FHIR',
    'التوسع: العيادات، الرعاية المنزلية، الأسنان',
  ])
  q(0.72, 4.35, 'التهديدات', C.amber, [
    'التصنيف التنظيمي للأدوات السريرية الرقمية',
    'دخول عمالقة HIS على نفس الفجوة',
    'حساسية بيانات صحية = ثقة تُبنى ببطء',
    'تغير أنظمة الخصوصية بين دول الخليج',
  ])
  s.addNotes('س: أكبر تهديد؟ ج: التصنيف التنظيمي — ولهذا بالضبط بنينا الذكاء بلا أحكام سريرية وبقواعد حتمية قابلة للتدقيق: نبقى في الجانب الآمن من الخط بتصميمنا لا بحظنا.')
}

// ═══ 21 · CLOSE ══════════════════════════════════════════════════════════════
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addImage({ path: 'pulse-periwinkle.png', x: 2.17, y: 2.7, w: 9, h: 2.36 })
  s.addText('عافية تعمل الآن.', ar({ x: 0, y: 1.15, w: W, h: 1.0, align: 'center', fontSize: 48, bold: true, color: C.cream }))
  s.addText('تطبيقان على TestFlight · لوحة منشورة · قاعدة حية · ١١٤ اختبارًا', ar({ x: 0, y: 5.2, w: W, h: 0.5, align: 'center', fontSize: 18, color: C.creamDim }))
  s.addText('الخطوة التالية: تجربة ميدانية في جناح واحد — ٩٠ يومًا تقيس الوقت الموفَّر وجودة التسليم', ar({ x: 0, y: 5.85, w: W, h: 0.5, align: 'center', fontSize: 16, color: C.peri }))
  s.addText('شكرًا — جاهزون لأي سؤال', ar({ x: 0, y: 6.6, w: W, h: 0.5, align: 'center', fontSize: 15, bold: true, color: C.cream }))
  s.addNotes('الإغلاق: "غيرنا سيعرض عليكم أفكارًا. نحن نعرض عليكم نظامًا يعمل — والفرق بين الاثنين هو بالضبط الفرق بين مشروع هاكاثون ومنتج يدخل مستشفى." ثم: افتحوا TestFlight وجربوه الآن.\nأسئلة الخاتمة المتوقعة:\nس: ما الذي تحتاجونه للفوز بعد اليوم؟ ج: جناح تجريبي واحد وشريك حكومي — كل شيء تقني جاهز.\nس: لماذا أنتم؟ ج: لأننا الوحيدون الذين جاؤوا بمنتج محكوم بقواعد سلامة قابلة للتدقيق — لا بعرض شرائح.')
}

pres.writeFile({ fileName: 'afia-pitch.pptx' }).then(() => console.log('deck written'))
