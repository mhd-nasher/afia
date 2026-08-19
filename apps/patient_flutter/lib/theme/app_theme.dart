/// IBM Plex Sans (IBM Plex Sans Arabic for ar) + IBM Plex Mono via
/// google_fonts. Warm light theme only — the inversion of the clinician
/// app's dark default.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

TextStyle sans(BuildContext context, double size,
    {FontWeight weight = FontWeight.w400, Color? color, double? height}) {
  final c = color ?? PatientColors.ink;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return isArabic
      ? GoogleFonts.ibmPlexSansArabic(
          fontSize: size, fontWeight: weight, color: c, height: height)
      : GoogleFonts.ibmPlexSans(
          fontSize: size, fontWeight: weight, color: c, height: height);
}

TextStyle mono(BuildContext context, double size,
    {FontWeight weight = FontWeight.w400, Color? color, double? height}) {
  return GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color ?? PatientColors.ink,
    height: height,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Uppercase eyebrow label above a question.
TextStyle eyebrow(BuildContext context, {Color? color}) => sans(
      context,
      15,
      weight: FontWeight.w600,
      color: color ?? PatientColors.inkDim,
    ).copyWith(letterSpacing: 0.6);

ThemeData buildPatientTheme({required bool arabic}) {
  final baseText = arabic
      ? GoogleFonts.ibmPlexSansArabicTextTheme()
      : GoogleFonts.ibmPlexSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: PatientColors.pageBg,
    canvasColor: PatientColors.pageBg,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: PatientColors.action,
      onPrimary: PatientColors.onAction,
      secondary: PatientColors.machine,
      onSecondary: PatientColors.onAction,
      error: PatientColors.emergency,
      onError: PatientColors.onEmergency,
      surface: PatientColors.surface,
      onSurface: PatientColors.ink,
    ),
    textTheme: baseText.apply(
      bodyColor: PatientColors.ink,
      displayColor: PatientColors.ink,
    ),
    dividerColor: PatientColors.hairline,
    splashFactory: InkRipple.splashFactory,
  );
}
