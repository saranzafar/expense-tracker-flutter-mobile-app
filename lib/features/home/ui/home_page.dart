import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../records/ui/record_form_page.dart';
import '../../records/widgets/record_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recent = ref.watch(recentRecordsProvider);

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
                      Text('Hello there', style: AppTextStyles.caption),
                      const SizedBox(height: 4),
                      Text('Your money', style: AppTextStyles.headline),
                    ],
                  ),
                ),
                Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            stats.when(
              loading: () => const _BalanceCardSkeleton(),
              error: (e, _) => Text('Error: $e'),
              data: (s) => _BalanceCard(stats: s),
            ),
            const SizedBox(height: 16),
            stats.maybeWhen(
              data: (s) => s.outstandingLoanCount == 0
                  ? const SizedBox.shrink()
                  : _OutstandingCard(stats: s),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent activity', style: AppTextStyles.title),
                stats.maybeWhen(
                  data: (_) => TextButton(
                      onPressed: () {},
                      child: Text('See all',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.ink))),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recent.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
              data: (items) {
                if (items.isEmpty) return const _EmptyRecent();
                return Column(
                  children: [
                    for (final r in items) RecordTile(record: r),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available balance', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(
            formatPkr(stats.availableBalance),
            style: AppTextStyles.display.copyWith(color: AppColors.green),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income (mo)',
                  value: formatPkr(stats.monthIncomeMinor),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 36, color: AppColors.hairline),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Expense (mo)',
                  value: formatPkr(stats.monthExpenseMinor),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _OutstandingCard extends StatelessWidget {
  const _OutstandingCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handshake_outlined,
                color: AppColors.ink, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Outstanding loans · ${stats.outstandingLoanCount}',
                    style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(formatPkr(stats.outstandingLoanMinor),
                    style: AppTextStyles.title
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.inkSubtle),
        ],
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SvgPicture.asset('assets/illustrations/track.svg', height: 120),
          const SizedBox(height: 12),
          Text('Nothing tracked yet',
              style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Tap + to log your first record.',
              style: AppTextStyles.caption),
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
