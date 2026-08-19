/// Four tabs — Patients · Received · Shift · Account (§5). No home screen:
/// Patients IS home. Reopening with an interrupted recording goes straight
/// back to it (§5). The 22px sync strip and 56px tab bar frame every tab.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../domain/handover.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'screens/account_screen.dart';
import 'screens/incoming_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/shift_board_screen.dart';
import 'screens/ward_list_screen.dart';
import 'widgets/common.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  bool _resumedInterrupted = false;

  @override
  void initState() {
    super.initState();
    // §5 — reopen goes directly to the interrupted draft, never a home screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeResume());
    AppModel.instance!.addListener(_maybeResume);
  }

  @override
  void dispose() {
    AppModel.instance?.removeListener(_maybeResume);
    super.dispose();
  }

  void _maybeResume() {
    if (_resumedInterrupted || !mounted) return;
    final model = AppModel.instance!;
    final interrupted = model.interruptedDraft;
    if (interrupted == null || model.template.isEmpty) return;
    _resumedInterrupted = true;
    final patient = model.patientById(interrupted.patientId);
    if (patient == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordingScreen(patient: patient, resume: interrupted),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final queued = model.handovers
            .where((h) =>
                h.status == HandoverStatus.queued ||
                h.status == HandoverStatus.signed)
            .length;
        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              Expanded(
                child: IndexedStack(index: _tab, children: const [
                  WardListScreen(),
                  IncomingScreen(),
                  ShiftBoardScreen(),
                  AccountScreen(),
                ]),
              ),
              SyncStrip(
                offline: model.syncStatus.fromCache,
                queued: queued,
              ),
              _TabBar(
                current: _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  const _TabBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final items = [
      (LucideIcons.list, t.tabPatients),
      (LucideIcons.mail, t.tabReceived),
      (LucideIcons.calendarDays, t.tabShift),
      (LucideIcons.user, t.tabAccount),
    ];
    return Container(
      height: 56,
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                child: Semantics(
                  selected: i == current,
                  button: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1,
                          size: 20,
                          color: i == current ? c.machine : c.textFaint),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: sans(context, 10,
                            weight: i == current
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: i == current ? c.machine : c.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
