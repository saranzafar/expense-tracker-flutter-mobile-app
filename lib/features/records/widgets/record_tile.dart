import 'package:flutter/material.dart';

import '../../../core/currency.dart';
import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../ui/record_form_page.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record, required this.currency});
  final RecordRow record;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context) {
    final isExpense = record.type == RecordType.expense;
    final isIncome = record.type == RecordType.income;
    final isLoan = record.type == RecordType.loanGiven;

    final IconData icon = isExpense
        ? Icons.arrow_upward_rounded
        : isIncome
            ? Icons.arrow_downward_rounded
            : Icons.handshake_outlined;

    final String title = isLoan
        ? (record.counterparty?.isNotEmpty == true
            ? record.counterparty!
            : 'Loan')
        : record.description?.isNotEmpty == true
            ? record.description!
            : (isExpense ? 'Expense' : 'Income');

    final String subtitle = isLoan
        ? (record.returned
            ? 'Returned · ${formatShortDate(record.occurredAt)}'
            : record.expectedReturnAt != null
                ? 'Due ${formatShortDate(record.expectedReturnAt!)}'
                : formatShortDate(record.occurredAt))
        : formatShortDate(record.occurredAt);

    final String amount = isIncome
        ? formatMoneySigned(record.amountMinor, currency, negative: false)
        : formatMoneySigned(record.amountMinor, currency, negative: true);

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            RecordFormPage(type: record.type, existing: record),
      )),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: context.hairline),
                borderRadius: BorderRadius.circular(12),
                color: isLoan ? AppColors.greenSoft : null,
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
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.inkMuted)),
                ],
              ),
            ),
            Text(amount,
                style: AppTextStyles.body.copyWith(
                    color: context.ink, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
