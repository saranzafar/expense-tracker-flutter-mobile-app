import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/chart_data.dart';
import '../core/date_range.dart';
import 'database.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) =>
    Connectivity().onConnectivityChanged);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

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

final outstandingLoansProvider =
    StreamProvider.family<List<RecordRow>, DateRangeFilter>((ref, range) {
  final r = range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        typesIn: {RecordType.loanGiven, RecordType.loanTaken},
        loanReturned: false,
        from: r.start,
        to: r.end,
      );
});

final returnedLoansProvider =
    StreamProvider.family<List<RecordRow>, DateRangeFilter>((ref, range) {
  final r = range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        typesIn: {RecordType.loanGiven, RecordType.loanTaken},
        loanReturned: true,
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
