import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

enum RecordType { expense, income, loanGiven, loanTaken }

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

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
  TextColumn get categoryId => text().nullable()();

  /// When set, this income record is the money side of a project payment
  /// (see [ProjectPayments]). Used to keep the two in sync on edit/delete.
  TextColumn get projectPaymentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DashboardStats {
  final int incomeMinor;
  final int expenseMinor;
  final int outstandingLoanMinor;
  final int outstandingBorrowedMinor;
  final int monthIncomeMinor;
  final int monthExpenseMinor;
  final int outstandingLoanCount;
  final int outstandingBorrowedCount;

  const DashboardStats({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.outstandingLoanMinor,
    required this.outstandingBorrowedMinor,
    required this.monthIncomeMinor,
    required this.monthExpenseMinor,
    required this.outstandingLoanCount,
    required this.outstandingBorrowedCount,
  });

  int get availableBalance =>
      incomeMinor - expenseMinor - outstandingLoanMinor - outstandingBorrowedMinor;

  static const empty = DashboardStats(
    incomeMinor: 0,
    expenseMinor: 0,
    outstandingLoanMinor: 0,
    outstandingBorrowedMinor: 0,
    monthIncomeMinor: 0,
    monthExpenseMinor: 0,
    outstandingLoanCount: 0,
    outstandingBorrowedCount: 0,
  );
}

@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get totalAmountMinor => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectPaymentRow')
class ProjectPayments extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get projectId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Records, Categories, Projects, ProjectPayments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 5;

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
          if (from < 3) {
            await m.addColumn(records, records.categoryId);
            await m.createTable(categories);
          }
          if (from < 4) {
            await m.createTable(projects);
            await m.createTable(projectPayments);
          }
          if (from < 5) {
            await m.addColumn(records, records.projectPaymentId);
            // Backfill: every existing project payment becomes an income
            // record so older projects also count toward the balance.
            final pays = await select(projectPayments).get();
            for (final pay in pays) {
              final proj = await (select(projects)
                    ..where((p) => p.id.equals(pay.projectId)))
                  .getSingleOrNull();
              await into(records).insert(
                _projectIncomeCompanion(
                  projectName: proj?.name ?? 'Project',
                  projectCategoryId: proj?.categoryId,
                  amountMinor: pay.amountMinor,
                  note: pay.note,
                  paidAt: pay.paidAt,
                  paymentId: pay.id,
                ),
              );
            }
          }
        },
      );

  // --- Backup helpers ---
  /// Run a checkpointed snapshot of the DB into [destPath] via VACUUM INTO.
  /// Produces a consistent, app-stable copy without closing connections.
  Future<void> snapshotTo(String destPath) async {
    await customStatement("VACUUM INTO ?", [destPath]);
  }

  Future<int> countRecords() async {
    final row = await customSelect('SELECT COUNT(*) AS c FROM records')
        .getSingle();
    return row.read<int>('c');
  }

  Future<bool> isEmpty() async => (await countRecords()) == 0;

  Stream<List<RecordRow>> watchRecords({
    RecordType? type,
    Set<RecordType>? typesIn,
    bool? loanReturned,
    DateTime? from,
    DateTime? to,
    int? limit,
    String? categoryId,
  }) {
    final q = select(records);
    if (type != null) q.where((r) => r.type.equalsValue(type));
    if (typesIn != null && typesIn.isNotEmpty) {
      q.where((r) => r.type.isInValues(typesIn.toList()));
    }
    if (loanReturned != null) {
      q.where((r) => r.returned.equals(loanReturned));
    }
    if (from != null) {
      q.where((r) => r.occurredAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      q.where((r) => r.occurredAt.isSmallerOrEqualValue(to));
    }
    if (categoryId != null) {
      q.where((r) => r.categoryId.equals(categoryId));
    }
    q.orderBy([
      (r) => OrderingTerm.desc(r.occurredAt),
      (r) => OrderingTerm.desc(r.createdAt),
    ]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Future<int?> earliestRecordYear() async {
    final q = selectOnly(records)
      ..addColumns([records.occurredAt.min()])
      ..limit(1);
    final row = await q.getSingleOrNull();
    final v = row?.read(records.occurredAt.min());
    return v?.year;
  }

  Future<void> upsertRecord(RecordsCompanion data) =>
      into(records).insertOnConflictUpdate(data);

  Future<int> deleteRecord(String id) async {
    return transaction(() async {
      final row =
          await (select(records)..where((r) => r.id.equals(id))).getSingleOrNull();
      // If this record is the money side of a project payment, drop the
      // payment too so the project's "Paid" total stays consistent.
      final paymentId = row?.projectPaymentId;
      if (paymentId != null) {
        await (delete(projectPayments)..where((p) => p.id.equals(paymentId)))
            .go();
      }
      return (delete(records)..where((r) => r.id.equals(id))).go();
    });
  }

  /// Keep a project payment in sync when its linked income record is edited
  /// from the Records screen.
  Future<void> syncProjectPaymentFromRecord(
    String paymentId, {
    required int amountMinor,
    required DateTime paidAt,
  }) =>
      (update(projectPayments)..where((p) => p.id.equals(paymentId))).write(
        ProjectPaymentsCompanion(
          amountMinor: Value(amountMinor),
          paidAt: Value(paidAt),
        ),
      );

  Future<void> markLoanReturned(String id, {required bool returned}) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        returned: Value(returned),
        returnedAt: Value(returned ? DateTime.now() : null),
      ),
    );
  }

  Stream<List<CategoryRow>> watchCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  Future<CategoryRow> addCategory(String name) async {
    final id = _uuid.v4();
    await into(categories).insert(
      CategoriesCompanion.insert(id: Value(id), name: name),
    );
    return (select(categories)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<void> renameCategory(String id, String name) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(name: Value(name)));

  Future<void> deleteCategory(String id) async {
    // Null out references so existing records/projects don't become orphaned.
    await (update(records)..where((r) => r.categoryId.equals(id)))
        .write(const RecordsCompanion(categoryId: Value(null)));
    await (update(projects)..where((p) => p.categoryId.equals(id)))
        .write(const ProjectsCompanion(categoryId: Value(null)));
    await (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Stream<DashboardStats> watchStats() {
    return select(records).watch().map((rows) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      int income = 0, expense = 0, outLoan = 0, outCount = 0;
      int outBorrowed = 0, outBorrowedCount = 0;
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
          case RecordType.loanTaken:
            if (!r.returned) {
              outBorrowed += r.amountMinor;
              outBorrowedCount += 1;
            }
            break;
        }
      }
      return DashboardStats(
        incomeMinor: income,
        expenseMinor: expense,
        outstandingLoanMinor: outLoan,
        outstandingBorrowedMinor: outBorrowed,
        monthIncomeMinor: monthInc,
        monthExpenseMinor: monthExp,
        outstandingLoanCount: outCount,
        outstandingBorrowedCount: outBorrowedCount,
      );
    });
  }

  // ── Projects ────────────────────────────────────────────────────────────────

  Stream<List<ProjectRow>> watchProjects() =>
      (select(projects)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .watch();

  Future<void> upsertProject(ProjectsCompanion data) =>
      into(projects).insertOnConflictUpdate(data);

  Future<void> deleteProject(String id) async {
    await transaction(() async {
      final paymentIds = await (selectOnly(projectPayments)
            ..addColumns([projectPayments.id])
            ..where(projectPayments.projectId.equals(id)))
          .map((r) => r.read(projectPayments.id)!)
          .get();
      if (paymentIds.isNotEmpty) {
        await (delete(records)
              ..where((r) => r.projectPaymentId.isIn(paymentIds)))
            .go();
      }
      await (delete(projectPayments)..where((p) => p.projectId.equals(id)))
          .go();
      await (delete(projects)..where((p) => p.id.equals(id))).go();
    });
  }

  // ── Project Payments ─────────────────────────────────────────────────────────

  Stream<List<ProjectPaymentRow>> watchProjectPayments(String projectId) =>
      (select(projectPayments)
            ..where((p) => p.projectId.equals(projectId))
            ..orderBy([(p) => OrderingTerm.asc(p.paidAt)]))
          .watch();

  /// Records a project payment AND its matching income record (the money the
  /// project earned), atomically. The income record flows into the balance,
  /// charts, totals and recent activity automatically.
  Future<void> addProjectPayment({
    required String projectId,
    required String projectName,
    String? projectCategoryId,
    required int amountMinor,
    String? note,
    required DateTime paidAt,
  }) async {
    final paymentId = _uuid.v4();
    await transaction(() async {
      await into(projectPayments).insert(
        ProjectPaymentsCompanion.insert(
          id: Value(paymentId),
          projectId: projectId,
          amountMinor: amountMinor,
          note: Value(note),
          paidAt: paidAt,
        ),
      );
      await into(records).insert(
        _projectIncomeCompanion(
          projectName: projectName,
          projectCategoryId: projectCategoryId,
          amountMinor: amountMinor,
          note: note,
          paidAt: paidAt,
          paymentId: paymentId,
        ),
      );
    });
  }

  Future<void> deleteProjectPayment(String id) async {
    await transaction(() async {
      await (delete(records)..where((r) => r.projectPaymentId.equals(id))).go();
      await (delete(projectPayments)..where((p) => p.id.equals(id))).go();
    });
  }

  /// Builds the income [RecordsCompanion] that mirrors a project payment.
  static RecordsCompanion _projectIncomeCompanion({
    required String projectName,
    required String? projectCategoryId,
    required int amountMinor,
    required String? note,
    required DateTime paidAt,
    required String paymentId,
  }) {
    final trimmedNote = note?.trim();
    final desc = (trimmedNote != null && trimmedNote.isNotEmpty)
        ? 'Project: $projectName — $trimmedNote'
        : 'Project: $projectName';
    return RecordsCompanion.insert(
      amountMinor: amountMinor,
      type: RecordType.income,
      description: Value(desc),
      occurredAt: paidAt,
      categoryId: Value(projectCategoryId),
      projectPaymentId: Value(paymentId),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'xpense.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
