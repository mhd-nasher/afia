/// Device-level settings: language (AR/EN only) and appearance. Dark is the
/// default theme — this app is used at 3 a.m. on a dim ward.
library;

import 'package:flutter/material.dart';

import '../services/prefs.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _loaded = false;

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get localeChosen => _locale != null;

  void loadFromPrefs() {
    if (_loaded) return;
    _locale = Prefs.instance.locale;
    _themeMode = Prefs.instance.themeMode;
    _loaded = true;
  }

  Future<void> setLocale(Locale l) async {
    _locale = l;
    notifyListeners();
    await Prefs.instance.setLocale(l);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    await Prefs.instance.setThemeMode(m);
  }

  /// Device locale (ar/en, else en) until the user chooses (§ first-run).
  Locale resolveLocale(Iterable<Locale> deviceLocales) {
    if (_locale != null) return _locale!;
    for (final l in deviceLocales) {
      if (l.languageCode == 'ar') return const Locale('ar');
      if (l.languageCode == 'en') return const Locale('en');
    }
    return const Locale('en');
  }
}
