import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_range.dart';
import 'database.dart';

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
  const RecordsQuery({required this.type, required this.range});

  @override
  bool operator ==(Object other) =>
      other is RecordsQuery && other.type == type && other.range == range;

  @override
  int get hashCode => Object.hash(type, range);
}

final filteredRecordsProvider =
    StreamProvider.family<List<RecordRow>, RecordsQuery>((ref, q) {
  final r = q.range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        typesIn: q.type.types,
        from: r.start,
        to: r.end,
      );
});

final outstandingLoansProvider =
    StreamProvider.family<List<RecordRow>, DateRangeFilter>((ref, range) {
  final r = range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        type: RecordType.loanGiven,
        loanReturned: false,
        from: r.start,
        to: r.end,
      );
});

final returnedLoansProvider =
    StreamProvider.family<List<RecordRow>, DateRangeFilter>((ref, range) {
  final r = range.resolve(DateTime.now());
  return ref.watch(databaseProvider).watchRecords(
        type: RecordType.loanGiven,
        loanReturned: true,
        from: r.start,
        to: r.end,
      );
});

final earliestRecordYearProvider = FutureProvider<int>((ref) async {
  final y = await ref.watch(databaseProvider).earliestRecordYear();
  return y ?? DateTime.now().year;
});
