import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/currency.dart';
import '../../../core/date_range.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../../records/ui/add_record_sheet.dart';
import '../../records/ui/record_form_page.dart';
import '../../shared/totals_strip.dart';

class LoansPage extends ConsumerStatefulWidget {
  const LoansPage({super.key});

  @override
  ConsumerState<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends ConsumerState<LoansPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final TabController _tab;
  LoanTypeFilter _type = LoanTypeFilter.all;
  String? _categoryId;
  DateRangeFilter _range = DateRangeFilter.month;

  bool get _hasActiveFilters =>
      _type != LoanTypeFilter.all ||
      _categoryId != null ||
      _range != DateRangeFilter.month;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoansFilterSheet(
        initialType: _type,
        initialCategoryId: _categoryId,
        initialRange: _range,
        onChanged: (type, categoryId, range) {
          setState(() {
            _type = type;
            _categoryId = categoryId;
            _range = range;
          });
        },
        onReset: () {
          setState(() {
            _type = LoanTypeFilter.all;
            _categoryId = null;
            _range = DateRangeFilter.month;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final outstandingQuery = LoansQuery(
      returned: false,
      type: _type,
      categoryId: _categoryId,
      range: _range,
    );
    final returnedQuery = LoansQuery(
      returned: true,
      type: _type,
      categoryId: _categoryId,
      range: _range,
    );
    final outstanding = ref.watch(loansProvider(outstandingQuery));
    final returned = ref.watch(loansProvider(returnedQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (_hasActiveFilters)
                  Positioned(
                    right: -1,
                    top: -1,
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
            onPressed: _openFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => openAddRecordSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tab,
            indicatorColor: AppColors.green,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: context.ink,
            unselectedLabelColor: context.inkSubtle,
            labelStyle:
                AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTextStyles.body,
            tabs: const [
              Tab(text: 'Outstanding'),
              Tab(text: 'Returned'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _LoansList(
              loans: outstanding, isOutstanding: true, query: outstandingQuery),
          _LoansList(
              loans: returned, isOutstanding: false, query: returnedQuery),
        ],
      ),
    );
  }
}

class _LoansList extends ConsumerWidget {
  const _LoansList(
      {required this.loans,
      required this.isOutstanding,
      required this.query});
  final AsyncValue<List<RecordRow>> loans;
  final bool isOutstanding;
  final LoansQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        ref.invalidate(loansProvider);
        await ref.read(loansProvider(query).future);
      },
      child: XSwitcher(
      child: loans.when(
        loading: () => const Center(
            key: ValueKey('loans-loading'),
            child: CircularProgressIndicator()),
        error: (e, _) => Center(
            key: const ValueKey('loans-error'), child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              key: const ValueKey('loans-empty'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: _Empty(isOutstanding: isOutstanding),
                ),
              ],
            );
          }
          final lent = items
              .where((r) => r.type == RecordType.loanGiven)
              .fold<int>(0, (s, r) => s + r.amountMinor);
          final borrowed = items
              .where((r) => r.type == RecordType.loanTaken)
              .fold<int>(0, (s, r) => s + r.amountMinor);
          final net = lent - borrowed;
          return ListView.builder(
            key: const ValueKey('loans-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: items.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return SummaryBoard(
                  left: BoardStat(
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.green,
                    label: 'Lent out',
                    value: formatMoney(lent, currency),
                  ),
                  middle: BoardStat(
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.danger,
                    label: 'Borrowed',
                    value: formatMoney(borrowed, currency),
                  ),
                  rightLabel: 'Net',
                  rightValue:
                      '${net >= 0 ? '+' : '−'} ${formatMoney(net.abs(), currency)}',
                  rightColor:
                      net >= 0 ? AppColors.green : AppColors.danger,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                );
              }
              final loan = items[i - 1];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: FadeIn(
                  key: ValueKey(loan.id),
                  child: _LoanCard(loan: loan),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  const _LoanCard({required this.loan});
  final RecordRow loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final isBorrowed = loan.type == RecordType.loanTaken;
    final overdue = !loan.returned &&
        loan.expectedReturnAt != null &&
        loan.expectedReturnAt!.isBefore(DateTime.now());

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecordFormPage(type: loan.type, existing: loan),
      )),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBorrowed
                        ? Icons.arrow_circle_down_outlined
                        : Icons.handshake_outlined,
                    size: 20,
                    color: context.ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.counterparty ??
                            (isBorrowed ? 'Loan taken' : 'Loan given'),
                        style:
                            AppTextStyles.title.copyWith(color: context.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBorrowed ? 'Borrowed from' : 'Lent to',
                        style: AppTextStyles.caption
                            .copyWith(color: context.inkMuted, fontSize: 11),
                      ),
                      if (loan.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 1),
                        Text(loan.description!,
                            style: AppTextStyles.caption
                                .copyWith(color: context.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                AnimatedMoney(
                  minor: loan.amountMinor,
                  currency: currency,
                  style: AppTextStyles.title.copyWith(
                      color: context.ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            XSwitcher(
              child: Row(
                key: ValueKey(loan.returned),
                children: [
                  if (loan.returned) ...[
                    _Badge(
                      text: isBorrowed ? 'Repaid' : 'Returned',
                      bg: AppColors.greenSoft,
                      fg: context.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                        loan.returnedAt != null
                            ? 'on ${formatShortDate(loan.returnedAt!)}'
                            : '',
                        style: AppTextStyles.caption
                            .copyWith(color: context.inkMuted)),
                  ] else ...[
                    if (loan.expectedReturnAt != null)
                      _Badge(
                        text: 'Due ${formatShortDate(loan.expectedReturnAt!)}',
                        bg: overdue
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : Colors.transparent,
                        fg: overdue ? AppColors.danger : context.inkMuted,
                        border: !overdue,
                        borderColor: context.hairline,
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref
                          .read(databaseProvider)
                          .markLoanReturned(loan.id, returned: true),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        isBorrowed ? 'Mark repaid' : 'Mark returned',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  if (loan.returned) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref
                          .read(databaseProvider)
                          .markLoanReturned(loan.id, returned: false),
                      child: Text(
                        isBorrowed ? 'Undo repayment' : 'Undo',
                        style: AppTextStyles.caption.copyWith(
                            color: context.ink, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.bg,
    required this.fg,
    this.border = false,
    this.borderColor,
  });
  final String text;
  final Color bg;
  final Color fg;
  final bool border;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: border
            ? Border.all(color: borderColor ?? context.hairline)
            : null,
      ),
      child: Text(text,
          style: AppTextStyles.caption
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isOutstanding});
  final bool isOutstanding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/illustrations/loans.svg',
            height: 140,
            theme: SvgTheme(currentColor: context.ink),
          ),
          const SizedBox(height: 16),
          Text(
              isOutstanding
                  ? 'No outstanding loans'
                  : 'Nothing returned yet',
              style: AppTextStyles.title.copyWith(color: context.ink)),
          const SizedBox(height: 6),
          Text(
            isOutstanding
                ? 'When you lend money, it shows up here.'
                : 'Loans marked as returned will appear here.',
            style:
                AppTextStyles.caption.copyWith(color: context.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _LoansFilterSheet extends ConsumerStatefulWidget {
  const _LoansFilterSheet({
    required this.initialType,
    required this.initialCategoryId,
    required this.initialRange,
    required this.onChanged,
    required this.onReset,
  });
  final LoanTypeFilter initialType;
  final String? initialCategoryId;
  final DateRangeFilter initialRange;
  final void Function(LoanTypeFilter, String?, DateRangeFilter) onChanged;
  final VoidCallback onReset;

  @override
  ConsumerState<_LoansFilterSheet> createState() => _LoansFilterSheetState();
}

class _LoansFilterSheetState extends ConsumerState<_LoansFilterSheet> {
  late LoanTypeFilter _type;
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
    return _quickRange;
  }

  bool get _hasActiveFilters =>
      _type != LoanTypeFilter.all ||
      _categoryId != null ||
      _isCustom ||
      _quickRange != DateRangeFilter.month;

  void _notify() => widget.onChanged(_type, _categoryId, _effectiveRange);

  void _reset() {
    setState(() {
      _type = LoanTypeFilter.all;
      _categoryId = null;
      _quickRange = DateRangeFilter.month;
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
              const InputDecoration(hintText: 'e.g. Family, Work'),
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
              Row(
                children: [
                  Text('Filter Loans',
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
                    selected: _type == LoanTypeFilter.all,
                    onTap: () {
                      setState(() => _type = LoanTypeFilter.all);
                      _notify();
                    },
                  ),
                  _Chip(
                    label: 'Lent out',
                    selected: _type == LoanTypeFilter.lent,
                    onTap: () {
                      setState(() => _type = LoanTypeFilter.lent);
                      _notify();
                    },
                  ),
                  _Chip(
                    label: 'Borrowed',
                    selected: _type == LoanTypeFilter.borrowed,
                    onTap: () {
                      setState(() => _type = LoanTypeFilter.borrowed);
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

// ── Chips / date tile (local copies, matching Records/Projects) ────────────────

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
