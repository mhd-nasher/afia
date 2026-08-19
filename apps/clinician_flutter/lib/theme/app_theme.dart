/// IBM Plex Sans + IBM Plex Mono (IBM Plex Sans Arabic for ar) via
/// google_fonts. Two text weights (400/500), three text tones, one accent.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

TextStyle sans(BuildContext context, double size,
    {FontWeight weight = FontWeight.w400, Color? color, double? height}) {
  final c = color ?? context.afia.text;
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
    color: color ?? context.afia.text,
    height: height,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Uppercase 11px section label — used on every screen.
TextStyle sectionLabel(BuildContext context, {Color? color}) => sans(
      context,
      11,
      color: color ?? context.afia.textFaint,
    ).copyWith(letterSpacing: 0.88);

ThemeData buildTheme({required Brightness brightness, required bool arabic}) {
  final colors = brightness == Brightness.dark ? AfiaColors.dark : AfiaColors.light;
  final baseText = arabic
      ? GoogleFonts.ibmPlexSansArabicTextTheme()
      : GoogleFonts.ibmPlexSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.surface,
    canvasColor: colors.surface,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.machine,
      onPrimary: colors.onAccent,
      secondary: colors.draft,
      onSecondary: colors.onAccent,
      error: colors.danger,
      onError: colors.surface,
      surface: colors.surface,
      onSurface: colors.text,
    ),
    textTheme: baseText.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    ),
    dividerColor: colors.hairline,
    splashFactory: InkRipple.splashFactory,
    extensions: [colors],
  );
}
