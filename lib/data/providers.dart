import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/chart_data.dart';
import '../core/date_range.dart';
import 'database.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) =>
    Connectivity().onConnectivityChanged);

/// App version name (from the native build / pubspec), e.g. "1.0.2".
/// Read at runtime so it never goes stale on a version bump.
final appVersionProvider = FutureProvider<String>((_) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Fires whenever any table changes — used to debounce automatic backups.
final dataChangeProvider = StreamProvider<void>(
    (ref) => ref.watch(databaseProvider).watchAnyChange());

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  return ref.watch(databaseProvider).watchStats();
});

final recentRecordsProvider = StreamProvider<List<RecordRow>>((ref) {
  return ref.watch(databaseProvider).watchRecords(limit: 8);
});

class RecordsFilter {
  final Set<RecordType> types;
  const RecordsFilter(this.types);

  static const all =
      RecordsFilter({RecordType.income, RecordType.expense});
  static const incomeOnly = RecordsFilter({RecordType.income});
  static const expenseOnly = RecordsFilter({RecordType.expense});

  @override
  bool operator ==(Object other) =>
      other is RecordsFilter &&
      other.types.length == types.length &&
      other.types.containsAll(types);

  @override
  int get hashCode => Object.hashAll(types);
}

class RecordsQuery {
  final RecordsFilter type;
  final DateRangeFilter range;
  final String? categoryId;
  final int limit;
  const RecordsQuery({
    required this.type,
    required this.range,
    this.categoryId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      other is RecordsQuery &&
      other.type == type &&
      other.range == range &&
      other.categoryId == categoryId &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(type, range, categoryId, limit);
}

final filteredRecordsProvider =
    StreamProvider.family<List<RecordRow>, RecordsQuery>((ref, q) {
  final r = q.range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        typesIn: q.type.types,
        from: r.start,
        to: r.end,
        categoryId: q.categoryId,
        limit: q.limit,
      );
});

/// Loan direction filter for the Loans screen.
enum LoanTypeFilter { all, lent, borrowed }

extension LoanTypeFilterX on LoanTypeFilter {
  Set<RecordType> get types => switch (this) {
        LoanTypeFilter.all =>
          const {RecordType.loanGiven, RecordType.loanTaken},
        LoanTypeFilter.lent => const {RecordType.loanGiven},
        LoanTypeFilter.borrowed => const {RecordType.loanTaken},
      };
}

/// Query for the Loans list — a tab (returned vs outstanding) plus the shared
/// type / category / date-range filters.
class LoansQuery {
  final bool returned;
  final LoanTypeFilter type;
  final String? categoryId;
  final DateRangeFilter range;
  const LoansQuery({
    required this.returned,
    required this.type,
    required this.range,
    this.categoryId,
  });

  @override
  bool operator ==(Object other) =>
      other is LoansQuery &&
      other.returned == returned &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.range == range;

  @override
  int get hashCode => Object.hash(returned, type, categoryId, range);
}

final loansProvider =
    StreamProvider.family<List<RecordRow>, LoansQuery>((ref, q) {
  final r = q.range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        typesIn: q.type.types,
        loanReturned: q.returned,
        categoryId: q.categoryId,
        from: r.start,
        to: r.end,
      );
});

final earliestRecordYearProvider = FutureProvider<int>((ref) async {
  final y = await ref.watch(databaseProvider).earliestRecordYear();
  return y ?? DateTime.now().year;
});

final categoriesProvider = StreamProvider<List<CategoryRow>>((ref) =>
    ref.watch(databaseProvider).watchCategories());

final projectsProvider = StreamProvider<List<ProjectRow>>(
    (ref) => ref.watch(databaseProvider).watchProjects());

final projectPaymentsProvider =
    StreamProvider.family<List<ProjectPaymentRow>, String>(
  (ref, projectId) =>
      ref.watch(databaseProvider).watchProjectPayments(projectId),
);

/// projectId → total payments received (minor units). Feeds the Projects board.
final receivedByProjectProvider = StreamProvider<Map<String, int>>(
    (ref) => ref.watch(databaseProvider).watchReceivedByProject());

final chartDataProvider =
    StreamProvider.family<List<ChartPoint>, ChartPeriod>((ref, period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final from = switch (period) {
    ChartPeriod.week => today.subtract(const Duration(days: 6)),
    ChartPeriod.month => today.subtract(const Duration(days: 29)),
    ChartPeriod.year => DateTime(now.year, 1, 1),
  };
  return ref
      .watch(databaseProvider)
      .watchRecords(
        typesIn: {RecordType.income, RecordType.expense},
        from: from,
        to: now,
      )
      .map((rows) => _aggregateChartPoints(rows, period, from, now));
});

// ── Per-filter totals (income + expense sum, no row limit) ────────────────────

class RecordsTotals {
  final int incomeMinor;
  final int expenseMinor;
  const RecordsTotals({required this.incomeMinor, required this.expenseMinor});
  int get netMinor => incomeMinor - expenseMinor;
  static const zero = RecordsTotals(incomeMinor: 0, expenseMinor: 0);
}

/// Like RecordsQuery but without `limit` — used for accurate totals.
class RecordsTotalsQuery {
  final RecordsFilter type;
  final DateRangeFilter range;
  final String? categoryId;
  const RecordsTotalsQuery(
      {required this.type, required this.range, this.categoryId});

  @override
  bool operator ==(Object other) =>
      other is RecordsTotalsQuery &&
      other.type == type &&
      other.range == range &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(type, range, categoryId);
}

final filteredTotalsProvider =
    StreamProvider.family<RecordsTotals, RecordsTotalsQuery>((ref, q) {
  final r = q.range.resolve(DateTime.now());
  return ref
      .watch(databaseProvider)
      .watchRecords(
        typesIn: q.type.types,
        from: r.start,
        to: r.end,
        categoryId: q.categoryId,
        // no limit — we need totals across all matching records
      )
      .map((rows) {
    int income = 0, expense = 0;
    for (final row in rows) {
      if (row.type == RecordType.income) income += row.amountMinor;
      if (row.type == RecordType.expense) expense += row.amountMinor;
    }
    return RecordsTotals(incomeMinor: income, expenseMinor: expense);
  });
});

// ── Custom-range chart data ────────────────────────────────────────────────────

class ChartDateRange {
  final DateTime from;
  final DateTime to;
  const ChartDateRange({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      other is ChartDateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

final customChartDataProvider =
    StreamProvider.family<List<ChartPoint>, ChartDateRange>((ref, range) {
  return ref
      .watch(databaseProvider)
      .watchRecords(
        typesIn: {RecordType.income, RecordType.expense},
        from: range.from,
        to: range.to,
      )
      .map((rows) => _aggregateCustomChartPoints(rows, range.from, range.to));
});

List<ChartPoint> _aggregateCustomChartPoints(
    List<RecordRow> rows, DateTime from, DateTime to) {
  final days = to.difference(from).inDays;
  final useMonthly = days > 90;
  final Map<DateTime, (double inc, double exp)> buckets = {};

  if (useMonthly) {
    var cursor = DateTime(from.year, from.month, 1);
    final lastMonth = DateTime(to.year, to.month, 1);
    while (!cursor.isAfter(lastMonth)) {
      buckets[cursor] = (0, 0);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  } else {
    for (var i = 0; i <= days; i++) {
      final d = from.add(Duration(days: i));
      buckets[DateTime(d.year, d.month, d.day)] = (0, 0);
    }
  }

  for (final r in rows) {
    final DateTime key = useMonthly
        ? DateTime(r.occurredAt.year, r.occurredAt.month, 1)
        : DateTime(
            r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
    if (!buckets.containsKey(key)) continue;
    final (inc, exp) = buckets[key]!;
    buckets[key] = r.type == RecordType.income
        ? (inc + r.amountMinor.toDouble(), exp)
        : (inc, exp + r.amountMinor.toDouble());
  }

  final sorted = buckets.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return sorted
      .map((e) => ChartPoint(
          date: e.key, income: e.value.$1, expense: e.value.$2))
      .toList();
}

List<ChartPoint> _aggregateChartPoints(
  List<RecordRow> rows,
  ChartPeriod period,
  DateTime from,
  DateTime now,
) {
  // Build bucket map
  final Map<DateTime, (double inc, double exp)> buckets = {};

  if (period == ChartPeriod.year) {
    // One bucket per month Jan–current month
    for (var m = 1; m <= now.month; m++) {
      buckets[DateTime(now.year, m, 1)] = (0, 0);
    }
  } else {
    final days = period == ChartPeriod.week ? 7 : 30;
    for (var i = 0; i < days; i++) {
      final d = from.add(Duration(days: i));
      buckets[DateTime(d.year, d.month, d.day)] = (0, 0);
    }
  }

  for (final r in rows) {
    final DateTime key;
    if (period == ChartPeriod.year) {
      key = DateTime(r.occurredAt.year, r.occurredAt.month, 1);
    } else {
      key = DateTime(
          r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
    }
    if (!buckets.containsKey(key)) continue;
    final (inc, exp) = buckets[key]!;
    if (r.type == RecordType.income) {
      buckets[key] = (inc + r.amountMinor.toDouble(), exp);
    } else {
      buckets[key] = (inc, exp + r.amountMinor.toDouble());
    }
  }

  final sorted = buckets.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return sorted
      .map((e) => ChartPoint(
            date: e.key,
            income: e.value.$1,
            expense: e.value.$2,
          ))
      .toList();
}
