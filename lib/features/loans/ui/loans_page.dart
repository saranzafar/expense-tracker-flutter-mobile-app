import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/date_range.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../../records/ui/add_record_sheet.dart';
import '../../records/ui/record_form_page.dart';
import '../../shared/date_range_bar.dart';

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
  DateRangeFilter _range = DateRangeFilter.month;

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final outstanding = ref.watch(outstandingLoansProvider(_range));
    final returned = ref.watch(returnedLoansProvider(_range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
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
      body: Column(
        children: [
          DateRangeBar(
            value: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _LoansList(loans: outstanding, isOutstanding: true),
                _LoansList(loans: returned, isOutstanding: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoansList extends ConsumerWidget {
  const _LoansList({required this.loans, required this.isOutstanding});
  final AsyncValue<List<RecordRow>> loans;
  final bool isOutstanding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return XSwitcher(
      child: loans.when(
        loading: () => const Center(
            key: ValueKey('loans-loading'),
            child: CircularProgressIndicator()),
        error: (e, _) => Center(
            key: const ValueKey('loans-error'), child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return _Empty(
                key: const ValueKey('loans-empty'),
                isOutstanding: isOutstanding);
          }
          return ListView.separated(
            key: const ValueKey('loans-list'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => FadeIn(
              key: ValueKey(items[i].id),
              child: _LoanCard(loan: items[i]),
            ),
          );
        },
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
  const _Empty({super.key, required this.isOutstanding});
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
