import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../widgets/record_tile.dart';

class RecordsListPage extends ConsumerStatefulWidget {
  const RecordsListPage({super.key});

  @override
  ConsumerState<RecordsListPage> createState() => _RecordsListPageState();
}

class _RecordsListPageState extends ConsumerState<RecordsListPage> {
  RecordsFilter _filter = RecordsFilter.all;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(filteredRecordsProvider(_filter));
    final currency = ref.watch(currencyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == RecordsFilter.all,
                    onTap: () =>
                        setState(() => _filter = RecordsFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Income',
                    selected: _filter == RecordsFilter.incomeOnly,
                    onTap: () => setState(
                        () => _filter = RecordsFilter.incomeOnly),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Expense',
                    selected: _filter == RecordsFilter.expenseOnly,
                    onTap: () => setState(
                        () => _filter = RecordsFilter.expenseOnly),
                  ),
                ],
              ),
            ),
            Expanded(
              child: XSwitcher(
                child: records.when(
                loading: () => const Center(
                    key: ValueKey('rec-loading'),
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    key: const ValueKey('rec-error'), child: Text('$e')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      key: const ValueKey('rec-empty'),
                      child: Text('No records yet.',
                          style: AppTextStyles.caption
                              .copyWith(color: context.inkMuted)),
                    );
                  }
                  final groups = _groupByDay(items);
                  return ListView.builder(
                    key: const ValueKey('rec-list'),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Text(formatDayHeader(g.day),
                                style: AppTextStyles.caption
                                    .copyWith(color: context.inkMuted)),
                          ),
                          for (final r in g.items)
                            FadeIn(
                              key: ValueKey('fade-${r.id}'),
                              child: Dismissible(
                              key: ValueKey(r.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: AppColors.danger
                                    .withValues(alpha: 0.1),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                child: const Icon(Icons.delete_outline,
                                    color: AppColors.danger),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete record?'),
                                        content: const Text(
                                            'This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(
                                                  ctx, false),
                                              child: const Text('Cancel')),
                                          FilledButton(
                                              style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.danger,
                                                  foregroundColor:
                                                      Colors.white),
                                              onPressed: () => Navigator.pop(
                                                  ctx, true),
                                              child: const Text('Delete')),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) {
                                ref
                                    .read(databaseProvider)
                                    .deleteRecord(r.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child: RecordTile(record: r, currency: currency),
                              ),
                            ),
                            ),
                        ],
                      );
                    },
                  );
                },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<RecordRow> items) {
    final map = <DateTime, List<RecordRow>>{};
    for (final r in items) {
      final d = DateTime(
          r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
      map.putIfAbsent(d, () => []).add(r);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) _DayGroup(k, map[k]!)];
  }
}

class _DayGroup {
  final DateTime day;
  final List<RecordRow> items;
  _DayGroup(this.day, this.items);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.ink : Colors.transparent,
          border: Border.all(
              color: selected ? context.ink : context.hairline),
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.fast,
          style: AppTextStyles.caption.copyWith(
              color: selected ? context.surface : context.ink,
              fontWeight: FontWeight.w600),
          child: Text(label),
        ),
      ),
    );
  }
}
