import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

enum RecordType { expense, income, loanGiven }

@DataClassName('RecordRow')
class Records extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  IntColumn get amountMinor => integer()();
  TextColumn get type => textEnum<RecordType>()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  TextColumn get counterparty => text().nullable()();
  DateTimeColumn get expectedReturnAt => dateTime().nullable()();
  BoolColumn get returned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get returnedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DashboardStats {
  final int incomeMinor;
  final int expenseMinor;
  final int outstandingLoanMinor;
  final int monthIncomeMinor;
  final int monthExpenseMinor;
  final int outstandingLoanCount;

  const DashboardStats({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.outstandingLoanMinor,
    required this.monthIncomeMinor,
    required this.monthExpenseMinor,
    required this.outstandingLoanCount,
  });

  int get availableBalance =>
      incomeMinor - expenseMinor - outstandingLoanMinor;

  static const empty = DashboardStats(
    incomeMinor: 0,
    expenseMinor: 0,
    outstandingLoanMinor: 0,
    monthIncomeMinor: 0,
    monthExpenseMinor: 0,
    outstandingLoanCount: 0,
  );
}

@DriftDatabase(tables: [Records])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 dev data: drop old tables and create new schema.
            await customStatement('DROP TABLE IF EXISTS transactions');
            await customStatement('DROP TABLE IF EXISTS categories');
            await m.createTable(records);
          }
        },
      );

  Stream<List<RecordRow>> watchRecords({
    RecordType? type,
    Set<RecordType>? typesIn,
    bool? loanReturned,
    int? limit,
  }) {
    final q = select(records);
    if (type != null) q.where((r) => r.type.equalsValue(type));
    if (typesIn != null && typesIn.isNotEmpty) {
      q.where((r) => r.type.isInValues(typesIn.toList()));
    }
    if (loanReturned != null) {
      q.where((r) => r.returned.equals(loanReturned));
    }
    q.orderBy([
      (r) => OrderingTerm.desc(r.occurredAt),
      (r) => OrderingTerm.desc(r.createdAt),
    ]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Future<void> upsertRecord(RecordsCompanion data) =>
      into(records).insertOnConflictUpdate(data);

  Future<int> deleteRecord(String id) =>
      (delete(records)..where((r) => r.id.equals(id))).go();

  Future<void> markLoanReturned(String id, {required bool returned}) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        returned: Value(returned),
        returnedAt: Value(returned ? DateTime.now() : null),
      ),
    );
  }

  Stream<DashboardStats> watchStats() {
    return select(records).watch().map((rows) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      int income = 0, expense = 0, outLoan = 0, outCount = 0;
      int monthInc = 0, monthExp = 0;
      for (final r in rows) {
        switch (r.type) {
          case RecordType.income:
            income += r.amountMinor;
            if (!r.occurredAt.isBefore(monthStart) &&
                r.occurredAt.isBefore(nextMonth)) {
              monthInc += r.amountMinor;
            }
            break;
          case RecordType.expense:
            expense += r.amountMinor;
            if (!r.occurredAt.isBefore(monthStart) &&
                r.occurredAt.isBefore(nextMonth)) {
              monthExp += r.amountMinor;
            }
            break;
          case RecordType.loanGiven:
            if (!r.returned) {
              outLoan += r.amountMinor;
              outCount += 1;
            }
            break;
        }
      }
      return DashboardStats(
        incomeMinor: income,
        expenseMinor: expense,
        outstandingLoanMinor: outLoan,
        monthIncomeMinor: monthInc,
        monthExpenseMinor: monthExp,
        outstandingLoanCount: outCount,
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'xpense.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
