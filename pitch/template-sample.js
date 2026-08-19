// Afia pitch deck — DESIGN TEMPLATE SAMPLE (5 slides, one per layout).
// Identity: the product's own design language — warm-dark covers, cream
// content, periwinkle=AI accent, indigo=action, pulse motif, mono numbers.
const pptxgen = require('pptxgenjs')

const C = {
  dark: '100F0E',      // warm dark (covers/dividers)
  darkSoft: '1A1817',  // elevated dark surface
  light: 'FAF9F7',     // content background (brand off-white)
  ink: '1A2438',       // primary text on light
  dim: '5A6478',       // secondary text on light
  cream: 'F2EFEA',     // primary text on dark
  creamDim: 'A8A29B',  // secondary text on dark
  peri: '8FA9D9',      // periwinkle — the AI accent
  indigo: '2D4A8A',    // action indigo
  coral: 'E8785C',     // sparse alert accent
  green: '58C48F',
  border: 'E2DFD9',
  card: 'FFFFFF',
}
const SANS = 'Arial'
const MONO = 'Courier New'
const W = 13.33, H = 7.5

const pres = new pptxgen()
pres.layout = 'LAYOUT_WIDE'
pres.rtlMode = true

const ar = (opts = {}) => ({ fontFace: SANS, align: 'right', lang: 'ar-SA', ...opts })

// ── S1 · COVER (dark) ────────────────────────────────────────────────────────
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addImage({ path: 'pulse-periwinkle.png', x: 2.17, y: 3.05, w: 9, h: 2.36 })
  s.addText('عافية', ar({ x: 0, y: 1.15, w: W, h: 1.5, align: 'center', fontSize: 80, bold: true, color: C.cream }))
  s.addText('Afia', { x: 0, y: 2.62, w: W, h: 0.5, align: 'center', fontFace: MONO, fontSize: 18, color: C.peri })
  s.addText('تسليم مناوبات صوتي آمن — ووصول أسرع للرعاية', ar({ x: 0, y: 5.3, w: W, h: 0.6, align: 'center', fontSize: 24, color: C.creamDim }))
  s.addText([
    { text: 'هاكاثون ٢٠٢٦  ·  ', options: { color: C.creamDim } },
    { text: 'فريق عافية', options: { color: C.peri, bold: true } },
  ], ar({ x: 0, y: 6.7, w: W, h: 0.4, align: 'center', fontSize: 14 }))
}

// ── S2 · SECTION DIVIDER (dark) ──────────────────────────────────────────────
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('01', { x: 0.9, y: 1.7, w: 4, h: 2.2, fontFace: MONO, fontSize: 130, bold: true, color: C.peri, align: 'left' })
  s.addText('الألم', ar({ x: 5.4, y: 2.05, w: 7, h: 1.2, fontSize: 54, bold: true, color: C.cream }))
  s.addText('ممرض يغرق في المهام الجانبية · ومريض ينتظر أكثر مما يجب', ar({ x: 5.4, y: 3.3, w: 7, h: 0.6, fontSize: 18, color: C.creamDim }))
  s.addImage({ path: 'pulse-faint.png', x: 2.15, y: 4.75, w: 9, h: 2.36 })
}

// ── S3 · CONTENT: two-column problem/solution (light) ───────────────────────
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('مشكلتان، منظومة واحدة', ar({ x: 0.7, y: 0.5, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))

  const col = (x, iconPath, iconBg, title, lines) => {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.7, w: 5.85, h: 5.1, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    s.addShape(pres.shapes.OVAL, { x: x + 5.85 - 0.95, y: 2.0, w: 0.62, h: 0.62, fill: { color: iconBg } })
    s.addImage({ path: iconPath, x: x + 5.85 - 0.95 + 0.14, y: 2.14, w: 0.34, h: 0.34 })
    s.addText(title, ar({ x: x + 0.3, y: 2.0, w: 5.85 - 1.45, h: 0.62, fontSize: 19, bold: true, color: C.ink, valign: 'middle', margin: 0 }))
    s.addText(lines.map((t, i) => ({ text: t, options: { bullet: true, breakLine: i < lines.length - 1, paraSpaceAfter: 10 } })),
      ar({ x: x + 0.35, y: 2.95, w: 5.85 - 0.75, h: 3.6, fontSize: 15, color: C.dim, valign: 'top' }))
  }
  col(6.75, 'ic-cross.png', C.indigo, 'وقت الممرض وجودة التسليم', [
    'التوثيق اليدوي يستهلك ساعات من كل وردية',
    'تسليم المناوبة الشفهي يفقد معلومات حرجة',
    'أخطاء أسماء الأدوية المتشابهة أخطر فشل ممكن',
  ])
  col(0.72, 'ic-clock.png', C.coral, 'وصول المريض للرعاية', [
    'وصف الحالة يتكرر ثلاث مرات قبل العلاج',
    'الطوارئ تستقبل حالات كان يمكن توجيهها مبكرًا',
    'لا شفافية عن حالة الطلب بعد إرساله',
  ])
}

// ── S4 · STATS (light) ───────────────────────────────────────────────────────
{
  const s = pres.addSlide()
  s.background = { color: C.light }
  s.addText('مبني ومُتحقق منه — أرقام حقيقية', ar({ x: 0.7, y: 0.55, w: 12, h: 0.8, fontSize: 34, bold: true, color: C.ink }))
  const tiles = [
    { n: '114', l: 'اختبارًا آليًا ناجحًا', c: C.indigo },
    { n: '10', l: 'قيود سلامة بنيوية', c: C.coral },
    { n: '3', l: 'واجهات على قاعدة واحدة', c: C.indigo },
    { n: '0', l: 'حكم سريري من الذكاء الاصطناعي', c: C.green },
  ]
  tiles.forEach((t, i) => {
    const x = 0.72 + i * 3.02
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 2.1, w: 2.86, h: 3.1, fill: { color: C.card }, line: { color: C.border, width: 1 }, rectRadius: 0.08 })
    s.addText(t.n, { x, y: 2.5, w: 2.86, h: 1.5, align: 'center', fontFace: MONO, fontSize: 64, bold: true, color: t.c, margin: 0 })
    s.addText(t.l, ar({ x: x + 0.2, y: 4.1, w: 2.46, h: 0.9, align: 'center', fontSize: 14, color: C.dim, valign: 'top' }))
  })
  s.addText('كل رقم أعلاه قابل للإثبات من مستودع الكود مباشرة', ar({ x: 0.7, y: 5.9, w: 12, h: 0.5, align: 'center', fontSize: 13, italic: true, color: C.dim }))
}

// ── S5 · SCREENSHOT LAYOUT (dark) ────────────────────────────────────────────
{
  const s = pres.addSlide()
  s.background = { color: C.dark }
  s.addText('تطبيق الممرض — قائمة الجناح', ar({ x: 0.7, y: 0.55, w: 12, h: 0.7, fontSize: 32, bold: true, color: C.cream }))
  // Device screenshot — phone-shaped: soft-rounded rectangle, true aspect 2.174
  s.addImage({ path: 'shot-ward.png', x: 9.15, y: 1.5, w: 2.53, h: 5.5 })
  const rows = [
    [{ t: '١٢' }, 'مريضًا في شاشة واحدة — بدون تمرير، مصمم لِلَمْحة الوردية'],
    [{ ic: 'ic-check.png' }, 'حالة كل تسليم واضحة: موقّع ≠ مسجَّل في النظام'],
    [{ ic: 'ic-zap.png' }, 'حفظ تلقائي كل ٤ ثوانٍ — وضع الجهاز جانبًا آمن دائمًا'],
  ]
  rows.forEach((r, i) => {
    const y = 1.9 + i * 1.5
    s.addShape(pres.shapes.OVAL, { x: 7.7, y, w: 0.6, h: 0.6, fill: { color: C.darkSoft }, line: { color: C.peri, width: 1.5 } })
    if (r[0].t) {
      s.addText(r[0].t, { x: 7.7, y, w: 0.6, h: 0.6, align: 'center', valign: 'middle', fontSize: 16, bold: true, color: C.peri, margin: 0 })
    } else {
      s.addImage({ path: r[0].ic, x: 7.7 + 0.15, y: y + 0.15, w: 0.3, h: 0.3 })
    }
    s.addText(r[1], ar({ x: 0.9, y: y - 0.15, w: 6.6, h: 0.95, fontSize: 16, color: C.creamDim, valign: 'middle' }))
  })
  s.addImage({ path: 'pulse-faint.png', x: 0.9, y: 5.7, w: 5.4, h: 1.42 })
}

pres.writeFile({ fileName: 'afia-template-sample.pptx' }).then(() => console.log('written'))
