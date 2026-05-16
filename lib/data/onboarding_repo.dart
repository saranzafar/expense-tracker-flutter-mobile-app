import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingSeen = 'onboarding_seen_v1';

class OnboardingRepo {
  Future<bool> isSeen() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboardingSeen) ?? false;
  }

  Future<void> markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboardingSeen, true);
  }

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kOnboardingSeen);
  }
}

final onboardingRepoProvider = Provider<OnboardingRepo>((_) => OnboardingRepo());

final onboardingSeenProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepoProvider).isSeen();
});
