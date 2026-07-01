import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/motion.dart';
import 'core/theme.dart';
import 'data/onboarding_repo.dart';
import 'data/settings_repo.dart';
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
      themeAnimationDuration: AppMotion.med,
      themeAnimationCurve: AppMotion.enter,
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
  @override
  Widget build(BuildContext context) {
    final seen = ref.watch(onboardingSeenProvider);
    return seen.when(
      loading: () => const _Splash(),
      error: (_, _) => const HomeShell(),
      // Automatic backup is triggered from HomeShell (on mount, on silent
      // sign-in, and debounced after edits) — see home_shell.dart.
      data: (seen) => seen ? const HomeShell() : const OnboardingPage(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
