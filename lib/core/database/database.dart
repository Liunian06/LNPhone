import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import '../models/moments_model.dart';
import '../models/contact_model.dart';
import '../models/api_preset.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [ChatSessions, ChatMessages, MomentsPosts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  // Migration Strategy
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(momentsPosts);
        }
        if (from < 3) {
          await m.addColumn(chatMessages, chatMessages.isRead);
          // 将所有现有消息标记为已读
          await (update(
            chatMessages,
          )).write(const ChatMessagesCompanion(isRead: Value(true)));
        }
        if (from < 4) {
          await m.addColumn(chatSessions, chatSessions.currentState);
        }
        if (from < 5) {
          await m.addColumn(chatSessions, chatSessions.isPinned);
        }
      },
    );
  }

  // --- ChatSession Queries ---

  /// 获取所有会话，置顶的排在前面，然后按最后更新时间倒序
  /// 返回的是 Model 列表，不是 DB Entity
  Future<List<ChatSession>> getAllSessions() async {
    final query = select(chatSessions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.lastUpdated, mode: OrderingMode.desc),
      ]);

    final sessions = await query.get();

    List<ChatSession> result = [];
    for (final s in sessions) {
      final messages = await (select(chatMessages)
            ..where((t) => t.sessionId.equals(s.id))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.timestamp,
                    mode: OrderingMode.asc,
                  ),
            ]))
          .get();

      result.add(
        ChatSession(
          id: s.id,
          roleId: s.roleId,
          meId: s.meId,
          messages: messages
              .map(
                (m) => ChatMessage(
                  id: m.id,
                  isMe: m.isMe,
                  type: m.type,
                  content: m.content,
                  timestamp: m.timestamp,
                  metadata: m.metadata,
                  isRead: m.isRead,
                ),
              )
              .toList(),
          lastUpdated: s.lastUpdated,
          enableExtendedChat: s.enableExtendedChat,
          currentState: s.currentState,
          isPinned: s.isPinned,
        ),
      );
    }
    return result;
  }

  /// 获取单个会话
  Future<ChatSession?> getChatSession(String id) async {
    final s = await (select(
      chatSessions,
    )..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (s == null) return null;

    final messages = await (select(chatMessages)
          ..where((t) => t.sessionId.equals(s.id))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.timestamp,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();

    return ChatSession(
      id: s.id,
      roleId: s.roleId,
      meId: s.meId,
      messages: messages
          .map(
            (m) => ChatMessage(
              id: m.id,
              isMe: m.isMe,
              type: m.type,
              content: m.content,
              timestamp: m.timestamp,
              metadata: m.metadata,
              isRead: m.isRead,
            ),
          )
          .toList(),
      lastUpdated: s.lastUpdated,
      enableExtendedChat: s.enableExtendedChat,
      currentState: s.currentState,
      isPinned: s.isPinned,
    );
  }

  /// 创建新会话
  /// 注意：这里传入的是 Companion (用于 insert/update)，
  /// Drift 默认生成的 Companion 类名是 TableName + Companion。
  /// ChatSessionsTable -> ChatSessionsCompanion
  Future<void> insertChatSession(ChatSessionsCompanion session) {
    return into(chatSessions).insert(session, mode: InsertMode.insertOrReplace);
  }

  /// 插入消息
  Future<void> insertMessage(ChatMessagesCompanion message) async {
    await into(chatMessages).insert(message);
    // 更新会话的最后更新时间
    await (update(
      chatSessions,
    )..where((t) => t.id.equals(message.sessionId.value)))
        .write(
      ChatSessionsCompanion(lastUpdated: Value(message.timestamp.value)),
    );
  }

  /// 批量插入消息
  Future<void> insertMessages(
    String sessionId,
    List<ChatMessagesCompanion> messages,
  ) async {
    await batch((batch) {
      batch.insertAll(chatMessages, messages, mode: InsertMode.insertOrReplace);
    });
    if (messages.isNotEmpty) {
      final lastMsg = messages.last;
      await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
        ChatSessionsCompanion(lastUpdated: lastMsg.timestamp),
      );
    }
  }

  /// 删除会话 (会级联删除消息)
  Future<void> deleteSession(String id) {
    return (delete(chatSessions)..where((t) => t.id.equals(id))).go();
  }

  /// 更新消息内容
  Future<void> updateMessageContent(String id, String newContent) {
    return (update(chatMessages)..where((t) => t.id.equals(id))).write(
      ChatMessagesCompanion(content: Value(newContent)),
    );
  }

  /// 标记消息为已读
  Future<void> markMessageAsRead(String id) {
    return (update(chatMessages)..where((t) => t.id.equals(id))).write(
      const ChatMessagesCompanion(isRead: Value(true)),
    );
  }

  /// 标记会话中所有消息为已读
  Future<void> markSessionAsRead(String sessionId) {
    return (update(chatMessages)..where((t) => t.sessionId.equals(sessionId)))
        .write(const ChatMessagesCompanion(isRead: Value(true)));
  }

  /// 删除单条消息
  Future<void> deleteMessage(String id) {
    return (delete(chatMessages)..where((t) => t.id.equals(id))).go();
  }

  /// 批量删除消息
  Future<void> deleteMessages(List<String> ids) {
    return (delete(chatMessages)..where((t) => t.id.isIn(ids))).go();
  }

  /// 删除指定时间之后的消息 (用于回溯)
  Future<void> deleteMessagesAfter(String sessionId, int timestamp) {
    return (delete(chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.timestamp.isBiggerThanValue(timestamp)))
        .go();
  }

  /// 更新会话设置
  Future<void> updateSessionSettings(String id, bool enableExtendedChat) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(enableExtendedChat: Value(enableExtendedChat)),
    );
  }

  /// 更新会话状态
  Future<void> updateSessionState(String id, String? state) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(currentState: Value(state)),
    );
  }

  /// 置顶/取消置顶会话
  Future<void> updateSessionPinned(String id, bool isPinned) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(isPinned: Value(isPinned)),
    );
  }
  // --- Moments Queries ---

  /// 获取所有朋友圈动态，按时间倒序
  Future<List<MomentsPost>> getAllMoments() async {
    final query = select(momentsPosts)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    final entities = await query.get();

    return entities.map((e) {
      return MomentsPost(
        id: e.id,
        user: e.user,
        content: e.content,
        mediaItems: e.mediaItems,
        createdAt: DateTime.fromMillisecondsSinceEpoch(e.createdAt),
        likes: e.likes,
        comments: e.comments,
        location: e.location,
      );
    }).toList();
  }

  /// 插入或更新朋友圈动态
  Future<void> insertMoment(MomentsPost post) {
    return into(momentsPosts).insert(
      MomentsPostsCompanion(
        id: Value(post.id),
        user: Value(post.user),
        content: Value(post.content),
        mediaItems: Value(post.mediaItems),
        createdAt: Value(post.createdAt.millisecondsSinceEpoch),
        likes: Value(post.likes),
        comments: Value(post.comments),
        location: Value(post.location),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除动态
  Future<void> deleteMoment(String id) {
    return (delete(momentsPosts)..where((t) => t.id.equals(id))).go();
  }

  // --- Helper Methods for Background Service ---

  Future<ChatMessage?> getLastMessage(String sessionId) async {
    final query = select(chatMessages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
      ])
      ..limit(1);

    final msg = await query.getSingleOrNull();
    if (msg == null) return null;

    return ChatMessage(
      id: msg.id,
      isMe: msg.isMe,
      type: msg.type,
      content: msg.content,
      timestamp: msg.timestamp,
      metadata: msg.metadata,
      isRead: msg.isRead,
    );
  }

  Future<ContactRole?> getContactById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rolesJson = prefs.getString('contact_roles');
      if (rolesJson != null) {
        final List<dynamic> decoded = jsonDecode(rolesJson);
        final roles =
            decoded.map((item) => ContactRole.fromJson(item)).toList();
        return roles.firstWhere((r) => r.id == id);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<ContactMe?> getMeById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final meListJson = prefs.getString('contact_me_list');
      if (meListJson != null) {
        final List<dynamic> decoded = jsonDecode(meListJson);
        final meList = decoded.map((item) => ContactMe.fromJson(item)).toList();
        return meList.firstWhere((m) => m.id == id);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<ApiPreset?> getApiPreset(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getStringList('api_presets') ?? [];
      final presets = presetsJson
          .map((json) => ApiPreset.fromJson(jsonDecode(json)))
          .toList();
      return presets.firstWhere((p) => p.id == id);
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<List<ApiPreset>> getAllApiPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getStringList('api_presets') ?? [];
      return presetsJson
          .map((json) => ApiPreset.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final messages = await (select(chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.timestamp,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();

    return messages
        .map(
          (m) => ChatMessage(
            id: m.id,
            isMe: m.isMe,
            type: m.type,
            content: m.content,
            timestamp: m.timestamp,
            metadata: m.metadata,
            isRead: m.isRead,
          ),
        )
        .toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
