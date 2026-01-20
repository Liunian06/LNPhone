// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSessionEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
      'role_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meIdMeta = const VerificationMeta('meId');
  @override
  late final GeneratedColumn<String> meId = GeneratedColumn<String>(
      'me_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<int> lastUpdated = GeneratedColumn<int>(
      'last_updated', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _enableExtendedChatMeta =
      const VerificationMeta('enableExtendedChat');
  @override
  late final GeneratedColumn<bool> enableExtendedChat = GeneratedColumn<bool>(
      'enable_extended_chat', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_extended_chat" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _enableIndependentSendButtonMeta =
      const VerificationMeta('enableIndependentSendButton');
  @override
  late final GeneratedColumn<bool> enableIndependentSendButton =
      GeneratedColumn<bool>(
          'enable_independent_send_button', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("enable_independent_send_button" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _currentStateMeta =
      const VerificationMeta('currentState');
  @override
  late final GeneratedColumn<String> currentState = GeneratedColumn<String>(
      'current_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      worldInfoIds = GeneratedColumn<String>(
              'world_info_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ChatSessionsTable.$converterworldInfoIds);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      textPresetIds = GeneratedColumn<String>(
              'text_preset_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ChatSessionsTable.$convertertextPresetIds);
  static const VerificationMeta _apiPresetIdMeta =
      const VerificationMeta('apiPresetId');
  @override
  late final GeneratedColumn<String> apiPresetId = GeneratedColumn<String>(
      'api_preset_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backgroundImageMeta =
      const VerificationMeta('backgroundImage');
  @override
  late final GeneratedColumn<String> backgroundImage = GeneratedColumn<String>(
      'background_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        roleId,
        meId,
        lastUpdated,
        enableExtendedChat,
        enableIndependentSendButton,
        currentState,
        isPinned,
        worldInfoIds,
        textPresetIds,
        apiPresetId,
        backgroundImage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ChatSessionEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(_roleIdMeta,
          roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta));
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('me_id')) {
      context.handle(
          _meIdMeta, meId.isAcceptableOrUnknown(data['me_id']!, _meIdMeta));
    } else if (isInserting) {
      context.missing(_meIdMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    if (data.containsKey('enable_extended_chat')) {
      context.handle(
          _enableExtendedChatMeta,
          enableExtendedChat.isAcceptableOrUnknown(
              data['enable_extended_chat']!, _enableExtendedChatMeta));
    }
    if (data.containsKey('enable_independent_send_button')) {
      context.handle(
          _enableIndependentSendButtonMeta,
          enableIndependentSendButton.isAcceptableOrUnknown(
              data['enable_independent_send_button']!,
              _enableIndependentSendButtonMeta));
    }
    if (data.containsKey('current_state')) {
      context.handle(
          _currentStateMeta,
          currentState.isAcceptableOrUnknown(
              data['current_state']!, _currentStateMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('api_preset_id')) {
      context.handle(
          _apiPresetIdMeta,
          apiPresetId.isAcceptableOrUnknown(
              data['api_preset_id']!, _apiPresetIdMeta));
    }
    if (data.containsKey('background_image')) {
      context.handle(
          _backgroundImageMeta,
          backgroundImage.isAcceptableOrUnknown(
              data['background_image']!, _backgroundImageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSessionEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSessionEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      roleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role_id'])!,
      meId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}me_id'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_updated'])!,
      enableExtendedChat: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}enable_extended_chat'])!,
      enableIndependentSendButton: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}enable_independent_send_button'])!,
      currentState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}current_state']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      worldInfoIds: $ChatSessionsTable.$converterworldInfoIds.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}world_info_ids'])!),
      textPresetIds: $ChatSessionsTable.$convertertextPresetIds.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}text_preset_ids'])!),
      apiPresetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_preset_id']),
      backgroundImage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}background_image']),
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterworldInfoIds =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertertextPresetIds =
      const StringListConverter();
}

class ChatSessionEntity extends DataClass
    implements Insertable<ChatSessionEntity> {
  final String id;
  final String roleId;
  final String meId;
  final int lastUpdated;
  final bool enableExtendedChat;
  final bool enableIndependentSendButton;
  final String? currentState;
  final bool isPinned;
  final List<String> worldInfoIds;
  final List<String> textPresetIds;
  final String? apiPresetId;
  final String? backgroundImage;
  const ChatSessionEntity(
      {required this.id,
      required this.roleId,
      required this.meId,
      required this.lastUpdated,
      required this.enableExtendedChat,
      required this.enableIndependentSendButton,
      this.currentState,
      required this.isPinned,
      required this.worldInfoIds,
      required this.textPresetIds,
      this.apiPresetId,
      this.backgroundImage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role_id'] = Variable<String>(roleId);
    map['me_id'] = Variable<String>(meId);
    map['last_updated'] = Variable<int>(lastUpdated);
    map['enable_extended_chat'] = Variable<bool>(enableExtendedChat);
    map['enable_independent_send_button'] =
        Variable<bool>(enableIndependentSendButton);
    if (!nullToAbsent || currentState != null) {
      map['current_state'] = Variable<String>(currentState);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    {
      map['world_info_ids'] = Variable<String>(
          $ChatSessionsTable.$converterworldInfoIds.toSql(worldInfoIds));
    }
    {
      map['text_preset_ids'] = Variable<String>(
          $ChatSessionsTable.$convertertextPresetIds.toSql(textPresetIds));
    }
    if (!nullToAbsent || apiPresetId != null) {
      map['api_preset_id'] = Variable<String>(apiPresetId);
    }
    if (!nullToAbsent || backgroundImage != null) {
      map['background_image'] = Variable<String>(backgroundImage);
    }
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      roleId: Value(roleId),
      meId: Value(meId),
      lastUpdated: Value(lastUpdated),
      enableExtendedChat: Value(enableExtendedChat),
      enableIndependentSendButton: Value(enableIndependentSendButton),
      currentState: currentState == null && nullToAbsent
          ? const Value.absent()
          : Value(currentState),
      isPinned: Value(isPinned),
      worldInfoIds: Value(worldInfoIds),
      textPresetIds: Value(textPresetIds),
      apiPresetId: apiPresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(apiPresetId),
      backgroundImage: backgroundImage == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundImage),
    );
  }

  factory ChatSessionEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSessionEntity(
      id: serializer.fromJson<String>(json['id']),
      roleId: serializer.fromJson<String>(json['roleId']),
      meId: serializer.fromJson<String>(json['meId']),
      lastUpdated: serializer.fromJson<int>(json['lastUpdated']),
      enableExtendedChat: serializer.fromJson<bool>(json['enableExtendedChat']),
      enableIndependentSendButton:
          serializer.fromJson<bool>(json['enableIndependentSendButton']),
      currentState: serializer.fromJson<String?>(json['currentState']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      worldInfoIds: serializer.fromJson<List<String>>(json['worldInfoIds']),
      textPresetIds: serializer.fromJson<List<String>>(json['textPresetIds']),
      apiPresetId: serializer.fromJson<String?>(json['apiPresetId']),
      backgroundImage: serializer.fromJson<String?>(json['backgroundImage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roleId': serializer.toJson<String>(roleId),
      'meId': serializer.toJson<String>(meId),
      'lastUpdated': serializer.toJson<int>(lastUpdated),
      'enableExtendedChat': serializer.toJson<bool>(enableExtendedChat),
      'enableIndependentSendButton':
          serializer.toJson<bool>(enableIndependentSendButton),
      'currentState': serializer.toJson<String?>(currentState),
      'isPinned': serializer.toJson<bool>(isPinned),
      'worldInfoIds': serializer.toJson<List<String>>(worldInfoIds),
      'textPresetIds': serializer.toJson<List<String>>(textPresetIds),
      'apiPresetId': serializer.toJson<String?>(apiPresetId),
      'backgroundImage': serializer.toJson<String?>(backgroundImage),
    };
  }

  ChatSessionEntity copyWith(
          {String? id,
          String? roleId,
          String? meId,
          int? lastUpdated,
          bool? enableExtendedChat,
          bool? enableIndependentSendButton,
          Value<String?> currentState = const Value.absent(),
          bool? isPinned,
          List<String>? worldInfoIds,
          List<String>? textPresetIds,
          Value<String?> apiPresetId = const Value.absent(),
          Value<String?> backgroundImage = const Value.absent()}) =>
      ChatSessionEntity(
        id: id ?? this.id,
        roleId: roleId ?? this.roleId,
        meId: meId ?? this.meId,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        enableExtendedChat: enableExtendedChat ?? this.enableExtendedChat,
        enableIndependentSendButton:
            enableIndependentSendButton ?? this.enableIndependentSendButton,
        currentState:
            currentState.present ? currentState.value : this.currentState,
        isPinned: isPinned ?? this.isPinned,
        worldInfoIds: worldInfoIds ?? this.worldInfoIds,
        textPresetIds: textPresetIds ?? this.textPresetIds,
        apiPresetId: apiPresetId.present ? apiPresetId.value : this.apiPresetId,
        backgroundImage: backgroundImage.present
            ? backgroundImage.value
            : this.backgroundImage,
      );
  ChatSessionEntity copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSessionEntity(
      id: data.id.present ? data.id.value : this.id,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      meId: data.meId.present ? data.meId.value : this.meId,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
      enableExtendedChat: data.enableExtendedChat.present
          ? data.enableExtendedChat.value
          : this.enableExtendedChat,
      enableIndependentSendButton: data.enableIndependentSendButton.present
          ? data.enableIndependentSendButton.value
          : this.enableIndependentSendButton,
      currentState: data.currentState.present
          ? data.currentState.value
          : this.currentState,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      worldInfoIds: data.worldInfoIds.present
          ? data.worldInfoIds.value
          : this.worldInfoIds,
      textPresetIds: data.textPresetIds.present
          ? data.textPresetIds.value
          : this.textPresetIds,
      apiPresetId:
          data.apiPresetId.present ? data.apiPresetId.value : this.apiPresetId,
      backgroundImage: data.backgroundImage.present
          ? data.backgroundImage.value
          : this.backgroundImage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionEntity(')
          ..write('id: $id, ')
          ..write('roleId: $roleId, ')
          ..write('meId: $meId, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('enableExtendedChat: $enableExtendedChat, ')
          ..write('enableIndependentSendButton: $enableIndependentSendButton, ')
          ..write('currentState: $currentState, ')
          ..write('isPinned: $isPinned, ')
          ..write('worldInfoIds: $worldInfoIds, ')
          ..write('textPresetIds: $textPresetIds, ')
          ..write('apiPresetId: $apiPresetId, ')
          ..write('backgroundImage: $backgroundImage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      roleId,
      meId,
      lastUpdated,
      enableExtendedChat,
      enableIndependentSendButton,
      currentState,
      isPinned,
      worldInfoIds,
      textPresetIds,
      apiPresetId,
      backgroundImage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSessionEntity &&
          other.id == this.id &&
          other.roleId == this.roleId &&
          other.meId == this.meId &&
          other.lastUpdated == this.lastUpdated &&
          other.enableExtendedChat == this.enableExtendedChat &&
          other.enableIndependentSendButton ==
              this.enableIndependentSendButton &&
          other.currentState == this.currentState &&
          other.isPinned == this.isPinned &&
          other.worldInfoIds == this.worldInfoIds &&
          other.textPresetIds == this.textPresetIds &&
          other.apiPresetId == this.apiPresetId &&
          other.backgroundImage == this.backgroundImage);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionEntity> {
  final Value<String> id;
  final Value<String> roleId;
  final Value<String> meId;
  final Value<int> lastUpdated;
  final Value<bool> enableExtendedChat;
  final Value<bool> enableIndependentSendButton;
  final Value<String?> currentState;
  final Value<bool> isPinned;
  final Value<List<String>> worldInfoIds;
  final Value<List<String>> textPresetIds;
  final Value<String?> apiPresetId;
  final Value<String?> backgroundImage;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.roleId = const Value.absent(),
    this.meId = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.enableExtendedChat = const Value.absent(),
    this.enableIndependentSendButton = const Value.absent(),
    this.currentState = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.worldInfoIds = const Value.absent(),
    this.textPresetIds = const Value.absent(),
    this.apiPresetId = const Value.absent(),
    this.backgroundImage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String id,
    required String roleId,
    required String meId,
    required int lastUpdated,
    this.enableExtendedChat = const Value.absent(),
    this.enableIndependentSendButton = const Value.absent(),
    this.currentState = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.worldInfoIds = const Value.absent(),
    this.textPresetIds = const Value.absent(),
    this.apiPresetId = const Value.absent(),
    this.backgroundImage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        roleId = Value(roleId),
        meId = Value(meId),
        lastUpdated = Value(lastUpdated);
  static Insertable<ChatSessionEntity> custom({
    Expression<String>? id,
    Expression<String>? roleId,
    Expression<String>? meId,
    Expression<int>? lastUpdated,
    Expression<bool>? enableExtendedChat,
    Expression<bool>? enableIndependentSendButton,
    Expression<String>? currentState,
    Expression<bool>? isPinned,
    Expression<String>? worldInfoIds,
    Expression<String>? textPresetIds,
    Expression<String>? apiPresetId,
    Expression<String>? backgroundImage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roleId != null) 'role_id': roleId,
      if (meId != null) 'me_id': meId,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (enableExtendedChat != null)
        'enable_extended_chat': enableExtendedChat,
      if (enableIndependentSendButton != null)
        'enable_independent_send_button': enableIndependentSendButton,
      if (currentState != null) 'current_state': currentState,
      if (isPinned != null) 'is_pinned': isPinned,
      if (worldInfoIds != null) 'world_info_ids': worldInfoIds,
      if (textPresetIds != null) 'text_preset_ids': textPresetIds,
      if (apiPresetId != null) 'api_preset_id': apiPresetId,
      if (backgroundImage != null) 'background_image': backgroundImage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? roleId,
      Value<String>? meId,
      Value<int>? lastUpdated,
      Value<bool>? enableExtendedChat,
      Value<bool>? enableIndependentSendButton,
      Value<String?>? currentState,
      Value<bool>? isPinned,
      Value<List<String>>? worldInfoIds,
      Value<List<String>>? textPresetIds,
      Value<String?>? apiPresetId,
      Value<String?>? backgroundImage,
      Value<int>? rowid}) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      meId: meId ?? this.meId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      enableExtendedChat: enableExtendedChat ?? this.enableExtendedChat,
      enableIndependentSendButton:
          enableIndependentSendButton ?? this.enableIndependentSendButton,
      currentState: currentState ?? this.currentState,
      isPinned: isPinned ?? this.isPinned,
      worldInfoIds: worldInfoIds ?? this.worldInfoIds,
      textPresetIds: textPresetIds ?? this.textPresetIds,
      apiPresetId: apiPresetId ?? this.apiPresetId,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (meId.present) {
      map['me_id'] = Variable<String>(meId.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<int>(lastUpdated.value);
    }
    if (enableExtendedChat.present) {
      map['enable_extended_chat'] = Variable<bool>(enableExtendedChat.value);
    }
    if (enableIndependentSendButton.present) {
      map['enable_independent_send_button'] =
          Variable<bool>(enableIndependentSendButton.value);
    }
    if (currentState.present) {
      map['current_state'] = Variable<String>(currentState.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (worldInfoIds.present) {
      map['world_info_ids'] = Variable<String>(
          $ChatSessionsTable.$converterworldInfoIds.toSql(worldInfoIds.value));
    }
    if (textPresetIds.present) {
      map['text_preset_ids'] = Variable<String>($ChatSessionsTable
          .$convertertextPresetIds
          .toSql(textPresetIds.value));
    }
    if (apiPresetId.present) {
      map['api_preset_id'] = Variable<String>(apiPresetId.value);
    }
    if (backgroundImage.present) {
      map['background_image'] = Variable<String>(backgroundImage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('roleId: $roleId, ')
          ..write('meId: $meId, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('enableExtendedChat: $enableExtendedChat, ')
          ..write('enableIndependentSendButton: $enableIndependentSendButton, ')
          ..write('currentState: $currentState, ')
          ..write('isPinned: $isPinned, ')
          ..write('worldInfoIds: $worldInfoIds, ')
          ..write('textPresetIds: $textPresetIds, ')
          ..write('apiPresetId: $apiPresetId, ')
          ..write('backgroundImage: $backgroundImage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES chat_sessions (id) ON DELETE CASCADE'));
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
      'is_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_me" IN (0, 1))'));
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<MessageType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<MessageType>($ChatMessagesTable.$convertertype);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String>
      metadata = GeneratedColumn<String>('metadata', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<Map<String, dynamic>?>(
              $ChatMessagesTable.$convertermetadatan);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, isMe, sender, type, content, timestamp, metadata, isRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessageEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('is_me')) {
      context.handle(
          _isMeMeta, isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta));
    } else if (isInserting) {
      context.missing(_isMeMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      isMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_me'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender']),
      type: $ChatMessagesTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      metadata: $ChatMessagesTable.$convertermetadatan.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])),
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }

  static TypeConverter<MessageType, int> $convertertype =
      const MessageTypeConverter();
  static TypeConverter<Map<String, dynamic>, String> $convertermetadata =
      const MetadataConverter();
  static TypeConverter<Map<String, dynamic>?, String?> $convertermetadatan =
      NullAwareTypeConverter.wrap($convertermetadata);
}

class ChatMessageEntity extends DataClass
    implements Insertable<ChatMessageEntity> {
  final String id;
  final String sessionId;
  final bool isMe;
  final String? sender;
  final MessageType type;
  final String content;
  final int timestamp;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  const ChatMessageEntity(
      {required this.id,
      required this.sessionId,
      required this.isMe,
      this.sender,
      required this.type,
      required this.content,
      required this.timestamp,
      this.metadata,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['is_me'] = Variable<bool>(isMe);
    if (!nullToAbsent || sender != null) {
      map['sender'] = Variable<String>(sender);
    }
    {
      map['type'] =
          Variable<int>($ChatMessagesTable.$convertertype.toSql(type));
    }
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(
          $ChatMessagesTable.$convertermetadatan.toSql(metadata));
    }
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      isMe: Value(isMe),
      sender:
          sender == null && nullToAbsent ? const Value.absent() : Value(sender),
      type: Value(type),
      content: Value(content),
      timestamp: Value(timestamp),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      isRead: Value(isRead),
    );
  }

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageEntity(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      isMe: serializer.fromJson<bool>(json['isMe']),
      sender: serializer.fromJson<String?>(json['sender']),
      type: serializer.fromJson<MessageType>(json['type']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      metadata: serializer.fromJson<Map<String, dynamic>?>(json['metadata']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'isMe': serializer.toJson<bool>(isMe),
      'sender': serializer.toJson<String?>(sender),
      'type': serializer.toJson<MessageType>(type),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<int>(timestamp),
      'metadata': serializer.toJson<Map<String, dynamic>?>(metadata),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  ChatMessageEntity copyWith(
          {String? id,
          String? sessionId,
          bool? isMe,
          Value<String?> sender = const Value.absent(),
          MessageType? type,
          String? content,
          int? timestamp,
          Value<Map<String, dynamic>?> metadata = const Value.absent(),
          bool? isRead}) =>
      ChatMessageEntity(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        isMe: isMe ?? this.isMe,
        sender: sender.present ? sender.value : this.sender,
        type: type ?? this.type,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        metadata: metadata.present ? metadata.value : this.metadata,
        isRead: isRead ?? this.isRead,
      );
  ChatMessageEntity copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageEntity(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
      sender: data.sender.present ? data.sender.value : this.sender,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageEntity(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('isMe: $isMe, ')
          ..write('sender: $sender, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionId, isMe, sender, type, content, timestamp, metadata, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageEntity &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.isMe == this.isMe &&
          other.sender == this.sender &&
          other.type == this.type &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.metadata == this.metadata &&
          other.isRead == this.isRead);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageEntity> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<bool> isMe;
  final Value<String?> sender;
  final Value<MessageType> type;
  final Value<String> content;
  final Value<int> timestamp;
  final Value<Map<String, dynamic>?> metadata;
  final Value<bool> isRead;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.isMe = const Value.absent(),
    this.sender = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.metadata = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required bool isMe,
    this.sender = const Value.absent(),
    required MessageType type,
    required String content,
    required int timestamp,
    this.metadata = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        isMe = Value(isMe),
        type = Value(type),
        content = Value(content),
        timestamp = Value(timestamp);
  static Insertable<ChatMessageEntity> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<bool>? isMe,
    Expression<String>? sender,
    Expression<int>? type,
    Expression<String>? content,
    Expression<int>? timestamp,
    Expression<String>? metadata,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (isMe != null) 'is_me': isMe,
      if (sender != null) 'sender': sender,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<bool>? isMe,
      Value<String?>? sender,
      Value<MessageType>? type,
      Value<String>? content,
      Value<int>? timestamp,
      Value<Map<String, dynamic>?>? metadata,
      Value<bool>? isRead,
      Value<int>? rowid}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      isMe: isMe ?? this.isMe,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($ChatMessagesTable.$convertertype.toSql(type.value));
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(
          $ChatMessagesTable.$convertermetadatan.toSql(metadata.value));
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('isMe: $isMe, ')
          ..write('sender: $sender, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MomentsPostsTable extends MomentsPosts
    with TableInfo<$MomentsPostsTable, MomentsPostEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MomentsPostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<MomentsUser, String> user =
      GeneratedColumn<String>('user', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MomentsUser>($MomentsPostsTable.$converteruser);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<MediaItem>, String>
      mediaItems = GeneratedColumn<String>('media_items', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<MediaItem>>(
              $MomentsPostsTable.$convertermediaItems);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<MomentsUser>, String> likes =
      GeneratedColumn<String>('likes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<MomentsUser>>($MomentsPostsTable.$converterlikes);
  @override
  late final GeneratedColumnWithTypeConverter<List<MomentsComment>, String>
      comments = GeneratedColumn<String>('comments', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<MomentsComment>>(
              $MomentsPostsTable.$convertercomments);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, user, content, mediaItems, createdAt, likes, comments, location];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moments_posts';
  @override
  VerificationContext validateIntegrity(Insertable<MomentsPostEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MomentsPostEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MomentsPostEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      user: $MomentsPostsTable.$converteruser.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user'])!),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      mediaItems: $MomentsPostsTable.$convertermediaItems.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}media_items'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      likes: $MomentsPostsTable.$converterlikes.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}likes'])!),
      comments: $MomentsPostsTable.$convertercomments.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comments'])!),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
    );
  }

  @override
  $MomentsPostsTable createAlias(String alias) {
    return $MomentsPostsTable(attachedDatabase, alias);
  }

  static TypeConverter<MomentsUser, String> $converteruser =
      const MomentsUserConverter();
  static TypeConverter<List<MediaItem>, String> $convertermediaItems =
      const MediaItemsConverter();
  static TypeConverter<List<MomentsUser>, String> $converterlikes =
      const LikesConverter();
  static TypeConverter<List<MomentsComment>, String> $convertercomments =
      const CommentsConverter();
}

class MomentsPostEntity extends DataClass
    implements Insertable<MomentsPostEntity> {
  final String id;
  final MomentsUser user;
  final String? content;
  final List<MediaItem> mediaItems;
  final int createdAt;
  final List<MomentsUser> likes;
  final List<MomentsComment> comments;
  final String? location;
  const MomentsPostEntity(
      {required this.id,
      required this.user,
      this.content,
      required this.mediaItems,
      required this.createdAt,
      required this.likes,
      required this.comments,
      this.location});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['user'] =
          Variable<String>($MomentsPostsTable.$converteruser.toSql(user));
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    {
      map['media_items'] = Variable<String>(
          $MomentsPostsTable.$convertermediaItems.toSql(mediaItems));
    }
    map['created_at'] = Variable<int>(createdAt);
    {
      map['likes'] =
          Variable<String>($MomentsPostsTable.$converterlikes.toSql(likes));
    }
    {
      map['comments'] = Variable<String>(
          $MomentsPostsTable.$convertercomments.toSql(comments));
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    return map;
  }

  MomentsPostsCompanion toCompanion(bool nullToAbsent) {
    return MomentsPostsCompanion(
      id: Value(id),
      user: Value(user),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      mediaItems: Value(mediaItems),
      createdAt: Value(createdAt),
      likes: Value(likes),
      comments: Value(comments),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
    );
  }

  factory MomentsPostEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MomentsPostEntity(
      id: serializer.fromJson<String>(json['id']),
      user: serializer.fromJson<MomentsUser>(json['user']),
      content: serializer.fromJson<String?>(json['content']),
      mediaItems: serializer.fromJson<List<MediaItem>>(json['mediaItems']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      likes: serializer.fromJson<List<MomentsUser>>(json['likes']),
      comments: serializer.fromJson<List<MomentsComment>>(json['comments']),
      location: serializer.fromJson<String?>(json['location']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user': serializer.toJson<MomentsUser>(user),
      'content': serializer.toJson<String?>(content),
      'mediaItems': serializer.toJson<List<MediaItem>>(mediaItems),
      'createdAt': serializer.toJson<int>(createdAt),
      'likes': serializer.toJson<List<MomentsUser>>(likes),
      'comments': serializer.toJson<List<MomentsComment>>(comments),
      'location': serializer.toJson<String?>(location),
    };
  }

  MomentsPostEntity copyWith(
          {String? id,
          MomentsUser? user,
          Value<String?> content = const Value.absent(),
          List<MediaItem>? mediaItems,
          int? createdAt,
          List<MomentsUser>? likes,
          List<MomentsComment>? comments,
          Value<String?> location = const Value.absent()}) =>
      MomentsPostEntity(
        id: id ?? this.id,
        user: user ?? this.user,
        content: content.present ? content.value : this.content,
        mediaItems: mediaItems ?? this.mediaItems,
        createdAt: createdAt ?? this.createdAt,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        location: location.present ? location.value : this.location,
      );
  MomentsPostEntity copyWithCompanion(MomentsPostsCompanion data) {
    return MomentsPostEntity(
      id: data.id.present ? data.id.value : this.id,
      user: data.user.present ? data.user.value : this.user,
      content: data.content.present ? data.content.value : this.content,
      mediaItems:
          data.mediaItems.present ? data.mediaItems.value : this.mediaItems,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      likes: data.likes.present ? data.likes.value : this.likes,
      comments: data.comments.present ? data.comments.value : this.comments,
      location: data.location.present ? data.location.value : this.location,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MomentsPostEntity(')
          ..write('id: $id, ')
          ..write('user: $user, ')
          ..write('content: $content, ')
          ..write('mediaItems: $mediaItems, ')
          ..write('createdAt: $createdAt, ')
          ..write('likes: $likes, ')
          ..write('comments: $comments, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, user, content, mediaItems, createdAt, likes, comments, location);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MomentsPostEntity &&
          other.id == this.id &&
          other.user == this.user &&
          other.content == this.content &&
          other.mediaItems == this.mediaItems &&
          other.createdAt == this.createdAt &&
          other.likes == this.likes &&
          other.comments == this.comments &&
          other.location == this.location);
}

class MomentsPostsCompanion extends UpdateCompanion<MomentsPostEntity> {
  final Value<String> id;
  final Value<MomentsUser> user;
  final Value<String?> content;
  final Value<List<MediaItem>> mediaItems;
  final Value<int> createdAt;
  final Value<List<MomentsUser>> likes;
  final Value<List<MomentsComment>> comments;
  final Value<String?> location;
  final Value<int> rowid;
  const MomentsPostsCompanion({
    this.id = const Value.absent(),
    this.user = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaItems = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.likes = const Value.absent(),
    this.comments = const Value.absent(),
    this.location = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MomentsPostsCompanion.insert({
    required String id,
    required MomentsUser user,
    this.content = const Value.absent(),
    required List<MediaItem> mediaItems,
    required int createdAt,
    required List<MomentsUser> likes,
    required List<MomentsComment> comments,
    this.location = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        user = Value(user),
        mediaItems = Value(mediaItems),
        createdAt = Value(createdAt),
        likes = Value(likes),
        comments = Value(comments);
  static Insertable<MomentsPostEntity> custom({
    Expression<String>? id,
    Expression<String>? user,
    Expression<String>? content,
    Expression<String>? mediaItems,
    Expression<int>? createdAt,
    Expression<String>? likes,
    Expression<String>? comments,
    Expression<String>? location,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (user != null) 'user': user,
      if (content != null) 'content': content,
      if (mediaItems != null) 'media_items': mediaItems,
      if (createdAt != null) 'created_at': createdAt,
      if (likes != null) 'likes': likes,
      if (comments != null) 'comments': comments,
      if (location != null) 'location': location,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MomentsPostsCompanion copyWith(
      {Value<String>? id,
      Value<MomentsUser>? user,
      Value<String?>? content,
      Value<List<MediaItem>>? mediaItems,
      Value<int>? createdAt,
      Value<List<MomentsUser>>? likes,
      Value<List<MomentsComment>>? comments,
      Value<String?>? location,
      Value<int>? rowid}) {
    return MomentsPostsCompanion(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      mediaItems: mediaItems ?? this.mediaItems,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      location: location ?? this.location,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (user.present) {
      map['user'] =
          Variable<String>($MomentsPostsTable.$converteruser.toSql(user.value));
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaItems.present) {
      map['media_items'] = Variable<String>(
          $MomentsPostsTable.$convertermediaItems.toSql(mediaItems.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (likes.present) {
      map['likes'] = Variable<String>(
          $MomentsPostsTable.$converterlikes.toSql(likes.value));
    }
    if (comments.present) {
      map['comments'] = Variable<String>(
          $MomentsPostsTable.$convertercomments.toSql(comments.value));
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MomentsPostsCompanion(')
          ..write('id: $id, ')
          ..write('user: $user, ')
          ..write('content: $content, ')
          ..write('mediaItems: $mediaItems, ')
          ..write('createdAt: $createdAt, ')
          ..write('likes: $likes, ')
          ..write('comments: $comments, ')
          ..write('location: $location, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorldInfosTable extends WorldInfos
    with TableInfo<$WorldInfosTable, WorldInfoEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldInfosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, content, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'world_infos';
  @override
  VerificationContext validateIntegrity(Insertable<WorldInfoEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorldInfoEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorldInfoEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorldInfosTable createAlias(String alias) {
    return $WorldInfosTable(attachedDatabase, alias);
  }
}

class WorldInfoEntity extends DataClass implements Insertable<WorldInfoEntity> {
  final String id;
  final String name;
  final String content;
  final int createdAt;
  final int updatedAt;
  const WorldInfoEntity(
      {required this.id,
      required this.name,
      required this.content,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WorldInfosCompanion toCompanion(bool nullToAbsent) {
    return WorldInfosCompanion(
      id: Value(id),
      name: Value(name),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorldInfoEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorldInfoEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  WorldInfoEntity copyWith(
          {String? id,
          String? name,
          String? content,
          int? createdAt,
          int? updatedAt}) =>
      WorldInfoEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorldInfoEntity copyWithCompanion(WorldInfosCompanion data) {
    return WorldInfoEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorldInfoEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorldInfoEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorldInfosCompanion extends UpdateCompanion<WorldInfoEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const WorldInfosCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorldInfosCompanion.insert({
    required String id,
    required String name,
    required String content,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        content = Value(content),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WorldInfoEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorldInfosCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? content,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return WorldInfosCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
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
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldInfosCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TextPresetsTable extends TextPresets
    with TableInfo<$TextPresetsTable, TextPresetEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TextPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, content, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'text_presets';
  @override
  VerificationContext validateIntegrity(Insertable<TextPresetEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TextPresetEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TextPresetEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TextPresetsTable createAlias(String alias) {
    return $TextPresetsTable(attachedDatabase, alias);
  }
}

class TextPresetEntity extends DataClass
    implements Insertable<TextPresetEntity> {
  final String id;
  final String name;
  final String content;
  final int createdAt;
  final int updatedAt;
  const TextPresetEntity(
      {required this.id,
      required this.name,
      required this.content,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TextPresetsCompanion toCompanion(bool nullToAbsent) {
    return TextPresetsCompanion(
      id: Value(id),
      name: Value(name),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TextPresetEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextPresetEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TextPresetEntity copyWith(
          {String? id,
          String? name,
          String? content,
          int? createdAt,
          int? updatedAt}) =>
      TextPresetEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TextPresetEntity copyWithCompanion(TextPresetsCompanion data) {
    return TextPresetEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TextPresetEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextPresetEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TextPresetsCompanion extends UpdateCompanion<TextPresetEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TextPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextPresetsCompanion.insert({
    required String id,
    required String name,
    required String content,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        content = Value(content),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TextPresetEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextPresetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? content,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return TextPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
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
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $MomentsPostsTable momentsPosts = $MomentsPostsTable(this);
  late final $WorldInfosTable worldInfos = $WorldInfosTable(this);
  late final $TextPresetsTable textPresets = $TextPresetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [chatSessions, chatMessages, momentsPosts, worldInfos, textPresets];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('chat_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('chat_messages', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ChatSessionsTableCreateCompanionBuilder = ChatSessionsCompanion
    Function({
  required String id,
  required String roleId,
  required String meId,
  required int lastUpdated,
  Value<bool> enableExtendedChat,
  Value<bool> enableIndependentSendButton,
  Value<String?> currentState,
  Value<bool> isPinned,
  Value<List<String>> worldInfoIds,
  Value<List<String>> textPresetIds,
  Value<String?> apiPresetId,
  Value<String?> backgroundImage,
  Value<int> rowid,
});
typedef $$ChatSessionsTableUpdateCompanionBuilder = ChatSessionsCompanion
    Function({
  Value<String> id,
  Value<String> roleId,
  Value<String> meId,
  Value<int> lastUpdated,
  Value<bool> enableExtendedChat,
  Value<bool> enableIndependentSendButton,
  Value<String?> currentState,
  Value<bool> isPinned,
  Value<List<String>> worldInfoIds,
  Value<List<String>> textPresetIds,
  Value<String?> apiPresetId,
  Value<String?> backgroundImage,
  Value<int> rowid,
});

final class $$ChatSessionsTableReferences extends BaseReferences<_$AppDatabase,
    $ChatSessionsTable, ChatSessionEntity> {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessageEntity>>
      _chatMessagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatMessages,
              aliasName: $_aliasNameGenerator(
                  db.chatSessions.id, db.chatMessages.sessionId));

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager($_db, $_db.chatMessages)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roleId => $composableBuilder(
      column: $table.roleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meId => $composableBuilder(
      column: $table.meId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableExtendedChat => $composableBuilder(
      column: $table.enableExtendedChat,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableIndependentSendButton => $composableBuilder(
      column: $table.enableIndependentSendButton,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentState => $composableBuilder(
      column: $table.currentState, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get worldInfoIds => $composableBuilder(
          column: $table.worldInfoIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get textPresetIds => $composableBuilder(
          column: $table.textPresetIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get apiPresetId => $composableBuilder(
      column: $table.apiPresetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backgroundImage => $composableBuilder(
      column: $table.backgroundImage,
      builder: (column) => ColumnFilters(column));

  Expression<bool> chatMessagesRefs(
      Expression<bool> Function($$ChatMessagesTableFilterComposer f) f) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableFilterComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roleId => $composableBuilder(
      column: $table.roleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meId => $composableBuilder(
      column: $table.meId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableExtendedChat => $composableBuilder(
      column: $table.enableExtendedChat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableIndependentSendButton => $composableBuilder(
      column: $table.enableIndependentSendButton,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentState => $composableBuilder(
      column: $table.currentState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldInfoIds => $composableBuilder(
      column: $table.worldInfoIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textPresetIds => $composableBuilder(
      column: $table.textPresetIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiPresetId => $composableBuilder(
      column: $table.apiPresetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backgroundImage => $composableBuilder(
      column: $table.backgroundImage,
      builder: (column) => ColumnOrderings(column));
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get meId =>
      $composableBuilder(column: $table.meId, builder: (column) => column);

  GeneratedColumn<int> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);

  GeneratedColumn<bool> get enableExtendedChat => $composableBuilder(
      column: $table.enableExtendedChat, builder: (column) => column);

  GeneratedColumn<bool> get enableIndependentSendButton => $composableBuilder(
      column: $table.enableIndependentSendButton, builder: (column) => column);

  GeneratedColumn<String> get currentState => $composableBuilder(
      column: $table.currentState, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get worldInfoIds =>
      $composableBuilder(
          column: $table.worldInfoIds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get textPresetIds =>
      $composableBuilder(
          column: $table.textPresetIds, builder: (column) => column);

  GeneratedColumn<String> get apiPresetId => $composableBuilder(
      column: $table.apiPresetId, builder: (column) => column);

  GeneratedColumn<String> get backgroundImage => $composableBuilder(
      column: $table.backgroundImage, builder: (column) => column);

  Expression<T> chatMessagesRefs<T extends Object>(
      Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSessionEntity,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (ChatSessionEntity, $$ChatSessionsTableReferences),
    ChatSessionEntity,
    PrefetchHooks Function({bool chatMessagesRefs})> {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> roleId = const Value.absent(),
            Value<String> meId = const Value.absent(),
            Value<int> lastUpdated = const Value.absent(),
            Value<bool> enableExtendedChat = const Value.absent(),
            Value<bool> enableIndependentSendButton = const Value.absent(),
            Value<String?> currentState = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<List<String>> worldInfoIds = const Value.absent(),
            Value<List<String>> textPresetIds = const Value.absent(),
            Value<String?> apiPresetId = const Value.absent(),
            Value<String?> backgroundImage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion(
            id: id,
            roleId: roleId,
            meId: meId,
            lastUpdated: lastUpdated,
            enableExtendedChat: enableExtendedChat,
            enableIndependentSendButton: enableIndependentSendButton,
            currentState: currentState,
            isPinned: isPinned,
            worldInfoIds: worldInfoIds,
            textPresetIds: textPresetIds,
            apiPresetId: apiPresetId,
            backgroundImage: backgroundImage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String roleId,
            required String meId,
            required int lastUpdated,
            Value<bool> enableExtendedChat = const Value.absent(),
            Value<bool> enableIndependentSendButton = const Value.absent(),
            Value<String?> currentState = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<List<String>> worldInfoIds = const Value.absent(),
            Value<List<String>> textPresetIds = const Value.absent(),
            Value<String?> apiPresetId = const Value.absent(),
            Value<String?> backgroundImage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion.insert(
            id: id,
            roleId: roleId,
            meId: meId,
            lastUpdated: lastUpdated,
            enableExtendedChat: enableExtendedChat,
            enableIndependentSendButton: enableIndependentSendButton,
            currentState: currentState,
            isPinned: isPinned,
            worldInfoIds: worldInfoIds,
            textPresetIds: textPresetIds,
            apiPresetId: apiPresetId,
            backgroundImage: backgroundImage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({chatMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatMessagesRefs) db.chatMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData<ChatSessionEntity,
                            $ChatSessionsTable, ChatMessageEntity>(
                        currentTable: table,
                        referencedTable: $$ChatSessionsTableReferences
                            ._chatMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatSessionsTableReferences(db, table, p0)
                                .chatMessagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChatSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSessionEntity,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (ChatSessionEntity, $$ChatSessionsTableReferences),
    ChatSessionEntity,
    PrefetchHooks Function({bool chatMessagesRefs})>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  required String id,
  required String sessionId,
  required bool isMe,
  Value<String?> sender,
  required MessageType type,
  required String content,
  required int timestamp,
  Value<Map<String, dynamic>?> metadata,
  Value<bool> isRead,
  Value<int> rowid,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<bool> isMe,
  Value<String?> sender,
  Value<MessageType> type,
  Value<String> content,
  Value<int> timestamp,
  Value<Map<String, dynamic>?> metadata,
  Value<bool> isRead,
  Value<int> rowid,
});

final class $$ChatMessagesTableReferences extends BaseReferences<_$AppDatabase,
    $ChatMessagesTable, ChatMessageEntity> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.chatSessions.createAlias(
          $_aliasNameGenerator(db.chatMessages.sessionId, db.chatSessions.id));

  $$ChatSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ChatSessionsTableTableManager($_db, $_db.chatSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMe => $composableBuilder(
      column: $table.isMe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MessageType, MessageType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Map<String, dynamic>?, Map<String, dynamic>,
          String>
      get metadata => $composableBuilder(
          column: $table.metadata,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableFilterComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMe => $composableBuilder(
      column: $table.isMe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String>
      get metadata => $composableBuilder(
          column: $table.metadata, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessageEntity,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessageEntity, $$ChatMessagesTableReferences),
    ChatMessageEntity,
    PrefetchHooks Function({bool sessionId})> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<bool> isMe = const Value.absent(),
            Value<String?> sender = const Value.absent(),
            Value<MessageType> type = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<Map<String, dynamic>?> metadata = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            sessionId: sessionId,
            isMe: isMe,
            sender: sender,
            type: type,
            content: content,
            timestamp: timestamp,
            metadata: metadata,
            isRead: isRead,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required bool isMe,
            Value<String?> sender = const Value.absent(),
            required MessageType type,
            required String content,
            required int timestamp,
            Value<Map<String, dynamic>?> metadata = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            sessionId: sessionId,
            isMe: isMe,
            sender: sender,
            type: type,
            content: content,
            timestamp: timestamp,
            metadata: metadata,
            isRead: isRead,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatMessagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$ChatMessagesTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$ChatMessagesTableReferences._sessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessageEntity,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessageEntity, $$ChatMessagesTableReferences),
    ChatMessageEntity,
    PrefetchHooks Function({bool sessionId})>;
typedef $$MomentsPostsTableCreateCompanionBuilder = MomentsPostsCompanion
    Function({
  required String id,
  required MomentsUser user,
  Value<String?> content,
  required List<MediaItem> mediaItems,
  required int createdAt,
  required List<MomentsUser> likes,
  required List<MomentsComment> comments,
  Value<String?> location,
  Value<int> rowid,
});
typedef $$MomentsPostsTableUpdateCompanionBuilder = MomentsPostsCompanion
    Function({
  Value<String> id,
  Value<MomentsUser> user,
  Value<String?> content,
  Value<List<MediaItem>> mediaItems,
  Value<int> createdAt,
  Value<List<MomentsUser>> likes,
  Value<List<MomentsComment>> comments,
  Value<String?> location,
  Value<int> rowid,
});

class $$MomentsPostsTableFilterComposer
    extends Composer<_$AppDatabase, $MomentsPostsTable> {
  $$MomentsPostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MomentsUser, MomentsUser, String> get user =>
      $composableBuilder(
          column: $table.user,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<MediaItem>, List<MediaItem>, String>
      get mediaItems => $composableBuilder(
          column: $table.mediaItems,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<MomentsUser>, List<MomentsUser>, String>
      get likes => $composableBuilder(
          column: $table.likes,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<MomentsComment>, List<MomentsComment>,
          String>
      get comments => $composableBuilder(
          column: $table.comments,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));
}

class $$MomentsPostsTableOrderingComposer
    extends Composer<_$AppDatabase, $MomentsPostsTable> {
  $$MomentsPostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get user => $composableBuilder(
      column: $table.user, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaItems => $composableBuilder(
      column: $table.mediaItems, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get likes => $composableBuilder(
      column: $table.likes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get comments => $composableBuilder(
      column: $table.comments, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));
}

class $$MomentsPostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MomentsPostsTable> {
  $$MomentsPostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MomentsUser, String> get user =>
      $composableBuilder(column: $table.user, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<MediaItem>, String> get mediaItems =>
      $composableBuilder(
          column: $table.mediaItems, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<MomentsUser>, String> get likes =>
      $composableBuilder(column: $table.likes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<MomentsComment>, String> get comments =>
      $composableBuilder(column: $table.comments, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);
}

class $$MomentsPostsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MomentsPostsTable,
    MomentsPostEntity,
    $$MomentsPostsTableFilterComposer,
    $$MomentsPostsTableOrderingComposer,
    $$MomentsPostsTableAnnotationComposer,
    $$MomentsPostsTableCreateCompanionBuilder,
    $$MomentsPostsTableUpdateCompanionBuilder,
    (
      MomentsPostEntity,
      BaseReferences<_$AppDatabase, $MomentsPostsTable, MomentsPostEntity>
    ),
    MomentsPostEntity,
    PrefetchHooks Function()> {
  $$MomentsPostsTableTableManager(_$AppDatabase db, $MomentsPostsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MomentsPostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MomentsPostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MomentsPostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<MomentsUser> user = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<List<MediaItem>> mediaItems = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<List<MomentsUser>> likes = const Value.absent(),
            Value<List<MomentsComment>> comments = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MomentsPostsCompanion(
            id: id,
            user: user,
            content: content,
            mediaItems: mediaItems,
            createdAt: createdAt,
            likes: likes,
            comments: comments,
            location: location,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required MomentsUser user,
            Value<String?> content = const Value.absent(),
            required List<MediaItem> mediaItems,
            required int createdAt,
            required List<MomentsUser> likes,
            required List<MomentsComment> comments,
            Value<String?> location = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MomentsPostsCompanion.insert(
            id: id,
            user: user,
            content: content,
            mediaItems: mediaItems,
            createdAt: createdAt,
            likes: likes,
            comments: comments,
            location: location,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MomentsPostsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MomentsPostsTable,
    MomentsPostEntity,
    $$MomentsPostsTableFilterComposer,
    $$MomentsPostsTableOrderingComposer,
    $$MomentsPostsTableAnnotationComposer,
    $$MomentsPostsTableCreateCompanionBuilder,
    $$MomentsPostsTableUpdateCompanionBuilder,
    (
      MomentsPostEntity,
      BaseReferences<_$AppDatabase, $MomentsPostsTable, MomentsPostEntity>
    ),
    MomentsPostEntity,
    PrefetchHooks Function()>;
typedef $$WorldInfosTableCreateCompanionBuilder = WorldInfosCompanion Function({
  required String id,
  required String name,
  required String content,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$WorldInfosTableUpdateCompanionBuilder = WorldInfosCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> content,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$WorldInfosTableFilterComposer
    extends Composer<_$AppDatabase, $WorldInfosTable> {
  $$WorldInfosTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WorldInfosTableOrderingComposer
    extends Composer<_$AppDatabase, $WorldInfosTable> {
  $$WorldInfosTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorldInfosTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorldInfosTable> {
  $$WorldInfosTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorldInfosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorldInfosTable,
    WorldInfoEntity,
    $$WorldInfosTableFilterComposer,
    $$WorldInfosTableOrderingComposer,
    $$WorldInfosTableAnnotationComposer,
    $$WorldInfosTableCreateCompanionBuilder,
    $$WorldInfosTableUpdateCompanionBuilder,
    (
      WorldInfoEntity,
      BaseReferences<_$AppDatabase, $WorldInfosTable, WorldInfoEntity>
    ),
    WorldInfoEntity,
    PrefetchHooks Function()> {
  $$WorldInfosTableTableManager(_$AppDatabase db, $WorldInfosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldInfosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldInfosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldInfosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorldInfosCompanion(
            id: id,
            name: name,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String content,
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorldInfosCompanion.insert(
            id: id,
            name: name,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorldInfosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorldInfosTable,
    WorldInfoEntity,
    $$WorldInfosTableFilterComposer,
    $$WorldInfosTableOrderingComposer,
    $$WorldInfosTableAnnotationComposer,
    $$WorldInfosTableCreateCompanionBuilder,
    $$WorldInfosTableUpdateCompanionBuilder,
    (
      WorldInfoEntity,
      BaseReferences<_$AppDatabase, $WorldInfosTable, WorldInfoEntity>
    ),
    WorldInfoEntity,
    PrefetchHooks Function()>;
typedef $$TextPresetsTableCreateCompanionBuilder = TextPresetsCompanion
    Function({
  required String id,
  required String name,
  required String content,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$TextPresetsTableUpdateCompanionBuilder = TextPresetsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> content,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$TextPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $TextPresetsTable> {
  $$TextPresetsTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TextPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TextPresetsTable> {
  $$TextPresetsTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TextPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TextPresetsTable> {
  $$TextPresetsTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TextPresetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TextPresetsTable,
    TextPresetEntity,
    $$TextPresetsTableFilterComposer,
    $$TextPresetsTableOrderingComposer,
    $$TextPresetsTableAnnotationComposer,
    $$TextPresetsTableCreateCompanionBuilder,
    $$TextPresetsTableUpdateCompanionBuilder,
    (
      TextPresetEntity,
      BaseReferences<_$AppDatabase, $TextPresetsTable, TextPresetEntity>
    ),
    TextPresetEntity,
    PrefetchHooks Function()> {
  $$TextPresetsTableTableManager(_$AppDatabase db, $TextPresetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TextPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TextPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TextPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TextPresetsCompanion(
            id: id,
            name: name,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String content,
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TextPresetsCompanion.insert(
            id: id,
            name: name,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TextPresetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TextPresetsTable,
    TextPresetEntity,
    $$TextPresetsTableFilterComposer,
    $$TextPresetsTableOrderingComposer,
    $$TextPresetsTableAnnotationComposer,
    $$TextPresetsTableCreateCompanionBuilder,
    $$TextPresetsTableUpdateCompanionBuilder,
    (
      TextPresetEntity,
      BaseReferences<_$AppDatabase, $TextPresetsTable, TextPresetEntity>
    ),
    TextPresetEntity,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$MomentsPostsTableTableManager get momentsPosts =>
      $$MomentsPostsTableTableManager(_db, _db.momentsPosts);
  $$WorldInfosTableTableManager get worldInfos =>
      $$WorldInfosTableTableManager(_db, _db.worldInfos);
  $$TextPresetsTableTableManager get textPresets =>
      $$TextPresetsTableTableManager(_db, _db.textPresets);
}
