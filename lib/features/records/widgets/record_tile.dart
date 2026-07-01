import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../ui/record_form_page.dart';

class RecordTile extends ConsumerWidget {
  const RecordTile({super.key, required this.record, required this.currency});
  final RecordRow record;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final isExpense = record.type == RecordType.expense;
    final isIncome = record.type == RecordType.income;
    final isLoanGiven = record.type == RecordType.loanGiven;
    final isLoanTaken = record.type == RecordType.loanTaken;
    final isLoan = isLoanGiven || isLoanTaken;

    final IconData icon = isExpense
        ? Icons.arrow_upward_rounded
        : isIncome
            ? Icons.arrow_downward_rounded
            : isLoanTaken
                ? Icons.arrow_circle_down_outlined
                : Icons.handshake_outlined;

    final String title = isLoan
        ? (record.counterparty?.isNotEmpty == true
            ? record.counterparty!
            : (isLoanTaken ? 'Loan taken' : 'Loan given'))
        : record.description?.isNotEmpty == true
            ? record.description!
            : (isExpense ? 'Expense' : 'Income');

    final String subtitle = isLoan
        ? (record.returned
            ? '${isLoanTaken ? 'Repaid' : 'Returned'} · ${formatShortDate(record.occurredAt)}'
            : record.expectedReturnAt != null
                ? 'Due ${formatShortDate(record.expectedReturnAt!)}'
                : formatShortDate(record.occurredAt))
        : formatShortDate(record.occurredAt);

    final String amount = isIncome
        ? formatMoneySigned(record.amountMinor, currency, negative: false)
        : formatMoneySigned(record.amountMinor, currency, negative: true);

    // Category name (expenses/income only) folded into the subline.
    String? catName;
    if (!isLoan && record.categoryId != null) {
      for (final c in cats) {
        if (c.id == record.categoryId) {
          catName = c.name;
          break;
        }
      }
    }
    final String subline =
        catName != null ? '$catName · $subtitle' : subtitle;

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            RecordFormPage(type: record.type, existing: record),
      )),
      borderRadius: BorderRadius.circular(AppRadii.inner),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: context.hairline),
                borderRadius: BorderRadius.circular(AppRadii.chip),
                color: isIncome || isLoan ? AppColors.greenSoft : null,
              ),
              child: Icon(icon,
                  color: isIncome ? AppColors.green : context.ink, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          color: context.ink,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(subline,
                      style: AppTextStyles.caption
                          .copyWith(color: context.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(amount,
                style: AppTextStyles.body.copyWith(
                    color: isIncome ? AppColors.green : context.ink,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
