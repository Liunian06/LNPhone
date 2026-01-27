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
import '../models/memory_model.dart';
import '../models/wallet_model.dart';
import 'tables.dart';
import '../models/emoji_model.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  ChatSessions,
  ChatMessages,
  MomentsPosts,
  WorldInfos,
  TextPresets,
  RoleMemories,
  ContactRoles,
  ContactMes,
  ApiPresets,
  MomentsUserSettings,
  AppSettings,
  WalletTransactions,
  Emojis,
  EmojiGroups,
])
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
  int get schemaVersion => 30;

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
        if (from < 8) {
          await m.addColumn(
              chatSessions, chatSessions.enableIndependentSendButton);
        }
        if (from < 9) {
          // 添加 sender 字段用于存储发送者名称
          await m.addColumn(chatMessages, chatMessages.sender);
        }
        if (from < 10) {
          // 添加角色记忆表
          await m.createTable(roleMemories);
        }
        if (from < 11) {
          // 添加角色人设表、用户人设表、API预设表
          await m.createTable(contactRoles);
          await m.createTable(contactMes);
          await m.createTable(apiPresets);

          // 注意：这里只创建了表，数据迁移逻辑在 ContactProvider 中处理
          // 因为 Drift 的 migration 主要是 schema 变更，而数据迁移可能涉及复杂的逻辑（如读取 SharedPreferences）
        }
        if (from < 12) {
          // 添加朋友圈用户设置表
          await m.createTable(momentsUserSettings);
        }
        if (from < 13) {
          // 添加通用应用设置表（替代 SharedPreferences）
          await m.createTable(appSettings);
        }
        if (from < 14) {
          // 添加钱包交易记录表
          await m.createTable(walletTransactions);
        }
        if (from < 15) {
          // 添加 API 预设类型字段
          try {
            await m.addColumn(apiPresets, apiPresets.type);
          } catch (e) {
            print('[Migration] Warning: failed to add type to apiPresets: $e');
          }
        }
        if (from < 16) {
          // 添加文生图开关
          try {
            await m.addColumn(chatSessions, chatSessions.enableTextToImage);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add enableTextToImage to chatSessions: $e');
          }
        }
        if (from < 17) {
          // 添加外貌和参考图字段
          // 使用 try-catch 包裹以防止列已存在时导致迁移失败
          // (例如从旧版本跨版本升级时，createTable 已经创建了包含新列的表，再次 addColumn 会导致 duplicate column 错误)
          try {
            await m.addColumn(contactRoles,
                contactRoles.appearance as GeneratedColumn<Object>);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add appearance to contactRoles: $e');
          }
          try {
            await m.addColumn(contactRoles,
                contactRoles.referenceImages as GeneratedColumn<Object>);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add referenceImages to contactRoles: $e');
          }
          try {
            await m.addColumn(
                contactMes, contactMes.appearance as GeneratedColumn<Object>);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add appearance to contactMes: $e');
          }
          try {
            await m.addColumn(contactMes,
                contactMes.referenceImages as GeneratedColumn<Object>);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add referenceImages to contactMes: $e');
          }
        }
        if (from < 18) {
          // 添加表情包表
          await m.createTable(emojis);
        }
        if (from < 19) {
          // 强制检查并添加缺失的列，防止之前的迁移失败导致表结构不完整
          try {
            await m.addColumn(emojis, emojis.localPath);
          } catch (e) {
            print('[Migration] localPath column might already exist: $e');
          }
        }
        if (from < 21) {
          // 确保 emojis 表存在
          try {
            await m.createTable(emojis);
          } catch (e) {
            print('[Migration] emojis table might already exist: $e');
          }
        }
        if (from < 22) {
          // 添加 rawContent 列
          try {
            await m.addColumn(emojis, emojis.rawContent);
          } catch (e) {
            print('[Migration] rawContent column might already exist: $e');
          }
        }
        if (from < 23) {
          // 添加 groupId 列并创建 EmojiGroups 表
          try {
            await m.addColumn(emojis, emojis.groupId);
            await m.createTable(emojiGroups);
          } catch (e) {
            print('[Migration] Error in version 23: $e');
          }
        }
        if (from < 24) {
          // 添加 EmojiGroups.isVisible 列
          try {
            await m.addColumn(
                emojiGroups, emojiGroups.isVisible as GeneratedColumn<Object>);
          } catch (e) {
            print('[Migration] Error in version 24: $e');
          }
        }
        if (from < 25) {
          // 添加独立生图 API 预设字段
          try {
            await m.addColumn(chatSessions,
                chatSessions.imageApiPresetId as GeneratedColumn<Object>);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add imageApiPresetId to chatSessions: $e');
          }
        }
        if (from < 26) {
          // 添加启用表情包开关
          try {
            await m.addColumn(chatSessions,
                chatSessions.enableEmoji as GeneratedColumn<Object>);
          } catch (e) {
            print(
                '[Migration] Warning: failed to add enableEmoji to chatSessions: $e');
          }
        }
        if (from < 27) {
          // 添加 ContactRoles.subscribedGroupIds 列
          try {
            await m.addColumn(contactRoles,
                contactRoles.subscribedGroupIds as GeneratedColumn<Object>);
          } catch (e) {
            print('[Migration] Error in version 27: $e');
          }
        }
        if (from < 28) {
          // 统一表情池重构：清空所有分组，将所有表情设为全局且未分组
          try {
            await m.deleteTable('emoji_groups');
            await m.createTable(emojiGroups);
            // 将所有表情更新为全局类型且无分组
            await customStatement(
                'UPDATE emojis SET type = 0, group_id = NULL, role_id = NULL');
            print(
                '[Migration] Version 28: All emojis flattened to unified pool.');
          } catch (e) {
            print('[Migration] Error in version 28: $e');
          }
        }
        if (from < 29) {
          // 添加 ContactRoles.subscribedEmojiIds 列
          try {
            await m.addColumn(contactRoles,
                contactRoles.subscribedEmojiIds as GeneratedColumn<Object>);
          } catch (e) {
            print('[Migration] Error in version 29: $e');
          }
        }
        if (from < 30) {
          // 添加 ApiPresets.timeout 列
          try {
            await m.addColumn(
                apiPresets, apiPresets.timeout as GeneratedColumn<Object>);
          } catch (e) {
            print('[Migration] Error in version 30: $e');
          }
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
                  sender: m.sender,
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
          enableTextToImage: s.enableTextToImage,
          enableEmoji: s.enableEmoji ?? true,
          enableIndependentSendButton: s.enableIndependentSendButton,
          currentState: s.currentState,
          isPinned: s.isPinned,
          worldInfoIds: s.worldInfoIds,
          textPresetIds: s.textPresetIds,
          apiPresetId: s.apiPresetId,
          imageApiPresetId: s.imageApiPresetId,
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
              sender: m.sender,
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
      enableTextToImage: s.enableTextToImage,
      enableEmoji: s.enableEmoji ?? true,
      enableIndependentSendButton: s.enableIndependentSendButton,
      currentState: s.currentState,
      isPinned: s.isPinned,
      worldInfoIds: s.worldInfoIds,
      textPresetIds: s.textPresetIds,
      apiPresetId: s.apiPresetId,
      imageApiPresetId: s.imageApiPresetId,
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

  /// 更新消息元数据
  Future<void> updateMessageMetadata(
      String id, Map<String, dynamic> newMetadata) {
    return (update(chatMessages)..where((t) => t.id.equals(id))).write(
      ChatMessagesCompanion(metadata: Value(newMetadata)),
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

  /// 获取所有图片类型的消息
  Future<List<ChatMessage>> getAllImageMessages() async {
    final query = select(chatMessages)
      ..where((t) => t.type.equals(MessageType.image.index));

    final entities = await query.get();

    return entities
        .map(
          (m) => ChatMessage(
            id: m.id,
            isMe: m.isMe,
            sender: m.sender,
            type: m.type,
            content: m.content,
            timestamp: m.timestamp,
            metadata: m.metadata,
            isRead: m.isRead,
          ),
        )
        .toList();
  }

  /// 删除指定时间之后的消息 (用于回溯)
  Future<void> deleteMessagesAfter(String sessionId, int timestamp) {
    return (delete(chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.timestamp.isBiggerThanValue(timestamp)))
        .go();
  }

  /// 更新会话设置
  Future<void> updateSessionSettings(
    String id, {
    bool? enableExtendedChat,
    bool? enableTextToImage,
    bool? enableEmoji,
    bool? enableIndependentSendButton,
  }) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(
        enableExtendedChat: enableExtendedChat != null
            ? Value(enableExtendedChat)
            : const Value.absent(),
        enableTextToImage: enableTextToImage != null
            ? Value(enableTextToImage)
            : const Value.absent(),
        enableIndependentSendButton: enableIndependentSendButton != null
            ? Value(enableIndependentSendButton)
            : const Value.absent(),
        enableEmoji:
            enableEmoji != null ? Value(enableEmoji) : const Value.absent(),
      ),
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
    String? imageApiPresetId,
  }) {
    return (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(
        worldInfoIds:
            worldInfoIds != null ? Value(worldInfoIds) : const Value.absent(),
        textPresetIds:
            textPresetIds != null ? Value(textPresetIds) : const Value.absent(),
        apiPresetId:
            apiPresetId != null ? Value(apiPresetId) : const Value.absent(),
        imageApiPresetId: imageApiPresetId != null
            ? Value(imageApiPresetId)
            : const Value.absent(),
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
        likes: e.likes, // 这里现在是 List<MomentLike>
        comments: e.comments,
        location: e.location,
      );
    }).toList();
  }

  Future<MomentsPost?> getMoment(String id) async {
    final query = select(momentsPosts)..where((t) => t.id.equals(id));
    final e = await query.getSingleOrNull();
    if (e == null) return null;
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
        likes: Value(post.likes), // 这里现在是 List<MomentLike>
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

  Future<void> deleteWorldInfos(List<String> ids) {
    return (delete(worldInfos)..where((t) => t.id.isIn(ids))).go();
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

  Future<void> deleteTextPresets(List<String> ids) {
    return (delete(textPresets)..where((t) => t.id.isIn(ids))).go();
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

  // --- Role Memory Queries ---

  /// 获取指定角色的所有记忆
  Future<List<RoleMemory>> getMemoriesByRoleId(String roleId) async {
    final query = select(roleMemories)
      ..where((t) => t.roleId.equals(roleId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities
        .map(
          (e) => RoleMemory(
            id: e.id,
            roleId: e.roleId,
            content: e.content,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            sourceSessionId: e.sourceSessionId,
            category: e.category,
          ),
        )
        .toList();
  }

  /// 获取所有记忆
  Future<List<RoleMemory>> getAllMemories() async {
    final query = select(roleMemories)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities
        .map(
          (e) => RoleMemory(
            id: e.id,
            roleId: e.roleId,
            content: e.content,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            sourceSessionId: e.sourceSessionId,
            category: e.category,
          ),
        )
        .toList();
  }

  /// 插入或更新记忆
  Future<void> insertMemory(RoleMemory memory) {
    return into(roleMemories).insert(
      RoleMemoriesCompanion(
        id: Value(memory.id),
        roleId: Value(memory.roleId),
        content: Value(memory.content),
        createdAt: Value(memory.createdAt),
        updatedAt: Value(memory.updatedAt),
        sourceSessionId: Value(memory.sourceSessionId),
        category: Value(memory.category),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 更新记忆内容
  Future<void> updateMemoryContent(
      String id, String content, MemoryCategory category) {
    return (update(roleMemories)..where((t) => t.id.equals(id))).write(
      RoleMemoriesCompanion(
        content: Value(content),
        category: Value(category),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 删除记忆
  Future<void> deleteMemory(String id) {
    return (delete(roleMemories)..where((t) => t.id.equals(id))).go();
  }

  /// 删除指定角色的所有记忆
  Future<void> deleteMemoriesByRoleId(String roleId) {
    return (delete(roleMemories)..where((t) => t.roleId.equals(roleId))).go();
  }

  /// 获取单条记忆
  Future<RoleMemory?> getMemory(String id) async {
    final e = await (select(roleMemories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (e == null) return null;
    return RoleMemory(
      id: e.id,
      roleId: e.roleId,
      content: e.content,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      sourceSessionId: e.sourceSessionId,
      category: e.category,
    );
  }

  // --- ContactRole Queries ---

  /// 获取所有角色人设
  Future<List<ContactRole>> getAllContactRoles() async {
    final entities = await select(contactRoles).get();
    return entities
        .map(
          (e) => ContactRole(
            id: e.id,
            name: e.name,
            avatarPath: e.avatarPath,
            description: e.description,
            appearance: e.appearance,
            referenceImages: e.referenceImages,
            subscribedGroupIds: e.subscribedGroupIds,
            subscribedEmojiIds: e.subscribedEmojiIds,
          ),
        )
        .toList();
  }

  /// 插入或更新角色人设
  Future<void> insertContactRole(ContactRole role) {
    return into(contactRoles).insert(
      ContactRolesCompanion(
        id: Value(role.id),
        name: Value(role.name),
        avatarPath: Value(role.avatarPath),
        description: Value(role.description),
        appearance: Value(role.appearance),
        referenceImages: Value(role.referenceImages),
        subscribedGroupIds: Value(role.subscribedGroupIds),
        subscribedEmojiIds: Value(role.subscribedEmojiIds),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除角色人设
  Future<void> deleteContactRole(String id) {
    return (delete(contactRoles)..where((t) => t.id.equals(id))).go();
  }

  /// 获取单个角色人设
  Future<ContactRole?> getContactRole(String id) async {
    final e = await (select(contactRoles)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (e == null) return null;
    return ContactRole(
      id: e.id,
      name: e.name,
      avatarPath: e.avatarPath,
      description: e.description,
      appearance: e.appearance,
      referenceImages: e.referenceImages,
      subscribedGroupIds: e.subscribedGroupIds,
      subscribedEmojiIds: e.subscribedEmojiIds,
    );
  }

  // --- ContactMe Queries ---

  /// 获取所有用户人设
  Future<List<ContactMe>> getAllContactMes() async {
    final entities = await select(contactMes).get();
    return entities
        .map(
          (e) => ContactMe(
            id: e.id,
            name: e.name,
            avatarPath: e.avatarPath,
            info: e.info,
            appearance: e.appearance,
            referenceImages: e.referenceImages,
          ),
        )
        .toList();
  }

  /// 插入或更新用户人设
  Future<void> insertContactMe(ContactMe me) {
    return into(contactMes).insert(
      ContactMesCompanion(
        id: Value(me.id),
        name: Value(me.name),
        avatarPath: Value(me.avatarPath),
        info: Value(me.info),
        appearance: Value(me.appearance),
        referenceImages: Value(me.referenceImages),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除用户人设
  Future<void> deleteContactMe(String id) {
    return (delete(contactMes)..where((t) => t.id.equals(id))).go();
  }

  /// 获取单个用户人设
  Future<ContactMe?> getContactMe(String id) async {
    final e = await (select(contactMes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (e == null) return null;
    return ContactMe(
      id: e.id,
      name: e.name,
      avatarPath: e.avatarPath,
      info: e.info,
      appearance: e.appearance,
      referenceImages: e.referenceImages,
    );
  }

  // --- ApiPreset Queries ---

  /// 获取所有API预设（从数据库）
  Future<List<ApiPreset>> getAllApiPresetsFromDb() async {
    final entities = await select(apiPresets).get();
    return entities
        .map(
          (e) => ApiPreset(
            id: e.id,
            name: e.name,
            type: e.type,
            provider: e.provider,
            baseUrl: e.baseUrl,
            apiKey: e.apiKey,
            model: e.model,
            temperature: e.temperature,
            topP: e.topP,
            isStream: e.isStream,
            enableThinking: e.enableThinking,
            timeout: e.timeout,
          ),
        )
        .toList();
  }

  /// 插入或更新API预设
  Future<void> insertApiPreset(ApiPreset preset) {
    return into(apiPresets).insert(
      ApiPresetsCompanion(
        id: Value(preset.id),
        name: Value(preset.name),
        type: Value(preset.type),
        provider: Value(preset.provider),
        baseUrl: Value(preset.baseUrl),
        apiKey: Value(preset.apiKey),
        model: Value(preset.model),
        temperature: Value(preset.temperature),
        topP: Value(preset.topP),
        isStream: Value(preset.isStream),
        enableThinking: Value(preset.enableThinking),
        timeout: Value(preset.timeout),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除API预设
  Future<void> deleteApiPreset(String id) {
    return (delete(apiPresets)..where((t) => t.id.equals(id))).go();
  }

  /// 获取单个API预设（从数据库）
  Future<ApiPreset?> getApiPresetFromDb(String id) async {
    final e = await (select(apiPresets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (e == null) return null;
    return ApiPreset(
      id: e.id,
      name: e.name,
      type: e.type,
      provider: e.provider,
      baseUrl: e.baseUrl,
      apiKey: e.apiKey,
      model: e.model,
      temperature: e.temperature,
      topP: e.topP,
      isStream: e.isStream,
      enableThinking: e.enableThinking,
      timeout: e.timeout,
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
      sender: msg.sender,
      type: msg.type,
      content: msg.content,
      timestamp: msg.timestamp,
      metadata: msg.metadata,
      isRead: msg.isRead,
    );
  }

  /// [已弃用] 请使用 getContactRole(id) 代替
  /// 此方法保留仅用于兼容后台服务
  Future<ContactRole?> getContactById(String id) async {
    // 直接从数据库读取
    return getContactRole(id);
  }

  /// [已弃用] 请使用 getContactMe(id) 代替
  /// 此方法保留仅用于兼容后台服务
  Future<ContactMe?> getMeById(String id) async {
    // 直接从数据库读取
    return getContactMe(id);
  }

  /// [已弃用] 请使用 getApiPresetFromDb(id) 代替
  /// 此方法保留仅用于兼容后台服务
  Future<ApiPreset?> getApiPreset(String id) async {
    // 直接从数据库读取
    return getApiPresetFromDb(id);
  }

  /// [已弃用] 请使用 getAllApiPresetsFromDb() 代替
  /// 此方法保留仅用于兼容旧代码
  Future<List<ApiPreset>> getAllApiPresets() async {
    // 直接从数据库读取
    return getAllApiPresetsFromDb();
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
            sender: m.sender,
            type: m.type,
            content: m.content,
            timestamp: m.timestamp,
            metadata: m.metadata,
            isRead: m.isRead,
          ),
        )
        .toList();
  }

  // --- MomentsUserSettings Queries ---

  /// 获取朋友圈用户设置
  Future<MomentsUserSettingsEntity?> getMomentsUserSettings() async {
    final e = await (select(momentsUserSettings)
          ..where((t) => t.id.equals('current_user')))
        .getSingleOrNull();
    return e;
  }

  /// 保存朋友圈用户设置
  Future<void> saveMomentsUserSettings({
    required String name,
    String? avatarUrl,
    String? coverImageUrl,
    String? signature,
  }) async {
    await into(momentsUserSettings).insert(
      MomentsUserSettingsCompanion(
        id: const Value('current_user'),
        name: Value(name),
        avatarUrl: Value(avatarUrl),
        coverImageUrl: Value(coverImageUrl),
        signature: Value(signature),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 更新朋友圈用户名称
  Future<void> updateMomentsUserName(String name) async {
    await (update(momentsUserSettings)
          ..where((t) => t.id.equals('current_user')))
        .write(MomentsUserSettingsCompanion(name: Value(name)));
  }

  /// 更新朋友圈用户头像
  Future<void> updateMomentsUserAvatar(String? avatarUrl) async {
    await (update(momentsUserSettings)
          ..where((t) => t.id.equals('current_user')))
        .write(MomentsUserSettingsCompanion(avatarUrl: Value(avatarUrl)));
  }

  /// 更新朋友圈用户封面
  Future<void> updateMomentsUserCover(String? coverImageUrl) async {
    await (update(momentsUserSettings)
          ..where((t) => t.id.equals('current_user')))
        .write(
            MomentsUserSettingsCompanion(coverImageUrl: Value(coverImageUrl)));
  }

  /// 更新朋友圈用户签名
  Future<void> updateMomentsUserSignature(String? signature) async {
    await (update(momentsUserSettings)
          ..where((t) => t.id.equals('current_user')))
        .write(MomentsUserSettingsCompanion(signature: Value(signature)));
  }

  // --- AppSettings Queries (Key-Value 设置存储) ---
  // 注意：所有应用设置应该存储在数据库中
  // SharedPreferences 已被弃用，请勿在其中读写数据

  /// 获取设置值（字符串）
  Future<String?> getSetting(String key) async {
    final e = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return e?.value;
  }

  /// 获取设置值（整数）
  Future<int?> getSettingInt(String key) async {
    final e = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (e == null) return null;
    return int.tryParse(e.value);
  }

  /// 获取设置值（浮点数）
  Future<double?> getSettingDouble(String key) async {
    final e = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (e == null) return null;
    return double.tryParse(e.value);
  }

  /// 获取设置值（布尔值）
  Future<bool?> getSettingBool(String key) async {
    final e = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (e == null) return null;
    return e.value == 'true';
  }

  /// 获取设置值（字符串列表）
  Future<List<String>?> getSettingStringList(String key) async {
    final e = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (e == null) return null;
    try {
      final List<dynamic> decoded = json.decode(e.value);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  /// 设置值（字符串）
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insert(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
        type: const Value('string'),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 设置值（整数）
  Future<void> setSettingInt(String key, int value) async {
    await into(appSettings).insert(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value.toString()),
        type: const Value('int'),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 设置值（浮点数）
  Future<void> setSettingDouble(String key, double value) async {
    await into(appSettings).insert(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value.toString()),
        type: const Value('double'),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 设置值（布尔值）
  Future<void> setSettingBool(String key, bool value) async {
    await into(appSettings).insert(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value.toString()),
        type: const Value('bool'),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 设置值（字符串列表）
  Future<void> setSettingStringList(String key, List<String> value) async {
    await into(appSettings).insert(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(json.encode(value)),
        type: const Value('json'),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    await (delete(appSettings)..where((t) => t.key.equals(key))).go();
  }

  /// 检查设置是否存在
  Future<bool> hasSetting(String key) async {
    final e = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return e != null;
  }

  /// 获取所有设置
  Future<Map<String, String>> getAllSettings() async {
    final entities = await select(appSettings).get();
    return {for (final e in entities) e.key: e.value};
  }

  // --- Wallet Queries ---

  /// 获取钱包余额
  Future<double> getWalletBalance() async {
    final balanceStr = await getSetting('wallet_balance');
    if (balanceStr == null) return 0.0;
    return double.tryParse(balanceStr) ?? 0.0;
  }

  /// 设置钱包余额
  Future<void> setWalletBalance(double balance) async {
    // 确保余额在有效范围内
    final clampedBalance = balance.clamp(0.0, Wallet.maxBalance);
    await setSetting('wallet_balance', clampedBalance.toString());
  }

  /// 获取所有钱包交易记录（按时间倒序）
  Future<List<WalletTransaction>> getAllWalletTransactions() async {
    final query = select(walletTransactions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities
        .map(
          (e) => WalletTransaction(
            id: e.id,
            type: e.type,
            direction: e.direction,
            amount: e.amount,
            description: e.description,
            relatedContactName: e.relatedContactName,
            relatedSessionId: e.relatedSessionId,
            relatedMessageId: e.relatedMessageId,
            timestamp: e.timestamp,
          ),
        )
        .toList();
  }

  /// 插入钱包交易记录
  Future<void> insertWalletTransaction(WalletTransaction transaction) async {
    await into(walletTransactions).insert(
      WalletTransactionsCompanion(
        id: Value(transaction.id),
        type: Value(transaction.type),
        direction: Value(transaction.direction),
        amount: Value(transaction.amount),
        description: Value(transaction.description),
        relatedContactName: Value(transaction.relatedContactName),
        relatedSessionId: Value(transaction.relatedSessionId),
        relatedMessageId: Value(transaction.relatedMessageId),
        timestamp: Value(transaction.timestamp),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除钱包交易记录
  Future<void> deleteWalletTransaction(String id) async {
    await (delete(walletTransactions)..where((t) => t.id.equals(id))).go();
  }

  /// 清空所有钱包交易记录
  Future<void> clearAllWalletTransactions() async {
    await delete(walletTransactions).go();
  }

  // --- Emoji Queries ---

  /// 获取所有表情包
  Future<List<EmojiModel>> getAllEmojis() async {
    final entities = await select(emojis).get();
    return entities
        .map(
          (e) => EmojiModel(
            id: e.id,
            meaning: e.meaning,
            rawContent: e.rawContent,
            groupId: e.groupId,
            localPath: e.localPath,
            type: e.type,
            roleId: e.roleId,
            createdAt: e.createdAt,
          ),
        )
        .toList();
  }

  /// 获取指定角色的表情包（包括全局表情和该角色的专属表情）
  Future<List<EmojiModel>> getEmojisForRole(String roleId) async {
    final query = select(emojis)
      ..where((t) =>
          t.type.equals(EmojiType.global.index) | t.roleId.equals(roleId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
      ]);
    final entities = await query.get();
    return entities
        .map(
          (e) => EmojiModel(
            id: e.id,
            meaning: e.meaning,
            rawContent: e.rawContent,
            groupId: e.groupId,
            localPath: e.localPath,
            type: e.type,
            roleId: e.roleId,
            createdAt: e.createdAt,
          ),
        )
        .toList();
  }

  /// 插入或更新表情包
  Future<void> insertEmoji(EmojiModel emoji) {
    return into(emojis).insert(
      EmojisCompanion(
        id: Value(emoji.id),
        meaning: Value(emoji.meaning),
        rawContent: Value(emoji.rawContent),
        groupId: Value(emoji.groupId),
        localPath: Value(emoji.localPath),
        type: Value(emoji.type),
        roleId: Value(emoji.roleId),
        createdAt: Value(emoji.createdAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 删除表情包
  Future<void> deleteEmoji(String id) {
    return (delete(emojis)..where((t) => t.id.equals(id))).go();
  }

  /// 批量删除表情包
  Future<void> deleteEmojis(List<String> ids) {
    return (delete(emojis)..where((t) => t.id.isIn(ids))).go();
  }

  // --- EmojiGroup Queries ---

  Future<List<EmojiGroupEntity>> getAllEmojiGroups() async {
    return await select(emojiGroups).get();
  }

  Future<void> insertEmojiGroup(EmojiGroupEntity group) {
    return into(emojiGroups).insert(group, mode: InsertMode.insertOrReplace);
  }

  Future<void> deleteEmojiGroup(String id) {
    return (delete(emojiGroups)..where((t) => t.id.equals(id))).go();
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
            // 设置繁忙超时，减少 database is locked 错误
            db.execute('PRAGMA busy_timeout = 5000;');
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
