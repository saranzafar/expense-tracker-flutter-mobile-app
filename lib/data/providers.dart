import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      other is RecordsFilter && other.types.length == types.length &&
      other.types.containsAll(types);

  @override
  int get hashCode => Object.hashAll(types);
}

final filteredRecordsProvider =
    StreamProvider.family<List<RecordRow>, RecordsFilter>((ref, f) {
  return ref.watch(databaseProvider).watchRecords(typesIn: f.types);
});

final outstandingLoansProvider = StreamProvider<List<RecordRow>>((ref) {
  return ref.watch(databaseProvider).watchRecords(
      type: RecordType.loanGiven, loanReturned: false);
});

final returnedLoansProvider = StreamProvider<List<RecordRow>>((ref) {
  return ref.watch(databaseProvider).watchRecords(
      type: RecordType.loanGiven, loanReturned: true);
});
