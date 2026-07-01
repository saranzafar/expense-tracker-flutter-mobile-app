import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import 'pixel_cat.dart';

/// "Xpy" the pixel cat — a playful companion on the home screen. Its mood
/// tracks the month's net (saving = happy, overspending = worried, quiet =
/// sleepy) and it reacts when your balance moves or when you tap to pet it.
class MascotCompanion extends ConsumerStatefulWidget {
  const MascotCompanion({super.key});

  @override
  ConsumerState<MascotCompanion> createState() => _MascotCompanionState();
}

class _MascotCompanionState extends ConsumerState<MascotCompanion> {
  int? _prevBalance;
  MascotReaction _reaction = MascotReaction.none;
  int _tick = 0;
  String? _speechOverride;
  Timer? _resetTimer;

  final _petLines = ['purr~', 'mrrp!', ':3', 'hehe', 'boop'];
  int _petIndex = 0;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  MascotMood _moodFor(DashboardStats s) {
    final net = s.monthIncomeMinor - s.monthExpenseMinor;
    if (s.monthIncomeMinor == 0 && s.monthExpenseMinor == 0) {
      return MascotMood.sleepy;
    }
    if (net > 0) return MascotMood.happy;
    if (net < 0) return MascotMood.worried;
    return MascotMood.content;
  }

  String _idleLine(MascotMood mood) {
    switch (mood) {
      case MascotMood.happy:
        return "You're saving — nice!";
      case MascotMood.content:
        return 'Balanced. Steady paws.';
      case MascotMood.worried:
        return 'Spending adds up… careful!';
      case MascotMood.sleepy:
        return 'Zzz… log something?';
    }
  }

  void _fireReaction(MascotReaction r, String speech) {
    setState(() {
      _reaction = r;
      _tick++;
      _speechOverride = speech;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _reaction = MascotReaction.none;
          _speechOverride = null;
        });
      }
    });
  }

  void _pet() {
    _petIndex = (_petIndex + 1) % _petLines.length;
    _fireReaction(MascotReaction.pet, _petLines[_petIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    // React to balance movement (income raises it, expenses lower it).
    ref.listen<AsyncValue<DashboardStats>>(dashboardStatsProvider, (prev, next) {
      final n = next.valueOrNull;
      if (n == null) return;
      final old = _prevBalance;
      _prevBalance = n.availableBalance;
      if (old == null || old == n.availableBalance) return;
      if (n.availableBalance > old) {
        _fireReaction(MascotReaction.income, 'Ooh, money in! +');
      } else {
        _fireReaction(MascotReaction.expense, 'Noted that expense.');
      }
    });

    final stats = statsAsync.valueOrNull;
    final mood = stats == null ? MascotMood.content : _moodFor(stats);
    _prevBalance ??= stats?.availableBalance;
    final speech = _speechOverride ?? _idleLine(mood);

    return GestureDetector(
      onTap: _pet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: context.cardSurface,
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: context.softShadow,
        ),
        child: Row(
          children: [
            PixelCat(
              mood: mood,
              reaction: _reaction,
              reactionTick: _tick,
              size: 68,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('XPY',
                          style: AppTextStyles.overline
                              .copyWith(color: context.inkSubtle)),
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  XSwitcher(
                    child: Text(
                      speech,
                      key: ValueKey(speech),
                      style: AppTextStyles.body.copyWith(color: context.ink),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.pets, size: 16, color: context.inkSubtle),
          ],
        ),
      ),
    );
  }
}
