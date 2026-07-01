import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// One labeled figure inside a [SummaryBoard] — an icon, a caption and a value,
/// all tinted with [color].
class BoardStat {
  const BoardStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

/// The three-figure summary board used above the Records, Loans and Projects
/// lists: two stats on the left, a right-aligned emphasis stat (Net / Remaining).
///
/// Extracted from the original Records `_TotalsStrip` so every screen shares one
/// look and one place to change it.
class SummaryBoard extends StatelessWidget {
  const SummaryBoard({
    super.key,
    required this.left,
    required this.middle,
    required this.rightLabel,
    required this.rightValue,
    required this.rightColor,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 4),
  });

  final BoardStat left;
  final BoardStat middle;
  final String rightLabel;
  final String rightValue;
  final Color rightColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardSurface,
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(AppRadii.inner),
          boxShadow: context.softShadow,
        ),
        child: Row(
          children: [
            _StatItem(stat: left),
            Container(
              width: 1,
              height: 32,
              color: context.hairline,
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            _StatItem(stat: middle),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rightLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkSubtle, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  rightValue,
                  style: AppTextStyles.caption.copyWith(
                    color: rightColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat});
  final BoardStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(stat.icon, size: 10, color: stat.color),
            const SizedBox(width: 3),
            Text(stat.label,
                style: AppTextStyles.caption
                    .copyWith(color: context.inkSubtle, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(stat.value,
            style: AppTextStyles.caption.copyWith(
                color: stat.color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
