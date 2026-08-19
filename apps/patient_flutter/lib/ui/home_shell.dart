/// The conventional shell (D-015): three tabs — الرئيسية · تقاريري · حسابي.
/// 64px targets, labels + icons, warm design. Every tab answers "where am I
/// and what do I do now" at a glance.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/auth_service.dart';
import '../state/episode_model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'screens/account_tab.dart';
import 'screens/home_tab.dart';
import 'screens/reports_tab.dart';
import 'widgets/common.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Cache the account name locally so the greeting and future reports
    // carry it (send() uses episode.name as the case's patientName).
    if (EpisodeModel.instance.episode.name.trim().isEmpty) {
      try {
        PatientAuthService.instance.currentAccount().then((a) {
          if (a != null && a.name.isNotEmpty) {
            EpisodeModel.instance.setName(a.name);
          }
        }).catchError((_) => null);
      } catch (_) {
        // Firebase unavailable: the greeting falls back to a plain hello.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final tabs = [
      (LucideIcons.home, t.tabHome),
      (LucideIcons.clipboardList, t.tabReports),
      (LucideIcons.user, t.tabAccount),
    ];
    return Scaffold(
      backgroundColor: PatientColors.pageBg,
      body: IndexedStack(index: _index, children: const [
        HomeTab(),
        ReportsTab(),
        AccountTab(),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: PatientColors.surface,
          border: Border(
              top: BorderSide(color: PatientColors.border, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(children: [
              for (final (i, tab) in tabs.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _index == i,
                    label: tab.$2,
                    child: InkWell(
                      onTap: () => setState(() => _index = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tab.$1,
                              size: 26,
                              color: _index == i
                                  ? PatientColors.action
                                  : PatientColors.inkDim),
                          const SizedBox(height: 4),
                          Text(tab.$2,
                              style: sans(context, 14,
                                  weight: _index == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _index == i
                                      ? PatientColors.action
                                      : PatientColors.inkDim)),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
