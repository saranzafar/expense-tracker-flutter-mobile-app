import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import 'pixel_cat.dart';

/// "Xpy" the pixel cat — a playful companion on the home screen. Its mood
/// tracks the month's net (saving = happy, overspending = worried, quiet =
/// sleepy), it chats on its own, and it reacts when your balance moves or when
/// you tap to pet it.
class MascotCompanion extends ConsumerStatefulWidget {
  const MascotCompanion({super.key});

  @override
  ConsumerState<MascotCompanion> createState() => _MascotCompanionState();
}

class _MascotCompanionState extends ConsumerState<MascotCompanion> {
  final _rng = math.Random();
  int? _prevBalance;
  MascotReaction _reaction = MascotReaction.none;
  int _tick = 0;
  String? _speechOverride;
  Timer? _resetTimer;

  MascotMood _mood = MascotMood.content;
  String _idleLine = 'Hey there 🐾';
  Timer? _chatterTimer;

  // ── Speech pools ──────────────────────────────────────────────────────────
  static const _happy = [
    "You're saving — nice!",
    'Look at that balance 😸',
    'Treats later? 💚',
    "We're crushing it!",
    'Purrfect budgeting.',
    'The coin jar grows!',
  ];
  static const _content = [
    'Balanced. Steady paws.',
    'All calm here.',
    'Just watching your coins.',
    "Tap me, I'm bored 👀",
    'Steady as she goes.',
    'Mrrp. Carry on.',
  ];
  static const _worried = [
    'Spending adds up… careful!',
    'Hmm, watch the outflow.',
    'Maybe skip a treat? 😿',
    "Budget's getting thin…",
    'Easy on the spending!',
    'I believe in you though.',
  ];
  static const _sleepy = [
    'Zzz… log something?',
    '*yawn* so quiet…',
    'Wake me with a record 😴',
    'Nap time…',
    'Nothing to track… zzz',
  ];
  static const _pet = [
    'purr~',
    'mrrp!',
    ':3',
    'hehe, boop',
    'that tickles!',
    'again! again!',
    'mrow 💕',
  ];
  static const _incomeLines = [
    'Ooh, money in! +',
    'Cha-ching! 🌟',
    'More for the jar!',
    'Nice earning!',
  ];
  static const _expenseLines = [
    'Noted that expense.',
    'Spent, huh? 📝',
    'There it goes…',
    'Tracked it!',
  ];

  List<String> _poolFor(MascotMood m) {
    switch (m) {
      case MascotMood.happy:
        return _happy;
      case MascotMood.content:
        return _content;
      case MascotMood.worried:
        return _worried;
      case MascotMood.sleepy:
        return _sleepy;
    }
  }

  String _pick(List<String> pool) => pool[_rng.nextInt(pool.length)];

  @override
  void initState() {
    super.initState();
    // Rotate idle chatter every few seconds when nothing else is being said.
    _chatterTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _speechOverride != null) return;
      setState(() => _idleLine = _pick(_poolFor(_mood)));
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _chatterTimer?.cancel();
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

  void _petCat() => _fireReaction(MascotReaction.pet, _pick(_pet));

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    ref.listen<AsyncValue<DashboardStats>>(dashboardStatsProvider,
        (prev, next) {
      final n = next.valueOrNull;
      if (n == null) return;
      final old = _prevBalance;
      _prevBalance = n.availableBalance;
      if (old == null || old == n.availableBalance) return;
      if (n.availableBalance > old) {
        _fireReaction(MascotReaction.income, _pick(_incomeLines));
      } else {
        _fireReaction(MascotReaction.expense, _pick(_expenseLines));
      }
    });

    final stats = statsAsync.valueOrNull;
    _mood = stats == null ? MascotMood.content : _moodFor(stats);
    _prevBalance ??= stats?.availableBalance;
    final speech = _speechOverride ?? _idleLine;

    return GestureDetector(
      onTap: _petCat,
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
              mood: _mood,
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
