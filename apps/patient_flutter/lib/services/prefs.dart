/// Small device-local storage: language choice, the mic primer once-flag,
/// and the WHOLE in-progress episode (incremental save from the first
/// answer, F-055). Nothing here ever leaves the device by itself.
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

  /// null = not chosen yet (first-run language choice shows).
  Locale? get locale {
    final code = _sp.getString('locale');
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale l) => _sp.setString('locale', l.languageCode);

  bool get micPrimerSeen => _sp.getBool('micPrimerSeen') ?? false;
  Future<void> setMicPrimerSeen() => _sp.setBool('micPrimerSeen', true);

  /// The episode JSON — written on every state change.
  String? get episodeJson => _sp.getString('episode');
  Future<void> setEpisodeJson(String json) => _sp.setString('episode', json);
  Future<void> clearEpisode() => _sp.remove('episode');
}
