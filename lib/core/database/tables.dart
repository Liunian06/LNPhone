import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/chat_model.dart';
import '../models/moments_model.dart';

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
  TextColumn get currentState => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

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
  IntColumn get type => integer().map(const MessageTypeConverter())();
  TextColumn get content => text()();
  IntColumn get timestamp => integer()();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
