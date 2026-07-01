import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/date_range.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../../shared/totals_strip.dart';
import 'project_detail_page.dart';
import 'project_form_page.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _categoryId;
  DateRangeFilter _range = DateRangeFilter.year;

  bool get _hasActiveFilters =>
      _categoryId != null || _range != DateRangeFilter.year;

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectFilterSheet(
        initialCategoryId: _categoryId,
        initialRange: _range,
        onChanged: (categoryId, range) {
          setState(() {
            _categoryId = categoryId;
            _range = range;
          });
        },
        onReset: () => setState(() {
          _categoryId = null;
          _range = DateRangeFilter.year;
        }),
      ),
    );
  }

  List<ProjectRow> _applyFilters(List<ProjectRow> all) {
    final now = DateTime.now();
    final resolved = _range.resolve(now);
    return all.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (p.startDate.isBefore(resolved.start) ||
          p.startDate.isAfter(resolved.end)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final projectsAsync = ref.watch(projectsProvider);
    final currency = ref.watch(currencyProvider);
    final received =
        ref.watch(receivedByProjectProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
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
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProjectFormPage(),
            )),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            ref.invalidate(projectsProvider);
            ref.invalidate(receivedByProjectProvider);
            await ref.read(projectsProvider.future);
          },
          child: XSwitcher(
          child: projectsAsync.when(
            loading: () => const Center(
                key: ValueKey('proj-loading'),
                child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(key: const ValueKey('proj-error'), child: Text('$e')),
            data: (all) {
              final items = _applyFilters(all);
              if (all.isEmpty) {
                return ListView(
                  key: const ValueKey('proj-empty'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_outlined,
                                  size: 56, color: context.inkSubtle),
                              const SizedBox(height: 16),
                              Text('No projects yet',
                                  style: AppTextStyles.title
                                      .copyWith(color: context.ink)),
                              const SizedBox(height: 6),
                              Text('Tap + to create your first project',
                                  style: AppTextStyles.caption
                                      .copyWith(color: context.inkMuted),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (items.isEmpty) {
                return ListView(
                  key: const ValueKey('proj-filtered-empty'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_off_outlined,
                                size: 48, color: context.inkSubtle),
                            const SizedBox(height: 12),
                            Text('No projects match',
                                style: AppTextStyles.title
                                    .copyWith(color: context.ink)),
                            const SizedBox(height: 4),
                            Text('Try adjusting your filters',
                                style: AppTextStyles.caption
                                    .copyWith(color: context.inkMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              final budget =
                  items.fold<int>(0, (s, p) => s + p.totalAmountMinor);
              final receivedTotal = items.fold<int>(
                  0, (s, p) => s + (received[p.id] ?? 0));
              final remaining = budget - receivedTotal;
              return ListView.builder(
                key: const ValueKey('proj-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: items.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return SummaryBoard(
                      left: BoardStat(
                        icon: Icons.account_balance_wallet_outlined,
                        color: context.ink,
                        label: 'Budget',
                        value: formatMoney(budget, currency),
                      ),
                      middle: BoardStat(
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.green,
                        label: 'Received',
                        value: formatMoney(receivedTotal, currency),
                      ),
                      rightLabel: 'Remaining',
                      rightValue: formatMoney(remaining, currency),
                      rightColor: remaining <= 0
                          ? AppColors.green
                          : context.ink,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    );
                  }
                  final project = items[i - 1];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                    child: FadeIn(
                      key: ValueKey(project.id),
                      child: _ProjectCard(
                        project: project,
                        currency: currency,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailPage(project: project),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ),
        ),
      ),
    );
  }
}

// ── Project card ──────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({
    required this.project,
    required this.currency,
    required this.onTap,
  });
  final ProjectRow project;
  final CurrencyOption currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(projectPaymentsProvider(project.id));
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catName = cats
        .where((c) => c.id == project.categoryId)
        .map((c) => c.name)
        .firstOrNull;

    return paymentsAsync.when(
      loading: () => _CardShell(
          project: project, catName: catName, onTap: onTap,
          currency: currency, paidMinor: 0),
      error: (_, __) => _CardShell(
          project: project, catName: catName, onTap: onTap,
          currency: currency, paidMinor: 0),
      data: (payments) {
        final paid = payments.fold(0, (s, p) => s + p.amountMinor);
        return _CardShell(
          project: project,
          catName: catName,
          onTap: onTap,
          currency: currency,
          paidMinor: paid,
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.project,
    required this.catName,
    required this.onTap,
    required this.currency,
    required this.paidMinor,
  });
  final ProjectRow project;
  final String? catName;
  final VoidCallback onTap;
  final CurrencyOption currency;
  final int paidMinor;

  @override
  Widget build(BuildContext context) {
    final progress =
        (paidMinor / project.totalAmountMinor).clamp(0.0, 1.0);
    final isDone = paidMinor >= project.totalAmountMinor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardSurface,
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          style: AppTextStyles.title
                              .copyWith(color: context.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (project.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(project.description!,
                            style: AppTextStyles.caption
                                .copyWith(color: context.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (catName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(catName!,
                        style: AppTextStyles.caption.copyWith(
                            color: context.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: context.hairline,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatMoney(paidMinor, currency)} paid',
                  style: AppTextStyles.caption.copyWith(
                      color: isDone ? AppColors.green : context.inkMuted),
                ),
                Text(
                  'of ${formatMoney(project.totalAmountMinor, currency)}',
                  style: AppTextStyles.caption
                      .copyWith(color: context.inkSubtle),
                ),
              ],
            ),
            if (project.endDate != null) ...[
              const SizedBox(height: 6),
              Text(
                '${formatShortDate(project.startDate)} → ${formatShortDate(project.endDate!)}',
                style: AppTextStyles.caption
                    .copyWith(color: context.inkSubtle, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _ProjectFilterSheet extends ConsumerStatefulWidget {
  const _ProjectFilterSheet({
    required this.initialCategoryId,
    required this.initialRange,
    required this.onChanged,
    required this.onReset,
  });
  final String? initialCategoryId;
  final DateRangeFilter initialRange;
  final void Function(String?, DateRangeFilter) onChanged;
  final VoidCallback onReset;

  @override
  ConsumerState<_ProjectFilterSheet> createState() =>
      _ProjectFilterSheetState();
}

class _ProjectFilterSheetState extends ConsumerState<_ProjectFilterSheet> {
  late String? _categoryId;
  late DateRangeFilter _quickRange;
  bool _isCustom = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    if (isCustomRange(widget.initialRange)) {
      _isCustom = true;
      final r = widget.initialRange.resolve(DateTime.now());
      _customStart = r.start;
      _customEnd = r.end;
      _quickRange = DateRangeFilter.year;
    } else {
      _quickRange = widget.initialRange;
    }
  }

  DateRangeFilter get _effectiveRange {
    if (_isCustom && _customStart != null && _customEnd != null) {
      return DateRangeFilter.custom(_customStart!, _customEnd!);
    }
    return _quickRange;
  }

  bool get _hasActiveFilters =>
      _categoryId != null ||
      _isCustom ||
      _quickRange != DateRangeFilter.year;

  void _notify() => widget.onChanged(_categoryId, _effectiveRange);

  void _reset() {
    setState(() {
      _categoryId = null;
      _quickRange = DateRangeFilter.year;
      _isCustom = false;
      _customStart = null;
      _customEnd = null;
    });
    widget.onReset();
  }

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
              const InputDecoration(hintText: 'e.g. Construction, IT'),
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
      _notify();
      return;
    }
    final row = await ref.read(databaseProvider).addCategory(name);
    if (!mounted) return;
    setState(() => _categoryId = row.id);
    _notify();
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
      lastDate: DateTime(2040),
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

              // Title + reset
              Row(
                children: [
                  Text('Filter Projects',
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

              // ── Category ──────────────────────────────────────────────────
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
                        setState(() => _categoryId =
                            _categoryId == cat.id ? null : cat.id);
                        _notify();
                      },
                    ),
                  _AddChip(onTap: () => _addCategory(cats)),
                ],
              ),

              // ── Date range ────────────────────────────────────────────────
              const SizedBox(height: 20),
              _sectionLabel('Start Date Range'),
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

              // Custom date pickers
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

  Widget _sectionLabel(String text) =>
      Text(text, style: AppTextStyles.title.copyWith(color: context.ink));
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
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
            color: selected ? context.surface : context.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      color: date != null ? context.ink : context.inkSubtle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
