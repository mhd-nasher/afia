/// Device-level settings: language (AR/EN only, full RTL). The patient app
/// is light/warm by design — there is no theme setting.
library;

import 'package:flutter/material.dart';

import '../services/prefs.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  Locale? _locale;
  bool _loaded = false;

  Locale? get locale => _locale;
  bool get localeChosen => _locale != null;

  void loadFromPrefs() {
    if (_loaded) return;
    _locale = Prefs.instance.locale;
    _loaded = true;
  }

  Future<void> setLocale(Locale l) async {
    _locale = l;
    notifyListeners();
    await Prefs.instance.setLocale(l);
  }

  /// Device locale (ar/en, else en) until the person chooses (first run).
  Locale resolveLocale(Iterable<Locale> deviceLocales) {
    if (_locale != null) return _locale!;
    for (final l in deviceLocales) {
      if (l.languageCode == 'ar') return const Locale('ar');
      if (l.languageCode == 'en') return const Locale('en');
    }
    return const Locale('en');
  }
}
