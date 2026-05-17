import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_range.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';

class DateRangeBar extends ConsumerWidget {
  const DateRangeBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateRangeFilter value;
  final ValueChanged<DateRangeFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earliestAsync = ref.watch(earliestRecordYearProvider);
    final earliest = earliestAsync.maybeWhen(
      data: (y) => y,
      orElse: () => DateTime.now().year,
    );
    final thisYear = DateTime.now().year;
    final selectedYear = calendarYearOf(value);
    final yearForChip = selectedYear ?? thisYear;

    final years = <int>[
      for (int y = thisYear; y >= earliest; y--) y,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PillChip(
              label: '1D',
              selected: value == DateRangeFilter.day,
              onTap: () => onChanged(DateRangeFilter.day),
            ),
            const SizedBox(width: 8),
            _PillChip(
              label: '1W',
              selected: value == DateRangeFilter.week,
              onTap: () => onChanged(DateRangeFilter.week),
            ),
            const SizedBox(width: 8),
            _PillChip(
              label: '1M',
              selected: value == DateRangeFilter.month,
              onTap: () => onChanged(DateRangeFilter.month),
            ),
            const SizedBox(width: 8),
            _PillChip(
              label: '1Y',
              selected: value == DateRangeFilter.year,
              onTap: () => onChanged(DateRangeFilter.year),
            ),
            const SizedBox(width: 8),
            _YearChip(
              year: yearForChip,
              selected: selectedYear != null,
              years: years,
              onPick: (y) => onChanged(DateRangeFilter.calendarYear(y)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.year,
    required this.selected,
    required this.years,
    required this.onPick,
  });
  final int year;
  final bool selected;
  final List<int> years;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Pick year',
      onSelected: onPick,
      itemBuilder: (_) => [
        for (final y in years)
          PopupMenuItem<int>(
            value: y,
            child: Row(
              children: [
                if (y == year && selected)
                  const Icon(Icons.check, size: 16, color: AppColors.green)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text('$y'),
              ],
            ),
          ),
      ],
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: selected ? context.ink : Colors.transparent,
          border: Border.all(
              color: selected ? context.ink : context.hairline),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: AppTextStyles.caption.copyWith(
                  color: selected ? context.surface : context.ink,
                  fontWeight: FontWeight.w600),
              child: Text('$year'),
            ),
            Icon(Icons.arrow_drop_down,
                size: 20,
                color: selected ? context.surface : context.ink),
          ],
        ),
      ),
    );
  }
}
