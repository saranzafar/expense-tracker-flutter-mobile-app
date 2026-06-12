import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_range.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../widgets/record_tile.dart';
import 'add_record_sheet.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

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

  bool get _hasActiveFilters =>
      _filter != RecordsFilter.all ||
      _selectedCategoryId != null ||
      _range != DateRangeFilter.month;

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialType: _filter,
        initialCategoryId: _selectedCategoryId,
        initialRange: _range,
        onChanged: (type, categoryId, range) {
          // Live update — list rebuilds behind the sheet immediately.
          setState(() {
            _filter = type;
            _selectedCategoryId = categoryId;
            _range = range;
          });
        },
        onReset: () => setState(() {
          _filter = RecordsFilter.all;
          _selectedCategoryId = null;
          _range = DateRangeFilter.month;
        }),
      ),
    );
  }

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
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (_hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => openAddRecordSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: XSwitcher(
          child: records.when(
            loading: () => const Center(
                key: ValueKey('rec-loading'),
                child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(key: const ValueKey('rec-error'), child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  key: const ValueKey('rec-empty'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48, color: context.inkSubtle),
                      const SizedBox(height: 12),
                      Text('No records found',
                          style:
                              AppTextStyles.title.copyWith(color: context.ink)),
                      const SizedBox(height: 4),
                      Text(
                        _hasActiveFilters
                            ? 'Try adjusting your filters'
                            : 'Tap + to add your first record',
                        style: AppTextStyles.caption
                            .copyWith(color: context.inkMuted),
                      ),
                    ],
                  ),
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
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
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
                              color:
                                  AppColors.danger.withValues(alpha: 0.1),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.danger),
                            ),
                            confirmDismiss: (_) async =>
                                await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete record?'),
                                    content: const Text(
                                        'This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                          style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.danger,
                                              foregroundColor:
                                                  Colors.white),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                ) ??
                                false,
                            onDismissed: (_) =>
                                ref.read(databaseProvider).deleteRecord(r.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              child:
                                  RecordTile(record: r, currency: currency),
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
    );
  }

  List<_DayGroup> _groupByDay(List<RecordRow> items) {
    final map = <DateTime, List<RecordRow>>{};
    for (final r in items) {
      final d =
          DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
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

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.initialType,
    required this.initialCategoryId,
    required this.initialRange,
    required this.onChanged,
    required this.onReset,
  });
  final RecordsFilter initialType;
  final String? initialCategoryId;
  final DateRangeFilter initialRange;
  final void Function(RecordsFilter, String?, DateRangeFilter) onChanged;
  final VoidCallback onReset;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late RecordsFilter _type;
  late String? _categoryId;
  late DateRangeFilter _quickRange;
  bool _isCustom = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categoryId = widget.initialCategoryId;
    if (isCustomRange(widget.initialRange)) {
      _isCustom = true;
      final r = widget.initialRange.resolve(DateTime.now());
      _customStart = r.start;
      _customEnd = r.end;
      _quickRange = DateRangeFilter.month;
    } else {
      _quickRange = widget.initialRange;
    }
  }

  DateRangeFilter get _effectiveRange {
    if (_isCustom && _customStart != null && _customEnd != null) {
      return DateRangeFilter.custom(_customStart!, _customEnd!);
    }
    return _isCustom ? _quickRange : _quickRange;
  }

  bool get _hasActiveFilters =>
      _type != RecordsFilter.all ||
      _categoryId != null ||
      _isCustom ||
      _quickRange != DateRangeFilter.month;

  Future<void> _addCategory(List<CategoryRow> cats) async {
    String inputText = '';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(hintText: 'e.g. Food, Transport'),
          onChanged: (v) => inputText = v,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, inputText.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final existing =
        cats.where((c) => c.name.toLowerCase() == name.toLowerCase());
    if (existing.isNotEmpty) {
      setState(() => _categoryId = existing.first.id);
      widget.onChanged(_type, existing.first.id, _effectiveRange);
      return;
    }
    final row = await ref.read(databaseProvider).addCategory(name);
    if (!mounted) return;
    setState(() => _categoryId = row.id);
    widget.onChanged(_type, row.id, _effectiveRange);
  }

  void _notify() =>
      widget.onChanged(_type, _categoryId, _effectiveRange);

  void _reset() {
    setState(() {
      _type = RecordsFilter.all;
      _categoryId = null;
      _quickRange = DateRangeFilter.month;
      _isCustom = false;
      _customStart = null;
      _customEnd = null;
    });
    widget.onReset();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_customStart ?? now)
        : (_customEnd ?? _customStart ?? now);
    final firstDate =
        isStart ? DateTime(2020) : (_customStart ?? DateTime(2020));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
        if (_customEnd != null && _customEnd!.isBefore(picked)) {
          _customEnd = null;
        }
      } else {
        _customEnd = picked;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row + reset icon
              Row(
                children: [
                  Text('Filter Records',
                      style: AppTextStyles.headline
                          .copyWith(color: context.ink)),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _hasActiveFilters ? 1.0 : 0.0,
                    duration: AppMotion.fast,
                    child: GestureDetector(
                      onTap: _hasActiveFilters ? _reset : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.hairline,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.refresh_rounded,
                            size: 18, color: context.ink),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Type ──────────────────────────────────────────────────────
              _sectionLabel('Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: 'All',
                    selected: _type == RecordsFilter.all,
                    onTap: () {
                      setState(() => _type = RecordsFilter.all);
                      _notify();
                    },
                  ),
                  _Chip(
                    label: 'Income',
                    selected: _type == RecordsFilter.incomeOnly,
                    onTap: () {
                      setState(() => _type = RecordsFilter.incomeOnly);
                      _notify();
                    },
                  ),
                  _Chip(
                    label: 'Expense',
                    selected: _type == RecordsFilter.expenseOnly,
                    onTap: () {
                      setState(() => _type = RecordsFilter.expenseOnly);
                      _notify();
                    },
                  ),
                ],
              ),

              // ── Category ──────────────────────────────────────────────────
              const SizedBox(height: 20),
              _sectionLabel('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (cats.isNotEmpty)
                    _Chip(
                      label: 'All',
                      selected: _categoryId == null,
                      onTap: () {
                        setState(() => _categoryId = null);
                        _notify();
                      },
                    ),
                  for (final cat in cats)
                    _Chip(
                      label: cat.name,
                      selected: _categoryId == cat.id,
                      onTap: () {
                        setState(() =>
                            _categoryId =
                                _categoryId == cat.id ? null : cat.id);
                        _notify();
                      },
                    ),
                  _AddChip(onTap: () => _addCategory(cats)),
                ],
              ),

              // ── Date range ────────────────────────────────────────────────
              const SizedBox(height: 20),
              _sectionLabel('Date Range'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: '1W',
                    selected:
                        !_isCustom && _quickRange == DateRangeFilter.week,
                    onTap: () {
                      setState(() {
                        _isCustom = false;
                        _quickRange = DateRangeFilter.week;
                      });
                      _notify();
                    },
                  ),
                  _Chip(
                    label: '1M',
                    selected:
                        !_isCustom && _quickRange == DateRangeFilter.month,
                    onTap: () {
                      setState(() {
                        _isCustom = false;
                        _quickRange = DateRangeFilter.month;
                      });
                      _notify();
                    },
                  ),
                  _Chip(
                    label: '1Y',
                    selected:
                        !_isCustom && _quickRange == DateRangeFilter.year,
                    onTap: () {
                      setState(() {
                        _isCustom = false;
                        _quickRange = DateRangeFilter.year;
                      });
                      _notify();
                    },
                  ),
                  _Chip(
                    label: 'Custom',
                    selected: _isCustom,
                    onTap: () {
                      setState(() => _isCustom = !_isCustom);
                      _notify();
                    },
                  ),
                ],
              ),

              // ── Custom date pickers ────────────────────────────────────────
              AnimatedSize(
                duration: AppMotion.med,
                curve: AppMotion.enter,
                alignment: Alignment.topCenter,
                child: _isCustom
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DateTile(
                                label: 'From',
                                date: _customStart,
                                onTap: () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateTile(
                                label: 'To',
                                date: _customEnd,
                                onTap: () => _pickDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.title.copyWith(color: context.ink),
      );
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(
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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          // Selected = ink (black in light, white in dark), unselected = transparent
          color: selected ? context.ink : Colors.transparent,
          border: Border.all(
            color: selected ? context.ink : context.hairline,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            // Flip: selected text = surface (white in light, dark in dark)
            color: selected ? context.surface : context.inkSubtle,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Add-category chip ─────────────────────────────────────────────────────────

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.hairline, width: 1.5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: context.inkSubtle),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: AppTextStyles.caption.copyWith(
                color: context.inkSubtle,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date picker tile ──────────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  const _DateTile(
      {required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: context.inkMuted, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: context.inkSubtle),
                const SizedBox(width: 6),
                Text(
                  date != null ? formatShortDate(date!) : 'Select',
                  style: AppTextStyles.body.copyWith(
                    color:
                        date != null ? context.ink : context.inkSubtle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
