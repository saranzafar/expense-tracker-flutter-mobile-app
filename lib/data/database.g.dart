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
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        returnedAt,
        categoryId
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
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
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
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
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
  final String? categoryId;
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
      this.returnedAt,
      this.categoryId});
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
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
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
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
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
      categoryId: serializer.fromJson<String?>(json['categoryId']),
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
      'categoryId': serializer.toJson<String?>(categoryId),
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
          Value<DateTime?> returnedAt = const Value.absent(),
          Value<String?> categoryId = const Value.absent()}) =>
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
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
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
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
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
          ..write('returnedAt: $returnedAt, ')
          ..write('categoryId: $categoryId')
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
      returnedAt,
      categoryId);
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
          other.returnedAt == this.returnedAt &&
          other.categoryId == this.categoryId);
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
  final Value<String?> categoryId;
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
    this.categoryId = const Value.absent(),
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
    this.categoryId = const Value.absent(),
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
    Expression<String>? categoryId,
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
      if (categoryId != null) 'category_id': categoryId,
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
      Value<String?>? categoryId,
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
      categoryId: categoryId ?? this.categoryId,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
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
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now());
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  const CategoryRow(
      {required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryRow copyWith({String? id, String? name, DateTime? createdAt}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects
    with TableInfo<$ProjectsTable, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalAmountMinorMeta =
      const VerificationMeta('totalAmountMinor');
  @override
  late final GeneratedColumn<int> totalAmountMinor = GeneratedColumn<int>(
      'total_amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now());
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        categoryId,
        totalAmountMinor,
        startDate,
        endDate,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('total_amount_minor')) {
      context.handle(
          _totalAmountMinorMeta,
          totalAmountMinor.isAcceptableOrUnknown(
              data['total_amount_minor']!, _totalAmountMinorMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMinorMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      totalAmountMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_amount_minor'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final int totalAmountMinor;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  const ProjectRow(
      {required this.id,
      required this.name,
      this.description,
      this.categoryId,
      required this.totalAmountMinor,
      required this.startDate,
      this.endDate,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['total_amount_minor'] = Variable<int>(totalAmountMinor);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      totalAmountMinor: Value(totalAmountMinor),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      createdAt: Value(createdAt),
    );
  }

  factory ProjectRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      totalAmountMinor: serializer.fromJson<int>(json['totalAmountMinor']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'categoryId': serializer.toJson<String?>(categoryId),
      'totalAmountMinor': serializer.toJson<int>(totalAmountMinor),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProjectRow copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          int? totalAmountMinor,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          DateTime? createdAt}) =>
      ProjectRow(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        totalAmountMinor: totalAmountMinor ?? this.totalAmountMinor,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        createdAt: createdAt ?? this.createdAt,
      );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      totalAmountMinor: data.totalAmountMinor.present
          ? data.totalAmountMinor.value
          : this.totalAmountMinor,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('totalAmountMinor: $totalAmountMinor, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, categoryId,
      totalAmountMinor, startDate, endDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.totalAmountMinor == this.totalAmountMinor &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> categoryId;
  final Value<int> totalAmountMinor;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.totalAmountMinor = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int totalAmountMinor,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        totalAmountMinor = Value(totalAmountMinor),
        startDate = Value(startDate);
  static Insertable<ProjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<int>? totalAmountMinor,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (totalAmountMinor != null) 'total_amount_minor': totalAmountMinor,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String?>? categoryId,
      Value<int>? totalAmountMinor,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      totalAmountMinor: totalAmountMinor ?? this.totalAmountMinor,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (totalAmountMinor.present) {
      map['total_amount_minor'] = Variable<int>(totalAmountMinor.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('totalAmountMinor: $totalAmountMinor, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectPaymentsTable extends ProjectPayments
    with TableInfo<$ProjectPaymentsTable, ProjectPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now());
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, amountMinor, note, paidAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_payments';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectPaymentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectPaymentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProjectPaymentsTable createAlias(String alias) {
    return $ProjectPaymentsTable(attachedDatabase, alias);
  }
}

class ProjectPaymentRow extends DataClass
    implements Insertable<ProjectPaymentRow> {
  final String id;
  final String projectId;
  final int amountMinor;
  final String? note;
  final DateTime paidAt;
  final DateTime createdAt;
  const ProjectPaymentRow(
      {required this.id,
      required this.projectId,
      required this.amountMinor,
      this.note,
      required this.paidAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['paid_at'] = Variable<DateTime>(paidAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectPaymentsCompanion toCompanion(bool nullToAbsent) {
    return ProjectPaymentsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      amountMinor: Value(amountMinor),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      paidAt: Value(paidAt),
      createdAt: Value(createdAt),
    );
  }

  factory ProjectPaymentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      note: serializer.fromJson<String?>(json['note']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'note': serializer.toJson<String?>(note),
      'paidAt': serializer.toJson<DateTime>(paidAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProjectPaymentRow copyWith(
          {String? id,
          String? projectId,
          int? amountMinor,
          Value<String?> note = const Value.absent(),
          DateTime? paidAt,
          DateTime? createdAt}) =>
      ProjectPaymentRow(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        amountMinor: amountMinor ?? this.amountMinor,
        note: note.present ? note.value : this.note,
        paidAt: paidAt ?? this.paidAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ProjectPaymentRow copyWithCompanion(ProjectPaymentsCompanion data) {
    return ProjectPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      note: data.note.present ? data.note.value : this.note,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectPaymentRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('note: $note, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, amountMinor, note, paidAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectPaymentRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.amountMinor == this.amountMinor &&
          other.note == this.note &&
          other.paidAt == this.paidAt &&
          other.createdAt == this.createdAt);
}

class ProjectPaymentsCompanion extends UpdateCompanion<ProjectPaymentRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<int> amountMinor;
  final Value<String?> note;
  final Value<DateTime> paidAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProjectPaymentsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.note = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required String projectId,
    required int amountMinor,
    this.note = const Value.absent(),
    required DateTime paidAt,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : projectId = Value(projectId),
        amountMinor = Value(amountMinor),
        paidAt = Value(paidAt);
  static Insertable<ProjectPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<int>? amountMinor,
    Expression<String>? note,
    Expression<DateTime>? paidAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (note != null) 'note': note,
      if (paidAt != null) 'paid_at': paidAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectPaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<int>? amountMinor,
      Value<String?>? note,
      Value<DateTime>? paidAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ProjectPaymentsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      amountMinor: amountMinor ?? this.amountMinor,
      note: note ?? this.note,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('note: $note, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ProjectPaymentsTable projectPayments =
      $ProjectPaymentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [records, categories, projects, projectPayments];
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
  Value<String?> categoryId,
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
  Value<String?> categoryId,
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

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);
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
            Value<String?> categoryId = const Value.absent(),
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
            categoryId: categoryId,
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
            Value<String?> categoryId = const Value.absent(),
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
            categoryId: categoryId,
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
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  required String name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()>;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  required String name,
  Value<String?> description,
  Value<String?> categoryId,
  required int totalAmountMinor,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String?> categoryId,
  Value<int> totalAmountMinor,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmountMinor => $composableBuilder(
      column: $table.totalAmountMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmountMinor => $composableBuilder(
      column: $table.totalAmountMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get totalAmountMinor => $composableBuilder(
      column: $table.totalAmountMinor, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    ProjectRow,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (ProjectRow, BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>),
    ProjectRow,
    PrefetchHooks Function()> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> totalAmountMinor = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            name: name,
            description: description,
            categoryId: categoryId,
            totalAmountMinor: totalAmountMinor,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            required int totalAmountMinor,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            name: name,
            description: description,
            categoryId: categoryId,
            totalAmountMinor: totalAmountMinor,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    ProjectRow,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (ProjectRow, BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>),
    ProjectRow,
    PrefetchHooks Function()>;
typedef $$ProjectPaymentsTableCreateCompanionBuilder = ProjectPaymentsCompanion
    Function({
  Value<String> id,
  required String projectId,
  required int amountMinor,
  Value<String?> note,
  required DateTime paidAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ProjectPaymentsTableUpdateCompanionBuilder = ProjectPaymentsCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<int> amountMinor,
  Value<String?> note,
  Value<DateTime> paidAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ProjectPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectPaymentsTable> {
  $$ProjectPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ProjectPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectPaymentsTable> {
  $$ProjectPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectPaymentsTable> {
  $$ProjectPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProjectPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectPaymentsTable,
    ProjectPaymentRow,
    $$ProjectPaymentsTableFilterComposer,
    $$ProjectPaymentsTableOrderingComposer,
    $$ProjectPaymentsTableAnnotationComposer,
    $$ProjectPaymentsTableCreateCompanionBuilder,
    $$ProjectPaymentsTableUpdateCompanionBuilder,
    (
      ProjectPaymentRow,
      BaseReferences<_$AppDatabase, $ProjectPaymentsTable, ProjectPaymentRow>
    ),
    ProjectPaymentRow,
    PrefetchHooks Function()> {
  $$ProjectPaymentsTableTableManager(
      _$AppDatabase db, $ProjectPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectPaymentsCompanion(
            id: id,
            projectId: projectId,
            amountMinor: amountMinor,
            note: note,
            paidAt: paidAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String projectId,
            required int amountMinor,
            Value<String?> note = const Value.absent(),
            required DateTime paidAt,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectPaymentsCompanion.insert(
            id: id,
            projectId: projectId,
            amountMinor: amountMinor,
            note: note,
            paidAt: paidAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjectPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectPaymentsTable,
    ProjectPaymentRow,
    $$ProjectPaymentsTableFilterComposer,
    $$ProjectPaymentsTableOrderingComposer,
    $$ProjectPaymentsTableAnnotationComposer,
    $$ProjectPaymentsTableCreateCompanionBuilder,
    $$ProjectPaymentsTableUpdateCompanionBuilder,
    (
      ProjectPaymentRow,
      BaseReferences<_$AppDatabase, $ProjectPaymentsTable, ProjectPaymentRow>
    ),
    ProjectPaymentRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ProjectPaymentsTableTableManager get projectPayments =>
      $$ProjectPaymentsTableTableManager(_db, _db.projectPayments);
}
