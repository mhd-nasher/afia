/// The patient design tokens — the counterpart to the clinician app,
/// INVERTED in every way that matters (designs/patient-design-notes.md):
/// warm, never clinical, because this is opened once, alone, in fright.
/// LIGHT/WARM only: cream surfaces (#FBF3EA / #FAF9F7 family), dark warm
/// ink, IBM Plex (Arabic for AR). 390×844 base · 64px targets · 17px body
/// floor · red on ONE screen only (the emergency interrupt) · periwinkle =
/// machine-made and unverified. The design commits to a single warm look —
/// there is deliberately no dark theme.
library;

import 'package:flutter/material.dart';

class PatientColors {
  PatientColors._();

  // Warm cream surfaces (same family as the clinician warm screen).
  static const Color pageBg = Color(0xFFFBF3EA);
  static const Color surface = Color(0xFFFAF9F7);
  static const Color raised = Color(0xFFF5EADD);
  static const Color border = Color(0xFFE4D6C6);
  static const Color hairline = Color(0xFFEAE6DF);

  // Dark warm ink, three tones.
  static const Color ink = Color(0xFF2A2418);
  static const Color inkDim = Color(0xFF6B6459);
  static const Color inkFaint = Color(0xFF8A8377);

  /// Primary action — deep indigo (the design system's "signed/actioned"
  /// hue). NOT red: red is spent entirely on the interrupt screen.
  static const Color action = Color(0xFF34397B);
  static const Color actionBg = Color(0xFFE9EAF4);
  static const Color onAction = Color(0xFFFFFFFF);

  /// Periwinkle — machine-made, unverified (AI tidy output before the
  /// patient accepts it). #8FA9D9 per the shared design system; the darker
  /// variant reads on cream.
  static const Color machine = Color(0xFF2D4A8A);
  static const Color machineBg = Color(0xFFEEF1FD);

  /// The ONLY red in the app — the emergency interrupt screen (and the call
  /// buttons on it). The first red the person sees means something absolute.
  static const Color emergency = Color(0xFFD93025);
  static const Color onEmergency = Color(0xFFFFFFFF);

  // Semantic (used sparingly).
  static const Color warn = Color(0xFFB8730C);
  static const Color ok = Color(0xFF1E8449);
}

/// Layout laws.
class PatientDimens {
  PatientDimens._();

  /// Frightened hands, possibly elderly — every target at least this (F-054).
  static const double touch = 64;

  /// Body text floor (F-054).
  static const double bodyText = 17;

  static const double radius = 10;
  static const double pagePadding = 20;
}
