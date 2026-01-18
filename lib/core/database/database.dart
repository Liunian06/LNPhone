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
import '../models/world_info_model.dart';
import '../models/text_preset_model.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
    tables: [ChatSessions, ChatMessages, MomentsPosts, WorldInfos, TextPresets])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  static AppDatabase? _instance;

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  AppDatabase._internal() : super(_openConnection());

  /// 重新连接数据库（用于导入备份后刷新连接）
  /// 返回新的数据库实例
  static Future<AppDatabase> reconnect() async {
    // 关闭现有连接
    if (_instance != null) {
      try {
        await _instance!.close();
        print('[Database] 已关闭现有数据库连接');
      } catch (e) {
        print('[Database] 关闭数据库连接时出错: $e');
      }
    }

    // 清除单例实例
    _instance = null;

    // 创建新实例（这会触发迁移）
    _instance = AppDatabase._internal();
    print('[Database] 已创建新的数据库连接');

    // 执行一次简单查询以触发数据库打开和迁移
    try {
      await _instance!.customSelect('SELECT 1').get();
      print('[Database] 数据库迁移检查完成');
    } catch (e) {
      print('[Database] 数据库初始化检查时出错: $e');
    }

    return _instance!;
  }

  /// 检查是否有活动的数据库连接
  static bool get hasActiveConnection => _instance != null;

  @override
  int get schemaVersion => 7;

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
        if (from < 6) {
          await m.createTable(worldInfos);
          await m.createTable(textPresets);
          await m.addColumn(chatSessions, chatSessions.worldInfoIds);
          await m.addColumn(chatSessions, chatSessions.textPresetIds);
          await m.addColumn(chatSessions, chatSessions.apiPresetId);
        }
        if (from < 7) {
          await m.addColumn(chatSessions, chatSessions.backgroundImage);
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
          worldInfoIds: s.worldInfoIds,
          textPresetIds: s.textPresetIds,
          apiPresetId: s.apiPresetId,
          backgroundImage: s.backgroundImage,
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
      worldInfoIds: s.worldInfoIds,
      textPresetIds: s.textPresetIds,
      apiPresetId: s.apiPresetId,
      backgroundImage: s.backgroundImage,
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

  /// 更新会话的最后更新时间（安全方式，使用 update 而非 insertOrReplace）
  /// 这是为了避免 insertOrReplace 触发外键级联删除导致消息丢失
  Future<void> updateSessionLastUpdated(
    String id,
    int lastUpdated, {
    List<String>? worldInfoIds,
    List<String>? textPresetIds,
  }) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(
        lastUpdated: Value(lastUpdated),
        worldInfoIds:
            worldInfoIds != null ? Value(worldInfoIds) : const Value.absent(),
        textPresetIds:
            textPresetIds != null ? Value(textPresetIds) : const Value.absent(),
      ),
    );
  }

  /// 更新会话的世界书、预设和 API 预设
  Future<void> updateSessionConfig(
    String id, {
    List<String>? worldInfoIds,
    List<String>? textPresetIds,
    String? apiPresetId,
  }) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(
        worldInfoIds:
            worldInfoIds != null ? Value(worldInfoIds) : const Value.absent(),
        textPresetIds:
            textPresetIds != null ? Value(textPresetIds) : const Value.absent(),
        apiPresetId:
            apiPresetId != null ? Value(apiPresetId) : const Value.absent(),
      ),
    );
  }

  /// 更新会话的背景图
  Future<void> updateSessionBackgroundImage(
      String id, String? backgroundImage) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(backgroundImage: Value(backgroundImage)),
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

  // --- World Info Queries ---

  Future<List<WorldInfo>> getAllWorldInfos() async {
    final query = select(worldInfos)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities
        .map(
          (e) => WorldInfo(
            id: e.id,
            name: e.name,
            content: e.content,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> insertWorldInfo(WorldInfo info) {
    return into(worldInfos).insert(
      WorldInfosCompanion(
        id: Value(info.id),
        name: Value(info.name),
        content: Value(info.content),
        createdAt: Value(info.createdAt),
        updatedAt: Value(info.updatedAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteWorldInfo(String id) {
    return (delete(worldInfos)..where((t) => t.id.equals(id))).go();
  }

  Future<WorldInfo?> getWorldInfo(String id) async {
    final e = await (select(worldInfos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (e == null) return null;
    return WorldInfo(
      id: e.id,
      name: e.name,
      content: e.content,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  // --- Text Preset Queries ---

  Future<List<TextPreset>> getAllTextPresets() async {
    final query = select(textPresets)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities
        .map(
          (e) => TextPreset(
            id: e.id,
            name: e.name,
            content: e.content,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> insertTextPreset(TextPreset preset) {
    return into(textPresets).insert(
      TextPresetsCompanion(
        id: Value(preset.id),
        name: Value(preset.name),
        content: Value(preset.content),
        createdAt: Value(preset.createdAt),
        updatedAt: Value(preset.updatedAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteTextPreset(String id) {
    return (delete(textPresets)..where((t) => t.id.equals(id))).go();
  }

  Future<TextPreset?> getTextPreset(String id) async {
    final e = await (select(textPresets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (e == null) return null;
    return TextPreset(
      id: e.id,
      name: e.name,
      content: e.content,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
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
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      print('[Database] Opening database at ${file.path}');
      // 使用 createInBackground 并开启 WAL 模式以支持多 Isolate 并发访问
      // 注意：不要启用 PRAGMA foreign_keys = ON，因为 insertOrReplace 会触发级联删除！
      return NativeDatabase.createInBackground(
        file,
        setup: (db) {
          try {
            db.execute('PRAGMA journal_mode = WAL;');
            // 不启用外键约束，避免 insertOrReplace 触发级联删除导致消息丢失
            // db.execute('PRAGMA foreign_keys = ON;');
            print(
                '[Database] WAL mode enabled (Foreign Keys disabled for safety)');
          } catch (e) {
            print('[Database] Error setting up database pragmas: $e');
          }
        },
      );
    } catch (e) {
      print('[Database] Error opening database: $e');
      rethrow;
    }
  });
}
