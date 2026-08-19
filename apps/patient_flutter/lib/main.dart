import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/prefs.dart';
import 'state/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local state loads FIRST: the episode, the language, and the emergency
  // path never depend on Firebase being reachable (§2.7).
  await Prefs.load();
  AppSettings.instance.loadFromPrefs();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Offline first start: the flow still runs; sending will queue when
    // Firebase becomes reachable on a later launch.
  }
  runApp(const AfiaPatientApp());
}
