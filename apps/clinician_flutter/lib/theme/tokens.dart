/// The design tokens, verbatim from designs/afia-clinician-design.html.
/// Design laws: 12 rows no scroll · 56px targets · borders, never cards ·
/// two text weights, three text tones, one accent doing one job.
/// Periwinkle = machine-produced and unverified; it becomes action blue the
/// moment a nurse signs. Dark is the DEFAULT — this is used at 3 a.m.
library;

import 'package:flutter/material.dart';

class AfiaColors extends ThemeExtension<AfiaColors> {
  final Color pageBg; // outer page
  final Color surface; // screen background
  final Color raised; // #232120 / #F1EEE9 — subtle raised bands
  final Color chipBg; // #302D2B — selected chip / sound-alike cell
  final Color border; // strong structural border
  final Color hairline; // row separator
  final Color text; // primary tone
  final Color textDim; // secondary tone
  final Color textFaint; // tertiary tone
  final Color machine; // periwinkle — machine-produced, unverified
  final Color signedAccent; // what periwinkle becomes on signing
  final Color draft; // violet — draft ready / interrupted
  final Color warn; // amber — caution / low confidence
  final Color ok; // green — confirmed in system
  final Color danger; // coral — clinical critical only
  final Color onAccent; // text/icon on the machine-accent fill
  final Color invertBg; // inverted system banner bg
  final Color invertText; // inverted system banner text
  final Color invertTextDim;

  const AfiaColors({
    required this.pageBg,
    required this.surface,
    required this.raised,
    required this.chipBg,
    required this.border,
    required this.hairline,
    required this.text,
    required this.textDim,
    required this.textFaint,
    required this.machine,
    required this.signedAccent,
    required this.draft,
    required this.warn,
    required this.ok,
    required this.danger,
    required this.onAccent,
    required this.invertBg,
    required this.invertText,
    required this.invertTextDim,
  });

  static const dark = AfiaColors(
    pageBg: Color(0xFF100F0E),
    surface: Color(0xFF1A1817),
    raised: Color(0xFF232120),
    chipBg: Color(0xFF302D2B),
    border: Color(0xFF3A3634),
    hairline: Color(0xFF2A2726),
    text: Color(0xFFF2EFEA),
    textDim: Color(0xFFA8A29B),
    textFaint: Color(0xFF8A837B),
    machine: Color(0xFF8FA9D9),
    signedAccent: Color(0xFF8FA9D9),
    draft: Color(0xFFA79EE8),
    warn: Color(0xFFF2B44C),
    ok: Color(0xFF58C48F),
    danger: Color(0xFFFF8A78),
    onAccent: Color(0xFF1A1817),
    invertBg: Color(0xFFF2EFEA),
    invertText: Color(0xFF1A1817),
    invertTextDim: Color(0xFF302D2B),
  );

  static const light = AfiaColors(
    pageBg: Color(0xFFFAF9F7),
    surface: Color(0xFFFAF9F7),
    raised: Color(0xFFF1EEE9),
    chipBg: Color(0xFFF1EEE9),
    border: Color(0xFFDDD8D0),
    hairline: Color(0xFFEAE6DF),
    text: Color(0xFF2A2418),
    textDim: Color(0xFF6B6459),
    textFaint: Color(0xFF8A8377),
    machine: Color(0xFF2D4A8A),
    signedAccent: Color(0xFF2D4A8A),
    draft: Color(0xFF7B6FD4),
    warn: Color(0xFFB8730C),
    ok: Color(0xFF1E8449),
    danger: Color(0xFFC0392B),
    onAccent: Color(0xFFFAF9F7),
    invertBg: Color(0xFF2A2418),
    invertText: Color(0xFFFAF9F7),
    invertTextDim: Color(0xFFDDD8D0),
  );

  /// Screen 11 — the one warm screen. No patient data, no elapsed time.
  static const warmBg = Color(0xFFFBF3EA);
  static const warmBorder = Color(0xFFE4D6C6);
  static const warmRaised = Color(0xFFF5EADD);
  static const warmAccent = Color(0xFFE8785C);
  static const warmText = Color(0xFF2A2418);
  static const warmTextDim = Color(0xFF6B6459);

  @override
  AfiaColors copyWith() => this;

  @override
  AfiaColors lerp(ThemeExtension<AfiaColors>? other, double t) =>
      t < 0.5 ? this : (other as AfiaColors? ?? this);
}

extension AfiaColorsX on BuildContext {
  AfiaColors get afia => Theme.of(this).extension<AfiaColors>()!;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
