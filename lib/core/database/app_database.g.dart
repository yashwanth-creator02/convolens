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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CallsTable calls = $CallsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [calls, settings];
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
          (Call, BaseReferences<_$AppDatabase, $CallsTable, Call>),
          Call,
          PrefetchHooks Function()
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (Call, BaseReferences<_$AppDatabase, $CallsTable, Call>),
      Call,
      PrefetchHooks Function()
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CallsTableTableManager get calls =>
      $$CallsTableTableManager(_db, _db.calls);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
