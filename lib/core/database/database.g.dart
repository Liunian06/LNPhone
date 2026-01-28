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
  static const VerificationMeta _enableEmojiMeta =
      const VerificationMeta('enableEmoji');
  @override
  late final GeneratedColumn<bool> enableEmoji = GeneratedColumn<bool>(
      'enable_emoji', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_emoji" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _enableTextToImageMeta =
      const VerificationMeta('enableTextToImage');
  @override
  late final GeneratedColumn<bool> enableTextToImage = GeneratedColumn<bool>(
      'enable_text_to_image', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_text_to_image" IN (0, 1))'),
      defaultValue: const Constant(false));
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
  static const VerificationMeta _imageApiPresetIdMeta =
      const VerificationMeta('imageApiPresetId');
  @override
  late final GeneratedColumn<String> imageApiPresetId = GeneratedColumn<String>(
      'image_api_preset_id', aliasedName, true,
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
        enableEmoji,
        enableTextToImage,
        enableIndependentSendButton,
        currentState,
        isPinned,
        worldInfoIds,
        textPresetIds,
        apiPresetId,
        imageApiPresetId,
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
    if (data.containsKey('enable_emoji')) {
      context.handle(
          _enableEmojiMeta,
          enableEmoji.isAcceptableOrUnknown(
              data['enable_emoji']!, _enableEmojiMeta));
    }
    if (data.containsKey('enable_text_to_image')) {
      context.handle(
          _enableTextToImageMeta,
          enableTextToImage.isAcceptableOrUnknown(
              data['enable_text_to_image']!, _enableTextToImageMeta));
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
    if (data.containsKey('image_api_preset_id')) {
      context.handle(
          _imageApiPresetIdMeta,
          imageApiPresetId.isAcceptableOrUnknown(
              data['image_api_preset_id']!, _imageApiPresetIdMeta));
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
      enableEmoji: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enable_emoji'])!,
      enableTextToImage: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}enable_text_to_image'])!,
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
      imageApiPresetId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_api_preset_id']),
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
  final bool enableEmoji;
  final bool enableTextToImage;
  final bool enableIndependentSendButton;
  final String? currentState;
  final bool isPinned;
  final List<String> worldInfoIds;
  final List<String> textPresetIds;
  final String? apiPresetId;
  final String? imageApiPresetId;
  final String? backgroundImage;
  const ChatSessionEntity(
      {required this.id,
      required this.roleId,
      required this.meId,
      required this.lastUpdated,
      required this.enableExtendedChat,
      required this.enableEmoji,
      required this.enableTextToImage,
      required this.enableIndependentSendButton,
      this.currentState,
      required this.isPinned,
      required this.worldInfoIds,
      required this.textPresetIds,
      this.apiPresetId,
      this.imageApiPresetId,
      this.backgroundImage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role_id'] = Variable<String>(roleId);
    map['me_id'] = Variable<String>(meId);
    map['last_updated'] = Variable<int>(lastUpdated);
    map['enable_extended_chat'] = Variable<bool>(enableExtendedChat);
    map['enable_emoji'] = Variable<bool>(enableEmoji);
    map['enable_text_to_image'] = Variable<bool>(enableTextToImage);
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
    if (!nullToAbsent || imageApiPresetId != null) {
      map['image_api_preset_id'] = Variable<String>(imageApiPresetId);
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
      enableEmoji: Value(enableEmoji),
      enableTextToImage: Value(enableTextToImage),
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
      imageApiPresetId: imageApiPresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(imageApiPresetId),
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
      enableEmoji: serializer.fromJson<bool>(json['enableEmoji']),
      enableTextToImage: serializer.fromJson<bool>(json['enableTextToImage']),
      enableIndependentSendButton:
          serializer.fromJson<bool>(json['enableIndependentSendButton']),
      currentState: serializer.fromJson<String?>(json['currentState']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      worldInfoIds: serializer.fromJson<List<String>>(json['worldInfoIds']),
      textPresetIds: serializer.fromJson<List<String>>(json['textPresetIds']),
      apiPresetId: serializer.fromJson<String?>(json['apiPresetId']),
      imageApiPresetId: serializer.fromJson<String?>(json['imageApiPresetId']),
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
      'enableEmoji': serializer.toJson<bool>(enableEmoji),
      'enableTextToImage': serializer.toJson<bool>(enableTextToImage),
      'enableIndependentSendButton':
          serializer.toJson<bool>(enableIndependentSendButton),
      'currentState': serializer.toJson<String?>(currentState),
      'isPinned': serializer.toJson<bool>(isPinned),
      'worldInfoIds': serializer.toJson<List<String>>(worldInfoIds),
      'textPresetIds': serializer.toJson<List<String>>(textPresetIds),
      'apiPresetId': serializer.toJson<String?>(apiPresetId),
      'imageApiPresetId': serializer.toJson<String?>(imageApiPresetId),
      'backgroundImage': serializer.toJson<String?>(backgroundImage),
    };
  }

  ChatSessionEntity copyWith(
          {String? id,
          String? roleId,
          String? meId,
          int? lastUpdated,
          bool? enableExtendedChat,
          bool? enableEmoji,
          bool? enableTextToImage,
          bool? enableIndependentSendButton,
          Value<String?> currentState = const Value.absent(),
          bool? isPinned,
          List<String>? worldInfoIds,
          List<String>? textPresetIds,
          Value<String?> apiPresetId = const Value.absent(),
          Value<String?> imageApiPresetId = const Value.absent(),
          Value<String?> backgroundImage = const Value.absent()}) =>
      ChatSessionEntity(
        id: id ?? this.id,
        roleId: roleId ?? this.roleId,
        meId: meId ?? this.meId,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        enableExtendedChat: enableExtendedChat ?? this.enableExtendedChat,
        enableEmoji: enableEmoji ?? this.enableEmoji,
        enableTextToImage: enableTextToImage ?? this.enableTextToImage,
        enableIndependentSendButton:
            enableIndependentSendButton ?? this.enableIndependentSendButton,
        currentState:
            currentState.present ? currentState.value : this.currentState,
        isPinned: isPinned ?? this.isPinned,
        worldInfoIds: worldInfoIds ?? this.worldInfoIds,
        textPresetIds: textPresetIds ?? this.textPresetIds,
        apiPresetId: apiPresetId.present ? apiPresetId.value : this.apiPresetId,
        imageApiPresetId: imageApiPresetId.present
            ? imageApiPresetId.value
            : this.imageApiPresetId,
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
      enableEmoji:
          data.enableEmoji.present ? data.enableEmoji.value : this.enableEmoji,
      enableTextToImage: data.enableTextToImage.present
          ? data.enableTextToImage.value
          : this.enableTextToImage,
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
      imageApiPresetId: data.imageApiPresetId.present
          ? data.imageApiPresetId.value
          : this.imageApiPresetId,
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
          ..write('enableEmoji: $enableEmoji, ')
          ..write('enableTextToImage: $enableTextToImage, ')
          ..write('enableIndependentSendButton: $enableIndependentSendButton, ')
          ..write('currentState: $currentState, ')
          ..write('isPinned: $isPinned, ')
          ..write('worldInfoIds: $worldInfoIds, ')
          ..write('textPresetIds: $textPresetIds, ')
          ..write('apiPresetId: $apiPresetId, ')
          ..write('imageApiPresetId: $imageApiPresetId, ')
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
      enableEmoji,
      enableTextToImage,
      enableIndependentSendButton,
      currentState,
      isPinned,
      worldInfoIds,
      textPresetIds,
      apiPresetId,
      imageApiPresetId,
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
          other.enableEmoji == this.enableEmoji &&
          other.enableTextToImage == this.enableTextToImage &&
          other.enableIndependentSendButton ==
              this.enableIndependentSendButton &&
          other.currentState == this.currentState &&
          other.isPinned == this.isPinned &&
          other.worldInfoIds == this.worldInfoIds &&
          other.textPresetIds == this.textPresetIds &&
          other.apiPresetId == this.apiPresetId &&
          other.imageApiPresetId == this.imageApiPresetId &&
          other.backgroundImage == this.backgroundImage);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionEntity> {
  final Value<String> id;
  final Value<String> roleId;
  final Value<String> meId;
  final Value<int> lastUpdated;
  final Value<bool> enableExtendedChat;
  final Value<bool> enableEmoji;
  final Value<bool> enableTextToImage;
  final Value<bool> enableIndependentSendButton;
  final Value<String?> currentState;
  final Value<bool> isPinned;
  final Value<List<String>> worldInfoIds;
  final Value<List<String>> textPresetIds;
  final Value<String?> apiPresetId;
  final Value<String?> imageApiPresetId;
  final Value<String?> backgroundImage;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.roleId = const Value.absent(),
    this.meId = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.enableExtendedChat = const Value.absent(),
    this.enableEmoji = const Value.absent(),
    this.enableTextToImage = const Value.absent(),
    this.enableIndependentSendButton = const Value.absent(),
    this.currentState = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.worldInfoIds = const Value.absent(),
    this.textPresetIds = const Value.absent(),
    this.apiPresetId = const Value.absent(),
    this.imageApiPresetId = const Value.absent(),
    this.backgroundImage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String id,
    required String roleId,
    required String meId,
    required int lastUpdated,
    this.enableExtendedChat = const Value.absent(),
    this.enableEmoji = const Value.absent(),
    this.enableTextToImage = const Value.absent(),
    this.enableIndependentSendButton = const Value.absent(),
    this.currentState = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.worldInfoIds = const Value.absent(),
    this.textPresetIds = const Value.absent(),
    this.apiPresetId = const Value.absent(),
    this.imageApiPresetId = const Value.absent(),
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
    Expression<bool>? enableEmoji,
    Expression<bool>? enableTextToImage,
    Expression<bool>? enableIndependentSendButton,
    Expression<String>? currentState,
    Expression<bool>? isPinned,
    Expression<String>? worldInfoIds,
    Expression<String>? textPresetIds,
    Expression<String>? apiPresetId,
    Expression<String>? imageApiPresetId,
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
      if (enableEmoji != null) 'enable_emoji': enableEmoji,
      if (enableTextToImage != null) 'enable_text_to_image': enableTextToImage,
      if (enableIndependentSendButton != null)
        'enable_independent_send_button': enableIndependentSendButton,
      if (currentState != null) 'current_state': currentState,
      if (isPinned != null) 'is_pinned': isPinned,
      if (worldInfoIds != null) 'world_info_ids': worldInfoIds,
      if (textPresetIds != null) 'text_preset_ids': textPresetIds,
      if (apiPresetId != null) 'api_preset_id': apiPresetId,
      if (imageApiPresetId != null) 'image_api_preset_id': imageApiPresetId,
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
      Value<bool>? enableEmoji,
      Value<bool>? enableTextToImage,
      Value<bool>? enableIndependentSendButton,
      Value<String?>? currentState,
      Value<bool>? isPinned,
      Value<List<String>>? worldInfoIds,
      Value<List<String>>? textPresetIds,
      Value<String?>? apiPresetId,
      Value<String?>? imageApiPresetId,
      Value<String?>? backgroundImage,
      Value<int>? rowid}) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      meId: meId ?? this.meId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      enableExtendedChat: enableExtendedChat ?? this.enableExtendedChat,
      enableEmoji: enableEmoji ?? this.enableEmoji,
      enableTextToImage: enableTextToImage ?? this.enableTextToImage,
      enableIndependentSendButton:
          enableIndependentSendButton ?? this.enableIndependentSendButton,
      currentState: currentState ?? this.currentState,
      isPinned: isPinned ?? this.isPinned,
      worldInfoIds: worldInfoIds ?? this.worldInfoIds,
      textPresetIds: textPresetIds ?? this.textPresetIds,
      apiPresetId: apiPresetId ?? this.apiPresetId,
      imageApiPresetId: imageApiPresetId ?? this.imageApiPresetId,
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
    if (enableEmoji.present) {
      map['enable_emoji'] = Variable<bool>(enableEmoji.value);
    }
    if (enableTextToImage.present) {
      map['enable_text_to_image'] = Variable<bool>(enableTextToImage.value);
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
    if (imageApiPresetId.present) {
      map['image_api_preset_id'] = Variable<String>(imageApiPresetId.value);
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
          ..write('enableEmoji: $enableEmoji, ')
          ..write('enableTextToImage: $enableTextToImage, ')
          ..write('enableIndependentSendButton: $enableIndependentSendButton, ')
          ..write('currentState: $currentState, ')
          ..write('isPinned: $isPinned, ')
          ..write('worldInfoIds: $worldInfoIds, ')
          ..write('textPresetIds: $textPresetIds, ')
          ..write('apiPresetId: $apiPresetId, ')
          ..write('imageApiPresetId: $imageApiPresetId, ')
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
  late final GeneratedColumnWithTypeConverter<List<MomentLike>, String> likes =
      GeneratedColumn<String>('likes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<MomentLike>>($MomentsPostsTable.$converterlikes);
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
  static TypeConverter<List<MomentLike>, String> $converterlikes =
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
  final List<MomentLike> likes;
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
      likes: serializer.fromJson<List<MomentLike>>(json['likes']),
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
      'likes': serializer.toJson<List<MomentLike>>(likes),
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
          List<MomentLike>? likes,
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
  final Value<List<MomentLike>> likes;
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
    required List<MomentLike> likes,
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
      Value<List<MomentLike>>? likes,
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
  @override
  late final GeneratedColumnWithTypeConverter<TextPresetType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<TextPresetType>($TextPresetsTable.$convertertype);
  static const VerificationMeta _isBuiltInMeta =
      const VerificationMeta('isBuiltIn');
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
      'is_built_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_built_in" IN (0, 1))'),
      defaultValue: const Constant(false));
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
      [id, name, content, type, isBuiltIn, createdAt, updatedAt];
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
    if (data.containsKey('is_built_in')) {
      context.handle(
          _isBuiltInMeta,
          isBuiltIn.isAcceptableOrUnknown(
              data['is_built_in']!, _isBuiltInMeta));
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
      type: $TextPresetsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      isBuiltIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_built_in'])!,
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

  static TypeConverter<TextPresetType, int> $convertertype =
      const TextPresetTypeConverter();
}

class TextPresetEntity extends DataClass
    implements Insertable<TextPresetEntity> {
  final String id;
  final String name;
  final String content;
  final TextPresetType type;
  final bool isBuiltIn;
  final int createdAt;
  final int updatedAt;
  const TextPresetEntity(
      {required this.id,
      required this.name,
      required this.content,
      required this.type,
      required this.isBuiltIn,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['content'] = Variable<String>(content);
    {
      map['type'] = Variable<int>($TextPresetsTable.$convertertype.toSql(type));
    }
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TextPresetsCompanion toCompanion(bool nullToAbsent) {
    return TextPresetsCompanion(
      id: Value(id),
      name: Value(name),
      content: Value(content),
      type: Value(type),
      isBuiltIn: Value(isBuiltIn),
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
      type: serializer.fromJson<TextPresetType>(json['type']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
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
      'type': serializer.toJson<TextPresetType>(type),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TextPresetEntity copyWith(
          {String? id,
          String? name,
          String? content,
          TextPresetType? type,
          bool? isBuiltIn,
          int? createdAt,
          int? updatedAt}) =>
      TextPresetEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        content: content ?? this.content,
        type: type ?? this.type,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TextPresetEntity copyWithCompanion(TextPresetsCompanion data) {
    return TextPresetEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      content: data.content.present ? data.content.value : this.content,
      type: data.type.present ? data.type.value : this.type,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
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
          ..write('type: $type, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, content, type, isBuiltIn, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextPresetEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.content == this.content &&
          other.type == this.type &&
          other.isBuiltIn == this.isBuiltIn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TextPresetsCompanion extends UpdateCompanion<TextPresetEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> content;
  final Value<TextPresetType> type;
  final Value<bool> isBuiltIn;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TextPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextPresetsCompanion.insert({
    required String id,
    required String name,
    required String content,
    this.type = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
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
    Expression<int>? type,
    Expression<bool>? isBuiltIn,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextPresetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? content,
      Value<TextPresetType>? type,
      Value<bool>? isBuiltIn,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return TextPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      type: type ?? this.type,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
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
    if (type.present) {
      map['type'] =
          Variable<int>($TextPresetsTable.$convertertype.toSql(type.value));
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
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
          ..write('type: $type, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoleMemoriesTable extends RoleMemories
    with TableInfo<$RoleMemoriesTable, RoleMemoryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoleMemoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceSessionIdMeta =
      const VerificationMeta('sourceSessionId');
  @override
  late final GeneratedColumn<String> sourceSessionId = GeneratedColumn<String>(
      'source_session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<MemoryCategory, int> category =
      GeneratedColumn<int>('category', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<MemoryCategory>($RoleMemoriesTable.$convertercategory);
  @override
  List<GeneratedColumn> get $columns =>
      [id, roleId, content, createdAt, updatedAt, sourceSessionId, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'role_memories';
  @override
  VerificationContext validateIntegrity(Insertable<RoleMemoryEntity> instance,
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
    if (data.containsKey('source_session_id')) {
      context.handle(
          _sourceSessionIdMeta,
          sourceSessionId.isAcceptableOrUnknown(
              data['source_session_id']!, _sourceSessionIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoleMemoryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoleMemoryEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      roleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      sourceSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_session_id']),
      category: $RoleMemoriesTable.$convertercategory.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category'])!),
    );
  }

  @override
  $RoleMemoriesTable createAlias(String alias) {
    return $RoleMemoriesTable(attachedDatabase, alias);
  }

  static TypeConverter<MemoryCategory, int> $convertercategory =
      const MemoryCategoryConverter();
}

class RoleMemoryEntity extends DataClass
    implements Insertable<RoleMemoryEntity> {
  final String id;
  final String roleId;
  final String content;
  final int createdAt;
  final int updatedAt;
  final String? sourceSessionId;
  final MemoryCategory category;
  const RoleMemoryEntity(
      {required this.id,
      required this.roleId,
      required this.content,
      required this.createdAt,
      required this.updatedAt,
      this.sourceSessionId,
      required this.category});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role_id'] = Variable<String>(roleId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || sourceSessionId != null) {
      map['source_session_id'] = Variable<String>(sourceSessionId);
    }
    {
      map['category'] =
          Variable<int>($RoleMemoriesTable.$convertercategory.toSql(category));
    }
    return map;
  }

  RoleMemoriesCompanion toCompanion(bool nullToAbsent) {
    return RoleMemoriesCompanion(
      id: Value(id),
      roleId: Value(roleId),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sourceSessionId: sourceSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceSessionId),
      category: Value(category),
    );
  }

  factory RoleMemoryEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoleMemoryEntity(
      id: serializer.fromJson<String>(json['id']),
      roleId: serializer.fromJson<String>(json['roleId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      sourceSessionId: serializer.fromJson<String?>(json['sourceSessionId']),
      category: serializer.fromJson<MemoryCategory>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roleId': serializer.toJson<String>(roleId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'sourceSessionId': serializer.toJson<String?>(sourceSessionId),
      'category': serializer.toJson<MemoryCategory>(category),
    };
  }

  RoleMemoryEntity copyWith(
          {String? id,
          String? roleId,
          String? content,
          int? createdAt,
          int? updatedAt,
          Value<String?> sourceSessionId = const Value.absent(),
          MemoryCategory? category}) =>
      RoleMemoryEntity(
        id: id ?? this.id,
        roleId: roleId ?? this.roleId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        sourceSessionId: sourceSessionId.present
            ? sourceSessionId.value
            : this.sourceSessionId,
        category: category ?? this.category,
      );
  RoleMemoryEntity copyWithCompanion(RoleMemoriesCompanion data) {
    return RoleMemoryEntity(
      id: data.id.present ? data.id.value : this.id,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sourceSessionId: data.sourceSessionId.present
          ? data.sourceSessionId.value
          : this.sourceSessionId,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoleMemoryEntity(')
          ..write('id: $id, ')
          ..write('roleId: $roleId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, roleId, content, createdAt, updatedAt, sourceSessionId, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoleMemoryEntity &&
          other.id == this.id &&
          other.roleId == this.roleId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sourceSessionId == this.sourceSessionId &&
          other.category == this.category);
}

class RoleMemoriesCompanion extends UpdateCompanion<RoleMemoryEntity> {
  final Value<String> id;
  final Value<String> roleId;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String?> sourceSessionId;
  final Value<MemoryCategory> category;
  final Value<int> rowid;
  const RoleMemoriesCompanion({
    this.id = const Value.absent(),
    this.roleId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sourceSessionId = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoleMemoriesCompanion.insert({
    required String id,
    required String roleId,
    required String content,
    required int createdAt,
    required int updatedAt,
    this.sourceSessionId = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        roleId = Value(roleId),
        content = Value(content),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<RoleMemoryEntity> custom({
    Expression<String>? id,
    Expression<String>? roleId,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? sourceSessionId,
    Expression<int>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roleId != null) 'role_id': roleId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sourceSessionId != null) 'source_session_id': sourceSessionId,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoleMemoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? roleId,
      Value<String>? content,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<String?>? sourceSessionId,
      Value<MemoryCategory>? category,
      Value<int>? rowid}) {
    return RoleMemoriesCompanion(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
      category: category ?? this.category,
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
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (sourceSessionId.present) {
      map['source_session_id'] = Variable<String>(sourceSessionId.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
          $RoleMemoriesTable.$convertercategory.toSql(category.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoleMemoriesCompanion(')
          ..write('id: $id, ')
          ..write('roleId: $roleId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactRolesTable extends ContactRoles
    with TableInfo<$ContactRolesTable, ContactRoleEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactRolesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appearanceMeta =
      const VerificationMeta('appearance');
  @override
  late final GeneratedColumn<String> appearance = GeneratedColumn<String>(
      'appearance', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      referenceImages = GeneratedColumn<String>(
              'reference_images', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ContactRolesTable.$converterreferenceImages);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      subscribedGroupIds = GeneratedColumn<String>(
              'subscribed_group_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ContactRolesTable.$convertersubscribedGroupIds);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      subscribedEmojiIds = GeneratedColumn<String>(
              'subscribed_emoji_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ContactRolesTable.$convertersubscribedEmojiIds);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        avatarPath,
        description,
        appearance,
        referenceImages,
        subscribedGroupIds,
        subscribedEmojiIds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_roles';
  @override
  VerificationContext validateIntegrity(Insertable<ContactRoleEntity> instance,
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
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('appearance')) {
      context.handle(
          _appearanceMeta,
          appearance.isAcceptableOrUnknown(
              data['appearance']!, _appearanceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactRoleEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactRoleEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      appearance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}appearance']),
      referenceImages: $ContactRolesTable.$converterreferenceImages.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}reference_images'])!),
      subscribedGroupIds: $ContactRolesTable.$convertersubscribedGroupIds
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}subscribed_group_ids'])!),
      subscribedEmojiIds: $ContactRolesTable.$convertersubscribedEmojiIds
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}subscribed_emoji_ids'])!),
    );
  }

  @override
  $ContactRolesTable createAlias(String alias) {
    return $ContactRolesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterreferenceImages =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertersubscribedGroupIds =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertersubscribedEmojiIds =
      const StringListConverter();
}

class ContactRoleEntity extends DataClass
    implements Insertable<ContactRoleEntity> {
  final String id;
  final String name;
  final String? avatarPath;
  final String description;
  final String? appearance;
  final List<String> referenceImages;
  final List<String> subscribedGroupIds;
  final List<String> subscribedEmojiIds;
  const ContactRoleEntity(
      {required this.id,
      required this.name,
      this.avatarPath,
      required this.description,
      this.appearance,
      required this.referenceImages,
      required this.subscribedGroupIds,
      required this.subscribedEmojiIds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || appearance != null) {
      map['appearance'] = Variable<String>(appearance);
    }
    {
      map['reference_images'] = Variable<String>(
          $ContactRolesTable.$converterreferenceImages.toSql(referenceImages));
    }
    {
      map['subscribed_group_ids'] = Variable<String>($ContactRolesTable
          .$convertersubscribedGroupIds
          .toSql(subscribedGroupIds));
    }
    {
      map['subscribed_emoji_ids'] = Variable<String>($ContactRolesTable
          .$convertersubscribedEmojiIds
          .toSql(subscribedEmojiIds));
    }
    return map;
  }

  ContactRolesCompanion toCompanion(bool nullToAbsent) {
    return ContactRolesCompanion(
      id: Value(id),
      name: Value(name),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      description: Value(description),
      appearance: appearance == null && nullToAbsent
          ? const Value.absent()
          : Value(appearance),
      referenceImages: Value(referenceImages),
      subscribedGroupIds: Value(subscribedGroupIds),
      subscribedEmojiIds: Value(subscribedEmojiIds),
    );
  }

  factory ContactRoleEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactRoleEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      description: serializer.fromJson<String>(json['description']),
      appearance: serializer.fromJson<String?>(json['appearance']),
      referenceImages:
          serializer.fromJson<List<String>>(json['referenceImages']),
      subscribedGroupIds:
          serializer.fromJson<List<String>>(json['subscribedGroupIds']),
      subscribedEmojiIds:
          serializer.fromJson<List<String>>(json['subscribedEmojiIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'description': serializer.toJson<String>(description),
      'appearance': serializer.toJson<String?>(appearance),
      'referenceImages': serializer.toJson<List<String>>(referenceImages),
      'subscribedGroupIds': serializer.toJson<List<String>>(subscribedGroupIds),
      'subscribedEmojiIds': serializer.toJson<List<String>>(subscribedEmojiIds),
    };
  }

  ContactRoleEntity copyWith(
          {String? id,
          String? name,
          Value<String?> avatarPath = const Value.absent(),
          String? description,
          Value<String?> appearance = const Value.absent(),
          List<String>? referenceImages,
          List<String>? subscribedGroupIds,
          List<String>? subscribedEmojiIds}) =>
      ContactRoleEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        description: description ?? this.description,
        appearance: appearance.present ? appearance.value : this.appearance,
        referenceImages: referenceImages ?? this.referenceImages,
        subscribedGroupIds: subscribedGroupIds ?? this.subscribedGroupIds,
        subscribedEmojiIds: subscribedEmojiIds ?? this.subscribedEmojiIds,
      );
  ContactRoleEntity copyWithCompanion(ContactRolesCompanion data) {
    return ContactRoleEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      description:
          data.description.present ? data.description.value : this.description,
      appearance:
          data.appearance.present ? data.appearance.value : this.appearance,
      referenceImages: data.referenceImages.present
          ? data.referenceImages.value
          : this.referenceImages,
      subscribedGroupIds: data.subscribedGroupIds.present
          ? data.subscribedGroupIds.value
          : this.subscribedGroupIds,
      subscribedEmojiIds: data.subscribedEmojiIds.present
          ? data.subscribedEmojiIds.value
          : this.subscribedEmojiIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactRoleEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('description: $description, ')
          ..write('appearance: $appearance, ')
          ..write('referenceImages: $referenceImages, ')
          ..write('subscribedGroupIds: $subscribedGroupIds, ')
          ..write('subscribedEmojiIds: $subscribedEmojiIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, avatarPath, description, appearance,
      referenceImages, subscribedGroupIds, subscribedEmojiIds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactRoleEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarPath == this.avatarPath &&
          other.description == this.description &&
          other.appearance == this.appearance &&
          other.referenceImages == this.referenceImages &&
          other.subscribedGroupIds == this.subscribedGroupIds &&
          other.subscribedEmojiIds == this.subscribedEmojiIds);
}

class ContactRolesCompanion extends UpdateCompanion<ContactRoleEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> avatarPath;
  final Value<String> description;
  final Value<String?> appearance;
  final Value<List<String>> referenceImages;
  final Value<List<String>> subscribedGroupIds;
  final Value<List<String>> subscribedEmojiIds;
  final Value<int> rowid;
  const ContactRolesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.description = const Value.absent(),
    this.appearance = const Value.absent(),
    this.referenceImages = const Value.absent(),
    this.subscribedGroupIds = const Value.absent(),
    this.subscribedEmojiIds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactRolesCompanion.insert({
    required String id,
    required String name,
    this.avatarPath = const Value.absent(),
    required String description,
    this.appearance = const Value.absent(),
    this.referenceImages = const Value.absent(),
    this.subscribedGroupIds = const Value.absent(),
    this.subscribedEmojiIds = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        description = Value(description);
  static Insertable<ContactRoleEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarPath,
    Expression<String>? description,
    Expression<String>? appearance,
    Expression<String>? referenceImages,
    Expression<String>? subscribedGroupIds,
    Expression<String>? subscribedEmojiIds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (description != null) 'description': description,
      if (appearance != null) 'appearance': appearance,
      if (referenceImages != null) 'reference_images': referenceImages,
      if (subscribedGroupIds != null)
        'subscribed_group_ids': subscribedGroupIds,
      if (subscribedEmojiIds != null)
        'subscribed_emoji_ids': subscribedEmojiIds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactRolesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? avatarPath,
      Value<String>? description,
      Value<String?>? appearance,
      Value<List<String>>? referenceImages,
      Value<List<String>>? subscribedGroupIds,
      Value<List<String>>? subscribedEmojiIds,
      Value<int>? rowid}) {
    return ContactRolesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      appearance: appearance ?? this.appearance,
      referenceImages: referenceImages ?? this.referenceImages,
      subscribedGroupIds: subscribedGroupIds ?? this.subscribedGroupIds,
      subscribedEmojiIds: subscribedEmojiIds ?? this.subscribedEmojiIds,
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
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (appearance.present) {
      map['appearance'] = Variable<String>(appearance.value);
    }
    if (referenceImages.present) {
      map['reference_images'] = Variable<String>($ContactRolesTable
          .$converterreferenceImages
          .toSql(referenceImages.value));
    }
    if (subscribedGroupIds.present) {
      map['subscribed_group_ids'] = Variable<String>($ContactRolesTable
          .$convertersubscribedGroupIds
          .toSql(subscribedGroupIds.value));
    }
    if (subscribedEmojiIds.present) {
      map['subscribed_emoji_ids'] = Variable<String>($ContactRolesTable
          .$convertersubscribedEmojiIds
          .toSql(subscribedEmojiIds.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactRolesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('description: $description, ')
          ..write('appearance: $appearance, ')
          ..write('referenceImages: $referenceImages, ')
          ..write('subscribedGroupIds: $subscribedGroupIds, ')
          ..write('subscribedEmojiIds: $subscribedEmojiIds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactMesTable extends ContactMes
    with TableInfo<$ContactMesTable, ContactMeEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactMesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _infoMeta = const VerificationMeta('info');
  @override
  late final GeneratedColumn<String> info = GeneratedColumn<String>(
      'info', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appearanceMeta =
      const VerificationMeta('appearance');
  @override
  late final GeneratedColumn<String> appearance = GeneratedColumn<String>(
      'appearance', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      referenceImages = GeneratedColumn<String>(
              'reference_images', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ContactMesTable.$converterreferenceImages);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, avatarPath, info, appearance, referenceImages];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_mes';
  @override
  VerificationContext validateIntegrity(Insertable<ContactMeEntity> instance,
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
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('info')) {
      context.handle(
          _infoMeta, info.isAcceptableOrUnknown(data['info']!, _infoMeta));
    } else if (isInserting) {
      context.missing(_infoMeta);
    }
    if (data.containsKey('appearance')) {
      context.handle(
          _appearanceMeta,
          appearance.isAcceptableOrUnknown(
              data['appearance']!, _appearanceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactMeEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactMeEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      info: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}info'])!,
      appearance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}appearance']),
      referenceImages: $ContactMesTable.$converterreferenceImages.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}reference_images'])!),
    );
  }

  @override
  $ContactMesTable createAlias(String alias) {
    return $ContactMesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterreferenceImages =
      const StringListConverter();
}

class ContactMeEntity extends DataClass implements Insertable<ContactMeEntity> {
  final String id;
  final String name;
  final String? avatarPath;
  final String info;
  final String? appearance;
  final List<String> referenceImages;
  const ContactMeEntity(
      {required this.id,
      required this.name,
      this.avatarPath,
      required this.info,
      this.appearance,
      required this.referenceImages});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['info'] = Variable<String>(info);
    if (!nullToAbsent || appearance != null) {
      map['appearance'] = Variable<String>(appearance);
    }
    {
      map['reference_images'] = Variable<String>(
          $ContactMesTable.$converterreferenceImages.toSql(referenceImages));
    }
    return map;
  }

  ContactMesCompanion toCompanion(bool nullToAbsent) {
    return ContactMesCompanion(
      id: Value(id),
      name: Value(name),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      info: Value(info),
      appearance: appearance == null && nullToAbsent
          ? const Value.absent()
          : Value(appearance),
      referenceImages: Value(referenceImages),
    );
  }

  factory ContactMeEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactMeEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      info: serializer.fromJson<String>(json['info']),
      appearance: serializer.fromJson<String?>(json['appearance']),
      referenceImages:
          serializer.fromJson<List<String>>(json['referenceImages']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'info': serializer.toJson<String>(info),
      'appearance': serializer.toJson<String?>(appearance),
      'referenceImages': serializer.toJson<List<String>>(referenceImages),
    };
  }

  ContactMeEntity copyWith(
          {String? id,
          String? name,
          Value<String?> avatarPath = const Value.absent(),
          String? info,
          Value<String?> appearance = const Value.absent(),
          List<String>? referenceImages}) =>
      ContactMeEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        info: info ?? this.info,
        appearance: appearance.present ? appearance.value : this.appearance,
        referenceImages: referenceImages ?? this.referenceImages,
      );
  ContactMeEntity copyWithCompanion(ContactMesCompanion data) {
    return ContactMeEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      info: data.info.present ? data.info.value : this.info,
      appearance:
          data.appearance.present ? data.appearance.value : this.appearance,
      referenceImages: data.referenceImages.present
          ? data.referenceImages.value
          : this.referenceImages,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactMeEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('info: $info, ')
          ..write('appearance: $appearance, ')
          ..write('referenceImages: $referenceImages')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, avatarPath, info, appearance, referenceImages);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactMeEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarPath == this.avatarPath &&
          other.info == this.info &&
          other.appearance == this.appearance &&
          other.referenceImages == this.referenceImages);
}

class ContactMesCompanion extends UpdateCompanion<ContactMeEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> avatarPath;
  final Value<String> info;
  final Value<String?> appearance;
  final Value<List<String>> referenceImages;
  final Value<int> rowid;
  const ContactMesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.info = const Value.absent(),
    this.appearance = const Value.absent(),
    this.referenceImages = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactMesCompanion.insert({
    required String id,
    required String name,
    this.avatarPath = const Value.absent(),
    required String info,
    this.appearance = const Value.absent(),
    this.referenceImages = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        info = Value(info);
  static Insertable<ContactMeEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarPath,
    Expression<String>? info,
    Expression<String>? appearance,
    Expression<String>? referenceImages,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (info != null) 'info': info,
      if (appearance != null) 'appearance': appearance,
      if (referenceImages != null) 'reference_images': referenceImages,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactMesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? avatarPath,
      Value<String>? info,
      Value<String?>? appearance,
      Value<List<String>>? referenceImages,
      Value<int>? rowid}) {
    return ContactMesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      info: info ?? this.info,
      appearance: appearance ?? this.appearance,
      referenceImages: referenceImages ?? this.referenceImages,
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
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (info.present) {
      map['info'] = Variable<String>(info.value);
    }
    if (appearance.present) {
      map['appearance'] = Variable<String>(appearance.value);
    }
    if (referenceImages.present) {
      map['reference_images'] = Variable<String>($ContactMesTable
          .$converterreferenceImages
          .toSql(referenceImages.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactMesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('info: $info, ')
          ..write('appearance: $appearance, ')
          ..write('referenceImages: $referenceImages, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiPresetsTable extends ApiPresets
    with TableInfo<$ApiPresetsTable, ApiPresetEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiPresetsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<ApiPresetType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<ApiPresetType>($ApiPresetsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<ApiProvider, int> provider =
      GeneratedColumn<int>('provider', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ApiProvider>($ApiPresetsTable.$converterprovider);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.7));
  static const VerificationMeta _topPMeta = const VerificationMeta('topP');
  @override
  late final GeneratedColumn<double> topP = GeneratedColumn<double>(
      'top_p', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.9));
  static const VerificationMeta _isStreamMeta =
      const VerificationMeta('isStream');
  @override
  late final GeneratedColumn<bool> isStream = GeneratedColumn<bool>(
      'is_stream', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_stream" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _enableThinkingMeta =
      const VerificationMeta('enableThinking');
  @override
  late final GeneratedColumn<bool> enableThinking = GeneratedColumn<bool>(
      'enable_thinking', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_thinking" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _timeoutMeta =
      const VerificationMeta('timeout');
  @override
  late final GeneratedColumn<int> timeout = GeneratedColumn<int>(
      'timeout', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(120));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        provider,
        baseUrl,
        apiKey,
        model,
        temperature,
        topP,
        isStream,
        enableThinking,
        timeout
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_presets';
  @override
  VerificationContext validateIntegrity(Insertable<ApiPresetEntity> instance,
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
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('top_p')) {
      context.handle(
          _topPMeta, topP.isAcceptableOrUnknown(data['top_p']!, _topPMeta));
    }
    if (data.containsKey('is_stream')) {
      context.handle(_isStreamMeta,
          isStream.isAcceptableOrUnknown(data['is_stream']!, _isStreamMeta));
    }
    if (data.containsKey('enable_thinking')) {
      context.handle(
          _enableThinkingMeta,
          enableThinking.isAcceptableOrUnknown(
              data['enable_thinking']!, _enableThinkingMeta));
    }
    if (data.containsKey('timeout')) {
      context.handle(_timeoutMeta,
          timeout.isAcceptableOrUnknown(data['timeout']!, _timeoutMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiPresetEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiPresetEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $ApiPresetsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      provider: $ApiPresetsTable.$converterprovider.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}provider'])!),
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url'])!,
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature'])!,
      topP: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}top_p'])!,
      isStream: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_stream'])!,
      enableThinking: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enable_thinking'])!,
      timeout: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timeout'])!,
    );
  }

  @override
  $ApiPresetsTable createAlias(String alias) {
    return $ApiPresetsTable(attachedDatabase, alias);
  }

  static TypeConverter<ApiPresetType, int> $convertertype =
      const ApiPresetTypeConverter();
  static TypeConverter<ApiProvider, int> $converterprovider =
      const ApiProviderConverter();
}

class ApiPresetEntity extends DataClass implements Insertable<ApiPresetEntity> {
  final String id;
  final String name;
  final ApiPresetType type;
  final ApiProvider provider;
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final double topP;
  final bool isStream;
  final bool enableThinking;
  final int timeout;
  const ApiPresetEntity(
      {required this.id,
      required this.name,
      required this.type,
      required this.provider,
      required this.baseUrl,
      required this.apiKey,
      required this.model,
      required this.temperature,
      required this.topP,
      required this.isStream,
      required this.enableThinking,
      required this.timeout});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>($ApiPresetsTable.$convertertype.toSql(type));
    }
    {
      map['provider'] =
          Variable<int>($ApiPresetsTable.$converterprovider.toSql(provider));
    }
    map['base_url'] = Variable<String>(baseUrl);
    map['api_key'] = Variable<String>(apiKey);
    map['model'] = Variable<String>(model);
    map['temperature'] = Variable<double>(temperature);
    map['top_p'] = Variable<double>(topP);
    map['is_stream'] = Variable<bool>(isStream);
    map['enable_thinking'] = Variable<bool>(enableThinking);
    map['timeout'] = Variable<int>(timeout);
    return map;
  }

  ApiPresetsCompanion toCompanion(bool nullToAbsent) {
    return ApiPresetsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      provider: Value(provider),
      baseUrl: Value(baseUrl),
      apiKey: Value(apiKey),
      model: Value(model),
      temperature: Value(temperature),
      topP: Value(topP),
      isStream: Value(isStream),
      enableThinking: Value(enableThinking),
      timeout: Value(timeout),
    );
  }

  factory ApiPresetEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiPresetEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<ApiPresetType>(json['type']),
      provider: serializer.fromJson<ApiProvider>(json['provider']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      model: serializer.fromJson<String>(json['model']),
      temperature: serializer.fromJson<double>(json['temperature']),
      topP: serializer.fromJson<double>(json['topP']),
      isStream: serializer.fromJson<bool>(json['isStream']),
      enableThinking: serializer.fromJson<bool>(json['enableThinking']),
      timeout: serializer.fromJson<int>(json['timeout']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<ApiPresetType>(type),
      'provider': serializer.toJson<ApiProvider>(provider),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'apiKey': serializer.toJson<String>(apiKey),
      'model': serializer.toJson<String>(model),
      'temperature': serializer.toJson<double>(temperature),
      'topP': serializer.toJson<double>(topP),
      'isStream': serializer.toJson<bool>(isStream),
      'enableThinking': serializer.toJson<bool>(enableThinking),
      'timeout': serializer.toJson<int>(timeout),
    };
  }

  ApiPresetEntity copyWith(
          {String? id,
          String? name,
          ApiPresetType? type,
          ApiProvider? provider,
          String? baseUrl,
          String? apiKey,
          String? model,
          double? temperature,
          double? topP,
          bool? isStream,
          bool? enableThinking,
          int? timeout}) =>
      ApiPresetEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        topP: topP ?? this.topP,
        isStream: isStream ?? this.isStream,
        enableThinking: enableThinking ?? this.enableThinking,
        timeout: timeout ?? this.timeout,
      );
  ApiPresetEntity copyWithCompanion(ApiPresetsCompanion data) {
    return ApiPresetEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      provider: data.provider.present ? data.provider.value : this.provider,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      model: data.model.present ? data.model.value : this.model,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      topP: data.topP.present ? data.topP.value : this.topP,
      isStream: data.isStream.present ? data.isStream.value : this.isStream,
      enableThinking: data.enableThinking.present
          ? data.enableThinking.value
          : this.enableThinking,
      timeout: data.timeout.present ? data.timeout.value : this.timeout,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiPresetEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('provider: $provider, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('model: $model, ')
          ..write('temperature: $temperature, ')
          ..write('topP: $topP, ')
          ..write('isStream: $isStream, ')
          ..write('enableThinking: $enableThinking, ')
          ..write('timeout: $timeout')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, provider, baseUrl, apiKey,
      model, temperature, topP, isStream, enableThinking, timeout);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiPresetEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.provider == this.provider &&
          other.baseUrl == this.baseUrl &&
          other.apiKey == this.apiKey &&
          other.model == this.model &&
          other.temperature == this.temperature &&
          other.topP == this.topP &&
          other.isStream == this.isStream &&
          other.enableThinking == this.enableThinking &&
          other.timeout == this.timeout);
}

class ApiPresetsCompanion extends UpdateCompanion<ApiPresetEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<ApiPresetType> type;
  final Value<ApiProvider> provider;
  final Value<String> baseUrl;
  final Value<String> apiKey;
  final Value<String> model;
  final Value<double> temperature;
  final Value<double> topP;
  final Value<bool> isStream;
  final Value<bool> enableThinking;
  final Value<int> timeout;
  final Value<int> rowid;
  const ApiPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.provider = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.model = const Value.absent(),
    this.temperature = const Value.absent(),
    this.topP = const Value.absent(),
    this.isStream = const Value.absent(),
    this.enableThinking = const Value.absent(),
    this.timeout = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiPresetsCompanion.insert({
    required String id,
    required String name,
    this.type = const Value.absent(),
    required ApiProvider provider,
    required String baseUrl,
    required String apiKey,
    required String model,
    this.temperature = const Value.absent(),
    this.topP = const Value.absent(),
    this.isStream = const Value.absent(),
    this.enableThinking = const Value.absent(),
    this.timeout = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        provider = Value(provider),
        baseUrl = Value(baseUrl),
        apiKey = Value(apiKey),
        model = Value(model);
  static Insertable<ApiPresetEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? provider,
    Expression<String>? baseUrl,
    Expression<String>? apiKey,
    Expression<String>? model,
    Expression<double>? temperature,
    Expression<double>? topP,
    Expression<bool>? isStream,
    Expression<bool>? enableThinking,
    Expression<int>? timeout,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (provider != null) 'provider': provider,
      if (baseUrl != null) 'base_url': baseUrl,
      if (apiKey != null) 'api_key': apiKey,
      if (model != null) 'model': model,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (isStream != null) 'is_stream': isStream,
      if (enableThinking != null) 'enable_thinking': enableThinking,
      if (timeout != null) 'timeout': timeout,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiPresetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<ApiPresetType>? type,
      Value<ApiProvider>? provider,
      Value<String>? baseUrl,
      Value<String>? apiKey,
      Value<String>? model,
      Value<double>? temperature,
      Value<double>? topP,
      Value<bool>? isStream,
      Value<bool>? enableThinking,
      Value<int>? timeout,
      Value<int>? rowid}) {
    return ApiPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      isStream: isStream ?? this.isStream,
      enableThinking: enableThinking ?? this.enableThinking,
      timeout: timeout ?? this.timeout,
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
    if (type.present) {
      map['type'] =
          Variable<int>($ApiPresetsTable.$convertertype.toSql(type.value));
    }
    if (provider.present) {
      map['provider'] = Variable<int>(
          $ApiPresetsTable.$converterprovider.toSql(provider.value));
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (topP.present) {
      map['top_p'] = Variable<double>(topP.value);
    }
    if (isStream.present) {
      map['is_stream'] = Variable<bool>(isStream.value);
    }
    if (enableThinking.present) {
      map['enable_thinking'] = Variable<bool>(enableThinking.value);
    }
    if (timeout.present) {
      map['timeout'] = Variable<int>(timeout.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('provider: $provider, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('model: $model, ')
          ..write('temperature: $temperature, ')
          ..write('topP: $topP, ')
          ..write('isStream: $isStream, ')
          ..write('enableThinking: $enableThinking, ')
          ..write('timeout: $timeout, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MomentsUserSettingsTable extends MomentsUserSettings
    with TableInfo<$MomentsUserSettingsTable, MomentsUserSettingsEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MomentsUserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('我'));
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverImageUrlMeta =
      const VerificationMeta('coverImageUrl');
  @override
  late final GeneratedColumn<String> coverImageUrl = GeneratedColumn<String>(
      'cover_image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _signatureMeta =
      const VerificationMeta('signature');
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
      'signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, avatarUrl, coverImageUrl, signature];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moments_user_settings';
  @override
  VerificationContext validateIntegrity(
      Insertable<MomentsUserSettingsEntity> instance,
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
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('cover_image_url')) {
      context.handle(
          _coverImageUrlMeta,
          coverImageUrl.isAcceptableOrUnknown(
              data['cover_image_url']!, _coverImageUrlMeta));
    }
    if (data.containsKey('signature')) {
      context.handle(_signatureMeta,
          signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MomentsUserSettingsEntity map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MomentsUserSettingsEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      coverImageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_image_url']),
      signature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signature']),
    );
  }

  @override
  $MomentsUserSettingsTable createAlias(String alias) {
    return $MomentsUserSettingsTable(attachedDatabase, alias);
  }
}

class MomentsUserSettingsEntity extends DataClass
    implements Insertable<MomentsUserSettingsEntity> {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? signature;
  const MomentsUserSettingsEntity(
      {required this.id,
      required this.name,
      this.avatarUrl,
      this.coverImageUrl,
      this.signature});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || coverImageUrl != null) {
      map['cover_image_url'] = Variable<String>(coverImageUrl);
    }
    if (!nullToAbsent || signature != null) {
      map['signature'] = Variable<String>(signature);
    }
    return map;
  }

  MomentsUserSettingsCompanion toCompanion(bool nullToAbsent) {
    return MomentsUserSettingsCompanion(
      id: Value(id),
      name: Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      coverImageUrl: coverImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageUrl),
      signature: signature == null && nullToAbsent
          ? const Value.absent()
          : Value(signature),
    );
  }

  factory MomentsUserSettingsEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MomentsUserSettingsEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      coverImageUrl: serializer.fromJson<String?>(json['coverImageUrl']),
      signature: serializer.fromJson<String?>(json['signature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'coverImageUrl': serializer.toJson<String?>(coverImageUrl),
      'signature': serializer.toJson<String?>(signature),
    };
  }

  MomentsUserSettingsEntity copyWith(
          {String? id,
          String? name,
          Value<String?> avatarUrl = const Value.absent(),
          Value<String?> coverImageUrl = const Value.absent(),
          Value<String?> signature = const Value.absent()}) =>
      MomentsUserSettingsEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        coverImageUrl:
            coverImageUrl.present ? coverImageUrl.value : this.coverImageUrl,
        signature: signature.present ? signature.value : this.signature,
      );
  MomentsUserSettingsEntity copyWithCompanion(
      MomentsUserSettingsCompanion data) {
    return MomentsUserSettingsEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      coverImageUrl: data.coverImageUrl.present
          ? data.coverImageUrl.value
          : this.coverImageUrl,
      signature: data.signature.present ? data.signature.value : this.signature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MomentsUserSettingsEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('signature: $signature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, avatarUrl, coverImageUrl, signature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MomentsUserSettingsEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.coverImageUrl == this.coverImageUrl &&
          other.signature == this.signature);
}

class MomentsUserSettingsCompanion
    extends UpdateCompanion<MomentsUserSettingsEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> avatarUrl;
  final Value<String?> coverImageUrl;
  final Value<String?> signature;
  final Value<int> rowid;
  const MomentsUserSettingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.signature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MomentsUserSettingsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.signature = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MomentsUserSettingsEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<String>? coverImageUrl,
    Expression<String>? signature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (signature != null) 'signature': signature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MomentsUserSettingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? avatarUrl,
      Value<String?>? coverImageUrl,
      Value<String?>? signature,
      Value<int>? rowid}) {
    return MomentsUserSettingsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      signature: signature ?? this.signature,
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
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (coverImageUrl.present) {
      map['cover_image_url'] = Variable<String>(coverImageUrl.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MomentsUserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('signature: $signature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('string'));
  @override
  List<GeneratedColumn> get $columns => [key, value, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettingEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingEntity(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingEntity extends DataClass
    implements Insertable<AppSettingEntity> {
  final String key;
  final String value;
  final String type;
  const AppSettingEntity(
      {required this.key, required this.value, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['type'] = Variable<String>(type);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      type: Value(type),
    );
  }

  factory AppSettingEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingEntity(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'type': serializer.toJson<String>(type),
    };
  }

  AppSettingEntity copyWith({String? key, String? value, String? type}) =>
      AppSettingEntity(
        key: key ?? this.key,
        value: value ?? this.value,
        type: type ?? this.type,
      );
  AppSettingEntity copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingEntity(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingEntity(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingEntity &&
          other.key == this.key &&
          other.value == this.value &&
          other.type == this.type);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingEntity> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> type;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSettingEntity> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<String>? type,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletTransactionsTable extends WalletTransactions
    with TableInfo<$WalletTransactionsTable, WalletTransactionEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<WalletTransactionType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<WalletTransactionType>(
              $WalletTransactionsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<TransactionDirection, int>
      direction = GeneratedColumn<int>('direction', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransactionDirection>(
              $WalletTransactionsTable.$converterdirection);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _relatedContactNameMeta =
      const VerificationMeta('relatedContactName');
  @override
  late final GeneratedColumn<String> relatedContactName =
      GeneratedColumn<String>('related_contact_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _relatedSessionIdMeta =
      const VerificationMeta('relatedSessionId');
  @override
  late final GeneratedColumn<String> relatedSessionId = GeneratedColumn<String>(
      'related_session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _relatedMessageIdMeta =
      const VerificationMeta('relatedMessageId');
  @override
  late final GeneratedColumn<String> relatedMessageId = GeneratedColumn<String>(
      'related_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        direction,
        amount,
        description,
        relatedContactName,
        relatedSessionId,
        relatedMessageId,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallet_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<WalletTransactionEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('related_contact_name')) {
      context.handle(
          _relatedContactNameMeta,
          relatedContactName.isAcceptableOrUnknown(
              data['related_contact_name']!, _relatedContactNameMeta));
    }
    if (data.containsKey('related_session_id')) {
      context.handle(
          _relatedSessionIdMeta,
          relatedSessionId.isAcceptableOrUnknown(
              data['related_session_id']!, _relatedSessionIdMeta));
    }
    if (data.containsKey('related_message_id')) {
      context.handle(
          _relatedMessageIdMeta,
          relatedMessageId.isAcceptableOrUnknown(
              data['related_message_id']!, _relatedMessageIdMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletTransactionEntity map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletTransactionEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: $WalletTransactionsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      direction: $WalletTransactionsTable.$converterdirection.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}direction'])!),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      relatedContactName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_contact_name']),
      relatedSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_session_id']),
      relatedMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_message_id']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $WalletTransactionsTable createAlias(String alias) {
    return $WalletTransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<WalletTransactionType, int> $convertertype =
      const WalletTransactionTypeConverter();
  static TypeConverter<TransactionDirection, int> $converterdirection =
      const TransactionDirectionConverter();
}

class WalletTransactionEntity extends DataClass
    implements Insertable<WalletTransactionEntity> {
  final String id;
  final WalletTransactionType type;
  final TransactionDirection direction;
  final double amount;
  final String? description;
  final String? relatedContactName;
  final String? relatedSessionId;
  final String? relatedMessageId;
  final int timestamp;
  const WalletTransactionEntity(
      {required this.id,
      required this.type,
      required this.direction,
      required this.amount,
      this.description,
      this.relatedContactName,
      this.relatedSessionId,
      this.relatedMessageId,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] =
          Variable<int>($WalletTransactionsTable.$convertertype.toSql(type));
    }
    {
      map['direction'] = Variable<int>(
          $WalletTransactionsTable.$converterdirection.toSql(direction));
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || relatedContactName != null) {
      map['related_contact_name'] = Variable<String>(relatedContactName);
    }
    if (!nullToAbsent || relatedSessionId != null) {
      map['related_session_id'] = Variable<String>(relatedSessionId);
    }
    if (!nullToAbsent || relatedMessageId != null) {
      map['related_message_id'] = Variable<String>(relatedMessageId);
    }
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  WalletTransactionsCompanion toCompanion(bool nullToAbsent) {
    return WalletTransactionsCompanion(
      id: Value(id),
      type: Value(type),
      direction: Value(direction),
      amount: Value(amount),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      relatedContactName: relatedContactName == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedContactName),
      relatedSessionId: relatedSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedSessionId),
      relatedMessageId: relatedMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedMessageId),
      timestamp: Value(timestamp),
    );
  }

  factory WalletTransactionEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletTransactionEntity(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<WalletTransactionType>(json['type']),
      direction: serializer.fromJson<TransactionDirection>(json['direction']),
      amount: serializer.fromJson<double>(json['amount']),
      description: serializer.fromJson<String?>(json['description']),
      relatedContactName:
          serializer.fromJson<String?>(json['relatedContactName']),
      relatedSessionId: serializer.fromJson<String?>(json['relatedSessionId']),
      relatedMessageId: serializer.fromJson<String?>(json['relatedMessageId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<WalletTransactionType>(type),
      'direction': serializer.toJson<TransactionDirection>(direction),
      'amount': serializer.toJson<double>(amount),
      'description': serializer.toJson<String?>(description),
      'relatedContactName': serializer.toJson<String?>(relatedContactName),
      'relatedSessionId': serializer.toJson<String?>(relatedSessionId),
      'relatedMessageId': serializer.toJson<String?>(relatedMessageId),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  WalletTransactionEntity copyWith(
          {String? id,
          WalletTransactionType? type,
          TransactionDirection? direction,
          double? amount,
          Value<String?> description = const Value.absent(),
          Value<String?> relatedContactName = const Value.absent(),
          Value<String?> relatedSessionId = const Value.absent(),
          Value<String?> relatedMessageId = const Value.absent(),
          int? timestamp}) =>
      WalletTransactionEntity(
        id: id ?? this.id,
        type: type ?? this.type,
        direction: direction ?? this.direction,
        amount: amount ?? this.amount,
        description: description.present ? description.value : this.description,
        relatedContactName: relatedContactName.present
            ? relatedContactName.value
            : this.relatedContactName,
        relatedSessionId: relatedSessionId.present
            ? relatedSessionId.value
            : this.relatedSessionId,
        relatedMessageId: relatedMessageId.present
            ? relatedMessageId.value
            : this.relatedMessageId,
        timestamp: timestamp ?? this.timestamp,
      );
  WalletTransactionEntity copyWithCompanion(WalletTransactionsCompanion data) {
    return WalletTransactionEntity(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      direction: data.direction.present ? data.direction.value : this.direction,
      amount: data.amount.present ? data.amount.value : this.amount,
      description:
          data.description.present ? data.description.value : this.description,
      relatedContactName: data.relatedContactName.present
          ? data.relatedContactName.value
          : this.relatedContactName,
      relatedSessionId: data.relatedSessionId.present
          ? data.relatedSessionId.value
          : this.relatedSessionId,
      relatedMessageId: data.relatedMessageId.present
          ? data.relatedMessageId.value
          : this.relatedMessageId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletTransactionEntity(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('direction: $direction, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('relatedContactName: $relatedContactName, ')
          ..write('relatedSessionId: $relatedSessionId, ')
          ..write('relatedMessageId: $relatedMessageId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, direction, amount, description,
      relatedContactName, relatedSessionId, relatedMessageId, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletTransactionEntity &&
          other.id == this.id &&
          other.type == this.type &&
          other.direction == this.direction &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.relatedContactName == this.relatedContactName &&
          other.relatedSessionId == this.relatedSessionId &&
          other.relatedMessageId == this.relatedMessageId &&
          other.timestamp == this.timestamp);
}

class WalletTransactionsCompanion
    extends UpdateCompanion<WalletTransactionEntity> {
  final Value<String> id;
  final Value<WalletTransactionType> type;
  final Value<TransactionDirection> direction;
  final Value<double> amount;
  final Value<String?> description;
  final Value<String?> relatedContactName;
  final Value<String?> relatedSessionId;
  final Value<String?> relatedMessageId;
  final Value<int> timestamp;
  final Value<int> rowid;
  const WalletTransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.direction = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.relatedContactName = const Value.absent(),
    this.relatedSessionId = const Value.absent(),
    this.relatedMessageId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletTransactionsCompanion.insert({
    required String id,
    required WalletTransactionType type,
    required TransactionDirection direction,
    required double amount,
    this.description = const Value.absent(),
    this.relatedContactName = const Value.absent(),
    this.relatedSessionId = const Value.absent(),
    this.relatedMessageId = const Value.absent(),
    required int timestamp,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        direction = Value(direction),
        amount = Value(amount),
        timestamp = Value(timestamp);
  static Insertable<WalletTransactionEntity> custom({
    Expression<String>? id,
    Expression<int>? type,
    Expression<int>? direction,
    Expression<double>? amount,
    Expression<String>? description,
    Expression<String>? relatedContactName,
    Expression<String>? relatedSessionId,
    Expression<String>? relatedMessageId,
    Expression<int>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (direction != null) 'direction': direction,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (relatedContactName != null)
        'related_contact_name': relatedContactName,
      if (relatedSessionId != null) 'related_session_id': relatedSessionId,
      if (relatedMessageId != null) 'related_message_id': relatedMessageId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<WalletTransactionType>? type,
      Value<TransactionDirection>? direction,
      Value<double>? amount,
      Value<String?>? description,
      Value<String?>? relatedContactName,
      Value<String?>? relatedSessionId,
      Value<String?>? relatedMessageId,
      Value<int>? timestamp,
      Value<int>? rowid}) {
    return WalletTransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      relatedContactName: relatedContactName ?? this.relatedContactName,
      relatedSessionId: relatedSessionId ?? this.relatedSessionId,
      relatedMessageId: relatedMessageId ?? this.relatedMessageId,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $WalletTransactionsTable.$convertertype.toSql(type.value));
    }
    if (direction.present) {
      map['direction'] = Variable<int>(
          $WalletTransactionsTable.$converterdirection.toSql(direction.value));
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (relatedContactName.present) {
      map['related_contact_name'] = Variable<String>(relatedContactName.value);
    }
    if (relatedSessionId.present) {
      map['related_session_id'] = Variable<String>(relatedSessionId.value);
    }
    if (relatedMessageId.present) {
      map['related_message_id'] = Variable<String>(relatedMessageId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('direction: $direction, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('relatedContactName: $relatedContactName, ')
          ..write('relatedSessionId: $relatedSessionId, ')
          ..write('relatedMessageId: $relatedMessageId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmojisTable extends Emojis with TableInfo<$EmojisTable, EmojiEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmojisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
      'meaning', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawContentMeta =
      const VerificationMeta('rawContent');
  @override
  late final GeneratedColumn<String> rawContent = GeneratedColumn<String>(
      'raw_content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<EmojiType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<EmojiType>($EmojisTable.$convertertype);
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
      'role_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, meaning, rawContent, groupId, localPath, type, roleId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emojis';
  @override
  VerificationContext validateIntegrity(Insertable<EmojiEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('raw_content')) {
      context.handle(
          _rawContentMeta,
          rawContent.isAcceptableOrUnknown(
              data['raw_content']!, _rawContentMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(_roleIdMeta,
          roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmojiEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmojiEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning'])!,
      rawContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_content']),
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      type: $EmojisTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      roleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmojisTable createAlias(String alias) {
    return $EmojisTable(attachedDatabase, alias);
  }

  static TypeConverter<EmojiType, int> $convertertype =
      const EmojiTypeConverter();
}

class EmojiEntity extends DataClass implements Insertable<EmojiEntity> {
  final String id;
  final String meaning;
  final String? rawContent;
  final String? groupId;
  final String localPath;
  final EmojiType type;
  final String? roleId;
  final int createdAt;
  const EmojiEntity(
      {required this.id,
      required this.meaning,
      this.rawContent,
      this.groupId,
      required this.localPath,
      required this.type,
      this.roleId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || rawContent != null) {
      map['raw_content'] = Variable<String>(rawContent);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['local_path'] = Variable<String>(localPath);
    {
      map['type'] = Variable<int>($EmojisTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || roleId != null) {
      map['role_id'] = Variable<String>(roleId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  EmojisCompanion toCompanion(bool nullToAbsent) {
    return EmojisCompanion(
      id: Value(id),
      meaning: Value(meaning),
      rawContent: rawContent == null && nullToAbsent
          ? const Value.absent()
          : Value(rawContent),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      localPath: Value(localPath),
      type: Value(type),
      roleId:
          roleId == null && nullToAbsent ? const Value.absent() : Value(roleId),
      createdAt: Value(createdAt),
    );
  }

  factory EmojiEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmojiEntity(
      id: serializer.fromJson<String>(json['id']),
      meaning: serializer.fromJson<String>(json['meaning']),
      rawContent: serializer.fromJson<String?>(json['rawContent']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      type: serializer.fromJson<EmojiType>(json['type']),
      roleId: serializer.fromJson<String?>(json['roleId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meaning': serializer.toJson<String>(meaning),
      'rawContent': serializer.toJson<String?>(rawContent),
      'groupId': serializer.toJson<String?>(groupId),
      'localPath': serializer.toJson<String>(localPath),
      'type': serializer.toJson<EmojiType>(type),
      'roleId': serializer.toJson<String?>(roleId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  EmojiEntity copyWith(
          {String? id,
          String? meaning,
          Value<String?> rawContent = const Value.absent(),
          Value<String?> groupId = const Value.absent(),
          String? localPath,
          EmojiType? type,
          Value<String?> roleId = const Value.absent(),
          int? createdAt}) =>
      EmojiEntity(
        id: id ?? this.id,
        meaning: meaning ?? this.meaning,
        rawContent: rawContent.present ? rawContent.value : this.rawContent,
        groupId: groupId.present ? groupId.value : this.groupId,
        localPath: localPath ?? this.localPath,
        type: type ?? this.type,
        roleId: roleId.present ? roleId.value : this.roleId,
        createdAt: createdAt ?? this.createdAt,
      );
  EmojiEntity copyWithCompanion(EmojisCompanion data) {
    return EmojiEntity(
      id: data.id.present ? data.id.value : this.id,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      rawContent:
          data.rawContent.present ? data.rawContent.value : this.rawContent,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      type: data.type.present ? data.type.value : this.type,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmojiEntity(')
          ..write('id: $id, ')
          ..write('meaning: $meaning, ')
          ..write('rawContent: $rawContent, ')
          ..write('groupId: $groupId, ')
          ..write('localPath: $localPath, ')
          ..write('type: $type, ')
          ..write('roleId: $roleId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, meaning, rawContent, groupId, localPath, type, roleId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmojiEntity &&
          other.id == this.id &&
          other.meaning == this.meaning &&
          other.rawContent == this.rawContent &&
          other.groupId == this.groupId &&
          other.localPath == this.localPath &&
          other.type == this.type &&
          other.roleId == this.roleId &&
          other.createdAt == this.createdAt);
}

class EmojisCompanion extends UpdateCompanion<EmojiEntity> {
  final Value<String> id;
  final Value<String> meaning;
  final Value<String?> rawContent;
  final Value<String?> groupId;
  final Value<String> localPath;
  final Value<EmojiType> type;
  final Value<String?> roleId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const EmojisCompanion({
    this.id = const Value.absent(),
    this.meaning = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.groupId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.type = const Value.absent(),
    this.roleId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmojisCompanion.insert({
    required String id,
    required String meaning,
    this.rawContent = const Value.absent(),
    this.groupId = const Value.absent(),
    required String localPath,
    required EmojiType type,
    this.roleId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        meaning = Value(meaning),
        localPath = Value(localPath),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<EmojiEntity> custom({
    Expression<String>? id,
    Expression<String>? meaning,
    Expression<String>? rawContent,
    Expression<String>? groupId,
    Expression<String>? localPath,
    Expression<int>? type,
    Expression<String>? roleId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meaning != null) 'meaning': meaning,
      if (rawContent != null) 'raw_content': rawContent,
      if (groupId != null) 'group_id': groupId,
      if (localPath != null) 'local_path': localPath,
      if (type != null) 'type': type,
      if (roleId != null) 'role_id': roleId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmojisCompanion copyWith(
      {Value<String>? id,
      Value<String>? meaning,
      Value<String?>? rawContent,
      Value<String?>? groupId,
      Value<String>? localPath,
      Value<EmojiType>? type,
      Value<String?>? roleId,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return EmojisCompanion(
      id: id ?? this.id,
      meaning: meaning ?? this.meaning,
      rawContent: rawContent ?? this.rawContent,
      groupId: groupId ?? this.groupId,
      localPath: localPath ?? this.localPath,
      type: type ?? this.type,
      roleId: roleId ?? this.roleId,
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
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (rawContent.present) {
      map['raw_content'] = Variable<String>(rawContent.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($EmojisTable.$convertertype.toSql(type.value));
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmojisCompanion(')
          ..write('id: $id, ')
          ..write('meaning: $meaning, ')
          ..write('rawContent: $rawContent, ')
          ..write('groupId: $groupId, ')
          ..write('localPath: $localPath, ')
          ..write('type: $type, ')
          ..write('roleId: $roleId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmojiGroupsTable extends EmojiGroups
    with TableInfo<$EmojiGroupsTable, EmojiGroupEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmojiGroupsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<EmojiType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<EmojiType>($EmojiGroupsTable.$convertertype);
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
      'role_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isVisibleMeta =
      const VerificationMeta('isVisible');
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
      'is_visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_visible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, roleId, isVisible, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emoji_groups';
  @override
  VerificationContext validateIntegrity(Insertable<EmojiGroupEntity> instance,
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
    if (data.containsKey('role_id')) {
      context.handle(_roleIdMeta,
          roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta));
    }
    if (data.containsKey('is_visible')) {
      context.handle(_isVisibleMeta,
          isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmojiGroupEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmojiGroupEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $EmojiGroupsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      roleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role_id']),
      isVisible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_visible'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmojiGroupsTable createAlias(String alias) {
    return $EmojiGroupsTable(attachedDatabase, alias);
  }

  static TypeConverter<EmojiType, int> $convertertype =
      const EmojiTypeConverter();
}

class EmojiGroupEntity extends DataClass
    implements Insertable<EmojiGroupEntity> {
  final String id;
  final String name;
  final EmojiType type;
  final String? roleId;
  final bool isVisible;
  final int createdAt;
  const EmojiGroupEntity(
      {required this.id,
      required this.name,
      required this.type,
      this.roleId,
      required this.isVisible,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>($EmojiGroupsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || roleId != null) {
      map['role_id'] = Variable<String>(roleId);
    }
    map['is_visible'] = Variable<bool>(isVisible);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  EmojiGroupsCompanion toCompanion(bool nullToAbsent) {
    return EmojiGroupsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      roleId:
          roleId == null && nullToAbsent ? const Value.absent() : Value(roleId),
      isVisible: Value(isVisible),
      createdAt: Value(createdAt),
    );
  }

  factory EmojiGroupEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmojiGroupEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<EmojiType>(json['type']),
      roleId: serializer.fromJson<String?>(json['roleId']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<EmojiType>(type),
      'roleId': serializer.toJson<String?>(roleId),
      'isVisible': serializer.toJson<bool>(isVisible),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  EmojiGroupEntity copyWith(
          {String? id,
          String? name,
          EmojiType? type,
          Value<String?> roleId = const Value.absent(),
          bool? isVisible,
          int? createdAt}) =>
      EmojiGroupEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        roleId: roleId.present ? roleId.value : this.roleId,
        isVisible: isVisible ?? this.isVisible,
        createdAt: createdAt ?? this.createdAt,
      );
  EmojiGroupEntity copyWithCompanion(EmojiGroupsCompanion data) {
    return EmojiGroupEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmojiGroupEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('roleId: $roleId, ')
          ..write('isVisible: $isVisible, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, roleId, isVisible, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmojiGroupEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.roleId == this.roleId &&
          other.isVisible == this.isVisible &&
          other.createdAt == this.createdAt);
}

class EmojiGroupsCompanion extends UpdateCompanion<EmojiGroupEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<EmojiType> type;
  final Value<String?> roleId;
  final Value<bool> isVisible;
  final Value<int> createdAt;
  final Value<int> rowid;
  const EmojiGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.roleId = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmojiGroupsCompanion.insert({
    required String id,
    required String name,
    required EmojiType type,
    this.roleId = const Value.absent(),
    this.isVisible = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<EmojiGroupEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? type,
    Expression<String>? roleId,
    Expression<bool>? isVisible,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (roleId != null) 'role_id': roleId,
      if (isVisible != null) 'is_visible': isVisible,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmojiGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<EmojiType>? type,
      Value<String?>? roleId,
      Value<bool>? isVisible,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return EmojiGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      roleId: roleId ?? this.roleId,
      isVisible: isVisible ?? this.isVisible,
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
    if (type.present) {
      map['type'] =
          Variable<int>($EmojiGroupsTable.$convertertype.toSql(type.value));
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmojiGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('roleId: $roleId, ')
          ..write('isVisible: $isVisible, ')
          ..write('createdAt: $createdAt, ')
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
  late final $RoleMemoriesTable roleMemories = $RoleMemoriesTable(this);
  late final $ContactRolesTable contactRoles = $ContactRolesTable(this);
  late final $ContactMesTable contactMes = $ContactMesTable(this);
  late final $ApiPresetsTable apiPresets = $ApiPresetsTable(this);
  late final $MomentsUserSettingsTable momentsUserSettings =
      $MomentsUserSettingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $WalletTransactionsTable walletTransactions =
      $WalletTransactionsTable(this);
  late final $EmojisTable emojis = $EmojisTable(this);
  late final $EmojiGroupsTable emojiGroups = $EmojiGroupsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        chatSessions,
        chatMessages,
        momentsPosts,
        worldInfos,
        textPresets,
        roleMemories,
        contactRoles,
        contactMes,
        apiPresets,
        momentsUserSettings,
        appSettings,
        walletTransactions,
        emojis,
        emojiGroups
      ];
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
  Value<bool> enableEmoji,
  Value<bool> enableTextToImage,
  Value<bool> enableIndependentSendButton,
  Value<String?> currentState,
  Value<bool> isPinned,
  Value<List<String>> worldInfoIds,
  Value<List<String>> textPresetIds,
  Value<String?> apiPresetId,
  Value<String?> imageApiPresetId,
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
  Value<bool> enableEmoji,
  Value<bool> enableTextToImage,
  Value<bool> enableIndependentSendButton,
  Value<String?> currentState,
  Value<bool> isPinned,
  Value<List<String>> worldInfoIds,
  Value<List<String>> textPresetIds,
  Value<String?> apiPresetId,
  Value<String?> imageApiPresetId,
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

  ColumnFilters<bool> get enableEmoji => $composableBuilder(
      column: $table.enableEmoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableTextToImage => $composableBuilder(
      column: $table.enableTextToImage,
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

  ColumnFilters<String> get imageApiPresetId => $composableBuilder(
      column: $table.imageApiPresetId,
      builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<bool> get enableEmoji => $composableBuilder(
      column: $table.enableEmoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableTextToImage => $composableBuilder(
      column: $table.enableTextToImage,
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

  ColumnOrderings<String> get imageApiPresetId => $composableBuilder(
      column: $table.imageApiPresetId,
      builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<bool> get enableEmoji => $composableBuilder(
      column: $table.enableEmoji, builder: (column) => column);

  GeneratedColumn<bool> get enableTextToImage => $composableBuilder(
      column: $table.enableTextToImage, builder: (column) => column);

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

  GeneratedColumn<String> get imageApiPresetId => $composableBuilder(
      column: $table.imageApiPresetId, builder: (column) => column);

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
            Value<bool> enableEmoji = const Value.absent(),
            Value<bool> enableTextToImage = const Value.absent(),
            Value<bool> enableIndependentSendButton = const Value.absent(),
            Value<String?> currentState = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<List<String>> worldInfoIds = const Value.absent(),
            Value<List<String>> textPresetIds = const Value.absent(),
            Value<String?> apiPresetId = const Value.absent(),
            Value<String?> imageApiPresetId = const Value.absent(),
            Value<String?> backgroundImage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion(
            id: id,
            roleId: roleId,
            meId: meId,
            lastUpdated: lastUpdated,
            enableExtendedChat: enableExtendedChat,
            enableEmoji: enableEmoji,
            enableTextToImage: enableTextToImage,
            enableIndependentSendButton: enableIndependentSendButton,
            currentState: currentState,
            isPinned: isPinned,
            worldInfoIds: worldInfoIds,
            textPresetIds: textPresetIds,
            apiPresetId: apiPresetId,
            imageApiPresetId: imageApiPresetId,
            backgroundImage: backgroundImage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String roleId,
            required String meId,
            required int lastUpdated,
            Value<bool> enableExtendedChat = const Value.absent(),
            Value<bool> enableEmoji = const Value.absent(),
            Value<bool> enableTextToImage = const Value.absent(),
            Value<bool> enableIndependentSendButton = const Value.absent(),
            Value<String?> currentState = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<List<String>> worldInfoIds = const Value.absent(),
            Value<List<String>> textPresetIds = const Value.absent(),
            Value<String?> apiPresetId = const Value.absent(),
            Value<String?> imageApiPresetId = const Value.absent(),
            Value<String?> backgroundImage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion.insert(
            id: id,
            roleId: roleId,
            meId: meId,
            lastUpdated: lastUpdated,
            enableExtendedChat: enableExtendedChat,
            enableEmoji: enableEmoji,
            enableTextToImage: enableTextToImage,
            enableIndependentSendButton: enableIndependentSendButton,
            currentState: currentState,
            isPinned: isPinned,
            worldInfoIds: worldInfoIds,
            textPresetIds: textPresetIds,
            apiPresetId: apiPresetId,
            imageApiPresetId: imageApiPresetId,
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
  required List<MomentLike> likes,
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
  Value<List<MomentLike>> likes,
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

  ColumnWithTypeConverterFilters<List<MomentLike>, List<MomentLike>, String>
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

  GeneratedColumnWithTypeConverter<List<MomentLike>, String> get likes =>
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
            Value<List<MomentLike>> likes = const Value.absent(),
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
            required List<MomentLike> likes,
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
  Value<TextPresetType> type,
  Value<bool> isBuiltIn,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$TextPresetsTableUpdateCompanionBuilder = TextPresetsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> content,
  Value<TextPresetType> type,
  Value<bool> isBuiltIn,
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

  ColumnWithTypeConverterFilters<TextPresetType, TextPresetType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
      column: $table.isBuiltIn, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
      column: $table.isBuiltIn, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumnWithTypeConverter<TextPresetType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

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
            Value<TextPresetType> type = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TextPresetsCompanion(
            id: id,
            name: name,
            content: content,
            type: type,
            isBuiltIn: isBuiltIn,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String content,
            Value<TextPresetType> type = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TextPresetsCompanion.insert(
            id: id,
            name: name,
            content: content,
            type: type,
            isBuiltIn: isBuiltIn,
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
typedef $$RoleMemoriesTableCreateCompanionBuilder = RoleMemoriesCompanion
    Function({
  required String id,
  required String roleId,
  required String content,
  required int createdAt,
  required int updatedAt,
  Value<String?> sourceSessionId,
  Value<MemoryCategory> category,
  Value<int> rowid,
});
typedef $$RoleMemoriesTableUpdateCompanionBuilder = RoleMemoriesCompanion
    Function({
  Value<String> id,
  Value<String> roleId,
  Value<String> content,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String?> sourceSessionId,
  Value<MemoryCategory> category,
  Value<int> rowid,
});

class $$RoleMemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $RoleMemoriesTable> {
  $$RoleMemoriesTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceSessionId => $composableBuilder(
      column: $table.sourceSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MemoryCategory, MemoryCategory, int>
      get category => $composableBuilder(
          column: $table.category,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$RoleMemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoleMemoriesTable> {
  $$RoleMemoriesTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceSessionId => $composableBuilder(
      column: $table.sourceSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));
}

class $$RoleMemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoleMemoriesTable> {
  $$RoleMemoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get sourceSessionId => $composableBuilder(
      column: $table.sourceSessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MemoryCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$RoleMemoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoleMemoriesTable,
    RoleMemoryEntity,
    $$RoleMemoriesTableFilterComposer,
    $$RoleMemoriesTableOrderingComposer,
    $$RoleMemoriesTableAnnotationComposer,
    $$RoleMemoriesTableCreateCompanionBuilder,
    $$RoleMemoriesTableUpdateCompanionBuilder,
    (
      RoleMemoryEntity,
      BaseReferences<_$AppDatabase, $RoleMemoriesTable, RoleMemoryEntity>
    ),
    RoleMemoryEntity,
    PrefetchHooks Function()> {
  $$RoleMemoriesTableTableManager(_$AppDatabase db, $RoleMemoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoleMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoleMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoleMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> roleId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<String?> sourceSessionId = const Value.absent(),
            Value<MemoryCategory> category = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoleMemoriesCompanion(
            id: id,
            roleId: roleId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceSessionId: sourceSessionId,
            category: category,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String roleId,
            required String content,
            required int createdAt,
            required int updatedAt,
            Value<String?> sourceSessionId = const Value.absent(),
            Value<MemoryCategory> category = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoleMemoriesCompanion.insert(
            id: id,
            roleId: roleId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceSessionId: sourceSessionId,
            category: category,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RoleMemoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoleMemoriesTable,
    RoleMemoryEntity,
    $$RoleMemoriesTableFilterComposer,
    $$RoleMemoriesTableOrderingComposer,
    $$RoleMemoriesTableAnnotationComposer,
    $$RoleMemoriesTableCreateCompanionBuilder,
    $$RoleMemoriesTableUpdateCompanionBuilder,
    (
      RoleMemoryEntity,
      BaseReferences<_$AppDatabase, $RoleMemoriesTable, RoleMemoryEntity>
    ),
    RoleMemoryEntity,
    PrefetchHooks Function()>;
typedef $$ContactRolesTableCreateCompanionBuilder = ContactRolesCompanion
    Function({
  required String id,
  required String name,
  Value<String?> avatarPath,
  required String description,
  Value<String?> appearance,
  Value<List<String>> referenceImages,
  Value<List<String>> subscribedGroupIds,
  Value<List<String>> subscribedEmojiIds,
  Value<int> rowid,
});
typedef $$ContactRolesTableUpdateCompanionBuilder = ContactRolesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> avatarPath,
  Value<String> description,
  Value<String?> appearance,
  Value<List<String>> referenceImages,
  Value<List<String>> subscribedGroupIds,
  Value<List<String>> subscribedEmojiIds,
  Value<int> rowid,
});

class $$ContactRolesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactRolesTable> {
  $$ContactRolesTableFilterComposer({
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

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appearance => $composableBuilder(
      column: $table.appearance, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get referenceImages => $composableBuilder(
          column: $table.referenceImages,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get subscribedGroupIds => $composableBuilder(
          column: $table.subscribedGroupIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get subscribedEmojiIds => $composableBuilder(
          column: $table.subscribedEmojiIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$ContactRolesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactRolesTable> {
  $$ContactRolesTableOrderingComposer({
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

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appearance => $composableBuilder(
      column: $table.appearance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceImages => $composableBuilder(
      column: $table.referenceImages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subscribedGroupIds => $composableBuilder(
      column: $table.subscribedGroupIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subscribedEmojiIds => $composableBuilder(
      column: $table.subscribedEmojiIds,
      builder: (column) => ColumnOrderings(column));
}

class $$ContactRolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactRolesTable> {
  $$ContactRolesTableAnnotationComposer({
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

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get appearance => $composableBuilder(
      column: $table.appearance, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get referenceImages =>
      $composableBuilder(
          column: $table.referenceImages, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String>
      get subscribedGroupIds => $composableBuilder(
          column: $table.subscribedGroupIds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String>
      get subscribedEmojiIds => $composableBuilder(
          column: $table.subscribedEmojiIds, builder: (column) => column);
}

class $$ContactRolesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContactRolesTable,
    ContactRoleEntity,
    $$ContactRolesTableFilterComposer,
    $$ContactRolesTableOrderingComposer,
    $$ContactRolesTableAnnotationComposer,
    $$ContactRolesTableCreateCompanionBuilder,
    $$ContactRolesTableUpdateCompanionBuilder,
    (
      ContactRoleEntity,
      BaseReferences<_$AppDatabase, $ContactRolesTable, ContactRoleEntity>
    ),
    ContactRoleEntity,
    PrefetchHooks Function()> {
  $$ContactRolesTableTableManager(_$AppDatabase db, $ContactRolesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactRolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactRolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactRolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> appearance = const Value.absent(),
            Value<List<String>> referenceImages = const Value.absent(),
            Value<List<String>> subscribedGroupIds = const Value.absent(),
            Value<List<String>> subscribedEmojiIds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactRolesCompanion(
            id: id,
            name: name,
            avatarPath: avatarPath,
            description: description,
            appearance: appearance,
            referenceImages: referenceImages,
            subscribedGroupIds: subscribedGroupIds,
            subscribedEmojiIds: subscribedEmojiIds,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> avatarPath = const Value.absent(),
            required String description,
            Value<String?> appearance = const Value.absent(),
            Value<List<String>> referenceImages = const Value.absent(),
            Value<List<String>> subscribedGroupIds = const Value.absent(),
            Value<List<String>> subscribedEmojiIds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactRolesCompanion.insert(
            id: id,
            name: name,
            avatarPath: avatarPath,
            description: description,
            appearance: appearance,
            referenceImages: referenceImages,
            subscribedGroupIds: subscribedGroupIds,
            subscribedEmojiIds: subscribedEmojiIds,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactRolesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContactRolesTable,
    ContactRoleEntity,
    $$ContactRolesTableFilterComposer,
    $$ContactRolesTableOrderingComposer,
    $$ContactRolesTableAnnotationComposer,
    $$ContactRolesTableCreateCompanionBuilder,
    $$ContactRolesTableUpdateCompanionBuilder,
    (
      ContactRoleEntity,
      BaseReferences<_$AppDatabase, $ContactRolesTable, ContactRoleEntity>
    ),
    ContactRoleEntity,
    PrefetchHooks Function()>;
typedef $$ContactMesTableCreateCompanionBuilder = ContactMesCompanion Function({
  required String id,
  required String name,
  Value<String?> avatarPath,
  required String info,
  Value<String?> appearance,
  Value<List<String>> referenceImages,
  Value<int> rowid,
});
typedef $$ContactMesTableUpdateCompanionBuilder = ContactMesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> avatarPath,
  Value<String> info,
  Value<String?> appearance,
  Value<List<String>> referenceImages,
  Value<int> rowid,
});

class $$ContactMesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactMesTable> {
  $$ContactMesTableFilterComposer({
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

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get info => $composableBuilder(
      column: $table.info, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appearance => $composableBuilder(
      column: $table.appearance, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get referenceImages => $composableBuilder(
          column: $table.referenceImages,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$ContactMesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactMesTable> {
  $$ContactMesTableOrderingComposer({
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

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get info => $composableBuilder(
      column: $table.info, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appearance => $composableBuilder(
      column: $table.appearance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceImages => $composableBuilder(
      column: $table.referenceImages,
      builder: (column) => ColumnOrderings(column));
}

class $$ContactMesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactMesTable> {
  $$ContactMesTableAnnotationComposer({
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

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<String> get info =>
      $composableBuilder(column: $table.info, builder: (column) => column);

  GeneratedColumn<String> get appearance => $composableBuilder(
      column: $table.appearance, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get referenceImages =>
      $composableBuilder(
          column: $table.referenceImages, builder: (column) => column);
}

class $$ContactMesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContactMesTable,
    ContactMeEntity,
    $$ContactMesTableFilterComposer,
    $$ContactMesTableOrderingComposer,
    $$ContactMesTableAnnotationComposer,
    $$ContactMesTableCreateCompanionBuilder,
    $$ContactMesTableUpdateCompanionBuilder,
    (
      ContactMeEntity,
      BaseReferences<_$AppDatabase, $ContactMesTable, ContactMeEntity>
    ),
    ContactMeEntity,
    PrefetchHooks Function()> {
  $$ContactMesTableTableManager(_$AppDatabase db, $ContactMesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactMesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactMesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactMesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String> info = const Value.absent(),
            Value<String?> appearance = const Value.absent(),
            Value<List<String>> referenceImages = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactMesCompanion(
            id: id,
            name: name,
            avatarPath: avatarPath,
            info: info,
            appearance: appearance,
            referenceImages: referenceImages,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> avatarPath = const Value.absent(),
            required String info,
            Value<String?> appearance = const Value.absent(),
            Value<List<String>> referenceImages = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactMesCompanion.insert(
            id: id,
            name: name,
            avatarPath: avatarPath,
            info: info,
            appearance: appearance,
            referenceImages: referenceImages,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactMesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContactMesTable,
    ContactMeEntity,
    $$ContactMesTableFilterComposer,
    $$ContactMesTableOrderingComposer,
    $$ContactMesTableAnnotationComposer,
    $$ContactMesTableCreateCompanionBuilder,
    $$ContactMesTableUpdateCompanionBuilder,
    (
      ContactMeEntity,
      BaseReferences<_$AppDatabase, $ContactMesTable, ContactMeEntity>
    ),
    ContactMeEntity,
    PrefetchHooks Function()>;
typedef $$ApiPresetsTableCreateCompanionBuilder = ApiPresetsCompanion Function({
  required String id,
  required String name,
  Value<ApiPresetType> type,
  required ApiProvider provider,
  required String baseUrl,
  required String apiKey,
  required String model,
  Value<double> temperature,
  Value<double> topP,
  Value<bool> isStream,
  Value<bool> enableThinking,
  Value<int> timeout,
  Value<int> rowid,
});
typedef $$ApiPresetsTableUpdateCompanionBuilder = ApiPresetsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<ApiPresetType> type,
  Value<ApiProvider> provider,
  Value<String> baseUrl,
  Value<String> apiKey,
  Value<String> model,
  Value<double> temperature,
  Value<double> topP,
  Value<bool> isStream,
  Value<bool> enableThinking,
  Value<int> timeout,
  Value<int> rowid,
});

class $$ApiPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $ApiPresetsTable> {
  $$ApiPresetsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ApiPresetType, ApiPresetType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ApiProvider, ApiProvider, int> get provider =>
      $composableBuilder(
          column: $table.provider,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get topP => $composableBuilder(
      column: $table.topP, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStream => $composableBuilder(
      column: $table.isStream, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableThinking => $composableBuilder(
      column: $table.enableThinking,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeout => $composableBuilder(
      column: $table.timeout, builder: (column) => ColumnFilters(column));
}

class $$ApiPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiPresetsTable> {
  $$ApiPresetsTableOrderingComposer({
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

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get topP => $composableBuilder(
      column: $table.topP, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStream => $composableBuilder(
      column: $table.isStream, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableThinking => $composableBuilder(
      column: $table.enableThinking,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeout => $composableBuilder(
      column: $table.timeout, builder: (column) => ColumnOrderings(column));
}

class $$ApiPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiPresetsTable> {
  $$ApiPresetsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<ApiPresetType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ApiProvider, int> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => column);

  GeneratedColumn<double> get topP =>
      $composableBuilder(column: $table.topP, builder: (column) => column);

  GeneratedColumn<bool> get isStream =>
      $composableBuilder(column: $table.isStream, builder: (column) => column);

  GeneratedColumn<bool> get enableThinking => $composableBuilder(
      column: $table.enableThinking, builder: (column) => column);

  GeneratedColumn<int> get timeout =>
      $composableBuilder(column: $table.timeout, builder: (column) => column);
}

class $$ApiPresetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ApiPresetsTable,
    ApiPresetEntity,
    $$ApiPresetsTableFilterComposer,
    $$ApiPresetsTableOrderingComposer,
    $$ApiPresetsTableAnnotationComposer,
    $$ApiPresetsTableCreateCompanionBuilder,
    $$ApiPresetsTableUpdateCompanionBuilder,
    (
      ApiPresetEntity,
      BaseReferences<_$AppDatabase, $ApiPresetsTable, ApiPresetEntity>
    ),
    ApiPresetEntity,
    PrefetchHooks Function()> {
  $$ApiPresetsTableTableManager(_$AppDatabase db, $ApiPresetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<ApiPresetType> type = const Value.absent(),
            Value<ApiProvider> provider = const Value.absent(),
            Value<String> baseUrl = const Value.absent(),
            Value<String> apiKey = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<double> temperature = const Value.absent(),
            Value<double> topP = const Value.absent(),
            Value<bool> isStream = const Value.absent(),
            Value<bool> enableThinking = const Value.absent(),
            Value<int> timeout = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ApiPresetsCompanion(
            id: id,
            name: name,
            type: type,
            provider: provider,
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            temperature: temperature,
            topP: topP,
            isStream: isStream,
            enableThinking: enableThinking,
            timeout: timeout,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<ApiPresetType> type = const Value.absent(),
            required ApiProvider provider,
            required String baseUrl,
            required String apiKey,
            required String model,
            Value<double> temperature = const Value.absent(),
            Value<double> topP = const Value.absent(),
            Value<bool> isStream = const Value.absent(),
            Value<bool> enableThinking = const Value.absent(),
            Value<int> timeout = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ApiPresetsCompanion.insert(
            id: id,
            name: name,
            type: type,
            provider: provider,
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            temperature: temperature,
            topP: topP,
            isStream: isStream,
            enableThinking: enableThinking,
            timeout: timeout,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ApiPresetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ApiPresetsTable,
    ApiPresetEntity,
    $$ApiPresetsTableFilterComposer,
    $$ApiPresetsTableOrderingComposer,
    $$ApiPresetsTableAnnotationComposer,
    $$ApiPresetsTableCreateCompanionBuilder,
    $$ApiPresetsTableUpdateCompanionBuilder,
    (
      ApiPresetEntity,
      BaseReferences<_$AppDatabase, $ApiPresetsTable, ApiPresetEntity>
    ),
    ApiPresetEntity,
    PrefetchHooks Function()>;
typedef $$MomentsUserSettingsTableCreateCompanionBuilder
    = MomentsUserSettingsCompanion Function({
  required String id,
  Value<String> name,
  Value<String?> avatarUrl,
  Value<String?> coverImageUrl,
  Value<String?> signature,
  Value<int> rowid,
});
typedef $$MomentsUserSettingsTableUpdateCompanionBuilder
    = MomentsUserSettingsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> avatarUrl,
  Value<String?> coverImageUrl,
  Value<String?> signature,
  Value<int> rowid,
});

class $$MomentsUserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $MomentsUserSettingsTable> {
  $$MomentsUserSettingsTableFilterComposer({
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

  ColumnFilters<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signature => $composableBuilder(
      column: $table.signature, builder: (column) => ColumnFilters(column));
}

class $$MomentsUserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $MomentsUserSettingsTable> {
  $$MomentsUserSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signature => $composableBuilder(
      column: $table.signature, builder: (column) => ColumnOrderings(column));
}

class $$MomentsUserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MomentsUserSettingsTable> {
  $$MomentsUserSettingsTableAnnotationComposer({
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

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);
}

class $$MomentsUserSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MomentsUserSettingsTable,
    MomentsUserSettingsEntity,
    $$MomentsUserSettingsTableFilterComposer,
    $$MomentsUserSettingsTableOrderingComposer,
    $$MomentsUserSettingsTableAnnotationComposer,
    $$MomentsUserSettingsTableCreateCompanionBuilder,
    $$MomentsUserSettingsTableUpdateCompanionBuilder,
    (
      MomentsUserSettingsEntity,
      BaseReferences<_$AppDatabase, $MomentsUserSettingsTable,
          MomentsUserSettingsEntity>
    ),
    MomentsUserSettingsEntity,
    PrefetchHooks Function()> {
  $$MomentsUserSettingsTableTableManager(
      _$AppDatabase db, $MomentsUserSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MomentsUserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MomentsUserSettingsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MomentsUserSettingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> coverImageUrl = const Value.absent(),
            Value<String?> signature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MomentsUserSettingsCompanion(
            id: id,
            name: name,
            avatarUrl: avatarUrl,
            coverImageUrl: coverImageUrl,
            signature: signature,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> name = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> coverImageUrl = const Value.absent(),
            Value<String?> signature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MomentsUserSettingsCompanion.insert(
            id: id,
            name: name,
            avatarUrl: avatarUrl,
            coverImageUrl: coverImageUrl,
            signature: signature,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MomentsUserSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MomentsUserSettingsTable,
    MomentsUserSettingsEntity,
    $$MomentsUserSettingsTableFilterComposer,
    $$MomentsUserSettingsTableOrderingComposer,
    $$MomentsUserSettingsTableAnnotationComposer,
    $$MomentsUserSettingsTableCreateCompanionBuilder,
    $$MomentsUserSettingsTableUpdateCompanionBuilder,
    (
      MomentsUserSettingsEntity,
      BaseReferences<_$AppDatabase, $MomentsUserSettingsTable,
          MomentsUserSettingsEntity>
    ),
    MomentsUserSettingsEntity,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<String> type,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<String> type,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSettingEntity,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSettingEntity,
      BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingEntity>
    ),
    AppSettingEntity,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            type: type,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<String> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            type: type,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSettingEntity,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSettingEntity,
      BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingEntity>
    ),
    AppSettingEntity,
    PrefetchHooks Function()>;
typedef $$WalletTransactionsTableCreateCompanionBuilder
    = WalletTransactionsCompanion Function({
  required String id,
  required WalletTransactionType type,
  required TransactionDirection direction,
  required double amount,
  Value<String?> description,
  Value<String?> relatedContactName,
  Value<String?> relatedSessionId,
  Value<String?> relatedMessageId,
  required int timestamp,
  Value<int> rowid,
});
typedef $$WalletTransactionsTableUpdateCompanionBuilder
    = WalletTransactionsCompanion Function({
  Value<String> id,
  Value<WalletTransactionType> type,
  Value<TransactionDirection> direction,
  Value<double> amount,
  Value<String?> description,
  Value<String?> relatedContactName,
  Value<String?> relatedSessionId,
  Value<String?> relatedMessageId,
  Value<int> timestamp,
  Value<int> rowid,
});

class $$WalletTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletTransactionsTable> {
  $$WalletTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<WalletTransactionType, WalletTransactionType,
          int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<TransactionDirection, TransactionDirection,
          int>
      get direction => $composableBuilder(
          column: $table.direction,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedContactName => $composableBuilder(
      column: $table.relatedContactName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedSessionId => $composableBuilder(
      column: $table.relatedSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedMessageId => $composableBuilder(
      column: $table.relatedMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$WalletTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletTransactionsTable> {
  $$WalletTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedContactName => $composableBuilder(
      column: $table.relatedContactName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedSessionId => $composableBuilder(
      column: $table.relatedSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedMessageId => $composableBuilder(
      column: $table.relatedMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$WalletTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletTransactionsTable> {
  $$WalletTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WalletTransactionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionDirection, int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get relatedContactName => $composableBuilder(
      column: $table.relatedContactName, builder: (column) => column);

  GeneratedColumn<String> get relatedSessionId => $composableBuilder(
      column: $table.relatedSessionId, builder: (column) => column);

  GeneratedColumn<String> get relatedMessageId => $composableBuilder(
      column: $table.relatedMessageId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$WalletTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WalletTransactionsTable,
    WalletTransactionEntity,
    $$WalletTransactionsTableFilterComposer,
    $$WalletTransactionsTableOrderingComposer,
    $$WalletTransactionsTableAnnotationComposer,
    $$WalletTransactionsTableCreateCompanionBuilder,
    $$WalletTransactionsTableUpdateCompanionBuilder,
    (
      WalletTransactionEntity,
      BaseReferences<_$AppDatabase, $WalletTransactionsTable,
          WalletTransactionEntity>
    ),
    WalletTransactionEntity,
    PrefetchHooks Function()> {
  $$WalletTransactionsTableTableManager(
      _$AppDatabase db, $WalletTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<WalletTransactionType> type = const Value.absent(),
            Value<TransactionDirection> direction = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> relatedContactName = const Value.absent(),
            Value<String?> relatedSessionId = const Value.absent(),
            Value<String?> relatedMessageId = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WalletTransactionsCompanion(
            id: id,
            type: type,
            direction: direction,
            amount: amount,
            description: description,
            relatedContactName: relatedContactName,
            relatedSessionId: relatedSessionId,
            relatedMessageId: relatedMessageId,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required WalletTransactionType type,
            required TransactionDirection direction,
            required double amount,
            Value<String?> description = const Value.absent(),
            Value<String?> relatedContactName = const Value.absent(),
            Value<String?> relatedSessionId = const Value.absent(),
            Value<String?> relatedMessageId = const Value.absent(),
            required int timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              WalletTransactionsCompanion.insert(
            id: id,
            type: type,
            direction: direction,
            amount: amount,
            description: description,
            relatedContactName: relatedContactName,
            relatedSessionId: relatedSessionId,
            relatedMessageId: relatedMessageId,
            timestamp: timestamp,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WalletTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WalletTransactionsTable,
    WalletTransactionEntity,
    $$WalletTransactionsTableFilterComposer,
    $$WalletTransactionsTableOrderingComposer,
    $$WalletTransactionsTableAnnotationComposer,
    $$WalletTransactionsTableCreateCompanionBuilder,
    $$WalletTransactionsTableUpdateCompanionBuilder,
    (
      WalletTransactionEntity,
      BaseReferences<_$AppDatabase, $WalletTransactionsTable,
          WalletTransactionEntity>
    ),
    WalletTransactionEntity,
    PrefetchHooks Function()>;
typedef $$EmojisTableCreateCompanionBuilder = EmojisCompanion Function({
  required String id,
  required String meaning,
  Value<String?> rawContent,
  Value<String?> groupId,
  required String localPath,
  required EmojiType type,
  Value<String?> roleId,
  required int createdAt,
  Value<int> rowid,
});
typedef $$EmojisTableUpdateCompanionBuilder = EmojisCompanion Function({
  Value<String> id,
  Value<String> meaning,
  Value<String?> rawContent,
  Value<String?> groupId,
  Value<String> localPath,
  Value<EmojiType> type,
  Value<String?> roleId,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$EmojisTableFilterComposer
    extends Composer<_$AppDatabase, $EmojisTable> {
  $$EmojisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawContent => $composableBuilder(
      column: $table.rawContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<EmojiType, EmojiType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get roleId => $composableBuilder(
      column: $table.roleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EmojisTableOrderingComposer
    extends Composer<_$AppDatabase, $EmojisTable> {
  $$EmojisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawContent => $composableBuilder(
      column: $table.rawContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roleId => $composableBuilder(
      column: $table.roleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EmojisTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmojisTable> {
  $$EmojisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get rawContent => $composableBuilder(
      column: $table.rawContent, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EmojiType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EmojisTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmojisTable,
    EmojiEntity,
    $$EmojisTableFilterComposer,
    $$EmojisTableOrderingComposer,
    $$EmojisTableAnnotationComposer,
    $$EmojisTableCreateCompanionBuilder,
    $$EmojisTableUpdateCompanionBuilder,
    (EmojiEntity, BaseReferences<_$AppDatabase, $EmojisTable, EmojiEntity>),
    EmojiEntity,
    PrefetchHooks Function()> {
  $$EmojisTableTableManager(_$AppDatabase db, $EmojisTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmojisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmojisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmojisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String?> rawContent = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<EmojiType> type = const Value.absent(),
            Value<String?> roleId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmojisCompanion(
            id: id,
            meaning: meaning,
            rawContent: rawContent,
            groupId: groupId,
            localPath: localPath,
            type: type,
            roleId: roleId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String meaning,
            Value<String?> rawContent = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            required String localPath,
            required EmojiType type,
            Value<String?> roleId = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EmojisCompanion.insert(
            id: id,
            meaning: meaning,
            rawContent: rawContent,
            groupId: groupId,
            localPath: localPath,
            type: type,
            roleId: roleId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmojisTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmojisTable,
    EmojiEntity,
    $$EmojisTableFilterComposer,
    $$EmojisTableOrderingComposer,
    $$EmojisTableAnnotationComposer,
    $$EmojisTableCreateCompanionBuilder,
    $$EmojisTableUpdateCompanionBuilder,
    (EmojiEntity, BaseReferences<_$AppDatabase, $EmojisTable, EmojiEntity>),
    EmojiEntity,
    PrefetchHooks Function()>;
typedef $$EmojiGroupsTableCreateCompanionBuilder = EmojiGroupsCompanion
    Function({
  required String id,
  required String name,
  required EmojiType type,
  Value<String?> roleId,
  Value<bool> isVisible,
  required int createdAt,
  Value<int> rowid,
});
typedef $$EmojiGroupsTableUpdateCompanionBuilder = EmojiGroupsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<EmojiType> type,
  Value<String?> roleId,
  Value<bool> isVisible,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$EmojiGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $EmojiGroupsTable> {
  $$EmojiGroupsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<EmojiType, EmojiType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get roleId => $composableBuilder(
      column: $table.roleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVisible => $composableBuilder(
      column: $table.isVisible, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EmojiGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmojiGroupsTable> {
  $$EmojiGroupsTableOrderingComposer({
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

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roleId => $composableBuilder(
      column: $table.roleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVisible => $composableBuilder(
      column: $table.isVisible, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EmojiGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmojiGroupsTable> {
  $$EmojiGroupsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<EmojiType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EmojiGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmojiGroupsTable,
    EmojiGroupEntity,
    $$EmojiGroupsTableFilterComposer,
    $$EmojiGroupsTableOrderingComposer,
    $$EmojiGroupsTableAnnotationComposer,
    $$EmojiGroupsTableCreateCompanionBuilder,
    $$EmojiGroupsTableUpdateCompanionBuilder,
    (
      EmojiGroupEntity,
      BaseReferences<_$AppDatabase, $EmojiGroupsTable, EmojiGroupEntity>
    ),
    EmojiGroupEntity,
    PrefetchHooks Function()> {
  $$EmojiGroupsTableTableManager(_$AppDatabase db, $EmojiGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmojiGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmojiGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmojiGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<EmojiType> type = const Value.absent(),
            Value<String?> roleId = const Value.absent(),
            Value<bool> isVisible = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmojiGroupsCompanion(
            id: id,
            name: name,
            type: type,
            roleId: roleId,
            isVisible: isVisible,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required EmojiType type,
            Value<String?> roleId = const Value.absent(),
            Value<bool> isVisible = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EmojiGroupsCompanion.insert(
            id: id,
            name: name,
            type: type,
            roleId: roleId,
            isVisible: isVisible,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmojiGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmojiGroupsTable,
    EmojiGroupEntity,
    $$EmojiGroupsTableFilterComposer,
    $$EmojiGroupsTableOrderingComposer,
    $$EmojiGroupsTableAnnotationComposer,
    $$EmojiGroupsTableCreateCompanionBuilder,
    $$EmojiGroupsTableUpdateCompanionBuilder,
    (
      EmojiGroupEntity,
      BaseReferences<_$AppDatabase, $EmojiGroupsTable, EmojiGroupEntity>
    ),
    EmojiGroupEntity,
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
  $$RoleMemoriesTableTableManager get roleMemories =>
      $$RoleMemoriesTableTableManager(_db, _db.roleMemories);
  $$ContactRolesTableTableManager get contactRoles =>
      $$ContactRolesTableTableManager(_db, _db.contactRoles);
  $$ContactMesTableTableManager get contactMes =>
      $$ContactMesTableTableManager(_db, _db.contactMes);
  $$ApiPresetsTableTableManager get apiPresets =>
      $$ApiPresetsTableTableManager(_db, _db.apiPresets);
  $$MomentsUserSettingsTableTableManager get momentsUserSettings =>
      $$MomentsUserSettingsTableTableManager(_db, _db.momentsUserSettings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$WalletTransactionsTableTableManager get walletTransactions =>
      $$WalletTransactionsTableTableManager(_db, _db.walletTransactions);
  $$EmojisTableTableManager get emojis =>
      $$EmojisTableTableManager(_db, _db.emojis);
  $$EmojiGroupsTableTableManager get emojiGroups =>
      $$EmojiGroupsTableTableManager(_db, _db.emojiGroups);
}
