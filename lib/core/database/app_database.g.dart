// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContactsTableTable extends ContactsTable
    with TableInfo<$ContactsTableTable, ContactsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBlockedMeta = const VerificationMeta(
    'isBlocked',
  );
  @override
  late final GeneratedColumn<bool> isBlocked = GeneratedColumn<bool>(
    'is_blocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_blocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    publicKey,
    avatar,
    isBlocked,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('is_blocked')) {
      context.handle(
        _isBlockedMeta,
        isBlocked.isAcceptableOrUnknown(data['is_blocked']!, _isBlockedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      isBlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_blocked'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContactsTableTable createAlias(String alias) {
    return $ContactsTableTable(attachedDatabase, alias);
  }
}

class ContactsTableData extends DataClass
    implements Insertable<ContactsTableData> {
  /// معرف جهة الاتصال (Primary Key)
  final String id;

  /// اسم جهة الاتصال
  final String name;

  /// المفتاح العام لجهة الاتصال (للتشفير)
  final String? publicKey;

  /// الصورة الشخصية (Base64 encoded)
  final String? avatar;

  /// حالة الحظر (Blocked)
  final bool isBlocked;

  /// تاريخ الإضافة
  final DateTime createdAt;

  /// تاريخ آخر تحديث
  final DateTime updatedAt;
  const ContactsTableData({
    required this.id,
    required this.name,
    this.publicKey,
    this.avatar,
    required this.isBlocked,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    map['is_blocked'] = Variable<bool>(isBlocked);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContactsTableCompanion toCompanion(bool nullToAbsent) {
    return ContactsTableCompanion(
      id: Value(id),
      name: Value(name),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      isBlocked: Value(isBlocked),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContactsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      isBlocked: serializer.fromJson<bool>(json['isBlocked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'publicKey': serializer.toJson<String?>(publicKey),
      'avatar': serializer.toJson<String?>(avatar),
      'isBlocked': serializer.toJson<bool>(isBlocked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContactsTableData copyWith({
    String? id,
    String? name,
    Value<String?> publicKey = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ContactsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    publicKey: publicKey.present ? publicKey.value : this.publicKey,
    avatar: avatar.present ? avatar.value : this.avatar,
    isBlocked: isBlocked ?? this.isBlocked,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContactsTableData copyWithCompanion(ContactsTableCompanion data) {
    return ContactsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      isBlocked: data.isBlocked.present ? data.isBlocked.value : this.isBlocked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('publicKey: $publicKey, ')
          ..write('avatar: $avatar, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, publicKey, avatar, isBlocked, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.publicKey == this.publicKey &&
          other.avatar == this.avatar &&
          other.isBlocked == this.isBlocked &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContactsTableCompanion extends UpdateCompanion<ContactsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> publicKey;
  final Value<String?> avatar;
  final Value<bool> isBlocked;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ContactsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.avatar = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsTableCompanion.insert({
    required String id,
    required String name,
    this.publicKey = const Value.absent(),
    this.avatar = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ContactsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? publicKey,
    Expression<String>? avatar,
    Expression<bool>? isBlocked,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (publicKey != null) 'public_key': publicKey,
      if (avatar != null) 'avatar': avatar,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? publicKey,
    Value<String?>? avatar,
    Value<bool>? isBlocked,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContactsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      avatar: avatar ?? this.avatar,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (isBlocked.present) {
      map['is_blocked'] = Variable<bool>(isBlocked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('publicKey: $publicKey, ')
          ..write('avatar: $avatar, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatsTableTable extends ChatsTable
    with TableInfo<$ChatsTableTable, ChatsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
    'peer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts_table (id)',
    ),
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
  static const VerificationMeta _lastMessageMeta = const VerificationMeta(
    'lastMessage',
  );
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
    'last_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isGroupMeta = const VerificationMeta(
    'isGroup',
  );
  @override
  late final GeneratedColumn<bool> isGroup = GeneratedColumn<bool>(
    'is_group',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<int> avatarColor = GeneratedColumn<int>(
    'avatar_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF0D9488),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerId,
    name,
    lastMessage,
    lastUpdated,
    isGroup,
    memberCount,
    avatarColor,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('last_message')) {
      context.handle(
        _lastMessageMeta,
        lastMessage.isAcceptableOrUnknown(
          data['last_message']!,
          _lastMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('is_group')) {
      context.handle(
        _isGroupMeta,
        isGroup.isAcceptableOrUnknown(data['is_group']!, _isGroupMeta),
      );
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      lastMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message'],
      ),
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
      isGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      ),
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatsTableTable createAlias(String alias) {
    return $ChatsTableTable(attachedDatabase, alias);
  }
}

class ChatsTableData extends DataClass implements Insertable<ChatsTableData> {
  /// معرف المحادثة (Primary Key)
  final String id;

  /// معرف جهة الاتصال (Foreign Key -> ContactsTable.id)
  /// null إذا كانت المحادثة جماعية
  final String? peerId;

  /// اسم المحادثة (للمجموعات)
  final String? name;

  /// آخر رسالة في المحادثة
  final String? lastMessage;

  /// تاريخ آخر تحديث
  final DateTime lastUpdated;

  /// هل المحادثة جماعية؟
  final bool isGroup;

  /// عدد الأعضاء (للمجموعات)
  final int? memberCount;

  /// لون الصورة الشخصية (للمجموعات)
  final int avatarColor;

  /// تاريخ الإنشاء
  final DateTime createdAt;
  const ChatsTableData({
    required this.id,
    this.peerId,
    this.name,
    this.lastMessage,
    required this.lastUpdated,
    required this.isGroup,
    this.memberCount,
    required this.avatarColor,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || peerId != null) {
      map['peer_id'] = Variable<String>(peerId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<String>(lastMessage);
    }
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    map['is_group'] = Variable<bool>(isGroup);
    if (!nullToAbsent || memberCount != null) {
      map['member_count'] = Variable<int>(memberCount);
    }
    map['avatar_color'] = Variable<int>(avatarColor);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatsTableCompanion toCompanion(bool nullToAbsent) {
    return ChatsTableCompanion(
      id: Value(id),
      peerId: peerId == null && nullToAbsent
          ? const Value.absent()
          : Value(peerId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      lastUpdated: Value(lastUpdated),
      isGroup: Value(isGroup),
      memberCount: memberCount == null && nullToAbsent
          ? const Value.absent()
          : Value(memberCount),
      avatarColor: Value(avatarColor),
      createdAt: Value(createdAt),
    );
  }

  factory ChatsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatsTableData(
      id: serializer.fromJson<String>(json['id']),
      peerId: serializer.fromJson<String?>(json['peerId']),
      name: serializer.fromJson<String?>(json['name']),
      lastMessage: serializer.fromJson<String?>(json['lastMessage']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
      isGroup: serializer.fromJson<bool>(json['isGroup']),
      memberCount: serializer.fromJson<int?>(json['memberCount']),
      avatarColor: serializer.fromJson<int>(json['avatarColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'peerId': serializer.toJson<String?>(peerId),
      'name': serializer.toJson<String?>(name),
      'lastMessage': serializer.toJson<String?>(lastMessage),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
      'isGroup': serializer.toJson<bool>(isGroup),
      'memberCount': serializer.toJson<int?>(memberCount),
      'avatarColor': serializer.toJson<int>(avatarColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatsTableData copyWith({
    String? id,
    Value<String?> peerId = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> lastMessage = const Value.absent(),
    DateTime? lastUpdated,
    bool? isGroup,
    Value<int?> memberCount = const Value.absent(),
    int? avatarColor,
    DateTime? createdAt,
  }) => ChatsTableData(
    id: id ?? this.id,
    peerId: peerId.present ? peerId.value : this.peerId,
    name: name.present ? name.value : this.name,
    lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    isGroup: isGroup ?? this.isGroup,
    memberCount: memberCount.present ? memberCount.value : this.memberCount,
    avatarColor: avatarColor ?? this.avatarColor,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatsTableData copyWithCompanion(ChatsTableCompanion data) {
    return ChatsTableData(
      id: data.id.present ? data.id.value : this.id,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      name: data.name.present ? data.name.value : this.name,
      lastMessage: data.lastMessage.present
          ? data.lastMessage.value
          : this.lastMessage,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      isGroup: data.isGroup.present ? data.isGroup.value : this.isGroup,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatsTableData(')
          ..write('id: $id, ')
          ..write('peerId: $peerId, ')
          ..write('name: $name, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('isGroup: $isGroup, ')
          ..write('memberCount: $memberCount, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    peerId,
    name,
    lastMessage,
    lastUpdated,
    isGroup,
    memberCount,
    avatarColor,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatsTableData &&
          other.id == this.id &&
          other.peerId == this.peerId &&
          other.name == this.name &&
          other.lastMessage == this.lastMessage &&
          other.lastUpdated == this.lastUpdated &&
          other.isGroup == this.isGroup &&
          other.memberCount == this.memberCount &&
          other.avatarColor == this.avatarColor &&
          other.createdAt == this.createdAt);
}

class ChatsTableCompanion extends UpdateCompanion<ChatsTableData> {
  final Value<String> id;
  final Value<String?> peerId;
  final Value<String?> name;
  final Value<String?> lastMessage;
  final Value<DateTime> lastUpdated;
  final Value<bool> isGroup;
  final Value<int?> memberCount;
  final Value<int> avatarColor;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatsTableCompanion({
    this.id = const Value.absent(),
    this.peerId = const Value.absent(),
    this.name = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatsTableCompanion.insert({
    required String id,
    this.peerId = const Value.absent(),
    this.name = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ChatsTableData> custom({
    Expression<String>? id,
    Expression<String>? peerId,
    Expression<String>? name,
    Expression<String>? lastMessage,
    Expression<DateTime>? lastUpdated,
    Expression<bool>? isGroup,
    Expression<int>? memberCount,
    Expression<int>? avatarColor,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerId != null) 'peer_id': peerId,
      if (name != null) 'name': name,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (isGroup != null) 'is_group': isGroup,
      if (memberCount != null) 'member_count': memberCount,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? peerId,
    Value<String?>? name,
    Value<String?>? lastMessage,
    Value<DateTime>? lastUpdated,
    Value<bool>? isGroup,
    Value<int?>? memberCount,
    Value<int>? avatarColor,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatsTableCompanion(
      id: id ?? this.id,
      peerId: peerId ?? this.peerId,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isGroup: isGroup ?? this.isGroup,
      memberCount: memberCount ?? this.memberCount,
      avatarColor: avatarColor ?? this.avatarColor,
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
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (isGroup.present) {
      map['is_group'] = Variable<bool>(isGroup.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<int>(avatarColor.value);
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
    return (StringBuffer('ChatsTableCompanion(')
          ..write('id: $id, ')
          ..write('peerId: $peerId, ')
          ..write('name: $name, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('isGroup: $isGroup, ')
          ..write('memberCount: $memberCount, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTableTable extends MessagesTable
    with TableInfo<$MessagesTableTable, MessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chats_table (id)',
    ),
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sending'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isFromMeMeta = const VerificationMeta(
    'isFromMe',
  );
  @override
  late final GeneratedColumn<bool> isFromMe = GeneratedColumn<bool>(
    'is_from_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_from_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _replyToIdMeta = const VerificationMeta(
    'replyToId',
  );
  @override
  late final GeneratedColumn<String> replyToId = GeneratedColumn<String>(
    'reply_to_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chatId,
    senderId,
    content,
    type,
    status,
    timestamp,
    isFromMe,
    replyToId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('is_from_me')) {
      context.handle(
        _isFromMeMeta,
        isFromMe.isAcceptableOrUnknown(data['is_from_me']!, _isFromMeMeta),
      );
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
        _replyToIdMeta,
        replyToId.isAcceptableOrUnknown(data['reply_to_id']!, _replyToIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      isFromMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_from_me'],
      )!,
      replyToId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_id'],
      ),
    );
  }

  @override
  $MessagesTableTable createAlias(String alias) {
    return $MessagesTableTable(attachedDatabase, alias);
  }
}

class MessagesTableData extends DataClass
    implements Insertable<MessagesTableData> {
  /// معرف الرسالة (Primary Key)
  final String id;

  /// معرف المحادثة (Foreign Key -> ChatsTable.id)
  final String chatId;

  /// معرف المرسل
  final String senderId;

  /// محتوى الرسالة (مشفّر)
  final String content;

  /// نوع الرسالة (text, image, voice, file)
  final String type;

  /// حالة الرسالة (sending, sent, delivered, read, failed)
  final String status;

  /// الطابع الزمني
  final DateTime timestamp;

  /// هل الرسالة من المستخدم الحالي؟
  final bool isFromMe;

  /// معرف الرسالة المرجعية (للرد على رسالة)
  final String? replyToId;
  const MessagesTableData({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.isFromMe,
    this.replyToId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chat_id'] = Variable<String>(chatId);
    map['sender_id'] = Variable<String>(senderId);
    map['content'] = Variable<String>(content);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_from_me'] = Variable<bool>(isFromMe);
    if (!nullToAbsent || replyToId != null) {
      map['reply_to_id'] = Variable<String>(replyToId);
    }
    return map;
  }

  MessagesTableCompanion toCompanion(bool nullToAbsent) {
    return MessagesTableCompanion(
      id: Value(id),
      chatId: Value(chatId),
      senderId: Value(senderId),
      content: Value(content),
      type: Value(type),
      status: Value(status),
      timestamp: Value(timestamp),
      isFromMe: Value(isFromMe),
      replyToId: replyToId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToId),
    );
  }

  factory MessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTableData(
      id: serializer.fromJson<String>(json['id']),
      chatId: serializer.fromJson<String>(json['chatId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String>(json['content']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isFromMe: serializer.fromJson<bool>(json['isFromMe']),
      replyToId: serializer.fromJson<String?>(json['replyToId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chatId': serializer.toJson<String>(chatId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String>(content),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isFromMe': serializer.toJson<bool>(isFromMe),
      'replyToId': serializer.toJson<String?>(replyToId),
    };
  }

  MessagesTableData copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? type,
    String? status,
    DateTime? timestamp,
    bool? isFromMe,
    Value<String?> replyToId = const Value.absent(),
  }) => MessagesTableData(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    type: type ?? this.type,
    status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp,
    isFromMe: isFromMe ?? this.isFromMe,
    replyToId: replyToId.present ? replyToId.value : this.replyToId,
  );
  MessagesTableData copyWithCompanion(MessagesTableCompanion data) {
    return MessagesTableData(
      id: data.id.present ? data.id.value : this.id,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isFromMe: data.isFromMe.present ? data.isFromMe.value : this.isFromMe,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableData(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('replyToId: $replyToId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chatId,
    senderId,
    content,
    type,
    status,
    timestamp,
    isFromMe,
    replyToId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTableData &&
          other.id == this.id &&
          other.chatId == this.chatId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.type == this.type &&
          other.status == this.status &&
          other.timestamp == this.timestamp &&
          other.isFromMe == this.isFromMe &&
          other.replyToId == this.replyToId);
}

class MessagesTableCompanion extends UpdateCompanion<MessagesTableData> {
  final Value<String> id;
  final Value<String> chatId;
  final Value<String> senderId;
  final Value<String> content;
  final Value<String> type;
  final Value<String> status;
  final Value<DateTime> timestamp;
  final Value<bool> isFromMe;
  final Value<String?> replyToId;
  final Value<int> rowid;
  const MessagesTableCompanion({
    this.id = const Value.absent(),
    this.chatId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesTableCompanion.insert({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chatId = Value(chatId),
       senderId = Value(senderId),
       content = Value(content);
  static Insertable<MessagesTableData> custom({
    Expression<String>? id,
    Expression<String>? chatId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<String>? type,
    Expression<String>? status,
    Expression<DateTime>? timestamp,
    Expression<bool>? isFromMe,
    Expression<String>? replyToId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (isFromMe != null) 'is_from_me': isFromMe,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? chatId,
    Value<String>? senderId,
    Value<String>? content,
    Value<String>? type,
    Value<String>? status,
    Value<DateTime>? timestamp,
    Value<bool>? isFromMe,
    Value<String?>? replyToId,
    Value<int>? rowid,
  }) {
    return MessagesTableCompanion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      replyToId: replyToId ?? this.replyToId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isFromMe.present) {
      map['is_from_me'] = Variable<bool>(isFromMe.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<String>(replyToId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('replyToId: $replyToId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelayQueueTableTable extends RelayQueueTable
    with TableInfo<$RelayQueueTableTable, RelayQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelayQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalSenderIdMeta = const VerificationMeta(
    'originalSenderId',
  );
  @override
  late final GeneratedColumn<String> originalSenderId = GeneratedColumn<String>(
    'original_sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalDestinationIdMeta =
      const VerificationMeta('finalDestinationId');
  @override
  late final GeneratedColumn<String> finalDestinationId =
      GeneratedColumn<String>(
        'final_destination_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedContentMeta = const VerificationMeta(
    'encryptedContent',
  );
  @override
  late final GeneratedColumn<String> encryptedContent = GeneratedColumn<String>(
    'encrypted_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hopCountMeta = const VerificationMeta(
    'hopCount',
  );
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
    'hop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxHopsMeta = const VerificationMeta(
    'maxHops',
  );
  @override
  late final GeneratedColumn<int> maxHops = GeneratedColumn<int>(
    'max_hops',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _traceMeta = const VerificationMeta('trace');
  @override
  late final GeneratedColumn<String> trace = GeneratedColumn<String>(
    'trace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastRetryAtMeta = const VerificationMeta(
    'lastRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRetryAt = GeneratedColumn<DateTime>(
    'last_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    originalSenderId,
    finalDestinationId,
    encryptedContent,
    hopCount,
    maxHops,
    trace,
    timestamp,
    type,
    metadata,
    queuedAt,
    retryCount,
    lastRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relay_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RelayQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('original_sender_id')) {
      context.handle(
        _originalSenderIdMeta,
        originalSenderId.isAcceptableOrUnknown(
          data['original_sender_id']!,
          _originalSenderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalSenderIdMeta);
    }
    if (data.containsKey('final_destination_id')) {
      context.handle(
        _finalDestinationIdMeta,
        finalDestinationId.isAcceptableOrUnknown(
          data['final_destination_id']!,
          _finalDestinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finalDestinationIdMeta);
    }
    if (data.containsKey('encrypted_content')) {
      context.handle(
        _encryptedContentMeta,
        encryptedContent.isAcceptableOrUnknown(
          data['encrypted_content']!,
          _encryptedContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedContentMeta);
    }
    if (data.containsKey('hop_count')) {
      context.handle(
        _hopCountMeta,
        hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta),
      );
    }
    if (data.containsKey('max_hops')) {
      context.handle(
        _maxHopsMeta,
        maxHops.isAcceptableOrUnknown(data['max_hops']!, _maxHopsMeta),
      );
    }
    if (data.containsKey('trace')) {
      context.handle(
        _traceMeta,
        trace.isAcceptableOrUnknown(data['trace']!, _traceMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_retry_at')) {
      context.handle(
        _lastRetryAtMeta,
        lastRetryAt.isAcceptableOrUnknown(
          data['last_retry_at']!,
          _lastRetryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  RelayQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelayQueueTableData(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      originalSenderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_sender_id'],
      )!,
      finalDestinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_destination_id'],
      )!,
      encryptedContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_content'],
      )!,
      hopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hop_count'],
      )!,
      maxHops: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_hops'],
      )!,
      trace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trace'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_retry_at'],
      ),
    );
  }

  @override
  $RelayQueueTableTable createAlias(String alias) {
    return $RelayQueueTableTable(attachedDatabase, alias);
  }
}

class RelayQueueTableData extends DataClass
    implements Insertable<RelayQueueTableData> {
  /// معرف فريد للرسالة (Primary Key)
  /// يستخدم messageId من MeshMessage
  final String messageId;

  /// معرف المرسل الأصلي
  final String originalSenderId;

  /// معرف الوجهة النهائية
  final String finalDestinationId;

  /// المحتوى المشفر (Base64) - لا يتم فك التشفير هنا
  final String encryptedContent;

  /// عدد القفزات الحالي
  final int hopCount;

  /// الحد الأقصى للقفزات (TTL)
  final int maxHops;

  /// قائمة معرفات الأجهزة التي مرت بها الرسالة (JSON array)
  final String trace;

  /// الطابع الزمني للرسالة الأصلية
  final DateTime timestamp;

  /// نوع الرسالة (message, friend_added, etc.)
  final String? type;

  /// بيانات إضافية (JSON)
  final String? metadata;

  /// تاريخ إضافة الرسالة إلى قائمة الانتظار
  final DateTime queuedAt;

  /// عدد المحاولات لإرسال الرسالة
  final int retryCount;

  /// آخر محاولة إرسال
  final DateTime? lastRetryAt;
  const RelayQueueTableData({
    required this.messageId,
    required this.originalSenderId,
    required this.finalDestinationId,
    required this.encryptedContent,
    required this.hopCount,
    required this.maxHops,
    required this.trace,
    required this.timestamp,
    this.type,
    this.metadata,
    required this.queuedAt,
    required this.retryCount,
    this.lastRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['original_sender_id'] = Variable<String>(originalSenderId);
    map['final_destination_id'] = Variable<String>(finalDestinationId);
    map['encrypted_content'] = Variable<String>(encryptedContent);
    map['hop_count'] = Variable<int>(hopCount);
    map['max_hops'] = Variable<int>(maxHops);
    map['trace'] = Variable<String>(trace);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt);
    }
    return map;
  }

  RelayQueueTableCompanion toCompanion(bool nullToAbsent) {
    return RelayQueueTableCompanion(
      messageId: Value(messageId),
      originalSenderId: Value(originalSenderId),
      finalDestinationId: Value(finalDestinationId),
      encryptedContent: Value(encryptedContent),
      hopCount: Value(hopCount),
      maxHops: Value(maxHops),
      trace: Value(trace),
      timestamp: Value(timestamp),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      queuedAt: Value(queuedAt),
      retryCount: Value(retryCount),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
    );
  }

  factory RelayQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelayQueueTableData(
      messageId: serializer.fromJson<String>(json['messageId']),
      originalSenderId: serializer.fromJson<String>(json['originalSenderId']),
      finalDestinationId: serializer.fromJson<String>(
        json['finalDestinationId'],
      ),
      encryptedContent: serializer.fromJson<String>(json['encryptedContent']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
      maxHops: serializer.fromJson<int>(json['maxHops']),
      trace: serializer.fromJson<String>(json['trace']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      type: serializer.fromJson<String?>(json['type']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetryAt: serializer.fromJson<DateTime?>(json['lastRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'originalSenderId': serializer.toJson<String>(originalSenderId),
      'finalDestinationId': serializer.toJson<String>(finalDestinationId),
      'encryptedContent': serializer.toJson<String>(encryptedContent),
      'hopCount': serializer.toJson<int>(hopCount),
      'maxHops': serializer.toJson<int>(maxHops),
      'trace': serializer.toJson<String>(trace),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'type': serializer.toJson<String?>(type),
      'metadata': serializer.toJson<String?>(metadata),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetryAt': serializer.toJson<DateTime?>(lastRetryAt),
    };
  }

  RelayQueueTableData copyWith({
    String? messageId,
    String? originalSenderId,
    String? finalDestinationId,
    String? encryptedContent,
    int? hopCount,
    int? maxHops,
    String? trace,
    DateTime? timestamp,
    Value<String?> type = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    DateTime? queuedAt,
    int? retryCount,
    Value<DateTime?> lastRetryAt = const Value.absent(),
  }) => RelayQueueTableData(
    messageId: messageId ?? this.messageId,
    originalSenderId: originalSenderId ?? this.originalSenderId,
    finalDestinationId: finalDestinationId ?? this.finalDestinationId,
    encryptedContent: encryptedContent ?? this.encryptedContent,
    hopCount: hopCount ?? this.hopCount,
    maxHops: maxHops ?? this.maxHops,
    trace: trace ?? this.trace,
    timestamp: timestamp ?? this.timestamp,
    type: type.present ? type.value : this.type,
    metadata: metadata.present ? metadata.value : this.metadata,
    queuedAt: queuedAt ?? this.queuedAt,
    retryCount: retryCount ?? this.retryCount,
    lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
  );
  RelayQueueTableData copyWithCompanion(RelayQueueTableCompanion data) {
    return RelayQueueTableData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      originalSenderId: data.originalSenderId.present
          ? data.originalSenderId.value
          : this.originalSenderId,
      finalDestinationId: data.finalDestinationId.present
          ? data.finalDestinationId.value
          : this.finalDestinationId,
      encryptedContent: data.encryptedContent.present
          ? data.encryptedContent.value
          : this.encryptedContent,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
      maxHops: data.maxHops.present ? data.maxHops.value : this.maxHops,
      trace: data.trace.present ? data.trace.value : this.trace,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      type: data.type.present ? data.type.value : this.type,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastRetryAt: data.lastRetryAt.present
          ? data.lastRetryAt.value
          : this.lastRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelayQueueTableData(')
          ..write('messageId: $messageId, ')
          ..write('originalSenderId: $originalSenderId, ')
          ..write('finalDestinationId: $finalDestinationId, ')
          ..write('encryptedContent: $encryptedContent, ')
          ..write('hopCount: $hopCount, ')
          ..write('maxHops: $maxHops, ')
          ..write('trace: $trace, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('metadata: $metadata, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    originalSenderId,
    finalDestinationId,
    encryptedContent,
    hopCount,
    maxHops,
    trace,
    timestamp,
    type,
    metadata,
    queuedAt,
    retryCount,
    lastRetryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelayQueueTableData &&
          other.messageId == this.messageId &&
          other.originalSenderId == this.originalSenderId &&
          other.finalDestinationId == this.finalDestinationId &&
          other.encryptedContent == this.encryptedContent &&
          other.hopCount == this.hopCount &&
          other.maxHops == this.maxHops &&
          other.trace == this.trace &&
          other.timestamp == this.timestamp &&
          other.type == this.type &&
          other.metadata == this.metadata &&
          other.queuedAt == this.queuedAt &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt);
}

class RelayQueueTableCompanion extends UpdateCompanion<RelayQueueTableData> {
  final Value<String> messageId;
  final Value<String> originalSenderId;
  final Value<String> finalDestinationId;
  final Value<String> encryptedContent;
  final Value<int> hopCount;
  final Value<int> maxHops;
  final Value<String> trace;
  final Value<DateTime> timestamp;
  final Value<String?> type;
  final Value<String?> metadata;
  final Value<DateTime> queuedAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetryAt;
  final Value<int> rowid;
  const RelayQueueTableCompanion({
    this.messageId = const Value.absent(),
    this.originalSenderId = const Value.absent(),
    this.finalDestinationId = const Value.absent(),
    this.encryptedContent = const Value.absent(),
    this.hopCount = const Value.absent(),
    this.maxHops = const Value.absent(),
    this.trace = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.type = const Value.absent(),
    this.metadata = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelayQueueTableCompanion.insert({
    required String messageId,
    required String originalSenderId,
    required String finalDestinationId,
    required String encryptedContent,
    this.hopCount = const Value.absent(),
    this.maxHops = const Value.absent(),
    this.trace = const Value.absent(),
    required DateTime timestamp,
    this.type = const Value.absent(),
    this.metadata = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       originalSenderId = Value(originalSenderId),
       finalDestinationId = Value(finalDestinationId),
       encryptedContent = Value(encryptedContent),
       timestamp = Value(timestamp);
  static Insertable<RelayQueueTableData> custom({
    Expression<String>? messageId,
    Expression<String>? originalSenderId,
    Expression<String>? finalDestinationId,
    Expression<String>? encryptedContent,
    Expression<int>? hopCount,
    Expression<int>? maxHops,
    Expression<String>? trace,
    Expression<DateTime>? timestamp,
    Expression<String>? type,
    Expression<String>? metadata,
    Expression<DateTime>? queuedAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (originalSenderId != null) 'original_sender_id': originalSenderId,
      if (finalDestinationId != null)
        'final_destination_id': finalDestinationId,
      if (encryptedContent != null) 'encrypted_content': encryptedContent,
      if (hopCount != null) 'hop_count': hopCount,
      if (maxHops != null) 'max_hops': maxHops,
      if (trace != null) 'trace': trace,
      if (timestamp != null) 'timestamp': timestamp,
      if (type != null) 'type': type,
      if (metadata != null) 'metadata': metadata,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelayQueueTableCompanion copyWith({
    Value<String>? messageId,
    Value<String>? originalSenderId,
    Value<String>? finalDestinationId,
    Value<String>? encryptedContent,
    Value<int>? hopCount,
    Value<int>? maxHops,
    Value<String>? trace,
    Value<DateTime>? timestamp,
    Value<String?>? type,
    Value<String?>? metadata,
    Value<DateTime>? queuedAt,
    Value<int>? retryCount,
    Value<DateTime?>? lastRetryAt,
    Value<int>? rowid,
  }) {
    return RelayQueueTableCompanion(
      messageId: messageId ?? this.messageId,
      originalSenderId: originalSenderId ?? this.originalSenderId,
      finalDestinationId: finalDestinationId ?? this.finalDestinationId,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      hopCount: hopCount ?? this.hopCount,
      maxHops: maxHops ?? this.maxHops,
      trace: trace ?? this.trace,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (originalSenderId.present) {
      map['original_sender_id'] = Variable<String>(originalSenderId.value);
    }
    if (finalDestinationId.present) {
      map['final_destination_id'] = Variable<String>(finalDestinationId.value);
    }
    if (encryptedContent.present) {
      map['encrypted_content'] = Variable<String>(encryptedContent.value);
    }
    if (hopCount.present) {
      map['hop_count'] = Variable<int>(hopCount.value);
    }
    if (maxHops.present) {
      map['max_hops'] = Variable<int>(maxHops.value);
    }
    if (trace.present) {
      map['trace'] = Variable<String>(trace.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastRetryAt.present) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelayQueueTableCompanion(')
          ..write('messageId: $messageId, ')
          ..write('originalSenderId: $originalSenderId, ')
          ..write('finalDestinationId: $finalDestinationId, ')
          ..write('encryptedContent: $encryptedContent, ')
          ..write('hopCount: $hopCount, ')
          ..write('maxHops: $maxHops, ')
          ..write('trace: $trace, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('metadata: $metadata, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTableTable contactsTable = $ContactsTableTable(this);
  late final $ChatsTableTable chatsTable = $ChatsTableTable(this);
  late final $MessagesTableTable messagesTable = $MessagesTableTable(this);
  late final $RelayQueueTableTable relayQueueTable = $RelayQueueTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contactsTable,
    chatsTable,
    messagesTable,
    relayQueueTable,
  ];
}

typedef $$ContactsTableTableCreateCompanionBuilder =
    ContactsTableCompanion Function({
      required String id,
      required String name,
      Value<String?> publicKey,
      Value<String?> avatar,
      Value<bool> isBlocked,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ContactsTableTableUpdateCompanionBuilder =
    ContactsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> publicKey,
      Value<String?> avatar,
      Value<bool> isBlocked,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ContactsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ContactsTableTable, ContactsTableData> {
  $$ContactsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ChatsTableTable, List<ChatsTableData>>
  _chatsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatsTable,
    aliasName: $_aliasNameGenerator(db.contactsTable.id, db.chatsTable.peerId),
  );

  $$ChatsTableTableProcessedTableManager get chatsTableRefs {
    final manager = $$ChatsTableTableTableManager(
      $_db,
      $_db.chatsTable,
    ).filter((f) => f.peerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTableTable> {
  $$ContactsTableTableFilterComposer({
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

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBlocked => $composableBuilder(
    column: $table.isBlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> chatsTableRefs(
    Expression<bool> Function($$ChatsTableTableFilterComposer f) f,
  ) {
    final $$ChatsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatsTable,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableTableFilterComposer(
            $db: $db,
            $table: $db.chatsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTableTable> {
  $$ContactsTableTableOrderingComposer({
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

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBlocked => $composableBuilder(
    column: $table.isBlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTableTable> {
  $$ContactsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<bool> get isBlocked =>
      $composableBuilder(column: $table.isBlocked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chatsTableRefs<T extends Object>(
    Expression<T> Function($$ChatsTableTableAnnotationComposer a) f,
  ) {
    final $$ChatsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatsTable,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.chatsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTableTable,
          ContactsTableData,
          $$ContactsTableTableFilterComposer,
          $$ContactsTableTableOrderingComposer,
          $$ContactsTableTableAnnotationComposer,
          $$ContactsTableTableCreateCompanionBuilder,
          $$ContactsTableTableUpdateCompanionBuilder,
          (ContactsTableData, $$ContactsTableTableReferences),
          ContactsTableData,
          PrefetchHooks Function({bool chatsTableRefs})
        > {
  $$ContactsTableTableTableManager(_$AppDatabase db, $ContactsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<bool> isBlocked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsTableCompanion(
                id: id,
                name: name,
                publicKey: publicKey,
                avatar: avatar,
                isBlocked: isBlocked,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> publicKey = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<bool> isBlocked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsTableCompanion.insert(
                id: id,
                name: name,
                publicKey: publicKey,
                avatar: avatar,
                isBlocked: isBlocked,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatsTableRefs) db.chatsTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatsTableRefs)
                    await $_getPrefetchedData<
                      ContactsTableData,
                      $ContactsTableTable,
                      ChatsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ContactsTableTableReferences
                          ._chatsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ContactsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).chatsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.peerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ContactsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTableTable,
      ContactsTableData,
      $$ContactsTableTableFilterComposer,
      $$ContactsTableTableOrderingComposer,
      $$ContactsTableTableAnnotationComposer,
      $$ContactsTableTableCreateCompanionBuilder,
      $$ContactsTableTableUpdateCompanionBuilder,
      (ContactsTableData, $$ContactsTableTableReferences),
      ContactsTableData,
      PrefetchHooks Function({bool chatsTableRefs})
    >;
typedef $$ChatsTableTableCreateCompanionBuilder =
    ChatsTableCompanion Function({
      required String id,
      Value<String?> peerId,
      Value<String?> name,
      Value<String?> lastMessage,
      Value<DateTime> lastUpdated,
      Value<bool> isGroup,
      Value<int?> memberCount,
      Value<int> avatarColor,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ChatsTableTableUpdateCompanionBuilder =
    ChatsTableCompanion Function({
      Value<String> id,
      Value<String?> peerId,
      Value<String?> name,
      Value<String?> lastMessage,
      Value<DateTime> lastUpdated,
      Value<bool> isGroup,
      Value<int?> memberCount,
      Value<int> avatarColor,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ChatsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ChatsTableTable, ChatsTableData> {
  $$ChatsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTableTable _peerIdTable(_$AppDatabase db) =>
      db.contactsTable.createAlias(
        $_aliasNameGenerator(db.chatsTable.peerId, db.contactsTable.id),
      );

  $$ContactsTableTableProcessedTableManager? get peerId {
    final $_column = $_itemColumn<String>('peer_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableTableManager(
      $_db,
      $_db.contactsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_peerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessagesTableTable, List<MessagesTableData>>
  _messagesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messagesTable,
    aliasName: $_aliasNameGenerator(db.chatsTable.id, db.messagesTable.chatId),
  );

  $$MessagesTableTableProcessedTableManager get messagesTableRefs {
    final manager = $$MessagesTableTableTableManager(
      $_db,
      $_db.messagesTable,
    ).filter((f) => f.chatId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChatsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChatsTableTable> {
  $$ChatsTableTableFilterComposer({
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

  ColumnFilters<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContactsTableTableFilterComposer get peerId {
    final $$ContactsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.contactsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableTableFilterComposer(
            $db: $db,
            $table: $db.contactsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messagesTableRefs(
    Expression<bool> Function($$MessagesTableTableFilterComposer f) f,
  ) {
    final $$MessagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messagesTable,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableTableFilterComposer(
            $db: $db,
            $table: $db.messagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTableTable> {
  $$ChatsTableTableOrderingComposer({
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

  ColumnOrderings<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContactsTableTableOrderingComposer get peerId {
    final $$ContactsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.contactsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableTableOrderingComposer(
            $db: $db,
            $table: $db.contactsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTableTable> {
  $$ChatsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGroup =>
      $composableBuilder(column: $table.isGroup, builder: (column) => column);

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ContactsTableTableAnnotationComposer get peerId {
    final $$ContactsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.contactsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.contactsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messagesTableRefs<T extends Object>(
    Expression<T> Function($$MessagesTableTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messagesTable,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.messagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTableTable,
          ChatsTableData,
          $$ChatsTableTableFilterComposer,
          $$ChatsTableTableOrderingComposer,
          $$ChatsTableTableAnnotationComposer,
          $$ChatsTableTableCreateCompanionBuilder,
          $$ChatsTableTableUpdateCompanionBuilder,
          (ChatsTableData, $$ChatsTableTableReferences),
          ChatsTableData,
          PrefetchHooks Function({bool peerId, bool messagesTableRefs})
        > {
  $$ChatsTableTableTableManager(_$AppDatabase db, $ChatsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> peerId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<int?> memberCount = const Value.absent(),
                Value<int> avatarColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsTableCompanion(
                id: id,
                peerId: peerId,
                name: name,
                lastMessage: lastMessage,
                lastUpdated: lastUpdated,
                isGroup: isGroup,
                memberCount: memberCount,
                avatarColor: avatarColor,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> peerId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<int?> memberCount = const Value.absent(),
                Value<int> avatarColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsTableCompanion.insert(
                id: id,
                peerId: peerId,
                name: name,
                lastMessage: lastMessage,
                lastUpdated: lastUpdated,
                isGroup: isGroup,
                memberCount: memberCount,
                avatarColor: avatarColor,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({peerId = false, messagesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (messagesTableRefs) db.messagesTable,
              ],
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
                    if (peerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.peerId,
                                referencedTable: $$ChatsTableTableReferences
                                    ._peerIdTable(db),
                                referencedColumn: $$ChatsTableTableReferences
                                    ._peerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesTableRefs)
                    await $_getPrefetchedData<
                      ChatsTableData,
                      $ChatsTableTable,
                      MessagesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ChatsTableTableReferences
                          ._messagesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChatsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).messagesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.chatId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTableTable,
      ChatsTableData,
      $$ChatsTableTableFilterComposer,
      $$ChatsTableTableOrderingComposer,
      $$ChatsTableTableAnnotationComposer,
      $$ChatsTableTableCreateCompanionBuilder,
      $$ChatsTableTableUpdateCompanionBuilder,
      (ChatsTableData, $$ChatsTableTableReferences),
      ChatsTableData,
      PrefetchHooks Function({bool peerId, bool messagesTableRefs})
    >;
typedef $$MessagesTableTableCreateCompanionBuilder =
    MessagesTableCompanion Function({
      required String id,
      required String chatId,
      required String senderId,
      required String content,
      Value<String> type,
      Value<String> status,
      Value<DateTime> timestamp,
      Value<bool> isFromMe,
      Value<String?> replyToId,
      Value<int> rowid,
    });
typedef $$MessagesTableTableUpdateCompanionBuilder =
    MessagesTableCompanion Function({
      Value<String> id,
      Value<String> chatId,
      Value<String> senderId,
      Value<String> content,
      Value<String> type,
      Value<String> status,
      Value<DateTime> timestamp,
      Value<bool> isFromMe,
      Value<String?> replyToId,
      Value<int> rowid,
    });

final class $$MessagesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $MessagesTableTable, MessagesTableData> {
  $$MessagesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChatsTableTable _chatIdTable(_$AppDatabase db) =>
      db.chatsTable.createAlias(
        $_aliasNameGenerator(db.messagesTable.chatId, db.chatsTable.id),
      );

  $$ChatsTableTableProcessedTableManager get chatId {
    final $_column = $_itemColumn<String>('chat_id')!;

    final manager = $$ChatsTableTableTableManager(
      $_db,
      $_db.chatsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chatIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableFilterComposer({
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

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFromMe => $composableBuilder(
    column: $table.isFromMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatsTableTableFilterComposer get chatId {
    final $$ChatsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chatsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableTableFilterComposer(
            $db: $db,
            $table: $db.chatsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableOrderingComposer({
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

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFromMe => $composableBuilder(
    column: $table.isFromMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatsTableTableOrderingComposer get chatId {
    final $$ChatsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chatsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableTableOrderingComposer(
            $db: $db,
            $table: $db.chatsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isFromMe =>
      $composableBuilder(column: $table.isFromMe, builder: (column) => column);

  GeneratedColumn<String> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  $$ChatsTableTableAnnotationComposer get chatId {
    final $$ChatsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chatsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.chatsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTableTable,
          MessagesTableData,
          $$MessagesTableTableFilterComposer,
          $$MessagesTableTableOrderingComposer,
          $$MessagesTableTableAnnotationComposer,
          $$MessagesTableTableCreateCompanionBuilder,
          $$MessagesTableTableUpdateCompanionBuilder,
          (MessagesTableData, $$MessagesTableTableReferences),
          MessagesTableData,
          PrefetchHooks Function({bool chatId})
        > {
  $$MessagesTableTableTableManager(_$AppDatabase db, $MessagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isFromMe = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion(
                id: id,
                chatId: chatId,
                senderId: senderId,
                content: content,
                type: type,
                status: status,
                timestamp: timestamp,
                isFromMe: isFromMe,
                replyToId: replyToId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chatId,
                required String senderId,
                required String content,
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isFromMe = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion.insert(
                id: id,
                chatId: chatId,
                senderId: senderId,
                content: content,
                type: type,
                status: status,
                timestamp: timestamp,
                isFromMe: isFromMe,
                replyToId: replyToId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatId = false}) {
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
                    if (chatId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chatId,
                                referencedTable: $$MessagesTableTableReferences
                                    ._chatIdTable(db),
                                referencedColumn: $$MessagesTableTableReferences
                                    ._chatIdTable(db)
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

typedef $$MessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTableTable,
      MessagesTableData,
      $$MessagesTableTableFilterComposer,
      $$MessagesTableTableOrderingComposer,
      $$MessagesTableTableAnnotationComposer,
      $$MessagesTableTableCreateCompanionBuilder,
      $$MessagesTableTableUpdateCompanionBuilder,
      (MessagesTableData, $$MessagesTableTableReferences),
      MessagesTableData,
      PrefetchHooks Function({bool chatId})
    >;
typedef $$RelayQueueTableTableCreateCompanionBuilder =
    RelayQueueTableCompanion Function({
      required String messageId,
      required String originalSenderId,
      required String finalDestinationId,
      required String encryptedContent,
      Value<int> hopCount,
      Value<int> maxHops,
      Value<String> trace,
      required DateTime timestamp,
      Value<String?> type,
      Value<String?> metadata,
      Value<DateTime> queuedAt,
      Value<int> retryCount,
      Value<DateTime?> lastRetryAt,
      Value<int> rowid,
    });
typedef $$RelayQueueTableTableUpdateCompanionBuilder =
    RelayQueueTableCompanion Function({
      Value<String> messageId,
      Value<String> originalSenderId,
      Value<String> finalDestinationId,
      Value<String> encryptedContent,
      Value<int> hopCount,
      Value<int> maxHops,
      Value<String> trace,
      Value<DateTime> timestamp,
      Value<String?> type,
      Value<String?> metadata,
      Value<DateTime> queuedAt,
      Value<int> retryCount,
      Value<DateTime?> lastRetryAt,
      Value<int> rowid,
    });

class $$RelayQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $RelayQueueTableTable> {
  $$RelayQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalSenderId => $composableBuilder(
    column: $table.originalSenderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalDestinationId => $composableBuilder(
    column: $table.finalDestinationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedContent => $composableBuilder(
    column: $table.encryptedContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHops => $composableBuilder(
    column: $table.maxHops,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trace => $composableBuilder(
    column: $table.trace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelayQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RelayQueueTableTable> {
  $$RelayQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalSenderId => $composableBuilder(
    column: $table.originalSenderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalDestinationId => $composableBuilder(
    column: $table.finalDestinationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedContent => $composableBuilder(
    column: $table.encryptedContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHops => $composableBuilder(
    column: $table.maxHops,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trace => $composableBuilder(
    column: $table.trace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelayQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelayQueueTableTable> {
  $$RelayQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get originalSenderId => $composableBuilder(
    column: $table.originalSenderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalDestinationId => $composableBuilder(
    column: $table.finalDestinationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedContent => $composableBuilder(
    column: $table.encryptedContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);

  GeneratedColumn<int> get maxHops =>
      $composableBuilder(column: $table.maxHops, builder: (column) => column);

  GeneratedColumn<String> get trace =>
      $composableBuilder(column: $table.trace, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => column,
  );
}

class $$RelayQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RelayQueueTableTable,
          RelayQueueTableData,
          $$RelayQueueTableTableFilterComposer,
          $$RelayQueueTableTableOrderingComposer,
          $$RelayQueueTableTableAnnotationComposer,
          $$RelayQueueTableTableCreateCompanionBuilder,
          $$RelayQueueTableTableUpdateCompanionBuilder,
          (
            RelayQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $RelayQueueTableTable,
              RelayQueueTableData
            >,
          ),
          RelayQueueTableData,
          PrefetchHooks Function()
        > {
  $$RelayQueueTableTableTableManager(
    _$AppDatabase db,
    $RelayQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelayQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelayQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelayQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> originalSenderId = const Value.absent(),
                Value<String> finalDestinationId = const Value.absent(),
                Value<String> encryptedContent = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                Value<int> maxHops = const Value.absent(),
                Value<String> trace = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayQueueTableCompanion(
                messageId: messageId,
                originalSenderId: originalSenderId,
                finalDestinationId: finalDestinationId,
                encryptedContent: encryptedContent,
                hopCount: hopCount,
                maxHops: maxHops,
                trace: trace,
                timestamp: timestamp,
                type: type,
                metadata: metadata,
                queuedAt: queuedAt,
                retryCount: retryCount,
                lastRetryAt: lastRetryAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String originalSenderId,
                required String finalDestinationId,
                required String encryptedContent,
                Value<int> hopCount = const Value.absent(),
                Value<int> maxHops = const Value.absent(),
                Value<String> trace = const Value.absent(),
                required DateTime timestamp,
                Value<String?> type = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayQueueTableCompanion.insert(
                messageId: messageId,
                originalSenderId: originalSenderId,
                finalDestinationId: finalDestinationId,
                encryptedContent: encryptedContent,
                hopCount: hopCount,
                maxHops: maxHops,
                trace: trace,
                timestamp: timestamp,
                type: type,
                metadata: metadata,
                queuedAt: queuedAt,
                retryCount: retryCount,
                lastRetryAt: lastRetryAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelayQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RelayQueueTableTable,
      RelayQueueTableData,
      $$RelayQueueTableTableFilterComposer,
      $$RelayQueueTableTableOrderingComposer,
      $$RelayQueueTableTableAnnotationComposer,
      $$RelayQueueTableTableCreateCompanionBuilder,
      $$RelayQueueTableTableUpdateCompanionBuilder,
      (
        RelayQueueTableData,
        BaseReferences<
          _$AppDatabase,
          $RelayQueueTableTable,
          RelayQueueTableData
        >,
      ),
      RelayQueueTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContactsTableTableTableManager get contactsTable =>
      $$ContactsTableTableTableManager(_db, _db.contactsTable);
  $$ChatsTableTableTableManager get chatsTable =>
      $$ChatsTableTableTableManager(_db, _db.chatsTable);
  $$MessagesTableTableTableManager get messagesTable =>
      $$MessagesTableTableTableManager(_db, _db.messagesTable);
  $$RelayQueueTableTableTableManager get relayQueueTable =>
      $$RelayQueueTableTableTableManager(_db, _db.relayQueueTable);
}
