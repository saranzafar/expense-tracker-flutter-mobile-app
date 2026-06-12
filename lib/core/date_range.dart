import 'package:flutter/material.dart' show DateTimeRange;

sealed class DateRangeFilter {
  const DateRangeFilter();
  DateTimeRange resolve(DateTime now);

  static const DateRangeFilter day = _Rolling.day();
  static const DateRangeFilter week = _Rolling(days: 7, label: '1W');
  static const DateRangeFilter month = _Rolling(days: 30, label: '1M');
  static const DateRangeFilter year = _Rolling(days: 365, label: '1Y');

  factory DateRangeFilter.calendarYear(int year) = _CalendarYear;
  factory DateRangeFilter.custom(DateTime start, DateTime end) = _Custom;

  String get label;
}

class _Rolling extends DateRangeFilter {
  final int days;
  @override
  final String label;
  final bool snapToToday;

  const _Rolling({required this.days, required this.label})
      : snapToToday = false;
  const _Rolling.day()
      : days = 1,
        label = '1D',
        snapToToday = true;

  @override
  DateTimeRange resolve(DateTime now) {
    final start = snapToToday
        ? DateTime(now.year, now.month, now.day)
        : now.subtract(Duration(days: days));
    return DateTimeRange(start: start, end: now);
  }

  @override
  bool operator ==(Object o) =>
      o is _Rolling &&
      o.days == days &&
      o.label == label &&
      o.snapToToday == snapToToday;

  @override
  int get hashCode => Object.hash(days, label, snapToToday);
}

class _CalendarYear extends DateRangeFilter {
  final int year;
  const _CalendarYear(this.year);

  @override
  String get label => '$year';

  @override
  DateTimeRange resolve(DateTime _) => DateTimeRange(
        start: DateTime(year, 1, 1),
        end: DateTime(year, 12, 31, 23, 59, 59, 999),
      );

  @override
  bool operator ==(Object o) => o is _CalendarYear && o.year == year;

  @override
  int get hashCode => year.hashCode;
}

class _Custom extends DateRangeFilter {
  final DateTime start;
  final DateTime end;
  const _Custom(this.start, this.end);

  @override
  String get label => 'Custom';

  @override
  DateTimeRange resolve(DateTime _) => DateTimeRange(start: start, end: end);

  @override
  bool operator ==(Object o) =>
      o is _Custom && o.start == start && o.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// True iff this filter is a specific calendar year (not a rolling window).
bool isCalendarYear(DateRangeFilter f) => f is _CalendarYear;
int? calendarYearOf(DateRangeFilter f) => f is _CalendarYear ? f.year : null;
bool isCustomRange(DateRangeFilter f) => f is _Custom;
