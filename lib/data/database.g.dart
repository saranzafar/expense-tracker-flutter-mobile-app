// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RecordsTable extends Records with TableInfo<$RecordsTable, RecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<RecordType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<RecordType>($RecordsTable.$convertertype);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now());
  static const VerificationMeta _counterpartyMeta =
      const VerificationMeta('counterparty');
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
      'counterparty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expectedReturnAtMeta =
      const VerificationMeta('expectedReturnAt');
  @override
  late final GeneratedColumn<DateTime> expectedReturnAt =
      GeneratedColumn<DateTime>('expected_return_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _returnedMeta =
      const VerificationMeta('returned');
  @override
  late final GeneratedColumn<bool> returned = GeneratedColumn<bool>(
      'returned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("returned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _returnedAtMeta =
      const VerificationMeta('returnedAt');
  @override
  late final GeneratedColumn<DateTime> returnedAt = GeneratedColumn<DateTime>(
      'returned_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        amountMinor,
        type,
        description,
        occurredAt,
        createdAt,
        counterparty,
        expectedReturnAt,
        returned,
        returnedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(Insertable<RecordRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('counterparty')) {
      context.handle(
          _counterpartyMeta,
          counterparty.isAcceptableOrUnknown(
              data['counterparty']!, _counterpartyMeta));
    }
    if (data.containsKey('expected_return_at')) {
      context.handle(
          _expectedReturnAtMeta,
          expectedReturnAt.isAcceptableOrUnknown(
              data['expected_return_at']!, _expectedReturnAtMeta));
    }
    if (data.containsKey('returned')) {
      context.handle(_returnedMeta,
          returned.isAcceptableOrUnknown(data['returned']!, _returnedMeta));
    }
    if (data.containsKey('returned_at')) {
      context.handle(
          _returnedAtMeta,
          returnedAt.isAcceptableOrUnknown(
              data['returned_at']!, _returnedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      type: $RecordsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      counterparty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counterparty']),
      expectedReturnAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}expected_return_at']),
      returned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}returned'])!,
      returnedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}returned_at']),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecordType, String, String> $convertertype =
      const EnumNameConverter<RecordType>(RecordType.values);
}

class RecordRow extends DataClass implements Insertable<RecordRow> {
  final String id;
  final int amountMinor;
  final RecordType type;
  final String? description;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String? counterparty;
  final DateTime? expectedReturnAt;
  final bool returned;
  final DateTime? returnedAt;
  const RecordRow(
      {required this.id,
      required this.amountMinor,
      required this.type,
      this.description,
      required this.occurredAt,
      required this.createdAt,
      this.counterparty,
      this.expectedReturnAt,
      required this.returned,
      this.returnedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount_minor'] = Variable<int>(amountMinor);
    {
      map['type'] = Variable<String>($RecordsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    if (!nullToAbsent || expectedReturnAt != null) {
      map['expected_return_at'] = Variable<DateTime>(expectedReturnAt);
    }
    map['returned'] = Variable<bool>(returned);
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<DateTime>(returnedAt);
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      expectedReturnAt: expectedReturnAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedReturnAt),
      returned: Value(returned),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
    );
  }

  factory RecordRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordRow(
      id: serializer.fromJson<String>(json['id']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      type: $RecordsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      description: serializer.fromJson<String?>(json['description']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      expectedReturnAt:
          serializer.fromJson<DateTime?>(json['expectedReturnAt']),
      returned: serializer.fromJson<bool>(json['returned']),
      returnedAt: serializer.fromJson<DateTime?>(json['returnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'type':
          serializer.toJson<String>($RecordsTable.$convertertype.toJson(type)),
      'description': serializer.toJson<String?>(description),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'counterparty': serializer.toJson<String?>(counterparty),
      'expectedReturnAt': serializer.toJson<DateTime?>(expectedReturnAt),
      'returned': serializer.toJson<bool>(returned),
      'returnedAt': serializer.toJson<DateTime?>(returnedAt),
    };
  }

  RecordRow copyWith(
          {String? id,
          int? amountMinor,
          RecordType? type,
          Value<String?> description = const Value.absent(),
          DateTime? occurredAt,
          DateTime? createdAt,
          Value<String?> counterparty = const Value.absent(),
          Value<DateTime?> expectedReturnAt = const Value.absent(),
          bool? returned,
          Value<DateTime?> returnedAt = const Value.absent()}) =>
      RecordRow(
        id: id ?? this.id,
        amountMinor: amountMinor ?? this.amountMinor,
        type: type ?? this.type,
        description: description.present ? description.value : this.description,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
        counterparty:
            counterparty.present ? counterparty.value : this.counterparty,
        expectedReturnAt: expectedReturnAt.present
            ? expectedReturnAt.value
            : this.expectedReturnAt,
        returned: returned ?? this.returned,
        returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
      );
  RecordRow copyWithCompanion(RecordsCompanion data) {
    return RecordRow(
      id: data.id.present ? data.id.value : this.id,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      type: data.type.present ? data.type.value : this.type,
      description:
          data.description.present ? data.description.value : this.description,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      expectedReturnAt: data.expectedReturnAt.present
          ? data.expectedReturnAt.value
          : this.expectedReturnAt,
      returned: data.returned.present ? data.returned.value : this.returned,
      returnedAt:
          data.returnedAt.present ? data.returnedAt.value : this.returnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordRow(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('counterparty: $counterparty, ')
          ..write('expectedReturnAt: $expectedReturnAt, ')
          ..write('returned: $returned, ')
          ..write('returnedAt: $returnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      amountMinor,
      type,
      description,
      occurredAt,
      createdAt,
      counterparty,
      expectedReturnAt,
      returned,
      returnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordRow &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.type == this.type &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.counterparty == this.counterparty &&
          other.expectedReturnAt == this.expectedReturnAt &&
          other.returned == this.returned &&
          other.returnedAt == this.returnedAt);
}

class RecordsCompanion extends UpdateCompanion<RecordRow> {
  final Value<String> id;
  final Value<int> amountMinor;
  final Value<RecordType> type;
  final Value<String?> description;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<String?> counterparty;
  final Value<DateTime?> expectedReturnAt;
  final Value<bool> returned;
  final Value<DateTime?> returnedAt;
  final Value<int> rowid;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.expectedReturnAt = const Value.absent(),
    this.returned = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.id = const Value.absent(),
    required int amountMinor,
    required RecordType type,
    this.description = const Value.absent(),
    required DateTime occurredAt,
    this.createdAt = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.expectedReturnAt = const Value.absent(),
    this.returned = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : amountMinor = Value(amountMinor),
        type = Value(type),
        occurredAt = Value(occurredAt);
  static Insertable<RecordRow> custom({
    Expression<String>? id,
    Expression<int>? amountMinor,
    Expression<String>? type,
    Expression<String>? description,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<String>? counterparty,
    Expression<DateTime>? expectedReturnAt,
    Expression<bool>? returned,
    Expression<DateTime>? returnedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (counterparty != null) 'counterparty': counterparty,
      if (expectedReturnAt != null) 'expected_return_at': expectedReturnAt,
      if (returned != null) 'returned': returned,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordsCompanion copyWith(
      {Value<String>? id,
      Value<int>? amountMinor,
      Value<RecordType>? type,
      Value<String?>? description,
      Value<DateTime>? occurredAt,
      Value<DateTime>? createdAt,
      Value<String?>? counterparty,
      Value<DateTime?>? expectedReturnAt,
      Value<bool>? returned,
      Value<DateTime?>? returnedAt,
      Value<int>? rowid}) {
    return RecordsCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      type: type ?? this.type,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      counterparty: counterparty ?? this.counterparty,
      expectedReturnAt: expectedReturnAt ?? this.expectedReturnAt,
      returned: returned ?? this.returned,
      returnedAt: returnedAt ?? this.returnedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($RecordsTable.$convertertype.toSql(type.value));
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (expectedReturnAt.present) {
      map['expected_return_at'] = Variable<DateTime>(expectedReturnAt.value);
    }
    if (returned.present) {
      map['returned'] = Variable<bool>(returned.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<DateTime>(returnedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('counterparty: $counterparty, ')
          ..write('expectedReturnAt: $expectedReturnAt, ')
          ..write('returned: $returned, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecordsTable records = $RecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [records];
}

typedef $$RecordsTableCreateCompanionBuilder = RecordsCompanion Function({
  Value<String> id,
  required int amountMinor,
  required RecordType type,
  Value<String?> description,
  required DateTime occurredAt,
  Value<DateTime> createdAt,
  Value<String?> counterparty,
  Value<DateTime?> expectedReturnAt,
  Value<bool> returned,
  Value<DateTime?> returnedAt,
  Value<int> rowid,
});
typedef $$RecordsTableUpdateCompanionBuilder = RecordsCompanion Function({
  Value<String> id,
  Value<int> amountMinor,
  Value<RecordType> type,
  Value<String?> description,
  Value<DateTime> occurredAt,
  Value<DateTime> createdAt,
  Value<String?> counterparty,
  Value<DateTime?> expectedReturnAt,
  Value<bool> returned,
  Value<DateTime?> returnedAt,
  Value<int> rowid,
});

class $$RecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RecordType, RecordType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterparty => $composableBuilder(
      column: $table.counterparty, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expectedReturnAt => $composableBuilder(
      column: $table.expectedReturnAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get returned => $composableBuilder(
      column: $table.returned, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get returnedAt => $composableBuilder(
      column: $table.returnedAt, builder: (column) => ColumnFilters(column));
}

class $$RecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterparty => $composableBuilder(
      column: $table.counterparty,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expectedReturnAt => $composableBuilder(
      column: $table.expectedReturnAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get returned => $composableBuilder(
      column: $table.returned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get returnedAt => $composableBuilder(
      column: $table.returnedAt, builder: (column) => ColumnOrderings(column));
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecordType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
      column: $table.counterparty, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedReturnAt => $composableBuilder(
      column: $table.expectedReturnAt, builder: (column) => column);

  GeneratedColumn<bool> get returned =>
      $composableBuilder(column: $table.returned, builder: (column) => column);

  GeneratedColumn<DateTime> get returnedAt => $composableBuilder(
      column: $table.returnedAt, builder: (column) => column);
}

class $$RecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecordsTable,
    RecordRow,
    $$RecordsTableFilterComposer,
    $$RecordsTableOrderingComposer,
    $$RecordsTableAnnotationComposer,
    $$RecordsTableCreateCompanionBuilder,
    $$RecordsTableUpdateCompanionBuilder,
    (RecordRow, BaseReferences<_$AppDatabase, $RecordsTable, RecordRow>),
    RecordRow,
    PrefetchHooks Function()> {
  $$RecordsTableTableManager(_$AppDatabase db, $RecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<RecordType> type = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> counterparty = const Value.absent(),
            Value<DateTime?> expectedReturnAt = const Value.absent(),
            Value<bool> returned = const Value.absent(),
            Value<DateTime?> returnedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecordsCompanion(
            id: id,
            amountMinor: amountMinor,
            type: type,
            description: description,
            occurredAt: occurredAt,
            createdAt: createdAt,
            counterparty: counterparty,
            expectedReturnAt: expectedReturnAt,
            returned: returned,
            returnedAt: returnedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required int amountMinor,
            required RecordType type,
            Value<String?> description = const Value.absent(),
            required DateTime occurredAt,
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> counterparty = const Value.absent(),
            Value<DateTime?> expectedReturnAt = const Value.absent(),
            Value<bool> returned = const Value.absent(),
            Value<DateTime?> returnedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecordsCompanion.insert(
            id: id,
            amountMinor: amountMinor,
            type: type,
            description: description,
            occurredAt: occurredAt,
            createdAt: createdAt,
            counterparty: counterparty,
            expectedReturnAt: expectedReturnAt,
            returned: returned,
            returnedAt: returnedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecordsTable,
    RecordRow,
    $$RecordsTableFilterComposer,
    $$RecordsTableOrderingComposer,
    $$RecordsTableAnnotationComposer,
    $$RecordsTableCreateCompanionBuilder,
    $$RecordsTableUpdateCompanionBuilder,
    (RecordRow, BaseReferences<_$AppDatabase, $RecordsTable, RecordRow>),
    RecordRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
}
