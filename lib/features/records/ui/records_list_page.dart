import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_range.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../../shared/date_range_bar.dart';
import '../widgets/record_tile.dart';
import 'add_record_sheet.dart';

class RecordsListPage extends ConsumerStatefulWidget {
  const RecordsListPage({super.key});

  @override
  ConsumerState<RecordsListPage> createState() => _RecordsListPageState();
}

class _RecordsListPageState extends ConsumerState<RecordsListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  RecordsFilter _filter = RecordsFilter.all;
  DateRangeFilter _range = DateRangeFilter.month;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = ref.watch(filteredRecordsProvider(RecordsQuery(
      type: _filter,
      range: _range,
      categoryId: _selectedCategoryId,
    )));
    final currency = ref.watch(currencyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => openAddRecordSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateRangeBar(
              value: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            _TypeSegmentBar(
              value: _filter,
              onChanged: (f) => setState(() {
                _filter = f;
                if (f == RecordsFilter.incomeOnly) _selectedCategoryId = null;
              }),
            ),
            AnimatedSize(
              duration: AppMotion.med,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: _filter == RecordsFilter.incomeOnly
                  ? const SizedBox(width: double.infinity)
                  : _CategoryFilterRow(
                      selected: _selectedCategoryId,
                      onChanged: (id) =>
                          setState(() => _selectedCategoryId = id),
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

// ── Primary type filter — segmented pill track ──────────────────────────────

class _TypeSegmentBar extends StatelessWidget {
  const _TypeSegmentBar({required this.value, required this.onChanged});
  final RecordsFilter value;
  final ValueChanged<RecordsFilter> onChanged;

  static const _options = [
    (RecordsFilter.all, 'All'),
    (RecordsFilter.incomeOnly, 'Income'),
    (RecordsFilter.expenseOnly, 'Expense'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: context.hairline,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final (filter, label) in _options)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(filter),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.enter,
                    decoration: BoxDecoration(
                      color: value == filter ? context.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: value == filter
                          ? [
                              BoxShadow(
                                color: context.ink.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.fast,
                      style: AppTextStyles.caption.copyWith(
                        color: value == filter ? context.ink : context.inkSubtle,
                        fontWeight: value == filter ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Secondary category filter — small accent chips ───────────────────────────

class _CategoryFilterRow extends ConsumerWidget {
  const _CategoryFilterRow({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    if (cats.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _CategoryChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final cat in cats) ...[
            const SizedBox(width: 6),
            _CategoryChip(
              label: cat.name,
              selected: selected == cat.id,
              onTap: () => onChanged(selected == cat.id ? null : cat.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenSoft : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.green.withValues(alpha: 0.4) : context.hairline,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.fast,
          style: AppTextStyles.caption.copyWith(
            color: selected ? context.ink : context.inkSubtle,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
