// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class AppMeta extends Table with TableInfo<AppMeta, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppMeta(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _installationIdMeta = const VerificationMeta(
    'installationId',
  );
  late final GeneratedColumn<String> installationId = GeneratedColumn<String>(
    'installation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastEnqueuedSeqMeta = const VerificationMeta(
    'lastEnqueuedSeq',
  );
  late final GeneratedColumn<int> lastEnqueuedSeq = GeneratedColumn<int>(
    'last_enqueued_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastAckedSeqMeta = const VerificationMeta(
    'lastAckedSeq',
  );
  late final GeneratedColumn<int> lastAckedSeq = GeneratedColumn<int>(
    'last_acked_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _syncEnabledMeta = const VerificationMeta(
    'syncEnabled',
  );
  late final GeneratedColumn<int> syncEnabled = GeneratedColumn<int>(
    'sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (sync_enabled IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _registrationAttemptedMeta =
      const VerificationMeta('registrationAttempted');
  late final GeneratedColumn<int> registrationAttempted = GeneratedColumn<int>(
    'registration_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (registration_attempted IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _deletionPendingMeta = const VerificationMeta(
    'deletionPending',
  );
  late final GeneratedColumn<int> deletionPending = GeneratedColumn<int>(
    'deletion_pending',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (deletion_pending IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastSyncErrorStatusMeta =
      const VerificationMeta('lastSyncErrorStatus');
  late final GeneratedColumn<int> lastSyncErrorStatus = GeneratedColumn<int>(
    'last_sync_error_status',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    installationId,
    lastEnqueuedSeq,
    lastAckedSeq,
    syncEnabled,
    registrationAttempted,
    deletionPending,
    lastSyncErrorStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('installation_id')) {
      context.handle(
        _installationIdMeta,
        installationId.isAcceptableOrUnknown(
          data['installation_id']!,
          _installationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installationIdMeta);
    }
    if (data.containsKey('last_enqueued_seq')) {
      context.handle(
        _lastEnqueuedSeqMeta,
        lastEnqueuedSeq.isAcceptableOrUnknown(
          data['last_enqueued_seq']!,
          _lastEnqueuedSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_acked_seq')) {
      context.handle(
        _lastAckedSeqMeta,
        lastAckedSeq.isAcceptableOrUnknown(
          data['last_acked_seq']!,
          _lastAckedSeqMeta,
        ),
      );
    }
    if (data.containsKey('sync_enabled')) {
      context.handle(
        _syncEnabledMeta,
        syncEnabled.isAcceptableOrUnknown(
          data['sync_enabled']!,
          _syncEnabledMeta,
        ),
      );
    }
    if (data.containsKey('registration_attempted')) {
      context.handle(
        _registrationAttemptedMeta,
        registrationAttempted.isAcceptableOrUnknown(
          data['registration_attempted']!,
          _registrationAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('deletion_pending')) {
      context.handle(
        _deletionPendingMeta,
        deletionPending.isAcceptableOrUnknown(
          data['deletion_pending']!,
          _deletionPendingMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error_status')) {
      context.handle(
        _lastSyncErrorStatusMeta,
        lastSyncErrorStatus.isAcceptableOrUnknown(
          data['last_sync_error_status']!,
          _lastSyncErrorStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      installationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installation_id'],
      )!,
      lastEnqueuedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_enqueued_seq'],
      )!,
      lastAckedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_acked_seq'],
      )!,
      syncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_enabled'],
      )!,
      registrationAttempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}registration_attempted'],
      )!,
      deletionPending: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deletion_pending'],
      )!,
      lastSyncErrorStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_error_status'],
      ),
    );
  }

  @override
  AppMeta createAlias(String alias) {
    return AppMeta(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(last_acked_seq >= 0 AND last_enqueued_seq >= last_acked_seq)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final int id;
  final String installationId;
  final int lastEnqueuedSeq;
  final int lastAckedSeq;
  final int syncEnabled;
  final int registrationAttempted;
  final int deletionPending;
  final int? lastSyncErrorStatus;
  const AppMetaData({
    required this.id,
    required this.installationId,
    required this.lastEnqueuedSeq,
    required this.lastAckedSeq,
    required this.syncEnabled,
    required this.registrationAttempted,
    required this.deletionPending,
    this.lastSyncErrorStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['installation_id'] = Variable<String>(installationId);
    map['last_enqueued_seq'] = Variable<int>(lastEnqueuedSeq);
    map['last_acked_seq'] = Variable<int>(lastAckedSeq);
    map['sync_enabled'] = Variable<int>(syncEnabled);
    map['registration_attempted'] = Variable<int>(registrationAttempted);
    map['deletion_pending'] = Variable<int>(deletionPending);
    if (!nullToAbsent || lastSyncErrorStatus != null) {
      map['last_sync_error_status'] = Variable<int>(lastSyncErrorStatus);
    }
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      id: Value(id),
      installationId: Value(installationId),
      lastEnqueuedSeq: Value(lastEnqueuedSeq),
      lastAckedSeq: Value(lastAckedSeq),
      syncEnabled: Value(syncEnabled),
      registrationAttempted: Value(registrationAttempted),
      deletionPending: Value(deletionPending),
      lastSyncErrorStatus: lastSyncErrorStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncErrorStatus),
    );
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      id: serializer.fromJson<int>(json['id']),
      installationId: serializer.fromJson<String>(json['installation_id']),
      lastEnqueuedSeq: serializer.fromJson<int>(json['last_enqueued_seq']),
      lastAckedSeq: serializer.fromJson<int>(json['last_acked_seq']),
      syncEnabled: serializer.fromJson<int>(json['sync_enabled']),
      registrationAttempted: serializer.fromJson<int>(
        json['registration_attempted'],
      ),
      deletionPending: serializer.fromJson<int>(json['deletion_pending']),
      lastSyncErrorStatus: serializer.fromJson<int?>(
        json['last_sync_error_status'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'installation_id': serializer.toJson<String>(installationId),
      'last_enqueued_seq': serializer.toJson<int>(lastEnqueuedSeq),
      'last_acked_seq': serializer.toJson<int>(lastAckedSeq),
      'sync_enabled': serializer.toJson<int>(syncEnabled),
      'registration_attempted': serializer.toJson<int>(registrationAttempted),
      'deletion_pending': serializer.toJson<int>(deletionPending),
      'last_sync_error_status': serializer.toJson<int?>(lastSyncErrorStatus),
    };
  }

  AppMetaData copyWith({
    int? id,
    String? installationId,
    int? lastEnqueuedSeq,
    int? lastAckedSeq,
    int? syncEnabled,
    int? registrationAttempted,
    int? deletionPending,
    Value<int?> lastSyncErrorStatus = const Value.absent(),
  }) => AppMetaData(
    id: id ?? this.id,
    installationId: installationId ?? this.installationId,
    lastEnqueuedSeq: lastEnqueuedSeq ?? this.lastEnqueuedSeq,
    lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    registrationAttempted: registrationAttempted ?? this.registrationAttempted,
    deletionPending: deletionPending ?? this.deletionPending,
    lastSyncErrorStatus: lastSyncErrorStatus.present
        ? lastSyncErrorStatus.value
        : this.lastSyncErrorStatus,
  );
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      id: data.id.present ? data.id.value : this.id,
      installationId: data.installationId.present
          ? data.installationId.value
          : this.installationId,
      lastEnqueuedSeq: data.lastEnqueuedSeq.present
          ? data.lastEnqueuedSeq.value
          : this.lastEnqueuedSeq,
      lastAckedSeq: data.lastAckedSeq.present
          ? data.lastAckedSeq.value
          : this.lastAckedSeq,
      syncEnabled: data.syncEnabled.present
          ? data.syncEnabled.value
          : this.syncEnabled,
      registrationAttempted: data.registrationAttempted.present
          ? data.registrationAttempted.value
          : this.registrationAttempted,
      deletionPending: data.deletionPending.present
          ? data.deletionPending.value
          : this.deletionPending,
      lastSyncErrorStatus: data.lastSyncErrorStatus.present
          ? data.lastSyncErrorStatus.value
          : this.lastSyncErrorStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('id: $id, ')
          ..write('installationId: $installationId, ')
          ..write('lastEnqueuedSeq: $lastEnqueuedSeq, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('registrationAttempted: $registrationAttempted, ')
          ..write('deletionPending: $deletionPending, ')
          ..write('lastSyncErrorStatus: $lastSyncErrorStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    installationId,
    lastEnqueuedSeq,
    lastAckedSeq,
    syncEnabled,
    registrationAttempted,
    deletionPending,
    lastSyncErrorStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.id == this.id &&
          other.installationId == this.installationId &&
          other.lastEnqueuedSeq == this.lastEnqueuedSeq &&
          other.lastAckedSeq == this.lastAckedSeq &&
          other.syncEnabled == this.syncEnabled &&
          other.registrationAttempted == this.registrationAttempted &&
          other.deletionPending == this.deletionPending &&
          other.lastSyncErrorStatus == this.lastSyncErrorStatus);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<int> id;
  final Value<String> installationId;
  final Value<int> lastEnqueuedSeq;
  final Value<int> lastAckedSeq;
  final Value<int> syncEnabled;
  final Value<int> registrationAttempted;
  final Value<int> deletionPending;
  final Value<int?> lastSyncErrorStatus;
  const AppMetaCompanion({
    this.id = const Value.absent(),
    this.installationId = const Value.absent(),
    this.lastEnqueuedSeq = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.registrationAttempted = const Value.absent(),
    this.deletionPending = const Value.absent(),
    this.lastSyncErrorStatus = const Value.absent(),
  });
  AppMetaCompanion.insert({
    this.id = const Value.absent(),
    required String installationId,
    this.lastEnqueuedSeq = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.registrationAttempted = const Value.absent(),
    this.deletionPending = const Value.absent(),
    this.lastSyncErrorStatus = const Value.absent(),
  }) : installationId = Value(installationId);
  static Insertable<AppMetaData> custom({
    Expression<int>? id,
    Expression<String>? installationId,
    Expression<int>? lastEnqueuedSeq,
    Expression<int>? lastAckedSeq,
    Expression<int>? syncEnabled,
    Expression<int>? registrationAttempted,
    Expression<int>? deletionPending,
    Expression<int>? lastSyncErrorStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (installationId != null) 'installation_id': installationId,
      if (lastEnqueuedSeq != null) 'last_enqueued_seq': lastEnqueuedSeq,
      if (lastAckedSeq != null) 'last_acked_seq': lastAckedSeq,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
      if (registrationAttempted != null)
        'registration_attempted': registrationAttempted,
      if (deletionPending != null) 'deletion_pending': deletionPending,
      if (lastSyncErrorStatus != null)
        'last_sync_error_status': lastSyncErrorStatus,
    });
  }

  AppMetaCompanion copyWith({
    Value<int>? id,
    Value<String>? installationId,
    Value<int>? lastEnqueuedSeq,
    Value<int>? lastAckedSeq,
    Value<int>? syncEnabled,
    Value<int>? registrationAttempted,
    Value<int>? deletionPending,
    Value<int?>? lastSyncErrorStatus,
  }) {
    return AppMetaCompanion(
      id: id ?? this.id,
      installationId: installationId ?? this.installationId,
      lastEnqueuedSeq: lastEnqueuedSeq ?? this.lastEnqueuedSeq,
      lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      registrationAttempted:
          registrationAttempted ?? this.registrationAttempted,
      deletionPending: deletionPending ?? this.deletionPending,
      lastSyncErrorStatus: lastSyncErrorStatus ?? this.lastSyncErrorStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (installationId.present) {
      map['installation_id'] = Variable<String>(installationId.value);
    }
    if (lastEnqueuedSeq.present) {
      map['last_enqueued_seq'] = Variable<int>(lastEnqueuedSeq.value);
    }
    if (lastAckedSeq.present) {
      map['last_acked_seq'] = Variable<int>(lastAckedSeq.value);
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<int>(syncEnabled.value);
    }
    if (registrationAttempted.present) {
      map['registration_attempted'] = Variable<int>(
        registrationAttempted.value,
      );
    }
    if (deletionPending.present) {
      map['deletion_pending'] = Variable<int>(deletionPending.value);
    }
    if (lastSyncErrorStatus.present) {
      map['last_sync_error_status'] = Variable<int>(lastSyncErrorStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('id: $id, ')
          ..write('installationId: $installationId, ')
          ..write('lastEnqueuedSeq: $lastEnqueuedSeq, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('registrationAttempted: $registrationAttempted, ')
          ..write('deletionPending: $deletionPending, ')
          ..write('lastSyncErrorStatus: $lastSyncErrorStatus')
          ..write(')'))
        .toString();
  }
}

class Projects extends Table with TableInfo<Projects, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Projects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(name) BETWEEN 1 AND 40)',
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(unit) BETWEEN 1 AND 8)',
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _quickAmountMeta = const VerificationMeta(
    'quickAmount',
  );
  late final GeneratedColumn<int> quickAmount = GeneratedColumn<int>(
    'quick_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (typeof(quick_amount) = \'integer\' AND quick_amount BETWEEN 1 AND 9999)',
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (archived IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    unit,
    iconKey,
    quickAmount,
    archived,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('quick_amount')) {
      context.handle(
        _quickAmountMeta,
        quickAmount.isAcceptableOrUnknown(
          data['quick_amount']!,
          _quickAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quickAmountMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      quickAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quick_amount'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
    );
  }

  @override
  Projects createAlias(String alias) {
    return Projects(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Project extends DataClass implements Insertable<Project> {
  final String? id;
  final String name;
  final String unit;
  final String iconKey;
  final int quickAmount;
  final int archived;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  const Project({
    this.id,
    required this.name,
    required this.unit,
    required this.iconKey,
    required this.quickAmount,
    required this.archived,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['icon_key'] = Variable<String>(iconKey);
    map['quick_amount'] = Variable<int>(quickAmount);
    map['archived'] = Variable<int>(archived);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      unit: Value(unit),
      iconKey: Value(iconKey),
      quickAmount: Value(quickAmount),
      archived: Value(archived),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      iconKey: serializer.fromJson<String>(json['icon_key']),
      quickAmount: serializer.fromJson<int>(json['quick_amount']),
      archived: serializer.fromJson<int>(json['archived']),
      createdAtUtcMs: serializer.fromJson<int>(json['created_at_utc_ms']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updated_at_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'icon_key': serializer.toJson<String>(iconKey),
      'quick_amount': serializer.toJson<int>(quickAmount),
      'archived': serializer.toJson<int>(archived),
      'created_at_utc_ms': serializer.toJson<int>(createdAtUtcMs),
      'updated_at_utc_ms': serializer.toJson<int>(updatedAtUtcMs),
    };
  }

  Project copyWith({
    Value<String?> id = const Value.absent(),
    String? name,
    String? unit,
    String? iconKey,
    int? quickAmount,
    int? archived,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
  }) => Project(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    iconKey: iconKey ?? this.iconKey,
    quickAmount: quickAmount ?? this.quickAmount,
    archived: archived ?? this.archived,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      quickAmount: data.quickAmount.present
          ? data.quickAmount.value
          : this.quickAmount,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('iconKey: $iconKey, ')
          ..write('quickAmount: $quickAmount, ')
          ..write('archived: $archived, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    unit,
    iconKey,
    quickAmount,
    archived,
    createdAtUtcMs,
    updatedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.iconKey == this.iconKey &&
          other.quickAmount == this.quickAmount &&
          other.archived == this.archived &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String?> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<String> iconKey;
  final Value<int> quickAmount;
  final Value<int> archived;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.quickAmount = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String unit,
    required String iconKey,
    required int quickAmount,
    this.archived = const Value.absent(),
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       unit = Value(unit),
       iconKey = Value(iconKey),
       quickAmount = Value(quickAmount),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<String>? iconKey,
    Expression<int>? quickAmount,
    Expression<int>? archived,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (iconKey != null) 'icon_key': iconKey,
      if (quickAmount != null) 'quick_amount': quickAmount,
      if (archived != null) 'archived': archived,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String?>? id,
    Value<String>? name,
    Value<String>? unit,
    Value<String>? iconKey,
    Value<int>? quickAmount,
    Value<int>? archived,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      iconKey: iconKey ?? this.iconKey,
      quickAmount: quickAmount ?? this.quickAmount,
      archived: archived ?? this.archived,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
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
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (quickAmount.present) {
      map['quick_amount'] = Variable<int>(quickAmount.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
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
          ..write('unit: $unit, ')
          ..write('iconKey: $iconKey, ')
          ..write('quickAmount: $quickAmount, ')
          ..write('archived: $archived, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Entries extends Table with TableInfo<Entries, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Entries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES projects(id)',
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (typeof(amount) = \'integer\' AND amount BETWEEN 1 AND 999999)',
  );
  static const VerificationMeta _occurredAtUtcMsMeta = const VerificationMeta(
    'occurredAtUtcMs',
  );
  late final GeneratedColumn<int> occurredAtUtcMs = GeneratedColumn<int>(
    'occurred_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _utcOffsetMinutesMeta = const VerificationMeta(
    'utcOffsetMinutes',
  );
  late final GeneratedColumn<int> utcOffsetMinutes = GeneratedColumn<int>(
    'utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _voidedAtUtcMsMeta = const VerificationMeta(
    'voidedAtUtcMs',
  );
  late final GeneratedColumn<int> voidedAtUtcMs = GeneratedColumn<int>(
    'voided_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    amount,
    occurredAtUtcMs,
    utcOffsetMinutes,
    localDate,
    voidedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('occurred_at_utc_ms')) {
      context.handle(
        _occurredAtUtcMsMeta,
        occurredAtUtcMs.isAcceptableOrUnknown(
          data['occurred_at_utc_ms']!,
          _occurredAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMsMeta);
    }
    if (data.containsKey('utc_offset_minutes')) {
      context.handle(
        _utcOffsetMinutesMeta,
        utcOffsetMinutes.isAcceptableOrUnknown(
          data['utc_offset_minutes']!,
          _utcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utcOffsetMinutesMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('voided_at_utc_ms')) {
      context.handle(
        _voidedAtUtcMsMeta,
        voidedAtUtcMs.isAcceptableOrUnknown(
          data['voided_at_utc_ms']!,
          _voidedAtUtcMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      occurredAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_utc_ms'],
      )!,
      utcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_minutes'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      voidedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}voided_at_utc_ms'],
      ),
    );
  }

  @override
  Entries createAlias(String alias) {
    return Entries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Entry extends DataClass implements Insertable<Entry> {
  final String? id;
  final String projectId;
  final int amount;
  final int occurredAtUtcMs;
  final int utcOffsetMinutes;
  final String localDate;
  final int? voidedAtUtcMs;
  const Entry({
    this.id,
    required this.projectId,
    required this.amount,
    required this.occurredAtUtcMs,
    required this.utcOffsetMinutes,
    required this.localDate,
    this.voidedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['project_id'] = Variable<String>(projectId);
    map['amount'] = Variable<int>(amount);
    map['occurred_at_utc_ms'] = Variable<int>(occurredAtUtcMs);
    map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || voidedAtUtcMs != null) {
      map['voided_at_utc_ms'] = Variable<int>(voidedAtUtcMs);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      projectId: Value(projectId),
      amount: Value(amount),
      occurredAtUtcMs: Value(occurredAtUtcMs),
      utcOffsetMinutes: Value(utcOffsetMinutes),
      localDate: Value(localDate),
      voidedAtUtcMs: voidedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAtUtcMs),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String?>(json['id']),
      projectId: serializer.fromJson<String>(json['project_id']),
      amount: serializer.fromJson<int>(json['amount']),
      occurredAtUtcMs: serializer.fromJson<int>(json['occurred_at_utc_ms']),
      utcOffsetMinutes: serializer.fromJson<int>(json['utc_offset_minutes']),
      localDate: serializer.fromJson<String>(json['local_date']),
      voidedAtUtcMs: serializer.fromJson<int?>(json['voided_at_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'project_id': serializer.toJson<String>(projectId),
      'amount': serializer.toJson<int>(amount),
      'occurred_at_utc_ms': serializer.toJson<int>(occurredAtUtcMs),
      'utc_offset_minutes': serializer.toJson<int>(utcOffsetMinutes),
      'local_date': serializer.toJson<String>(localDate),
      'voided_at_utc_ms': serializer.toJson<int?>(voidedAtUtcMs),
    };
  }

  Entry copyWith({
    Value<String?> id = const Value.absent(),
    String? projectId,
    int? amount,
    int? occurredAtUtcMs,
    int? utcOffsetMinutes,
    String? localDate,
    Value<int?> voidedAtUtcMs = const Value.absent(),
  }) => Entry(
    id: id.present ? id.value : this.id,
    projectId: projectId ?? this.projectId,
    amount: amount ?? this.amount,
    occurredAtUtcMs: occurredAtUtcMs ?? this.occurredAtUtcMs,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    localDate: localDate ?? this.localDate,
    voidedAtUtcMs: voidedAtUtcMs.present
        ? voidedAtUtcMs.value
        : this.voidedAtUtcMs,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      amount: data.amount.present ? data.amount.value : this.amount,
      occurredAtUtcMs: data.occurredAtUtcMs.present
          ? data.occurredAtUtcMs.value
          : this.occurredAtUtcMs,
      utcOffsetMinutes: data.utcOffsetMinutes.present
          ? data.utcOffsetMinutes.value
          : this.utcOffsetMinutes,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      voidedAtUtcMs: data.voidedAtUtcMs.present
          ? data.voidedAtUtcMs.value
          : this.voidedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('amount: $amount, ')
          ..write('occurredAtUtcMs: $occurredAtUtcMs, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('localDate: $localDate, ')
          ..write('voidedAtUtcMs: $voidedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    amount,
    occurredAtUtcMs,
    utcOffsetMinutes,
    localDate,
    voidedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.amount == this.amount &&
          other.occurredAtUtcMs == this.occurredAtUtcMs &&
          other.utcOffsetMinutes == this.utcOffsetMinutes &&
          other.localDate == this.localDate &&
          other.voidedAtUtcMs == this.voidedAtUtcMs);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String?> id;
  final Value<String> projectId;
  final Value<int> amount;
  final Value<int> occurredAtUtcMs;
  final Value<int> utcOffsetMinutes;
  final Value<String> localDate;
  final Value<int?> voidedAtUtcMs;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.amount = const Value.absent(),
    this.occurredAtUtcMs = const Value.absent(),
    this.utcOffsetMinutes = const Value.absent(),
    this.localDate = const Value.absent(),
    this.voidedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required String projectId,
    required int amount,
    required int occurredAtUtcMs,
    required int utcOffsetMinutes,
    required String localDate,
    this.voidedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       amount = Value(amount),
       occurredAtUtcMs = Value(occurredAtUtcMs),
       utcOffsetMinutes = Value(utcOffsetMinutes),
       localDate = Value(localDate);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<int>? amount,
    Expression<int>? occurredAtUtcMs,
    Expression<int>? utcOffsetMinutes,
    Expression<String>? localDate,
    Expression<int>? voidedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (amount != null) 'amount': amount,
      if (occurredAtUtcMs != null) 'occurred_at_utc_ms': occurredAtUtcMs,
      if (utcOffsetMinutes != null) 'utc_offset_minutes': utcOffsetMinutes,
      if (localDate != null) 'local_date': localDate,
      if (voidedAtUtcMs != null) 'voided_at_utc_ms': voidedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String?>? id,
    Value<String>? projectId,
    Value<int>? amount,
    Value<int>? occurredAtUtcMs,
    Value<int>? utcOffsetMinutes,
    Value<String>? localDate,
    Value<int?>? voidedAtUtcMs,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      amount: amount ?? this.amount,
      occurredAtUtcMs: occurredAtUtcMs ?? this.occurredAtUtcMs,
      utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
      localDate: localDate ?? this.localDate,
      voidedAtUtcMs: voidedAtUtcMs ?? this.voidedAtUtcMs,
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
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (occurredAtUtcMs.present) {
      map['occurred_at_utc_ms'] = Variable<int>(occurredAtUtcMs.value);
    }
    if (utcOffsetMinutes.present) {
      map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (voidedAtUtcMs.present) {
      map['voided_at_utc_ms'] = Variable<int>(voidedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('amount: $amount, ')
          ..write('occurredAtUtcMs: $occurredAtUtcMs, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('localDate: $localDate, ')
          ..write('voidedAtUtcMs: $voidedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Outbox extends Table with TableInfo<Outbox, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Outbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY CHECK (seq >= 1)',
  );
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _bodyJsonMeta = const VerificationMeta(
    'bodyJson',
  );
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
    'body_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _nextAttemptAtUtcMsMeta =
      const VerificationMeta('nextAttemptAtUtcMs');
  late final GeneratedColumn<int> nextAttemptAtUtcMs = GeneratedColumn<int>(
    'next_attempt_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    opId,
    bodyJson,
    attempts,
    nextAttemptAtUtcMs,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('body_json')) {
      context.handle(
        _bodyJsonMeta,
        bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at_utc_ms')) {
      context.handle(
        _nextAttemptAtUtcMsMeta,
        nextAttemptAtUtcMs.isAcceptableOrUnknown(
          data['next_attempt_at_utc_ms']!,
          _nextAttemptAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      bodyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_json'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at_utc_ms'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  Outbox createAlias(String alias) {
    return Outbox(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int seq;
  final String opId;
  final String bodyJson;
  final int attempts;
  final int? nextAttemptAtUtcMs;
  final String? lastErrorCode;
  const OutboxData({
    required this.seq,
    required this.opId,
    required this.bodyJson,
    required this.attempts,
    this.nextAttemptAtUtcMs,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['op_id'] = Variable<String>(opId);
    map['body_json'] = Variable<String>(bodyJson);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAtUtcMs != null) {
      map['next_attempt_at_utc_ms'] = Variable<int>(nextAttemptAtUtcMs);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      opId: Value(opId),
      bodyJson: Value(bodyJson),
      attempts: Value(attempts),
      nextAttemptAtUtcMs: nextAttemptAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAtUtcMs),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      opId: serializer.fromJson<String>(json['op_id']),
      bodyJson: serializer.fromJson<String>(json['body_json']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAtUtcMs: serializer.fromJson<int?>(
        json['next_attempt_at_utc_ms'],
      ),
      lastErrorCode: serializer.fromJson<String?>(json['last_error_code']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'op_id': serializer.toJson<String>(opId),
      'body_json': serializer.toJson<String>(bodyJson),
      'attempts': serializer.toJson<int>(attempts),
      'next_attempt_at_utc_ms': serializer.toJson<int?>(nextAttemptAtUtcMs),
      'last_error_code': serializer.toJson<String?>(lastErrorCode),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? opId,
    String? bodyJson,
    int? attempts,
    Value<int?> nextAttemptAtUtcMs = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
  }) => OutboxData(
    seq: seq ?? this.seq,
    opId: opId ?? this.opId,
    bodyJson: bodyJson ?? this.bodyJson,
    attempts: attempts ?? this.attempts,
    nextAttemptAtUtcMs: nextAttemptAtUtcMs.present
        ? nextAttemptAtUtcMs.value
        : this.nextAttemptAtUtcMs,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      opId: data.opId.present ? data.opId.value : this.opId,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAtUtcMs: data.nextAttemptAtUtcMs.present
          ? data.nextAttemptAtUtcMs.value
          : this.nextAttemptAtUtcMs,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAtUtcMs: $nextAttemptAtUtcMs, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    opId,
    bodyJson,
    attempts,
    nextAttemptAtUtcMs,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.opId == this.opId &&
          other.bodyJson == this.bodyJson &&
          other.attempts == this.attempts &&
          other.nextAttemptAtUtcMs == this.nextAttemptAtUtcMs &&
          other.lastErrorCode == this.lastErrorCode);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> opId;
  final Value<String> bodyJson;
  final Value<int> attempts;
  final Value<int?> nextAttemptAtUtcMs;
  final Value<String?> lastErrorCode;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.opId = const Value.absent(),
    this.bodyJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAtUtcMs = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String opId,
    required String bodyJson,
    this.attempts = const Value.absent(),
    this.nextAttemptAtUtcMs = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  }) : opId = Value(opId),
       bodyJson = Value(bodyJson);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? opId,
    Expression<String>? bodyJson,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAtUtcMs,
    Expression<String>? lastErrorCode,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (opId != null) 'op_id': opId,
      if (bodyJson != null) 'body_json': bodyJson,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAtUtcMs != null)
        'next_attempt_at_utc_ms': nextAttemptAtUtcMs,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? opId,
    Value<String>? bodyJson,
    Value<int>? attempts,
    Value<int?>? nextAttemptAtUtcMs,
    Value<String?>? lastErrorCode,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      opId: opId ?? this.opId,
      bodyJson: bodyJson ?? this.bodyJson,
      attempts: attempts ?? this.attempts,
      nextAttemptAtUtcMs: nextAttemptAtUtcMs ?? this.nextAttemptAtUtcMs,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAtUtcMs.present) {
      map['next_attempt_at_utc_ms'] = Variable<int>(nextAttemptAtUtcMs.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAtUtcMs: $nextAttemptAtUtcMs, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }
}

abstract class _$KodoDatabase extends GeneratedDatabase {
  _$KodoDatabase(QueryExecutor e) : super(e);
  $KodoDatabaseManager get managers => $KodoDatabaseManager(this);
  late final AppMeta appMeta = AppMeta(this);
  late final Projects projects = Projects(this);
  late final Entries entries = Entries(this);
  late final Index entriesProjectDate = Index(
    'entries_project_date',
    'CREATE INDEX entries_project_date ON entries (project_id, local_date, occurred_at_utc_ms DESC, id DESC)',
  );
  late final Index entriesDate = Index(
    'entries_date',
    'CREATE INDEX entries_date ON entries (local_date) WHERE voided_at_utc_ms IS NULL',
  );
  late final Outbox outbox = Outbox(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMeta,
    projects,
    entries,
    entriesProjectDate,
    entriesDate,
    outbox,
  ];
}

typedef $AppMetaCreateCompanionBuilder =
    AppMetaCompanion Function({
      Value<int> id,
      required String installationId,
      Value<int> lastEnqueuedSeq,
      Value<int> lastAckedSeq,
      Value<int> syncEnabled,
      Value<int> registrationAttempted,
      Value<int> deletionPending,
      Value<int?> lastSyncErrorStatus,
    });
typedef $AppMetaUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<int> id,
      Value<String> installationId,
      Value<int> lastEnqueuedSeq,
      Value<int> lastAckedSeq,
      Value<int> syncEnabled,
      Value<int> registrationAttempted,
      Value<int> deletionPending,
      Value<int?> lastSyncErrorStatus,
    });

class $AppMetaFilterComposer extends Composer<_$KodoDatabase, AppMeta> {
  $AppMetaFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastEnqueuedSeq => $composableBuilder(
    column: $table.lastEnqueuedSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get registrationAttempted => $composableBuilder(
    column: $table.registrationAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletionPending => $composableBuilder(
    column: $table.deletionPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncErrorStatus => $composableBuilder(
    column: $table.lastSyncErrorStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $AppMetaOrderingComposer extends Composer<_$KodoDatabase, AppMeta> {
  $AppMetaOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastEnqueuedSeq => $composableBuilder(
    column: $table.lastEnqueuedSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get registrationAttempted => $composableBuilder(
    column: $table.registrationAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletionPending => $composableBuilder(
    column: $table.deletionPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncErrorStatus => $composableBuilder(
    column: $table.lastSyncErrorStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AppMetaAnnotationComposer extends Composer<_$KodoDatabase, AppMeta> {
  $AppMetaAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastEnqueuedSeq => $composableBuilder(
    column: $table.lastEnqueuedSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get registrationAttempted => $composableBuilder(
    column: $table.registrationAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletionPending => $composableBuilder(
    column: $table.deletionPending,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncErrorStatus => $composableBuilder(
    column: $table.lastSyncErrorStatus,
    builder: (column) => column,
  );
}

class $AppMetaTableManager
    extends
        RootTableManager<
          _$KodoDatabase,
          AppMeta,
          AppMetaData,
          $AppMetaFilterComposer,
          $AppMetaOrderingComposer,
          $AppMetaAnnotationComposer,
          $AppMetaCreateCompanionBuilder,
          $AppMetaUpdateCompanionBuilder,
          (AppMetaData, BaseReferences<_$KodoDatabase, AppMeta, AppMetaData>),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $AppMetaTableManager(_$KodoDatabase db, AppMeta table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppMetaFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppMetaOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppMetaAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> installationId = const Value.absent(),
                Value<int> lastEnqueuedSeq = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<int> syncEnabled = const Value.absent(),
                Value<int> registrationAttempted = const Value.absent(),
                Value<int> deletionPending = const Value.absent(),
                Value<int?> lastSyncErrorStatus = const Value.absent(),
              }) => AppMetaCompanion(
                id: id,
                installationId: installationId,
                lastEnqueuedSeq: lastEnqueuedSeq,
                lastAckedSeq: lastAckedSeq,
                syncEnabled: syncEnabled,
                registrationAttempted: registrationAttempted,
                deletionPending: deletionPending,
                lastSyncErrorStatus: lastSyncErrorStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String installationId,
                Value<int> lastEnqueuedSeq = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<int> syncEnabled = const Value.absent(),
                Value<int> registrationAttempted = const Value.absent(),
                Value<int> deletionPending = const Value.absent(),
                Value<int?> lastSyncErrorStatus = const Value.absent(),
              }) => AppMetaCompanion.insert(
                id: id,
                installationId: installationId,
                lastEnqueuedSeq: lastEnqueuedSeq,
                lastAckedSeq: lastAckedSeq,
                syncEnabled: syncEnabled,
                registrationAttempted: registrationAttempted,
                deletionPending: deletionPending,
                lastSyncErrorStatus: lastSyncErrorStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AppMetaProcessedTableManager =
    ProcessedTableManager<
      _$KodoDatabase,
      AppMeta,
      AppMetaData,
      $AppMetaFilterComposer,
      $AppMetaOrderingComposer,
      $AppMetaAnnotationComposer,
      $AppMetaCreateCompanionBuilder,
      $AppMetaUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$KodoDatabase, AppMeta, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;
typedef $ProjectsCreateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String?> id,
      required String name,
      required String unit,
      required String iconKey,
      required int quickAmount,
      Value<int> archived,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> rowid,
    });
typedef $ProjectsUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String?> id,
      Value<String> name,
      Value<String> unit,
      Value<String> iconKey,
      Value<int> quickAmount,
      Value<int> archived,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> rowid,
    });

final class $ProjectsReferences
    extends BaseReferences<_$KodoDatabase, Projects, Project> {
  $ProjectsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Entries, List<Entry>> _entriesRefsTable(
    _$KodoDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'projects__id__entries__project_id',
  );

  $EntriesProcessedTableManager get entriesRefs {
    final manager = $EntriesTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ProjectsFilterComposer extends Composer<_$KodoDatabase, Projects> {
  $ProjectsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quickAmount => $composableBuilder(
    column: $table.quickAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($EntriesFilterComposer f) f,
  ) {
    final $EntriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntriesFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProjectsOrderingComposer extends Composer<_$KodoDatabase, Projects> {
  $ProjectsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quickAmount => $composableBuilder(
    column: $table.quickAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ProjectsAnnotationComposer extends Composer<_$KodoDatabase, Projects> {
  $ProjectsAnnotationComposer({
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

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get quickAmount => $composableBuilder(
    column: $table.quickAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($EntriesAnnotationComposer a) f,
  ) {
    final $EntriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntriesAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProjectsTableManager
    extends
        RootTableManager<
          _$KodoDatabase,
          Projects,
          Project,
          $ProjectsFilterComposer,
          $ProjectsOrderingComposer,
          $ProjectsAnnotationComposer,
          $ProjectsCreateCompanionBuilder,
          $ProjectsUpdateCompanionBuilder,
          (Project, $ProjectsReferences),
          Project,
          PrefetchHooks Function({bool entriesRefs})
        > {
  $ProjectsTableManager(_$KodoDatabase db, Projects table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProjectsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProjectsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProjectsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> quickAmount = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                unit: unit,
                iconKey: iconKey,
                quickAmount: quickAmount,
                archived: archived,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String name,
                required String unit,
                required String iconKey,
                required int quickAmount,
                Value<int> archived = const Value.absent(),
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                unit: unit,
                iconKey: iconKey,
                quickAmount: quickAmount,
                archived: archived,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $ProjectsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<Project, Projects, Entry>(
                      currentTable: table,
                      referencedTable: $ProjectsReferences._entriesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $ProjectsReferences(db, table, p0).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ProjectsProcessedTableManager =
    ProcessedTableManager<
      _$KodoDatabase,
      Projects,
      Project,
      $ProjectsFilterComposer,
      $ProjectsOrderingComposer,
      $ProjectsAnnotationComposer,
      $ProjectsCreateCompanionBuilder,
      $ProjectsUpdateCompanionBuilder,
      (Project, $ProjectsReferences),
      Project,
      PrefetchHooks Function({bool entriesRefs})
    >;
typedef $EntriesCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<String?> id,
      required String projectId,
      required int amount,
      required int occurredAtUtcMs,
      required int utcOffsetMinutes,
      required String localDate,
      Value<int?> voidedAtUtcMs,
      Value<int> rowid,
    });
typedef $EntriesUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String?> id,
      Value<String> projectId,
      Value<int> amount,
      Value<int> occurredAtUtcMs,
      Value<int> utcOffsetMinutes,
      Value<String> localDate,
      Value<int?> voidedAtUtcMs,
      Value<int> rowid,
    });

final class $EntriesReferences
    extends BaseReferences<_$KodoDatabase, Entries, Entry> {
  $EntriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Projects _projectIdTable(_$KodoDatabase db) =>
      db.projects.createAlias('entries__project_id__projects__id');

  $ProjectsProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $ProjectsTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EntriesFilterComposer extends Composer<_$KodoDatabase, Entries> {
  $EntriesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAtUtcMs => $composableBuilder(
    column: $table.occurredAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voidedAtUtcMs => $composableBuilder(
    column: $table.voidedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $ProjectsFilterComposer get projectId {
    final $ProjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntriesOrderingComposer extends Composer<_$KodoDatabase, Entries> {
  $EntriesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtUtcMs => $composableBuilder(
    column: $table.occurredAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voidedAtUtcMs => $composableBuilder(
    column: $table.voidedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $ProjectsOrderingComposer get projectId {
    final $ProjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntriesAnnotationComposer extends Composer<_$KodoDatabase, Entries> {
  $EntriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get occurredAtUtcMs => $composableBuilder(
    column: $table.occurredAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get voidedAtUtcMs => $composableBuilder(
    column: $table.voidedAtUtcMs,
    builder: (column) => column,
  );

  $ProjectsAnnotationComposer get projectId {
    final $ProjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntriesTableManager
    extends
        RootTableManager<
          _$KodoDatabase,
          Entries,
          Entry,
          $EntriesFilterComposer,
          $EntriesOrderingComposer,
          $EntriesAnnotationComposer,
          $EntriesCreateCompanionBuilder,
          $EntriesUpdateCompanionBuilder,
          (Entry, $EntriesReferences),
          Entry,
          PrefetchHooks Function({bool projectId})
        > {
  $EntriesTableManager(_$KodoDatabase db, Entries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> occurredAtUtcMs = const Value.absent(),
                Value<int> utcOffsetMinutes = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<int?> voidedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                projectId: projectId,
                amount: amount,
                occurredAtUtcMs: occurredAtUtcMs,
                utcOffsetMinutes: utcOffsetMinutes,
                localDate: localDate,
                voidedAtUtcMs: voidedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String projectId,
                required int amount,
                required int occurredAtUtcMs,
                required int utcOffsetMinutes,
                required String localDate,
                Value<int?> voidedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                projectId: projectId,
                amount: amount,
                occurredAtUtcMs: occurredAtUtcMs,
                utcOffsetMinutes: utcOffsetMinutes,
                localDate: localDate,
                voidedAtUtcMs: voidedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $EntriesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $EntriesReferences
                                    ._projectIdTable(db),
                                referencedColumn: $EntriesReferences
                                    ._projectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $EntriesProcessedTableManager =
    ProcessedTableManager<
      _$KodoDatabase,
      Entries,
      Entry,
      $EntriesFilterComposer,
      $EntriesOrderingComposer,
      $EntriesAnnotationComposer,
      $EntriesCreateCompanionBuilder,
      $EntriesUpdateCompanionBuilder,
      (Entry, $EntriesReferences),
      Entry,
      PrefetchHooks Function({bool projectId})
    >;
typedef $OutboxCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      required String opId,
      required String bodyJson,
      Value<int> attempts,
      Value<int?> nextAttemptAtUtcMs,
      Value<String?> lastErrorCode,
    });
typedef $OutboxUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      Value<String> opId,
      Value<String> bodyJson,
      Value<int> attempts,
      Value<int?> nextAttemptAtUtcMs,
      Value<String?> lastErrorCode,
    });

class $OutboxFilterComposer extends Composer<_$KodoDatabase, Outbox> {
  $OutboxFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyJson => $composableBuilder(
    column: $table.bodyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAtUtcMs => $composableBuilder(
    column: $table.nextAttemptAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $OutboxOrderingComposer extends Composer<_$KodoDatabase, Outbox> {
  $OutboxOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyJson => $composableBuilder(
    column: $table.bodyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAtUtcMs => $composableBuilder(
    column: $table.nextAttemptAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OutboxAnnotationComposer extends Composer<_$KodoDatabase, Outbox> {
  $OutboxAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get bodyJson =>
      $composableBuilder(column: $table.bodyJson, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAtUtcMs => $composableBuilder(
    column: $table.nextAttemptAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $OutboxTableManager
    extends
        RootTableManager<
          _$KodoDatabase,
          Outbox,
          OutboxData,
          $OutboxFilterComposer,
          $OutboxOrderingComposer,
          $OutboxAnnotationComposer,
          $OutboxCreateCompanionBuilder,
          $OutboxUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$KodoDatabase, Outbox, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $OutboxTableManager(_$KodoDatabase db, Outbox table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OutboxFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OutboxOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OutboxAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> opId = const Value.absent(),
                Value<String> bodyJson = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAtUtcMs = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                opId: opId,
                bodyJson: bodyJson,
                attempts: attempts,
                nextAttemptAtUtcMs: nextAttemptAtUtcMs,
                lastErrorCode: lastErrorCode,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String opId,
                required String bodyJson,
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAtUtcMs = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => OutboxCompanion.insert(
                seq: seq,
                opId: opId,
                bodyJson: bodyJson,
                attempts: attempts,
                nextAttemptAtUtcMs: nextAttemptAtUtcMs,
                lastErrorCode: lastErrorCode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $OutboxProcessedTableManager =
    ProcessedTableManager<
      _$KodoDatabase,
      Outbox,
      OutboxData,
      $OutboxFilterComposer,
      $OutboxOrderingComposer,
      $OutboxAnnotationComposer,
      $OutboxCreateCompanionBuilder,
      $OutboxUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$KodoDatabase, Outbox, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;

class $KodoDatabaseManager {
  final _$KodoDatabase _db;
  $KodoDatabaseManager(this._db);
  $AppMetaTableManager get appMeta => $AppMetaTableManager(_db, _db.appMeta);
  $ProjectsTableManager get projects =>
      $ProjectsTableManager(_db, _db.projects);
  $EntriesTableManager get entries => $EntriesTableManager(_db, _db.entries);
  $OutboxTableManager get outbox => $OutboxTableManager(_db, _db.outbox);
}
