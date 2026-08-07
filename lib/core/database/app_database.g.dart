// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CallsTable extends Calls with TableInfo<$CallsTable, Call> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedFromDeviceMeta = const VerificationMeta(
    'removedFromDevice',
  );
  @override
  late final GeneratedColumn<bool> removedFromDevice = GeneratedColumn<bool>(
    'removed_from_device',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed_from_device" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    number,
    name,
    type,
    duration,
    timestamp,
    removedFromDevice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calls';
  @override
  VerificationContext validateIntegrity(
    Insertable<Call> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('removed_from_device')) {
      context.handle(
        _removedFromDeviceMeta,
        removedFromDevice.isAcceptableOrUnknown(
          data['removed_from_device']!,
          _removedFromDeviceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {number, timestamp, duration, type},
  ];
  @override
  Call map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Call(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      removedFromDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed_from_device'],
      )!,
    );
  }

  @override
  $CallsTable createAlias(String alias) {
    return $CallsTable(attachedDatabase, alias);
  }
}

class Call extends DataClass implements Insertable<Call> {
  final int id;
  final String? number;
  final String? name;
  final int type;
  final int duration;
  final int timestamp;
  final bool removedFromDevice;
  const Call({
    required this.id,
    this.number,
    this.name,
    required this.type,
    required this.duration,
    required this.timestamp,
    required this.removedFromDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<String>(number);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['type'] = Variable<int>(type);
    map['duration'] = Variable<int>(duration);
    map['timestamp'] = Variable<int>(timestamp);
    map['removed_from_device'] = Variable<bool>(removedFromDevice);
    return map;
  }

  CallsCompanion toCompanion(bool nullToAbsent) {
    return CallsCompanion(
      id: Value(id),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: Value(type),
      duration: Value(duration),
      timestamp: Value(timestamp),
      removedFromDevice: Value(removedFromDevice),
    );
  }

  factory Call.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Call(
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<String?>(json['number']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<int>(json['type']),
      duration: serializer.fromJson<int>(json['duration']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      removedFromDevice: serializer.fromJson<bool>(json['removedFromDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<String?>(number),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<int>(type),
      'duration': serializer.toJson<int>(duration),
      'timestamp': serializer.toJson<int>(timestamp),
      'removedFromDevice': serializer.toJson<bool>(removedFromDevice),
    };
  }

  Call copyWith({
    int? id,
    Value<String?> number = const Value.absent(),
    Value<String?> name = const Value.absent(),
    int? type,
    int? duration,
    int? timestamp,
    bool? removedFromDevice,
  }) => Call(
    id: id ?? this.id,
    number: number.present ? number.value : this.number,
    name: name.present ? name.value : this.name,
    type: type ?? this.type,
    duration: duration ?? this.duration,
    timestamp: timestamp ?? this.timestamp,
    removedFromDevice: removedFromDevice ?? this.removedFromDevice,
  );
  Call copyWithCompanion(CallsCompanion data) {
    return Call(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      duration: data.duration.present ? data.duration.value : this.duration,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      removedFromDevice: data.removedFromDevice.present
          ? data.removedFromDevice.value
          : this.removedFromDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Call(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('duration: $duration, ')
          ..write('timestamp: $timestamp, ')
          ..write('removedFromDevice: $removedFromDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    number,
    name,
    type,
    duration,
    timestamp,
    removedFromDevice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Call &&
          other.id == this.id &&
          other.number == this.number &&
          other.name == this.name &&
          other.type == this.type &&
          other.duration == this.duration &&
          other.timestamp == this.timestamp &&
          other.removedFromDevice == this.removedFromDevice);
}

class CallsCompanion extends UpdateCompanion<Call> {
  final Value<int> id;
  final Value<String?> number;
  final Value<String?> name;
  final Value<int> type;
  final Value<int> duration;
  final Value<int> timestamp;
  final Value<bool> removedFromDevice;
  const CallsCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.duration = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.removedFromDevice = const Value.absent(),
  });
  CallsCompanion.insert({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.name = const Value.absent(),
    required int type,
    required int duration,
    required int timestamp,
    this.removedFromDevice = const Value.absent(),
  }) : type = Value(type),
       duration = Value(duration),
       timestamp = Value(timestamp);
  static Insertable<Call> custom({
    Expression<int>? id,
    Expression<String>? number,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? duration,
    Expression<int>? timestamp,
    Expression<bool>? removedFromDevice,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (duration != null) 'duration': duration,
      if (timestamp != null) 'timestamp': timestamp,
      if (removedFromDevice != null) 'removed_from_device': removedFromDevice,
    });
  }

  CallsCompanion copyWith({
    Value<int>? id,
    Value<String?>? number,
    Value<String?>? name,
    Value<int>? type,
    Value<int>? duration,
    Value<int>? timestamp,
    Value<bool>? removedFromDevice,
  }) {
    return CallsCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      removedFromDevice: removedFromDevice ?? this.removedFromDevice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (removedFromDevice.present) {
      map['removed_from_device'] = Variable<bool>(removedFromDevice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallsCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('duration: $duration, ')
          ..write('timestamp: $timestamp, ')
          ..write('removedFromDevice: $removedFromDevice')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncEnabledMeta = const VerificationMeta(
    'syncEnabled',
  );
  @override
  late final GeneratedColumn<bool> syncEnabled = GeneratedColumn<bool>(
    'sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _archiveModeMeta = const VerificationMeta(
    'archiveMode',
  );
  @override
  late final GeneratedColumn<bool> archiveMode = GeneratedColumn<bool>(
    'archive_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archive_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _devModeMeta = const VerificationMeta(
    'devMode',
  );
  @override
  late final GeneratedColumn<bool> devMode = GeneratedColumn<bool>(
    'dev_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dev_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showContactNameMeta = const VerificationMeta(
    'showContactName',
  );
  @override
  late final GeneratedColumn<bool> showContactName = GeneratedColumn<bool>(
    'show_contact_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_contact_name" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showPhoneNumberMeta = const VerificationMeta(
    'showPhoneNumber',
  );
  @override
  late final GeneratedColumn<bool> showPhoneNumber = GeneratedColumn<bool>(
    'show_phone_number',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_phone_number" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showCallTypeMeta = const VerificationMeta(
    'showCallType',
  );
  @override
  late final GeneratedColumn<bool> showCallType = GeneratedColumn<bool>(
    'show_call_type',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_call_type" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showDurationMeta = const VerificationMeta(
    'showDuration',
  );
  @override
  late final GeneratedColumn<bool> showDuration = GeneratedColumn<bool>(
    'show_duration',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_duration" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showDateMeta = const VerificationMeta(
    'showDate',
  );
  @override
  late final GeneratedColumn<bool> showDate = GeneratedColumn<bool>(
    'show_date',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_date" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showTimeMeta = const VerificationMeta(
    'showTime',
  );
  @override
  late final GeneratedColumn<bool> showTime = GeneratedColumn<bool>(
    'show_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_time" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncEnabled,
    archiveMode,
    devMode,
    showContactName,
    showPhoneNumber,
    showCallType,
    showDuration,
    showDate,
    showTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('archive_mode')) {
      context.handle(
        _archiveModeMeta,
        archiveMode.isAcceptableOrUnknown(
          data['archive_mode']!,
          _archiveModeMeta,
        ),
      );
    }
    if (data.containsKey('dev_mode')) {
      context.handle(
        _devModeMeta,
        devMode.isAcceptableOrUnknown(data['dev_mode']!, _devModeMeta),
      );
    }
    if (data.containsKey('show_contact_name')) {
      context.handle(
        _showContactNameMeta,
        showContactName.isAcceptableOrUnknown(
          data['show_contact_name']!,
          _showContactNameMeta,
        ),
      );
    }
    if (data.containsKey('show_phone_number')) {
      context.handle(
        _showPhoneNumberMeta,
        showPhoneNumber.isAcceptableOrUnknown(
          data['show_phone_number']!,
          _showPhoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('show_call_type')) {
      context.handle(
        _showCallTypeMeta,
        showCallType.isAcceptableOrUnknown(
          data['show_call_type']!,
          _showCallTypeMeta,
        ),
      );
    }
    if (data.containsKey('show_duration')) {
      context.handle(
        _showDurationMeta,
        showDuration.isAcceptableOrUnknown(
          data['show_duration']!,
          _showDurationMeta,
        ),
      );
    }
    if (data.containsKey('show_date')) {
      context.handle(
        _showDateMeta,
        showDate.isAcceptableOrUnknown(data['show_date']!, _showDateMeta),
      );
    }
    if (data.containsKey('show_time')) {
      context.handle(
        _showTimeMeta,
        showTime.isAcceptableOrUnknown(data['show_time']!, _showTimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_enabled'],
      )!,
      archiveMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archive_mode'],
      )!,
      devMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dev_mode'],
      )!,
      showContactName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_contact_name'],
      )!,
      showPhoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_phone_number'],
      )!,
      showCallType: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_call_type'],
      )!,
      showDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_duration'],
      )!,
      showDate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_date'],
      )!,
      showTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_time'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final bool syncEnabled;
  final bool archiveMode;
  final bool devMode;
  final bool showContactName;
  final bool showPhoneNumber;
  final bool showCallType;
  final bool showDuration;
  final bool showDate;
  final bool showTime;
  const Setting({
    required this.id,
    required this.syncEnabled,
    required this.archiveMode,
    required this.devMode,
    required this.showContactName,
    required this.showPhoneNumber,
    required this.showCallType,
    required this.showDuration,
    required this.showDate,
    required this.showTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_enabled'] = Variable<bool>(syncEnabled);
    map['archive_mode'] = Variable<bool>(archiveMode);
    map['dev_mode'] = Variable<bool>(devMode);
    map['show_contact_name'] = Variable<bool>(showContactName);
    map['show_phone_number'] = Variable<bool>(showPhoneNumber);
    map['show_call_type'] = Variable<bool>(showCallType);
    map['show_duration'] = Variable<bool>(showDuration);
    map['show_date'] = Variable<bool>(showDate);
    map['show_time'] = Variable<bool>(showTime);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      syncEnabled: Value(syncEnabled),
      archiveMode: Value(archiveMode),
      devMode: Value(devMode),
      showContactName: Value(showContactName),
      showPhoneNumber: Value(showPhoneNumber),
      showCallType: Value(showCallType),
      showDuration: Value(showDuration),
      showDate: Value(showDate),
      showTime: Value(showTime),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      syncEnabled: serializer.fromJson<bool>(json['syncEnabled']),
      archiveMode: serializer.fromJson<bool>(json['archiveMode']),
      devMode: serializer.fromJson<bool>(json['devMode']),
      showContactName: serializer.fromJson<bool>(json['showContactName']),
      showPhoneNumber: serializer.fromJson<bool>(json['showPhoneNumber']),
      showCallType: serializer.fromJson<bool>(json['showCallType']),
      showDuration: serializer.fromJson<bool>(json['showDuration']),
      showDate: serializer.fromJson<bool>(json['showDate']),
      showTime: serializer.fromJson<bool>(json['showTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncEnabled': serializer.toJson<bool>(syncEnabled),
      'archiveMode': serializer.toJson<bool>(archiveMode),
      'devMode': serializer.toJson<bool>(devMode),
      'showContactName': serializer.toJson<bool>(showContactName),
      'showPhoneNumber': serializer.toJson<bool>(showPhoneNumber),
      'showCallType': serializer.toJson<bool>(showCallType),
      'showDuration': serializer.toJson<bool>(showDuration),
      'showDate': serializer.toJson<bool>(showDate),
      'showTime': serializer.toJson<bool>(showTime),
    };
  }

  Setting copyWith({
    int? id,
    bool? syncEnabled,
    bool? archiveMode,
    bool? devMode,
    bool? showContactName,
    bool? showPhoneNumber,
    bool? showCallType,
    bool? showDuration,
    bool? showDate,
    bool? showTime,
  }) => Setting(
    id: id ?? this.id,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    archiveMode: archiveMode ?? this.archiveMode,
    devMode: devMode ?? this.devMode,
    showContactName: showContactName ?? this.showContactName,
    showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
    showCallType: showCallType ?? this.showCallType,
    showDuration: showDuration ?? this.showDuration,
    showDate: showDate ?? this.showDate,
    showTime: showTime ?? this.showTime,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      syncEnabled: data.syncEnabled.present
          ? data.syncEnabled.value
          : this.syncEnabled,
      archiveMode: data.archiveMode.present
          ? data.archiveMode.value
          : this.archiveMode,
      devMode: data.devMode.present ? data.devMode.value : this.devMode,
      showContactName: data.showContactName.present
          ? data.showContactName.value
          : this.showContactName,
      showPhoneNumber: data.showPhoneNumber.present
          ? data.showPhoneNumber.value
          : this.showPhoneNumber,
      showCallType: data.showCallType.present
          ? data.showCallType.value
          : this.showCallType,
      showDuration: data.showDuration.present
          ? data.showDuration.value
          : this.showDuration,
      showDate: data.showDate.present ? data.showDate.value : this.showDate,
      showTime: data.showTime.present ? data.showTime.value : this.showTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('archiveMode: $archiveMode, ')
          ..write('devMode: $devMode, ')
          ..write('showContactName: $showContactName, ')
          ..write('showPhoneNumber: $showPhoneNumber, ')
          ..write('showCallType: $showCallType, ')
          ..write('showDuration: $showDuration, ')
          ..write('showDate: $showDate, ')
          ..write('showTime: $showTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncEnabled,
    archiveMode,
    devMode,
    showContactName,
    showPhoneNumber,
    showCallType,
    showDuration,
    showDate,
    showTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.syncEnabled == this.syncEnabled &&
          other.archiveMode == this.archiveMode &&
          other.devMode == this.devMode &&
          other.showContactName == this.showContactName &&
          other.showPhoneNumber == this.showPhoneNumber &&
          other.showCallType == this.showCallType &&
          other.showDuration == this.showDuration &&
          other.showDate == this.showDate &&
          other.showTime == this.showTime);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<bool> syncEnabled;
  final Value<bool> archiveMode;
  final Value<bool> devMode;
  final Value<bool> showContactName;
  final Value<bool> showPhoneNumber;
  final Value<bool> showCallType;
  final Value<bool> showDuration;
  final Value<bool> showDate;
  final Value<bool> showTime;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.archiveMode = const Value.absent(),
    this.devMode = const Value.absent(),
    this.showContactName = const Value.absent(),
    this.showPhoneNumber = const Value.absent(),
    this.showCallType = const Value.absent(),
    this.showDuration = const Value.absent(),
    this.showDate = const Value.absent(),
    this.showTime = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.archiveMode = const Value.absent(),
    this.devMode = const Value.absent(),
    this.showContactName = const Value.absent(),
    this.showPhoneNumber = const Value.absent(),
    this.showCallType = const Value.absent(),
    this.showDuration = const Value.absent(),
    this.showDate = const Value.absent(),
    this.showTime = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<bool>? syncEnabled,
    Expression<bool>? archiveMode,
    Expression<bool>? devMode,
    Expression<bool>? showContactName,
    Expression<bool>? showPhoneNumber,
    Expression<bool>? showCallType,
    Expression<bool>? showDuration,
    Expression<bool>? showDate,
    Expression<bool>? showTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
      if (archiveMode != null) 'archive_mode': archiveMode,
      if (devMode != null) 'dev_mode': devMode,
      if (showContactName != null) 'show_contact_name': showContactName,
      if (showPhoneNumber != null) 'show_phone_number': showPhoneNumber,
      if (showCallType != null) 'show_call_type': showCallType,
      if (showDuration != null) 'show_duration': showDuration,
      if (showDate != null) 'show_date': showDate,
      if (showTime != null) 'show_time': showTime,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? syncEnabled,
    Value<bool>? archiveMode,
    Value<bool>? devMode,
    Value<bool>? showContactName,
    Value<bool>? showPhoneNumber,
    Value<bool>? showCallType,
    Value<bool>? showDuration,
    Value<bool>? showDate,
    Value<bool>? showTime,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      archiveMode: archiveMode ?? this.archiveMode,
      devMode: devMode ?? this.devMode,
      showContactName: showContactName ?? this.showContactName,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      showCallType: showCallType ?? this.showCallType,
      showDuration: showDuration ?? this.showDuration,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<bool>(syncEnabled.value);
    }
    if (archiveMode.present) {
      map['archive_mode'] = Variable<bool>(archiveMode.value);
    }
    if (devMode.present) {
      map['dev_mode'] = Variable<bool>(devMode.value);
    }
    if (showContactName.present) {
      map['show_contact_name'] = Variable<bool>(showContactName.value);
    }
    if (showPhoneNumber.present) {
      map['show_phone_number'] = Variable<bool>(showPhoneNumber.value);
    }
    if (showCallType.present) {
      map['show_call_type'] = Variable<bool>(showCallType.value);
    }
    if (showDuration.present) {
      map['show_duration'] = Variable<bool>(showDuration.value);
    }
    if (showDate.present) {
      map['show_date'] = Variable<bool>(showDate.value);
    }
    if (showTime.present) {
      map['show_time'] = Variable<bool>(showTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('archiveMode: $archiveMode, ')
          ..write('devMode: $devMode, ')
          ..write('showContactName: $showContactName, ')
          ..write('showPhoneNumber: $showPhoneNumber, ')
          ..write('showCallType: $showCallType, ')
          ..write('showDuration: $showDuration, ')
          ..write('showDate: $showDate, ')
          ..write('showTime: $showTime')
          ..write(')'))
        .toString();
  }
}

class $CallDetailsTable extends CallDetails
    with TableInfo<$CallDetailsTable, CallDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _callIdMeta = const VerificationMeta('callId');
  @override
  late final GeneratedColumn<int> callId = GeneratedColumn<int>(
    'call_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<int> reminderAt = GeneratedColumn<int>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderLabelMeta = const VerificationMeta(
    'reminderLabel',
  );
  @override
  late final GeneratedColumn<String> reminderLabel = GeneratedColumn<String>(
    'reminder_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    callId,
    note,
    reminderAt,
    reminderLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('call_id')) {
      context.handle(
        _callIdMeta,
        callId.isAcceptableOrUnknown(data['call_id']!, _callIdMeta),
      );
    } else if (isInserting) {
      context.missing(_callIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('reminder_label')) {
      context.handle(
        _reminderLabelMeta,
        reminderLabel.isAcceptableOrUnknown(
          data['reminder_label']!,
          _reminderLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {callId},
  ];
  @override
  CallDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallDetail(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      callId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}call_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_at'],
      ),
      reminderLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_label'],
      ),
    );
  }

  @override
  $CallDetailsTable createAlias(String alias) {
    return $CallDetailsTable(attachedDatabase, alias);
  }
}

class CallDetail extends DataClass implements Insertable<CallDetail> {
  final int id;
  final int callId;
  final String? note;
  final int? reminderAt;
  final String? reminderLabel;
  const CallDetail({
    required this.id,
    required this.callId,
    this.note,
    this.reminderAt,
    this.reminderLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['call_id'] = Variable<int>(callId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<int>(reminderAt);
    }
    if (!nullToAbsent || reminderLabel != null) {
      map['reminder_label'] = Variable<String>(reminderLabel);
    }
    return map;
  }

  CallDetailsCompanion toCompanion(bool nullToAbsent) {
    return CallDetailsCompanion(
      id: Value(id),
      callId: Value(callId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      reminderLabel: reminderLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderLabel),
    );
  }

  factory CallDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallDetail(
      id: serializer.fromJson<int>(json['id']),
      callId: serializer.fromJson<int>(json['callId']),
      note: serializer.fromJson<String?>(json['note']),
      reminderAt: serializer.fromJson<int?>(json['reminderAt']),
      reminderLabel: serializer.fromJson<String?>(json['reminderLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'callId': serializer.toJson<int>(callId),
      'note': serializer.toJson<String?>(note),
      'reminderAt': serializer.toJson<int?>(reminderAt),
      'reminderLabel': serializer.toJson<String?>(reminderLabel),
    };
  }

  CallDetail copyWith({
    int? id,
    int? callId,
    Value<String?> note = const Value.absent(),
    Value<int?> reminderAt = const Value.absent(),
    Value<String?> reminderLabel = const Value.absent(),
  }) => CallDetail(
    id: id ?? this.id,
    callId: callId ?? this.callId,
    note: note.present ? note.value : this.note,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    reminderLabel: reminderLabel.present
        ? reminderLabel.value
        : this.reminderLabel,
  );
  CallDetail copyWithCompanion(CallDetailsCompanion data) {
    return CallDetail(
      id: data.id.present ? data.id.value : this.id,
      callId: data.callId.present ? data.callId.value : this.callId,
      note: data.note.present ? data.note.value : this.note,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      reminderLabel: data.reminderLabel.present
          ? data.reminderLabel.value
          : this.reminderLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallDetail(')
          ..write('id: $id, ')
          ..write('callId: $callId, ')
          ..write('note: $note, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('reminderLabel: $reminderLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, callId, note, reminderAt, reminderLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallDetail &&
          other.id == this.id &&
          other.callId == this.callId &&
          other.note == this.note &&
          other.reminderAt == this.reminderAt &&
          other.reminderLabel == this.reminderLabel);
}

class CallDetailsCompanion extends UpdateCompanion<CallDetail> {
  final Value<int> id;
  final Value<int> callId;
  final Value<String?> note;
  final Value<int?> reminderAt;
  final Value<String?> reminderLabel;
  const CallDetailsCompanion({
    this.id = const Value.absent(),
    this.callId = const Value.absent(),
    this.note = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.reminderLabel = const Value.absent(),
  });
  CallDetailsCompanion.insert({
    this.id = const Value.absent(),
    required int callId,
    this.note = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.reminderLabel = const Value.absent(),
  }) : callId = Value(callId);
  static Insertable<CallDetail> custom({
    Expression<int>? id,
    Expression<int>? callId,
    Expression<String>? note,
    Expression<int>? reminderAt,
    Expression<String>? reminderLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callId != null) 'call_id': callId,
      if (note != null) 'note': note,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (reminderLabel != null) 'reminder_label': reminderLabel,
    });
  }

  CallDetailsCompanion copyWith({
    Value<int>? id,
    Value<int>? callId,
    Value<String?>? note,
    Value<int?>? reminderAt,
    Value<String?>? reminderLabel,
  }) {
    return CallDetailsCompanion(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      note: note ?? this.note,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderLabel: reminderLabel ?? this.reminderLabel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (callId.present) {
      map['call_id'] = Variable<int>(callId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<int>(reminderAt.value);
    }
    if (reminderLabel.present) {
      map['reminder_label'] = Variable<String>(reminderLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallDetailsCompanion(')
          ..write('id: $id, ')
          ..write('callId: $callId, ')
          ..write('note: $note, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('reminderLabel: $reminderLabel')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({int? id, String? name}) =>
      Tag(id: id ?? this.id, name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $CallTagsTable extends CallTags with TableInfo<$CallTagsTable, CallTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _callIdMeta = const VerificationMeta('callId');
  @override
  late final GeneratedColumn<int> callId = GeneratedColumn<int>(
    'call_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [callId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('call_id')) {
      context.handle(
        _callIdMeta,
        callId.isAcceptableOrUnknown(data['call_id']!, _callIdMeta),
      );
    } else if (isInserting) {
      context.missing(_callIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {callId, tagId};
  @override
  CallTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallTag(
      callId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}call_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $CallTagsTable createAlias(String alias) {
    return $CallTagsTable(attachedDatabase, alias);
  }
}

class CallTag extends DataClass implements Insertable<CallTag> {
  final int callId;
  final int tagId;
  const CallTag({required this.callId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['call_id'] = Variable<int>(callId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  CallTagsCompanion toCompanion(bool nullToAbsent) {
    return CallTagsCompanion(callId: Value(callId), tagId: Value(tagId));
  }

  factory CallTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallTag(
      callId: serializer.fromJson<int>(json['callId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'callId': serializer.toJson<int>(callId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  CallTag copyWith({int? callId, int? tagId}) =>
      CallTag(callId: callId ?? this.callId, tagId: tagId ?? this.tagId);
  CallTag copyWithCompanion(CallTagsCompanion data) {
    return CallTag(
      callId: data.callId.present ? data.callId.value : this.callId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallTag(')
          ..write('callId: $callId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(callId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallTag &&
          other.callId == this.callId &&
          other.tagId == this.tagId);
}

class CallTagsCompanion extends UpdateCompanion<CallTag> {
  final Value<int> callId;
  final Value<int> tagId;
  final Value<int> rowid;
  const CallTagsCompanion({
    this.callId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CallTagsCompanion.insert({
    required int callId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : callId = Value(callId),
       tagId = Value(tagId);
  static Insertable<CallTag> custom({
    Expression<int>? callId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (callId != null) 'call_id': callId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CallTagsCompanion copyWith({
    Value<int>? callId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return CallTagsCompanion(
      callId: callId ?? this.callId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (callId.present) {
      map['call_id'] = Variable<int>(callId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallTagsCompanion(')
          ..write('callId: $callId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CallAttachmentsTable extends CallAttachments
    with TableInfo<$CallAttachmentsTable, CallAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _callIdMeta = const VerificationMeta('callId');
  @override
  late final GeneratedColumn<int> callId = GeneratedColumn<int>(
    'call_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    callId,
    filePath,
    originalFileName,
    fileType,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('call_id')) {
      context.handle(
        _callIdMeta,
        callId.isAcceptableOrUnknown(data['call_id']!, _callIdMeta),
      );
    } else if (isInserting) {
      context.missing(_callIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileNameMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      callId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}call_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $CallAttachmentsTable createAlias(String alias) {
    return $CallAttachmentsTable(attachedDatabase, alias);
  }
}

class CallAttachment extends DataClass implements Insertable<CallAttachment> {
  final int id;
  final int callId;
  final String filePath;
  final String originalFileName;
  final String fileType;
  final int addedAt;
  const CallAttachment({
    required this.id,
    required this.callId,
    required this.filePath,
    required this.originalFileName,
    required this.fileType,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['call_id'] = Variable<int>(callId);
    map['file_path'] = Variable<String>(filePath);
    map['original_file_name'] = Variable<String>(originalFileName);
    map['file_type'] = Variable<String>(fileType);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  CallAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return CallAttachmentsCompanion(
      id: Value(id),
      callId: Value(callId),
      filePath: Value(filePath),
      originalFileName: Value(originalFileName),
      fileType: Value(fileType),
      addedAt: Value(addedAt),
    );
  }

  factory CallAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallAttachment(
      id: serializer.fromJson<int>(json['id']),
      callId: serializer.fromJson<int>(json['callId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      originalFileName: serializer.fromJson<String>(json['originalFileName']),
      fileType: serializer.fromJson<String>(json['fileType']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'callId': serializer.toJson<int>(callId),
      'filePath': serializer.toJson<String>(filePath),
      'originalFileName': serializer.toJson<String>(originalFileName),
      'fileType': serializer.toJson<String>(fileType),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  CallAttachment copyWith({
    int? id,
    int? callId,
    String? filePath,
    String? originalFileName,
    String? fileType,
    int? addedAt,
  }) => CallAttachment(
    id: id ?? this.id,
    callId: callId ?? this.callId,
    filePath: filePath ?? this.filePath,
    originalFileName: originalFileName ?? this.originalFileName,
    fileType: fileType ?? this.fileType,
    addedAt: addedAt ?? this.addedAt,
  );
  CallAttachment copyWithCompanion(CallAttachmentsCompanion data) {
    return CallAttachment(
      id: data.id.present ? data.id.value : this.id,
      callId: data.callId.present ? data.callId.value : this.callId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallAttachment(')
          ..write('id: $id, ')
          ..write('callId: $callId, ')
          ..write('filePath: $filePath, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('fileType: $fileType, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, callId, filePath, originalFileName, fileType, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallAttachment &&
          other.id == this.id &&
          other.callId == this.callId &&
          other.filePath == this.filePath &&
          other.originalFileName == this.originalFileName &&
          other.fileType == this.fileType &&
          other.addedAt == this.addedAt);
}

class CallAttachmentsCompanion extends UpdateCompanion<CallAttachment> {
  final Value<int> id;
  final Value<int> callId;
  final Value<String> filePath;
  final Value<String> originalFileName;
  final Value<String> fileType;
  final Value<int> addedAt;
  const CallAttachmentsCompanion({
    this.id = const Value.absent(),
    this.callId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  CallAttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required int callId,
    required String filePath,
    required String originalFileName,
    required String fileType,
    required int addedAt,
  }) : callId = Value(callId),
       filePath = Value(filePath),
       originalFileName = Value(originalFileName),
       fileType = Value(fileType),
       addedAt = Value(addedAt);
  static Insertable<CallAttachment> custom({
    Expression<int>? id,
    Expression<int>? callId,
    Expression<String>? filePath,
    Expression<String>? originalFileName,
    Expression<String>? fileType,
    Expression<int>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callId != null) 'call_id': callId,
      if (filePath != null) 'file_path': filePath,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (fileType != null) 'file_type': fileType,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  CallAttachmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? callId,
    Value<String>? filePath,
    Value<String>? originalFileName,
    Value<String>? fileType,
    Value<int>? addedAt,
  }) {
    return CallAttachmentsCompanion(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      filePath: filePath ?? this.filePath,
      originalFileName: originalFileName ?? this.originalFileName,
      fileType: fileType ?? this.fileType,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (callId.present) {
      map['call_id'] = Variable<int>(callId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('callId: $callId, ')
          ..write('filePath: $filePath, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('fileType: $fileType, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CallsTable calls = $CallsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CallDetailsTable callDetails = $CallDetailsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $CallTagsTable callTags = $CallTagsTable(this);
  late final $CallAttachmentsTable callAttachments = $CallAttachmentsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    calls,
    settings,
    callDetails,
    tags,
    callTags,
    callAttachments,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_details', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_attachments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CallsTableCreateCompanionBuilder =
    CallsCompanion Function({
      Value<int> id,
      Value<String?> number,
      Value<String?> name,
      required int type,
      required int duration,
      required int timestamp,
      Value<bool> removedFromDevice,
    });
typedef $$CallsTableUpdateCompanionBuilder =
    CallsCompanion Function({
      Value<int> id,
      Value<String?> number,
      Value<String?> name,
      Value<int> type,
      Value<int> duration,
      Value<int> timestamp,
      Value<bool> removedFromDevice,
    });

final class $$CallsTableReferences
    extends BaseReferences<_$AppDatabase, $CallsTable, Call> {
  $$CallsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CallDetailsTable, List<CallDetail>>
  _callDetailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.callDetails,
    aliasName: 'calls__id__call_details__call_id',
  );

  $$CallDetailsTableProcessedTableManager get callDetailsRefs {
    final manager = $$CallDetailsTableTableManager(
      $_db,
      $_db.callDetails,
    ).filter((f) => f.callId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_callDetailsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CallTagsTable, List<CallTag>> _callTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.callTags,
    aliasName: 'calls__id__call_tags__call_id',
  );

  $$CallTagsTableProcessedTableManager get callTagsRefs {
    final manager = $$CallTagsTableTableManager(
      $_db,
      $_db.callTags,
    ).filter((f) => f.callId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_callTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CallAttachmentsTable, List<CallAttachment>>
  _callAttachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.callAttachments,
    aliasName: 'calls__id__call_attachments__call_id',
  );

  $$CallAttachmentsTableProcessedTableManager get callAttachmentsRefs {
    final manager = $$CallAttachmentsTableTableManager(
      $_db,
      $_db.callAttachments,
    ).filter((f) => f.callId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _callAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CallsTableFilterComposer extends Composer<_$AppDatabase, $CallsTable> {
  $$CallsTableFilterComposer({
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

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get removedFromDevice => $composableBuilder(
    column: $table.removedFromDevice,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> callDetailsRefs(
    Expression<bool> Function($$CallDetailsTableFilterComposer f) f,
  ) {
    final $$CallDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callDetails,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallDetailsTableFilterComposer(
            $db: $db,
            $table: $db.callDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> callTagsRefs(
    Expression<bool> Function($$CallTagsTableFilterComposer f) f,
  ) {
    final $$CallTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callTags,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallTagsTableFilterComposer(
            $db: $db,
            $table: $db.callTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> callAttachmentsRefs(
    Expression<bool> Function($$CallAttachmentsTableFilterComposer f) f,
  ) {
    final $$CallAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callAttachments,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.callAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallsTable> {
  $$CallsTableOrderingComposer({
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

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get removedFromDevice => $composableBuilder(
    column: $table.removedFromDevice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CallsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallsTable> {
  $$CallsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get removedFromDevice => $composableBuilder(
    column: $table.removedFromDevice,
    builder: (column) => column,
  );

  Expression<T> callDetailsRefs<T extends Object>(
    Expression<T> Function($$CallDetailsTableAnnotationComposer a) f,
  ) {
    final $$CallDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callDetails,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallDetailsTableAnnotationComposer(
            $db: $db,
            $table: $db.callDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> callTagsRefs<T extends Object>(
    Expression<T> Function($$CallTagsTableAnnotationComposer a) f,
  ) {
    final $$CallTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callTags,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.callTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> callAttachmentsRefs<T extends Object>(
    Expression<T> Function($$CallAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$CallAttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callAttachments,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallAttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.callAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallsTable,
          Call,
          $$CallsTableFilterComposer,
          $$CallsTableOrderingComposer,
          $$CallsTableAnnotationComposer,
          $$CallsTableCreateCompanionBuilder,
          $$CallsTableUpdateCompanionBuilder,
          (Call, $$CallsTableReferences),
          Call,
          PrefetchHooks Function({
            bool callDetailsRefs,
            bool callTagsRefs,
            bool callAttachmentsRefs,
          })
        > {
  $$CallsTableTableManager(_$AppDatabase db, $CallsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<bool> removedFromDevice = const Value.absent(),
              }) => CallsCompanion(
                id: id,
                number: number,
                name: name,
                type: type,
                duration: duration,
                timestamp: timestamp,
                removedFromDevice: removedFromDevice,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<String?> name = const Value.absent(),
                required int type,
                required int duration,
                required int timestamp,
                Value<bool> removedFromDevice = const Value.absent(),
              }) => CallsCompanion.insert(
                id: id,
                number: number,
                name: name,
                type: type,
                duration: duration,
                timestamp: timestamp,
                removedFromDevice: removedFromDevice,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CallsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                callDetailsRefs = false,
                callTagsRefs = false,
                callAttachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (callDetailsRefs) db.callDetails,
                    if (callTagsRefs) db.callTags,
                    if (callAttachmentsRefs) db.callAttachments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (callDetailsRefs)
                        await $_getPrefetchedData<
                          Call,
                          $CallsTable,
                          CallDetail
                        >(
                          currentTable: table,
                          referencedTable: $$CallsTableReferences
                              ._callDetailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CallsTableReferences(
                                db,
                                table,
                                p0,
                              ).callDetailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.callId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (callTagsRefs)
                        await $_getPrefetchedData<Call, $CallsTable, CallTag>(
                          currentTable: table,
                          referencedTable: $$CallsTableReferences
                              ._callTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CallsTableReferences(
                                db,
                                table,
                                p0,
                              ).callTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.callId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (callAttachmentsRefs)
                        await $_getPrefetchedData<
                          Call,
                          $CallsTable,
                          CallAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$CallsTableReferences
                              ._callAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CallsTableReferences(
                                db,
                                table,
                                p0,
                              ).callAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.callId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CallsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallsTable,
      Call,
      $$CallsTableFilterComposer,
      $$CallsTableOrderingComposer,
      $$CallsTableAnnotationComposer,
      $$CallsTableCreateCompanionBuilder,
      $$CallsTableUpdateCompanionBuilder,
      (Call, $$CallsTableReferences),
      Call,
      PrefetchHooks Function({
        bool callDetailsRefs,
        bool callTagsRefs,
        bool callAttachmentsRefs,
      })
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<bool> syncEnabled,
      Value<bool> archiveMode,
      Value<bool> devMode,
      Value<bool> showContactName,
      Value<bool> showPhoneNumber,
      Value<bool> showCallType,
      Value<bool> showDuration,
      Value<bool> showDate,
      Value<bool> showTime,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<bool> syncEnabled,
      Value<bool> archiveMode,
      Value<bool> devMode,
      Value<bool> showContactName,
      Value<bool> showPhoneNumber,
      Value<bool> showCallType,
      Value<bool> showDuration,
      Value<bool> showDate,
      Value<bool> showTime,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archiveMode => $composableBuilder(
    column: $table.archiveMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get devMode => $composableBuilder(
    column: $table.devMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showContactName => $composableBuilder(
    column: $table.showContactName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showPhoneNumber => $composableBuilder(
    column: $table.showPhoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCallType => $composableBuilder(
    column: $table.showCallType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showDuration => $composableBuilder(
    column: $table.showDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showDate => $composableBuilder(
    column: $table.showDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showTime => $composableBuilder(
    column: $table.showTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archiveMode => $composableBuilder(
    column: $table.archiveMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get devMode => $composableBuilder(
    column: $table.devMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showContactName => $composableBuilder(
    column: $table.showContactName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showPhoneNumber => $composableBuilder(
    column: $table.showPhoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCallType => $composableBuilder(
    column: $table.showCallType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showDuration => $composableBuilder(
    column: $table.showDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showDate => $composableBuilder(
    column: $table.showDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showTime => $composableBuilder(
    column: $table.showTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archiveMode => $composableBuilder(
    column: $table.archiveMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get devMode =>
      $composableBuilder(column: $table.devMode, builder: (column) => column);

  GeneratedColumn<bool> get showContactName => $composableBuilder(
    column: $table.showContactName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showPhoneNumber => $composableBuilder(
    column: $table.showPhoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showCallType => $composableBuilder(
    column: $table.showCallType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showDuration => $composableBuilder(
    column: $table.showDuration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showDate =>
      $composableBuilder(column: $table.showDate, builder: (column) => column);

  GeneratedColumn<bool> get showTime =>
      $composableBuilder(column: $table.showTime, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<bool> archiveMode = const Value.absent(),
                Value<bool> devMode = const Value.absent(),
                Value<bool> showContactName = const Value.absent(),
                Value<bool> showPhoneNumber = const Value.absent(),
                Value<bool> showCallType = const Value.absent(),
                Value<bool> showDuration = const Value.absent(),
                Value<bool> showDate = const Value.absent(),
                Value<bool> showTime = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                syncEnabled: syncEnabled,
                archiveMode: archiveMode,
                devMode: devMode,
                showContactName: showContactName,
                showPhoneNumber: showPhoneNumber,
                showCallType: showCallType,
                showDuration: showDuration,
                showDate: showDate,
                showTime: showTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<bool> archiveMode = const Value.absent(),
                Value<bool> devMode = const Value.absent(),
                Value<bool> showContactName = const Value.absent(),
                Value<bool> showPhoneNumber = const Value.absent(),
                Value<bool> showCallType = const Value.absent(),
                Value<bool> showDuration = const Value.absent(),
                Value<bool> showDate = const Value.absent(),
                Value<bool> showTime = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                syncEnabled: syncEnabled,
                archiveMode: archiveMode,
                devMode: devMode,
                showContactName: showContactName,
                showPhoneNumber: showPhoneNumber,
                showCallType: showCallType,
                showDuration: showDuration,
                showDate: showDate,
                showTime: showTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$CallDetailsTableCreateCompanionBuilder =
    CallDetailsCompanion Function({
      Value<int> id,
      required int callId,
      Value<String?> note,
      Value<int?> reminderAt,
      Value<String?> reminderLabel,
    });
typedef $$CallDetailsTableUpdateCompanionBuilder =
    CallDetailsCompanion Function({
      Value<int> id,
      Value<int> callId,
      Value<String?> note,
      Value<int?> reminderAt,
      Value<String?> reminderLabel,
    });

final class $$CallDetailsTableReferences
    extends BaseReferences<_$AppDatabase, $CallDetailsTable, CallDetail> {
  $$CallDetailsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CallsTable _callIdTable(_$AppDatabase db) =>
      db.calls.createAlias('call_details__call_id__calls__id');

  $$CallsTableProcessedTableManager get callId {
    final $_column = $_itemColumn<int>('call_id')!;

    final manager = $$CallsTableTableManager(
      $_db,
      $_db.calls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_callIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CallDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $CallDetailsTable> {
  $$CallDetailsTableFilterComposer({
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

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderLabel => $composableBuilder(
    column: $table.reminderLabel,
    builder: (column) => ColumnFilters(column),
  );

  $$CallsTableFilterComposer get callId {
    final $$CallsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableFilterComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallDetailsTable> {
  $$CallDetailsTableOrderingComposer({
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

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderLabel => $composableBuilder(
    column: $table.reminderLabel,
    builder: (column) => ColumnOrderings(column),
  );

  $$CallsTableOrderingComposer get callId {
    final $$CallsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableOrderingComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallDetailsTable> {
  $$CallDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderLabel => $composableBuilder(
    column: $table.reminderLabel,
    builder: (column) => column,
  );

  $$CallsTableAnnotationComposer get callId {
    final $$CallsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableAnnotationComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallDetailsTable,
          CallDetail,
          $$CallDetailsTableFilterComposer,
          $$CallDetailsTableOrderingComposer,
          $$CallDetailsTableAnnotationComposer,
          $$CallDetailsTableCreateCompanionBuilder,
          $$CallDetailsTableUpdateCompanionBuilder,
          (CallDetail, $$CallDetailsTableReferences),
          CallDetail,
          PrefetchHooks Function({bool callId})
        > {
  $$CallDetailsTableTableManager(_$AppDatabase db, $CallDetailsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> callId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> reminderAt = const Value.absent(),
                Value<String?> reminderLabel = const Value.absent(),
              }) => CallDetailsCompanion(
                id: id,
                callId: callId,
                note: note,
                reminderAt: reminderAt,
                reminderLabel: reminderLabel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int callId,
                Value<String?> note = const Value.absent(),
                Value<int?> reminderAt = const Value.absent(),
                Value<String?> reminderLabel = const Value.absent(),
              }) => CallDetailsCompanion.insert(
                id: id,
                callId: callId,
                note: note,
                reminderAt: reminderAt,
                reminderLabel: reminderLabel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallDetailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({callId = false}) {
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
                    if (callId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.callId,
                                referencedTable: $$CallDetailsTableReferences
                                    ._callIdTable(db),
                                referencedColumn: $$CallDetailsTableReferences
                                    ._callIdTable(db)
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

typedef $$CallDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallDetailsTable,
      CallDetail,
      $$CallDetailsTableFilterComposer,
      $$CallDetailsTableOrderingComposer,
      $$CallDetailsTableAnnotationComposer,
      $$CallDetailsTableCreateCompanionBuilder,
      $$CallDetailsTableUpdateCompanionBuilder,
      (CallDetail, $$CallDetailsTableReferences),
      CallDetail,
      PrefetchHooks Function({bool callId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CallTagsTable, List<CallTag>> _callTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.callTags,
    aliasName: 'tags__id__call_tags__tag_id',
  );

  $$CallTagsTableProcessedTableManager get callTagsRefs {
    final manager = $$CallTagsTableTableManager(
      $_db,
      $_db.callTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_callTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> callTagsRefs(
    Expression<bool> Function($$CallTagsTableFilterComposer f) f,
  ) {
    final $$CallTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallTagsTableFilterComposer(
            $db: $db,
            $table: $db.callTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> callTagsRefs<T extends Object>(
    Expression<T> Function($$CallTagsTableAnnotationComposer a) f,
  ) {
    final $$CallTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.callTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool callTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({callTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (callTagsRefs) db.callTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (callTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, CallTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._callTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).callTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool callTagsRefs})
    >;
typedef $$CallTagsTableCreateCompanionBuilder =
    CallTagsCompanion Function({
      required int callId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$CallTagsTableUpdateCompanionBuilder =
    CallTagsCompanion Function({
      Value<int> callId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$CallTagsTableReferences
    extends BaseReferences<_$AppDatabase, $CallTagsTable, CallTag> {
  $$CallTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CallsTable _callIdTable(_$AppDatabase db) =>
      db.calls.createAlias('call_tags__call_id__calls__id');

  $$CallsTableProcessedTableManager get callId {
    final $_column = $_itemColumn<int>('call_id')!;

    final manager = $$CallsTableTableManager(
      $_db,
      $_db.calls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_callIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('call_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CallTagsTableFilterComposer
    extends Composer<_$AppDatabase, $CallTagsTable> {
  $$CallTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CallsTableFilterComposer get callId {
    final $$CallsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableFilterComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallTagsTable> {
  $$CallTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CallsTableOrderingComposer get callId {
    final $$CallsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableOrderingComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallTagsTable> {
  $$CallTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CallsTableAnnotationComposer get callId {
    final $$CallsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableAnnotationComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallTagsTable,
          CallTag,
          $$CallTagsTableFilterComposer,
          $$CallTagsTableOrderingComposer,
          $$CallTagsTableAnnotationComposer,
          $$CallTagsTableCreateCompanionBuilder,
          $$CallTagsTableUpdateCompanionBuilder,
          (CallTag, $$CallTagsTableReferences),
          CallTag,
          PrefetchHooks Function({bool callId, bool tagId})
        > {
  $$CallTagsTableTableManager(_$AppDatabase db, $CallTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> callId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  CallTagsCompanion(callId: callId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required int callId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => CallTagsCompanion.insert(
                callId: callId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({callId = false, tagId = false}) {
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
                    if (callId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.callId,
                                referencedTable: $$CallTagsTableReferences
                                    ._callIdTable(db),
                                referencedColumn: $$CallTagsTableReferences
                                    ._callIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$CallTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$CallTagsTableReferences
                                    ._tagIdTable(db)
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

typedef $$CallTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallTagsTable,
      CallTag,
      $$CallTagsTableFilterComposer,
      $$CallTagsTableOrderingComposer,
      $$CallTagsTableAnnotationComposer,
      $$CallTagsTableCreateCompanionBuilder,
      $$CallTagsTableUpdateCompanionBuilder,
      (CallTag, $$CallTagsTableReferences),
      CallTag,
      PrefetchHooks Function({bool callId, bool tagId})
    >;
typedef $$CallAttachmentsTableCreateCompanionBuilder =
    CallAttachmentsCompanion Function({
      Value<int> id,
      required int callId,
      required String filePath,
      required String originalFileName,
      required String fileType,
      required int addedAt,
    });
typedef $$CallAttachmentsTableUpdateCompanionBuilder =
    CallAttachmentsCompanion Function({
      Value<int> id,
      Value<int> callId,
      Value<String> filePath,
      Value<String> originalFileName,
      Value<String> fileType,
      Value<int> addedAt,
    });

final class $$CallAttachmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CallAttachmentsTable, CallAttachment> {
  $$CallAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CallsTable _callIdTable(_$AppDatabase db) =>
      db.calls.createAlias('call_attachments__call_id__calls__id');

  $$CallsTableProcessedTableManager get callId {
    final $_column = $_itemColumn<int>('call_id')!;

    final manager = $$CallsTableTableManager(
      $_db,
      $_db.calls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_callIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CallAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CallAttachmentsTable> {
  $$CallAttachmentsTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CallsTableFilterComposer get callId {
    final $$CallsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableFilterComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallAttachmentsTable> {
  $$CallAttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CallsTableOrderingComposer get callId {
    final $$CallsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableOrderingComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallAttachmentsTable> {
  $$CallAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$CallsTableAnnotationComposer get callId {
    final $$CallsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableAnnotationComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallAttachmentsTable,
          CallAttachment,
          $$CallAttachmentsTableFilterComposer,
          $$CallAttachmentsTableOrderingComposer,
          $$CallAttachmentsTableAnnotationComposer,
          $$CallAttachmentsTableCreateCompanionBuilder,
          $$CallAttachmentsTableUpdateCompanionBuilder,
          (CallAttachment, $$CallAttachmentsTableReferences),
          CallAttachment,
          PrefetchHooks Function({bool callId})
        > {
  $$CallAttachmentsTableTableManager(
    _$AppDatabase db,
    $CallAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> callId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> originalFileName = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
              }) => CallAttachmentsCompanion(
                id: id,
                callId: callId,
                filePath: filePath,
                originalFileName: originalFileName,
                fileType: fileType,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int callId,
                required String filePath,
                required String originalFileName,
                required String fileType,
                required int addedAt,
              }) => CallAttachmentsCompanion.insert(
                id: id,
                callId: callId,
                filePath: filePath,
                originalFileName: originalFileName,
                fileType: fileType,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({callId = false}) {
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
                    if (callId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.callId,
                                referencedTable:
                                    $$CallAttachmentsTableReferences
                                        ._callIdTable(db),
                                referencedColumn:
                                    $$CallAttachmentsTableReferences
                                        ._callIdTable(db)
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

typedef $$CallAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallAttachmentsTable,
      CallAttachment,
      $$CallAttachmentsTableFilterComposer,
      $$CallAttachmentsTableOrderingComposer,
      $$CallAttachmentsTableAnnotationComposer,
      $$CallAttachmentsTableCreateCompanionBuilder,
      $$CallAttachmentsTableUpdateCompanionBuilder,
      (CallAttachment, $$CallAttachmentsTableReferences),
      CallAttachment,
      PrefetchHooks Function({bool callId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CallsTableTableManager get calls =>
      $$CallsTableTableManager(_db, _db.calls);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CallDetailsTableTableManager get callDetails =>
      $$CallDetailsTableTableManager(_db, _db.callDetails);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$CallTagsTableTableManager get callTags =>
      $$CallTagsTableTableManager(_db, _db.callTags);
  $$CallAttachmentsTableTableManager get callAttachments =>
      $$CallAttachmentsTableTableManager(_db, _db.callAttachments);
}
