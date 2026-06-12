import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/database.dart';
import 'record_form_page.dart';

Future<void> openAddRecordSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<RecordType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add new',
                style: AppTextStyles.headline.copyWith(color: context.ink)),
            const SizedBox(height: 16),
            _TypeCard(
              icon: Icons.arrow_upward_rounded,
              title: 'Expense',
              subtitle: 'Money you spent',
              onTap: () => Navigator.pop(ctx, RecordType.expense),
            ),
            const SizedBox(height: 10),
            _TypeCard(
              icon: Icons.arrow_downward_rounded,
              title: 'Income',
              subtitle: 'Money you received',
              onTap: () => Navigator.pop(ctx, RecordType.income),
            ),
            const SizedBox(height: 10),
            _TypeCard(
              icon: Icons.handshake_outlined,
              title: 'Loan given',
              subtitle: 'Money you lent to someone',
              onTap: () => Navigator.pop(ctx, RecordType.loanGiven),
              accent: true,
            ),
            const SizedBox(height: 10),
            _TypeCard(
              icon: Icons.arrow_circle_down_outlined,
              title: 'Loan taken',
              subtitle: 'Money you borrowed from someone',
              onTap: () => Navigator.pop(ctx, RecordType.loanTaken),
            ),
          ],
        ),
      ),
    ),
  );
  if (picked != null && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordFormPage(type: picked),
    ));
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent ? AppColors.greenSoft : Colors.transparent,
                border: Border.all(color: context.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.title.copyWith(color: context.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.inkMuted)),
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
