import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/chart_data.dart';
import '../../../core/currency.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../../../shell/home_shell.dart';
import '../../backup/ui/widgets/profile_chip.dart';
import '../../records/ui/record_form_page.dart';
import '../../records/widgets/record_tile.dart';
import '../../shared/section_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recent = ref.watch(recentRecordsProvider);
    final currency = ref.watch(currencyProvider);
    final name = ref.watch(displayNameProvider);
    final balanceHidden = ref.watch(balanceHiddenProvider);
    final greeting = name.isEmpty ? 'Hello there' : 'Hi, $name';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(recentRecordsProvider);
            ref.invalidate(chartDataProvider);
            ref.invalidate(customChartDataProvider);
            await ref.read(dashboardStatsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
            FadeIn(
              delay: const Duration(milliseconds: 40),
              child: XSwitcher(
              child: stats.when(
                loading: () => const _BalanceCardSkeleton(
                    key: ValueKey('balance-loading')),
                error: (e, _) => Text('Error: $e',
                    key: const ValueKey('balance-error')),
                data: (s) => _BalanceCard(
                    key: const ValueKey('balance-data'),
                    stats: s,
                    currency: currency,
                    hidden: balanceHidden,
                    onToggle: () => ref
                        .read(balanceHiddenProvider.notifier)
                        .set(!balanceHidden)),
              ),
              ),
            ),
            const SizedBox(height: 16),
            FadeIn(
              delay: const Duration(milliseconds: 100),
              child: XSwitcher(
              child: stats.maybeWhen(
                data: (s) =>
                    s.outstandingLoanCount + s.outstandingBorrowedCount == 0
                        ? const SizedBox.shrink(key: ValueKey('out-empty'))
                        : _OutstandingCard(
                            key: const ValueKey('out-card'),
                            stats: s,
                            currency: currency),
                orElse: () => const SizedBox.shrink(key: ValueKey('out-none')),
              ),
              ),
            ),
            const SizedBox(height: 16),
            FadeIn(
              delay: const Duration(milliseconds: 160),
              child: const _ChartCard(),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              'Recent activity',
              trailing: stats.maybeWhen(
                data: (_) => GestureDetector(
                  onTap: () => ref.read(shellNavProvider.notifier).goTo(1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('See all',
                          style: AppTextStyles.caption
                              .copyWith(color: context.inkMuted)),
                      Icon(Icons.chevron_right,
                          size: 16, color: context.inkSubtle),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
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
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    super.key,
    required this.stats,
    required this.currency,
    required this.hidden,
    required this.onToggle,
  });
  final DashboardStats stats;
  final CurrencyOption currency;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light mode: black hero card. Dark mode: dark-gray card (not white).
    // Text is always white since both card backgrounds are dark.
    final cardBg = isDark ? const Color(0xFF1A1A1B) : Colors.black;
    const foreground = Colors.white;
    final muted = foreground.withValues(alpha: 0.60);
    final subtle = foreground.withValues(alpha: 0.40);
    final hairline = foreground.withValues(alpha: 0.12);
    const valueColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: context.softShadow,
      ),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.hero),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.hero),
        ),
        child: Stack(
          children: [
            // Faint top sheen so the hero reads like a premium surface.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                    painter: _BalanceDecorPainter(isDark: false)),
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
                      Text('AVAILABLE BALANCE',
                          style:
                              AppTextStyles.overline.copyWith(color: muted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Icon(
                            hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: muted,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(currency.code,
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  XSwitcher(
                    child: hidden
                        ? Text(
                            '••••••',
                            key: const ValueKey('bal-hidden'),
                            style: AppTextStyles.display.copyWith(
                                color: AppColors.green, fontSize: 44),
                          )
                        : AnimatedMoney(
                            key: const ValueKey('bal-shown'),
                            minor: stats.availableBalance,
                            currency: currency,
                            style: AppTextStyles.display
                                .copyWith(color: AppColors.green, fontSize: 44),
                          ),
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
                          hidden: hidden,
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
                            hidden: hidden,
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
    this.hidden = false,
  });
  final String label;
  final int minor;
  final CurrencyOption currency;
  final IconData icon;
  final Color valueColor;
  final Color mutedColor;
  final Color subtleColor;
  final bool accentDot;
  final bool hidden;

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
        XSwitcher(
          child: hidden
              ? Text('•••',
                  key: const ValueKey('mini-hidden'),
                  style: AppTextStyles.title
                      .copyWith(color: valueColor, fontWeight: FontWeight.w700))
              : AnimatedMoney(
                  key: const ValueKey('mini-shown'),
                  minor: minor,
                  currency: currency,
                  style: AppTextStyles.title
                      .copyWith(color: valueColor, fontWeight: FontWeight.w700),
                ),
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
        color: isDark ? const Color(0xFF1A1A1B) : Colors.black,
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
    return PressScale(
      onTap: () => ref.read(shellNavProvider.notifier).goTo(2),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greenSoft,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              child: Icon(Icons.handshake_outlined,
                  color: context.ink, size: 20),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats.outstandingLoanCount > 0) ...[
                  Text(
                      'Lent · ${stats.outstandingLoanCount}',
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
                if (stats.outstandingLoanCount > 0 &&
                    stats.outstandingBorrowedCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                        height: 1,
                        color: AppColors.green.withValues(alpha: 0.18)),
                  ),
                if (stats.outstandingBorrowedCount > 0) ...[
                  Text(
                      'Borrowed · ${stats.outstandingBorrowedCount}',
                      style: AppTextStyles.caption
                          .copyWith(color: context.inkMuted)),
                  const SizedBox(height: 2),
                  AnimatedMoney(
                    minor: stats.outstandingBorrowedMinor,
                    currency: currency,
                    style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700, color: context.ink),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.inkSubtle),
        ],
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
        color: context.cardSurface,
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: context.softShadow,
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

// ── Chart Card ──────────────────────────────────────────────────────────────

class _ChartCard extends ConsumerStatefulWidget {
  const _ChartCard();

  @override
  ConsumerState<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends ConsumerState<_ChartCard> {
  ChartPeriod? _period = ChartPeriod.month; // null = custom
  DateTimeRange? _customRange;

  // Legend visibility — tap a chip to hide/show its line. Never both off.
  bool _showIncome = true;
  bool _showExpense = true;

  bool get _isCustom => _period == null;

  void _toggleSeries({required bool income}) {
    setState(() {
      if (income) {
        // Refuse to hide the last visible line.
        if (_showIncome && !_showExpense) return;
        _showIncome = !_showIncome;
      } else {
        if (_showExpense && !_showIncome) return;
        _showExpense = !_showExpense;
      }
    });
  }

  bool get _useMonthly {
    if (_period == ChartPeriod.year) return true;
    if (_customRange != null) return _customRange!.duration.inDays > 90;
    return false;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        _period = null;
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    // Resolve chart data from the correct provider
    final AsyncValue<List<ChartPoint>> chartAsync;
    if (_period != null) {
      chartAsync = ref.watch(chartDataProvider(_period!));
    } else if (_customRange != null) {
      chartAsync = ref.watch(customChartDataProvider(ChartDateRange(
        from: _customRange!.start,
        to: _customRange!.end,
      )));
    } else {
      chartAsync = const AsyncData([]);
    }

    // Compute totals from loaded chart points
    final points = chartAsync.valueOrNull ?? [];
    final totalIncome =
        points.fold<int>(0, (s, p) => s + p.income.toInt());
    final totalExpense =
        points.fold<int>(0, (s, p) => s + p.expense.toInt());
    final net = totalIncome - totalExpense;
    final hasTotals =
        chartAsync.hasValue && (totalIncome > 0 || totalExpense > 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: title row ────────────────────────────────────────
          Text('OVERVIEW',
              style: AppTextStyles.overline.copyWith(color: context.inkSubtle)),
          const SizedBox(height: 12),
          // ── Period chips (scrollable to handle long custom label) ────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodChip(
                  label: '1W',
                  selected: _period == ChartPeriod.week,
                  onTap: () => setState(() {
                    _period = ChartPeriod.week;
                    _customRange = null;
                  }),
                ),
                const SizedBox(width: 6),
                _PeriodChip(
                  label: '1M',
                  selected: _period == ChartPeriod.month,
                  onTap: () => setState(() {
                    _period = ChartPeriod.month;
                    _customRange = null;
                  }),
                ),
                const SizedBox(width: 6),
                _PeriodChip(
                  label: '1Y',
                  selected: _period == ChartPeriod.year,
                  onTap: () => setState(() {
                    _period = ChartPeriod.year;
                    _customRange = null;
                  }),
                ),
                const SizedBox(width: 6),
                _PeriodChip(
                  label: _isCustom && _customRange != null
                      ? '${formatShortDate(_customRange!.start)} – ${formatShortDate(_customRange!.end)}'
                      : 'Custom',
                  selected: _isCustom,
                  onTap: _pickCustomRange,
                ),
              ],
            ),
          ),

          // ── Totals row ───────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: hasTotals
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        _TotalStat(
                          label: 'Income',
                          minor: totalIncome,
                          currency: currency,
                          color: AppColors.green,
                          icon: Icons.arrow_downward_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: context.hairline,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        _TotalStat(
                          label: 'Expense',
                          minor: totalExpense,
                          currency: currency,
                          color: AppColors.danger,
                          icon: Icons.arrow_upward_rounded,
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Net',
                                style: AppTextStyles.caption
                                    .copyWith(color: context.inkSubtle, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              '${net >= 0 ? '+' : '−'} ${formatMoney(net.abs(), currency)}',
                              style: AppTextStyles.caption.copyWith(
                                color: net >= 0
                                    ? AppColors.green
                                    : AppColors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),

          // ── Chart ────────────────────────────────────────────────────
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: chartAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.green, strokeWidth: 2),
              ),
              error: (e, _) => const SizedBox.shrink(),
              data: (pts) {
                final allZero =
                    pts.every((p) => p.income == 0 && p.expense == 0);
                if (allZero || pts.isEmpty) {
                  return Center(
                    child: Text('No data for this period',
                        style: AppTextStyles.caption
                            .copyWith(color: context.inkMuted)),
                  );
                }
                return _LineChart(
                  points: pts,
                  useMonthly: _useMonthly,
                  currency: currency,
                  showIncome: _showIncome,
                  showExpense: _showExpense,
                );
              },
            ),
          ),

          // ── Legend ───────────────────────────────────────────────────
          const SizedBox(height: 16),
          Row(
            children: [
              _Legend(
                color: AppColors.green,
                label: 'Income',
                enabled: _showIncome,
                onTap: () => _toggleSeries(income: true),
              ),
              const SizedBox(width: 16),
              _Legend(
                color: AppColors.danger,
                label: 'Expense',
                enabled: _showExpense,
                onTap: () => _toggleSeries(income: false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  const _TotalStat({
    required this.label,
    required this.minor,
    required this.currency,
    required this.color,
    required this.icon,
  });
  final String label;
  final int minor;
  final CurrencyOption currency;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: context.inkSubtle, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          formatMoney(minor, currency),
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? context.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: selected ? context.ink : context.hairline),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: AppTextStyles.caption.copyWith(
            color: selected ? context.surface : context.ink,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.enabled = true,
    this.onTap,
  });
  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: enabled ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: context.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.points,
    required this.useMonthly,
    required this.currency,
    this.showIncome = true,
    this.showExpense = true,
  });
  final List<ChartPoint> points;
  final bool useMonthly;
  final CurrencyOption currency;
  final bool showIncome;
  final bool showExpense;

  @override
  Widget build(BuildContext context) {
    final inkMuted = context.inkMuted;
    final inkColor = context.ink;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), points[i].income / 100));
      expenseSpots.add(FlSpot(i.toDouble(), points[i].expense / 100));
    }

    // Rescale the Y-axis to only the visible series, so the remaining line
    // expands to fill the card when one is toggled off.
    final maxVal = points.fold<double>(0.0, (m, p) {
      double v = 0;
      if (showIncome && p.income > v) v = p.income;
      if (showExpense && p.expense > v) v = p.expense;
      return v > m ? v : m;
    }) /
        100;
    final maxY = maxVal == 0 ? 100.0 : (maxVal * 1.25).ceilToDouble();

    // Series list, in draw order, tracking which is income for the tooltip.
    final bars = <LineChartBarData>[];
    final barIsIncome = <bool>[];

    String bottomLabel(int idx) {
      if (idx < 0 || idx >= points.length) return '';
      final d = points[idx].date;
      if (useMonthly) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return months[d.month - 1];
      } else if (points.length <= 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[d.weekday - 1];
      } else {
        if (idx % 5 != 0) return '';
        return '${d.day}';
      }
    }

    if (showIncome) {
      bars.add(LineChartBarData(
        spots: incomeSpots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: AppColors.green,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.green.withValues(alpha: 0.15),
              AppColors.green.withValues(alpha: 0.0),
            ],
          ),
        ),
      ));
      barIsIncome.add(true);
    }
    if (showExpense) {
      bars.add(LineChartBarData(
        spots: expenseSpots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: AppColors.danger,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.danger.withValues(alpha: 0.06),
              AppColors.danger.withValues(alpha: 0.0),
            ],
          ),
        ),
      ));
      barIsIncome.add(false);
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineBarsData: bars,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final label = bottomLabel(value.toInt());
                if (label.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: AppTextStyles.caption
                        .copyWith(color: inkMuted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => inkColor,
            getTooltipItems: (spots) => spots.map((s) {
              final isIncome = s.barIndex >= 0 && s.barIndex < barIsIncome.length
                  ? barIsIncome[s.barIndex]
                  : true;
              final amount = (s.y * 100).round();
              return LineTooltipItem(
                '${isIncome ? '↑' : '↓'} ${formatMoney(amount, currency)}',
                AppTextStyles.caption.copyWith(
                  color: isIncome ? AppColors.green : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }
}
