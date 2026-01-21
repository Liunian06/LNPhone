import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/chat_model.dart';
import '../models/moments_model.dart';
import '../models/memory_model.dart';
import '../models/api_preset.dart';
import '../models/wallet_model.dart';

/// List<String> 的转换器
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    try {
      final List<dynamic> list = json.decode(fromDb);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

/// 消息类型的转换器：Enum <-> Int
class MessageTypeConverter extends TypeConverter<MessageType, int> {
  const MessageTypeConverter();

  @override
  MessageType fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < MessageType.values.length) {
      return MessageType.values[fromDb];
    }
    return MessageType.words; // Default fallback
  }

  @override
  int toSql(MessageType value) {
    return value.index;
  }
}

/// Metadata 的转换器：Map<String, dynamic> <-> JSON String
class MetadataConverter extends TypeConverter<Map<String, dynamic>, String> {
  const MetadataConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      return json.decode(fromDb) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}

/// MomentsUser 的转换器
class MomentsUserConverter extends TypeConverter<MomentsUser, String> {
  const MomentsUserConverter();

  @override
  MomentsUser fromSql(String fromDb) {
    return MomentsUser.fromJson(json.decode(fromDb));
  }

  @override
  String toSql(MomentsUser value) {
    return json.encode(value.toJson());
  }
}

/// List<MediaItem> 的转换器
class MediaItemsConverter extends TypeConverter<List<MediaItem>, String> {
  const MediaItemsConverter();

  @override
  List<MediaItem> fromSql(String fromDb) {
    final List<dynamic> list = json.decode(fromDb);
    return list.map((e) => MediaItem.fromJson(e)).toList();
  }

  @override
  String toSql(List<MediaItem> value) {
    return json.encode(value.map((e) => e.toJson()).toList());
  }
}

/// List<MomentsUser> (Likes) 的转换器
class LikesConverter extends TypeConverter<List<MomentsUser>, String> {
  const LikesConverter();

  @override
  List<MomentsUser> fromSql(String fromDb) {
    final List<dynamic> list = json.decode(fromDb);
    return list.map((e) => MomentsUser.fromJson(e)).toList();
  }

  @override
  String toSql(List<MomentsUser> value) {
    return json.encode(value.map((e) => e.toJson()).toList());
  }
}

/// List<MomentsComment> (Comments) 的转换器
class CommentsConverter extends TypeConverter<List<MomentsComment>, String> {
  const CommentsConverter();

  @override
  List<MomentsComment> fromSql(String fromDb) {
    final List<dynamic> list = json.decode(fromDb);
    return list.map((e) => MomentsComment.fromJson(e)).toList();
  }

  @override
  String toSql(List<MomentsComment> value) {
    return json.encode(value.map((e) => e.toJson()).toList());
  }
}

/// 记忆分类转换器
class MemoryCategoryConverter extends TypeConverter<MemoryCategory, int> {
  const MemoryCategoryConverter();

  @override
  MemoryCategory fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < MemoryCategory.values.length) {
      return MemoryCategory.values[fromDb];
    }
    return MemoryCategory.general;
  }

  @override
  int toSql(MemoryCategory value) {
    return value.index;
  }
}

/// ApiProvider 的转换器
class ApiProviderConverter extends TypeConverter<ApiProvider, int> {
  const ApiProviderConverter();

  @override
  ApiProvider fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < ApiProvider.values.length) {
      return ApiProvider.values[fromDb];
    }
    return ApiProvider.openai;
  }

  @override
  int toSql(ApiProvider value) {
    return value.index;
  }
}

/// 钱包交易类型转换器
class WalletTransactionTypeConverter
    extends TypeConverter<WalletTransactionType, int> {
  const WalletTransactionTypeConverter();

  @override
  WalletTransactionType fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < WalletTransactionType.values.length) {
      return WalletTransactionType.values[fromDb];
    }
    return WalletTransactionType.transfer;
  }

  @override
  int toSql(WalletTransactionType value) {
    return value.index;
  }
}

/// 交易方向转换器
class TransactionDirectionConverter
    extends TypeConverter<TransactionDirection, int> {
  const TransactionDirectionConverter();

  @override
  TransactionDirection fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < TransactionDirection.values.length) {
      return TransactionDirection.values[fromDb];
    }
    return TransactionDirection.income;
  }

  @override
  int toSql(TransactionDirection value) {
    return value.index;
  }
}

/// 钱包交易记录表
@DataClassName('WalletTransactionEntity')
class WalletTransactions extends Table {
  TextColumn get id => text()();
  IntColumn get type => integer().map(const WalletTransactionTypeConverter())();
  IntColumn get direction =>
      integer().map(const TransactionDirectionConverter())();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  TextColumn get relatedContactName => text().nullable()();
  TextColumn get relatedSessionId => text().nullable()();
  TextColumn get relatedMessageId => text().nullable()();
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 朋友圈用户设置表（头像、封面、昵称、签名）
@DataClassName('MomentsUserSettingsEntity')
class MomentsUserSettings extends Table {
  TextColumn get id => text()(); // 固定为 'current_user'
  TextColumn get name => text().withDefault(const Constant('我'))();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  TextColumn get signature => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 应用设置表（Key-Value 存储）
/// 用于存储所有之前在 SharedPreferences 中的设置
/// 注意：所有设置应该存储在数据库中，SharedPreferences 已被弃用
@DataClassName('AppSettingEntity')
class AppSettings extends Table {
  TextColumn get key => text()(); // 设置键名
  TextColumn get value => text()(); // 设置值（JSON 格式）
  TextColumn get type => text().withDefault(
      const Constant('string'))(); // 值类型: string, int, double, bool, json

  @override
  Set<Column> get primaryKey => {key};
}

/// 角色人设表
@DataClassName('ContactRoleEntity')
class ContactRoles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 用户人设表
@DataClassName('ContactMeEntity')
class ContactMes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get info => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// API预设表
@DataClassName('ApiPresetEntity')
class ApiPresets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get provider => integer().map(const ApiProviderConverter())();
  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text()();
  TextColumn get model => text()();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  RealColumn get topP => real().withDefault(const Constant(0.9))();
  BoolColumn get isStream => boolean().withDefault(const Constant(true))();
  BoolColumn get enableThinking =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 角色记忆表
@DataClassName('RoleMemoryEntity')
class RoleMemories extends Table {
  TextColumn get id => text()();
  TextColumn get roleId => text()(); // 关联的角色 ID
  TextColumn get content => text()(); // 记忆内容
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get sourceSessionId => text().nullable()(); // 来源会话 ID
  IntColumn get category => integer()
      .map(const MemoryCategoryConverter())
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 聊天会话表
@DataClassName('ChatSessionEntity')
class ChatSessions extends Table {
  // 使用 String 作为主键，保持与原有逻辑兼容（原逻辑生成的 ID 是 "时间戳-随机数"）
  TextColumn get id => text()();
  TextColumn get roleId => text()();
  TextColumn get meId => text()();
  IntColumn get lastUpdated => integer()();
  BoolColumn get enableExtendedChat =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get enableIndependentSendButton =>
      boolean().withDefault(const Constant(false))();
  TextColumn get currentState => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get worldInfoIds => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get textPresetIds => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get apiPresetId => text().nullable()();
  TextColumn get backgroundImage => text().nullable()(); // 聊天背景图路径

  @override
  Set<Column> get primaryKey => {id};
}

/// 世界书表
@DataClassName('WorldInfoEntity')
class WorldInfos extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 预设表
@DataClassName('TextPresetEntity')
class TextPresets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 朋友圈动态表
@DataClassName('MomentsPostEntity')
class MomentsPosts extends Table {
  TextColumn get id => text()();
  TextColumn get user => text().map(const MomentsUserConverter())();
  TextColumn get content => text().nullable()();
  TextColumn get mediaItems => text().map(const MediaItemsConverter())();
  IntColumn get createdAt => integer()(); // timestamp
  TextColumn get likes => text().map(const LikesConverter())();
  TextColumn get comments => text().map(const CommentsConverter())();
  TextColumn get location => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 聊天消息表
@DataClassName('ChatMessageEntity')
class ChatMessages extends Table {
  TextColumn get id => text()();
  // 关联到会话 ID
  TextColumn get sessionId =>
      text().references(ChatSessions, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isMe => boolean()();
  TextColumn get sender => text().nullable()(); // 发送者名称（用于引用显示）
  IntColumn get type => integer().map(const MessageTypeConverter())();
  TextColumn get content => text()();
  IntColumn get timestamp => integer()();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
