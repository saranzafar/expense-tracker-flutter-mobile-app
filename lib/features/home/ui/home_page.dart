import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/currency.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../../../shell/home_shell.dart';
import '../../backup/ui/widgets/profile_chip.dart';
import '../../records/ui/record_form_page.dart';
import '../../records/widgets/record_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recent = ref.watch(recentRecordsProvider);
    final currency = ref.watch(currencyProvider);
    final name = ref.watch(displayNameProvider);
    final greeting = name.isEmpty ? 'Hello there' : 'Hi, $name';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XSwitcher(
                        duration: AppMotion.fast,
                        child: Text(
                          greeting,
                          key: ValueKey(greeting),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption
                              .copyWith(color: context.inkMuted),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Your money',
                          style: AppTextStyles.headline
                              .copyWith(color: context.ink)),
                    ],
                  ),
                ),
                const ProfileChip(),
              ],
            ),
            const SizedBox(height: 20),
            XSwitcher(
              child: stats.when(
                loading: () => const _BalanceCardSkeleton(
                    key: ValueKey('balance-loading')),
                error: (e, _) => Text('Error: $e',
                    key: const ValueKey('balance-error')),
                data: (s) => _BalanceCard(
                    key: const ValueKey('balance-data'),
                    stats: s,
                    currency: currency),
              ),
            ),
            const SizedBox(height: 16),
            XSwitcher(
              child: stats.maybeWhen(
                data: (s) => s.outstandingLoanCount == 0
                    ? const SizedBox.shrink(key: ValueKey('out-empty'))
                    : _OutstandingCard(
                        key: const ValueKey('out-card'),
                        stats: s,
                        currency: currency),
                orElse: () => const SizedBox.shrink(key: ValueKey('out-none')),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent activity',
                    style: AppTextStyles.title.copyWith(color: context.ink)),
                stats.maybeWhen(
                  data: (_) => TextButton(
                      onPressed: () =>
                          ref.read(shellNavProvider.notifier).goTo(1),
                      child: Text('See all',
                          style: AppTextStyles.caption
                              .copyWith(color: context.ink))),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            XSwitcher(
              child: recent.when(
                loading: () => const Padding(
                  key: ValueKey('recent-loading'),
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Text('$e', key: const ValueKey('recent-error')),
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyRecent(key: ValueKey('recent-empty'));
                  }
                  return Column(
                    key: const ValueKey('recent-list'),
                    children: [
                      for (final r in items)
                        FadeIn(
                          key: ValueKey(r.id),
                          child: RecordTile(record: r, currency: currency),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({super.key, required this.stats, required this.currency});
  final DashboardStats stats;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In light mode: black hero card with white text.
    // In dark mode: invert — white hero card with black text. Green accent stays.
    final cardBg = isDark ? Colors.white : Colors.black;
    final foreground = isDark ? Colors.black : Colors.white;
    final muted = foreground.withValues(alpha: 0.60);
    final subtle = foreground.withValues(alpha: 0.40);
    final hairline = foreground.withValues(alpha: 0.12);
    final valueColor = isDark ? Colors.black : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                    painter: _BalanceDecorPainter(isDark: isDark)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 5,
                        width: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Available balance',
                          style:
                              AppTextStyles.caption.copyWith(color: muted)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(currency.code,
                            style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.ink : Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedMoney(
                    minor: stats.availableBalance,
                    currency: currency,
                    style: AppTextStyles.display
                        .copyWith(color: AppColors.green, fontSize: 38),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: hairline),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Income (mo)',
                          minor: stats.monthIncomeMinor,
                          currency: currency,
                          icon: Icons.arrow_downward_rounded,
                          valueColor: valueColor,
                          mutedColor: muted,
                          subtleColor: subtle,
                          accentDot: true,
                        ),
                      ),
                      Container(width: 1, height: 36, color: hairline),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _MiniStat(
                            label: 'Expense (mo)',
                            minor: stats.monthExpenseMinor,
                            currency: currency,
                            icon: Icons.arrow_upward_rounded,
                            valueColor: valueColor,
                            mutedColor: muted,
                            subtleColor: subtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.minor,
    required this.currency,
    required this.icon,
    required this.valueColor,
    required this.mutedColor,
    required this.subtleColor,
    this.accentDot = false,
  });
  final String label;
  final int minor;
  final CurrencyOption currency;
  final IconData icon;
  final Color valueColor;
  final Color mutedColor;
  final Color subtleColor;
  final bool accentDot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon,
              size: 14,
              color: accentDot ? AppColors.green : subtleColor),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: mutedColor)),
        ]),
        const SizedBox(height: 4),
        AnimatedMoney(
          minor: minor,
          currency: currency,
          style: AppTextStyles.title
              .copyWith(color: valueColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BalanceDecorPainter extends CustomPainter {
  _BalanceDecorPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // On dark mode (white card), green accents need slightly higher alpha
    // to stay visible against white; on light mode (black card), green pops
    // naturally so we use lower alpha for subtlety.
    final base = isDark ? 0.55 : 0.35;
    final bright = isDark ? 0.85 : 0.7;
    final scanAlpha = isDark ? 0.18 : 0.08;
    final arcAlpha = isDark ? 0.28 : 0.15;

    final stroke = Paint()
      ..color = AppColors.green.withValues(alpha: base)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width - 36, 14),
      Offset(size.width - 8, 42),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width - 22, 12),
      Offset(size.width - 12, 22),
      stroke..color = AppColors.green.withValues(alpha: bright),
    );

    final scan = Paint()
      ..color = AppColors.green.withValues(alpha: scanAlpha)
      ..strokeWidth = 1;
    const scanY1 = 78.0;
    const scanY2 = 108.0;
    canvas.drawLine(const Offset(0, scanY1), Offset(size.width, scanY1), scan);
    canvas.drawLine(const Offset(0, scanY2), Offset(size.width, scanY2), scan);

    final arc = Paint()
      ..color = AppColors.green.withValues(alpha: arcAlpha)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(-30, size.height + 20), 70, arc);
  }

  @override
  bool shouldRepaint(covariant _BalanceDecorPainter old) =>
      old.isDark != isDark;
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: AppColors.green)),
    );
  }
}

class _OutstandingCard extends ConsumerWidget {
  const _OutstandingCard(
      {super.key, required this.stats, required this.currency});
  final DashboardStats stats;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.greenSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ref.read(shellNavProvider.notifier).goTo(2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.handshake_outlined,
                color: context.ink, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding loans · ${stats.outstandingLoanCount}',
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkMuted)),
                const SizedBox(height: 2),
                AnimatedMoney(
                  minor: stats.outstandingLoanMinor,
                  currency: currency,
                  style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700, color: context.ink),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.inkSubtle),
        ],
      ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/illustrations/track.svg',
            height: 120,
            theme: SvgTheme(currentColor: context.ink),
          ),
          const SizedBox(height: 12),
          Text('Nothing tracked yet',
              style: AppTextStyles.title.copyWith(color: context.ink)),
          const SizedBox(height: 4),
          Text('Tap + to log your first record.',
              style:
                  AppTextStyles.caption.copyWith(color: context.inkMuted)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.ink,
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    const RecordFormPage(type: RecordType.expense),
              )),
              child: const Text('Add first record'),
            ),
          ),
        ],
      ),
    );
  }
}
