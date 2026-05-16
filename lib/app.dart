import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/onboarding_repo.dart';
import 'data/settings_repo.dart';
import 'features/backup/data/backup_repo.dart';
import 'features/onboarding/ui/onboarding_page.dart';
import 'shell/home_shell.dart';

class XpenseApp extends ConsumerWidget {
  const XpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Xpense Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: mode,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();
  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  bool _autoBackupScheduled = false;

  @override
  Widget build(BuildContext context) {
    final seen = ref.watch(onboardingSeenProvider);
    return seen.when(
      loading: () => const _Splash(),
      error: (_, _) => const HomeShell(),
      data: (seen) {
        if (seen && !_autoBackupScheduled) {
          _autoBackupScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(backupRepoProvider).autoBackupIfDue();
          });
        }
        return seen ? const HomeShell() : const OnboardingPage();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
