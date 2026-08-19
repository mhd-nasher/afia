/// Small device-local preferences: language (AR/EN only), first-run flags,
/// theme choice, mic primer, shift-complete once-flag. Nothing clinical
/// lives here.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  final SharedPreferences _sp;
  Prefs(this._sp);

  static Prefs? _instance;
  static Future<Prefs> load() async =>
      _instance ??= Prefs(await SharedPreferences.getInstance());
  static Prefs get instance => _instance!;

  /// null = not chosen yet (first-run choice screen shows).
  Locale? get locale {
    final code = _sp.getString('locale');
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale l) => _sp.setString('locale', l.languageCode);

  ThemeMode get themeMode => switch (_sp.getString('theme')) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark, // dark is the DEFAULT (design law)
      };

  Future<void> setThemeMode(ThemeMode m) => _sp.setString(
      'theme',
      switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      });

  bool get micPrimerSeen => _sp.getBool('micPrimerSeen') ?? false;
  Future<void> setMicPrimerSeen() => _sp.setBool('micPrimerSeen', true);

  String? get shiftCompleteShownFor => _sp.getString('shiftCompleteShownFor');
  Future<void> setShiftCompleteShownFor(String dayKey) =>
      _sp.setString('shiftCompleteShownFor', dayKey);

  /// D-014 — the nurse's own ward-list order (serialized WardOrder), cached
  /// on-device; the account copy lives in aiMemory/{uid} preferences.
  String? get wardOrder => _sp.getString('wardOrder');
  Future<void> setWardOrder(String serialized) =>
      _sp.setString('wardOrder', serialized);
}
