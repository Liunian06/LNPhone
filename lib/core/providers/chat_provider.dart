import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import '../models/api_preset.dart';
import '../models/contact_model.dart';
import '../models/moments_model.dart';
import '../models/world_info_model.dart';
import '../models/text_preset_model.dart';
import '../providers/prompt_settings_provider.dart';
import '../services/llm_service.dart';
import '../models/prompt_config.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';
import '../database/database.dart' as db;

class ChatProvider extends ChangeNotifier {
  List<ChatSession> _chats = [];
  List<WorldInfo> _worldInfos = [];
  List<TextPreset> _textPresets = [];
  bool _isLoaded = false;
  late db.AppDatabase _database;

  // 聊天状态管理
  final Map<String, bool> _typingStates = {};
  final Map<String, String> _currentStates = {};
  final Map<String, Timer> _debounceTimers = {};

  List<ChatSession> get chats => _chats;
  List<WorldInfo> get worldInfos => _worldInfos;
  List<TextPreset> get textPresets => _textPresets;
  bool get isLoaded => _isLoaded;

  bool isTyping(String chatId) => _typingStates[chatId] ?? false;
  String? getCurrentState(String chatId) => _currentStates[chatId];

  ChatProvider() {
    _database = db.AppDatabase();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. 检查并执行迁移
    await _performMigration();

    // 2. 从数据库加载数据
    await _refreshChats();
    await refreshWorldInfos();
    await refreshTextPresets();

    _isLoaded = true;
    notifyListeners();
  }

  /// 重新加载数据（用于导入备份后刷新数据）
  /// 这会重新获取数据库实例并刷新所有数据
  Future<void> reloadData() async {
    // 获取最新的数据库实例（可能已经被重连）
    _database = db.AppDatabase();

    // 清空当前状态
    _typingStates.clear();
    _currentStates.clear();
    _debounceTimers.forEach((_, timer) => timer.cancel());
    _debounceTimers.clear();

    // 重新加载所有数据
    _chats = await _database.getAllSessions();
    _worldInfos = await _database.getAllWorldInfos();
    _textPresets = await _database.getAllTextPresets();

    // 恢复状态
    for (final chat in _chats) {
      if (chat.currentState != null) {
        _currentStates[chat.id] = chat.currentState!;
      }
    }

    debugPrint(
        '[ChatProvider] 数据重新加载完成: ${_chats.length} 个会话, ${_worldInfos.length} 个世界书, ${_textPresets.length} 个预设');
    notifyListeners();
  }

  /// 从 SharedPreferences 迁移到 SQLite
  Future<void> _performMigration() async {
    final prefs = await SharedPreferences.getInstance();
    // 检查是否有由于旧版本遗留的数据
    if (prefs.containsKey('chat_sessions')) {
      final chatsJson = prefs.getString('chat_sessions');
      if (chatsJson != null) {
        try {
          debugPrint('Starting migration from SharedPreferences to SQLite...');
          final List<dynamic> decoded = jsonDecode(chatsJson);
          final oldSessions =
              decoded.map((item) => ChatSession.fromJson(item)).toList();

          for (final session in oldSessions) {
            // 插入 Session
            await _database.insertChatSession(
              db.ChatSessionsCompanion(
                id: drift.Value(session.id),
                roleId: drift.Value(session.roleId),
                meId: drift.Value(session.meId),
                lastUpdated: drift.Value(session.lastUpdated),
                enableExtendedChat: drift.Value(session.enableExtendedChat),
                enableIndependentSendButton:
                    drift.Value(session.enableIndependentSendButton),
              ),
            );

            // 插入 Messages
            if (session.messages.isNotEmpty) {
              final msgs = session.messages
                  .map(
                    (m) => db.ChatMessagesCompanion(
                      id: drift.Value(m.id),
                      sessionId: drift.Value(session.id),
                      isMe: drift.Value(m.isMe),
                      type: drift.Value(m.type),
                      content: drift.Value(m.content),
                      timestamp: drift.Value(m.timestamp),
                      metadata: drift.Value(m.metadata),
                    ),
                  )
                  .toList();

              await _database.insertMessages(session.id, msgs);
            }
          }

          // 迁移成功后删除旧数据
          await prefs.remove('chat_sessions');
          debugPrint('Migration completed successfully.');
        } catch (e) {
          debugPrint('Migration failed: $e');
        }
      }
    }
  }

  /// 重新从数据库加载数据到内存
  Future<void> _refreshChats() async {
    _chats = await _database.getAllSessions();
    // 恢复状态
    for (final chat in _chats) {
      if (chat.currentState != null) {
        _currentStates[chat.id] = chat.currentState!;
      }
    }
    notifyListeners();
  }

  Future<void> refreshWorldInfos() async {
    _worldInfos = await _database.getAllWorldInfos();
    notifyListeners();
  }

  Future<void> refreshTextPresets() async {
    _textPresets = await _database.getAllTextPresets();
    notifyListeners();
  }

  Future<void> addWorldInfo(WorldInfo info) async {
    await _database.insertWorldInfo(info);
    await refreshWorldInfos();
  }

  Future<void> deleteWorldInfo(String id) async {
    await _database.deleteWorldInfo(id);
    await refreshWorldInfos();
  }

  Future<void> addTextPreset(TextPreset preset) async {
    await _database.insertTextPreset(preset);
    await refreshTextPresets();
  }

  Future<void> deleteTextPreset(String id) async {
    await _database.deleteTextPreset(id);
    await refreshTextPresets();
  }

  Future<String> createChat(
    String roleId,
    String meId, {
    List<String>? worldInfoIds,
    List<String>? textPresetIds,
  }) async {
    // Check if chat already exists
    // 我们可以直接在内存列表中查，避免 DB 查询，提高响应速度
    final existingIndex = _chats.indexWhere(
      (c) => c.roleId == roleId && c.meId == meId,
    );

    if (existingIndex != -1) {
      // 如果存在，将其移动到顶部 (通过更新 lastUpdated)
      final chat = _chats[existingIndex];
      // 使用最新的时间戳
      final newTime = DateTime.now().millisecondsSinceEpoch;

      // 使用 update 而不是 insertOrReplace，避免触发级联删除！
      // insertOrReplace 会先删除再插入，导致外键级联删除所有关联的 messages
      await _database.updateSessionLastUpdated(
        chat.id,
        newTime,
        worldInfoIds: worldInfoIds,
        textPresetIds: textPresetIds,
      );

      // 刷新列表
      await _refreshChats();
      return chat.id;
    }

    final newId = _generateId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _database.insertChatSession(
      db.ChatSessionsCompanion(
        id: drift.Value(newId),
        roleId: drift.Value(roleId),
        meId: drift.Value(meId),
        lastUpdated: drift.Value(timestamp),
        worldInfoIds: worldInfoIds != null
            ? drift.Value(worldInfoIds)
            : const drift.Value.absent(),
        textPresetIds: textPresetIds != null
            ? drift.Value(textPresetIds)
            : const drift.Value.absent(),
      ),
    );

    await _refreshChats();
    return newId;
  }

  Future<void> addMessage(
    String chatId,
    String content,
    MessageType type,
    bool isMe, {
    Map<String, dynamic>? metadata,
    String? sender, // 发送者名称（用于引用显示）
  }) async {
    final newMessage = db.ChatMessagesCompanion(
      id: drift.Value(_generateId()),
      sessionId: drift.Value(chatId),
      content: drift.Value(content),
      isMe: drift.Value(isMe),
      sender: drift.Value(sender),
      type: drift.Value(type),
      timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
      metadata: drift.Value(metadata),
      isRead: drift.Value(isMe), // 自己发的消息默认已读，对方发的默认未读
    );

    await _database.insertMessage(newMessage);
    await _refreshChats();

    // 更新后台服务活跃时间
    if (isMe) {
      await BackgroundService.updateLastActiveTime();
    }
  }

  /// 批量添加多条消息
  Future<void> addMessages(String chatId, List<ChatMessage> messages) async {
    if (messages.isEmpty) return;

    final dbMessages = messages
        .map(
          (m) => db.ChatMessagesCompanion(
            id: drift.Value(
              m.id.isEmpty ? _generateId() : m.id,
            ), // Ensure ID exists
            sessionId: drift.Value(chatId),
            isMe: drift.Value(m.isMe),
            type: drift.Value(m.type),
            content: drift.Value(m.content),
            timestamp: drift.Value(m.timestamp),
            metadata: drift.Value(m.metadata),
            isRead: drift.Value(m.isRead),
          ),
        )
        .toList();

    await _database.insertMessages(chatId, dbMessages);
    await _refreshChats();
  }

  /// 标记会话为已读
  Future<void> markSessionAsRead(String chatId) async {
    await _database.markSessionAsRead(chatId);
    await _refreshChats();
  }

  /// 置顶/取消置顶聊天
  Future<void> togglePinChat(String chatId) async {
    final chat = getChat(chatId);
    if (chat != null) {
      await _database.updateSessionPinned(chatId, !chat.isPinned);
      await _refreshChats();
    }
  }

  Future<void> deleteChat(String chatId) async {
    await _database.deleteSession(chatId);
    await _refreshChats();
  }

  /// 更新消息内容
  Future<void> updateMessage(String messageId, String newContent) async {
    await _database.updateMessageContent(messageId, newContent);
    await _refreshChats();
  }

  /// 更新消息元数据
  Future<void> updateMessageMetadata(
      String messageId, Map<String, dynamic> newMetadata) async {
    await _database.updateMessageMetadata(messageId, newMetadata);
    await _refreshChats();
  }

  /// 删除单条消息
  Future<void> deleteMessage(String messageId) async {
    await _database.deleteMessage(messageId);
    await _refreshChats();
  }

  /// 批量删除消息
  Future<void> deleteMessages(List<String> messageIds) async {
    await _database.deleteMessages(messageIds);
    await _refreshChats();
  }

  /// 回溯：删除指定时间之后的消息
  Future<void> backtrack(String sessionId, int timestamp) async {
    await _database.deleteMessagesAfter(sessionId, timestamp);
    await _refreshChats();
  }

  ChatSession? getChat(String chatId) {
    try {
      return _chats.firstWhere((c) => c.id == chatId);
    } catch (e) {
      return null;
    }
  }

  /// 更新聊天的扩展聊天设置
  Future<void> updateChatSettings(
    String chatId, {
    bool? enableExtendedChat,
    bool? enableIndependentSendButton,
  }) async {
    await _database.updateSessionSettings(
      chatId,
      enableExtendedChat: enableExtendedChat,
      enableIndependentSendButton: enableIndependentSendButton,
    );
    await _refreshChats();
  }

  /// 更新聊天的配置（世界书、预设、API预设）
  Future<void> updateChatConfig(
    String chatId, {
    List<String>? worldInfoIds,
    List<String>? textPresetIds,
    String? apiPresetId,
  }) async {
    await _database.updateSessionConfig(
      chatId,
      worldInfoIds: worldInfoIds,
      textPresetIds: textPresetIds,
      apiPresetId: apiPresetId,
    );
    await _refreshChats();
  }

  /// 更新聊天的背景图
  Future<void> updateChatBackgroundImage(
      String chatId, String? imagePath) async {
    await _database.updateSessionBackgroundImage(chatId, imagePath);
    await _refreshChats();
  }

  /// 生成 AI 回复
  Future<void> generateAiResponse({
    required String chatId,
    required ApiPreset apiPreset,
    required PromptConfig promptConfig,
    required ContactRole role,
    required ContactMe me,
    required Function(String content, MomentsUser user) onAddMoment,
    Function(String error)? onError,
    bool enableExtendedChat = true,
    int delayedReplySeconds = 0,
    List<String> roleMemories = const [], // 角色记忆列表
    Function(String content, String? categoryStr)? onAddMemory, // 添加记忆的回调（带分类）
  }) async {
    // 取消该会话之前的延迟任务（防抖）
    _debounceTimers[chatId]?.cancel();
    _debounceTimers.remove(chatId);

    // 定义实际执行的任务
    Future<void> performGeneration() async {
      try {
        _typingStates[chatId] = true;
        notifyListeners();

        final chat = getChat(chatId);
        if (chat == null) {
          _typingStates[chatId] = false;
          notifyListeners();
          return;
        }

        // 获取世界书和预设内容
        final worldInfos = <String>[];
        if (chat.worldInfoIds.isNotEmpty) {
          // 使用 _database 实例直接查询，避免 Provider 问题
          final allWorldInfos = await _database.getAllWorldInfos();
          for (final id in chat.worldInfoIds) {
            try {
              final info = allWorldInfos.firstWhere((e) => e.id == id);
              if (info.content.isNotEmpty) {
                worldInfos.add(info.content);
              }
            } catch (e) {
              // 忽略找不到的世界书
            }
          }
        }

        final textPresets = <String>[];
        if (chat.textPresetIds.isNotEmpty) {
          // 使用 _database 实例直接查询，避免 Provider 问题
          final allTextPresets = await _database.getAllTextPresets();
          for (final id in chat.textPresetIds) {
            try {
              final preset = allTextPresets.firstWhere((e) => e.id == id);
              if (preset.content.isNotEmpty) {
                textPresets.add(preset.content);
              }
            } catch (e) {
              // 忽略找不到的预设
            }
          }
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final aiMessages = await LlmService.generateResponse(
          apiPreset: apiPreset,
          promptConfig: promptConfig,
          history: chat.messages,
          role: role,
          me: me,
          messageIdPrefix: 'ai-$timestamp',
          worldInfos: worldInfos,
          textPresets: textPresets,
          roleMemories: roleMemories, // 传入角色记忆
        );

        _typingStates[chatId] = false;
        notifyListeners();

        if (aiMessages.isNotEmpty) {
          // 更新当前状态
          try {
            final stateMessage = aiMessages.lastWhere(
              (msg) => msg.type == MessageType.state,
            );
            _currentStates[chatId] = stateMessage.content;
            // 持久化状态
            await _database.updateSessionState(chatId, stateMessage.content);
            // notifyListeners(); // 下面的 addMessage 会触发 notify
          } catch (e) {
            // 没有找到state消息，不更新状态
          }

          // 过滤消息
          final filteredMessages = aiMessages.where((msg) {
            if (msg.type == MessageType.state) return false;
            if (!enableExtendedChat) {
              return msg.type != MessageType.action &&
                  msg.type != MessageType.thought;
            }
            return true;
          }).toList();

          if (filteredMessages.isNotEmpty) {
            for (final message in filteredMessages) {
              // 计算延迟时间
              final textLength = message.content.length;
              final delayMs = _calculateTypingDelay(textLength);

              _typingStates[chatId] = true;
              notifyListeners();

              await Future.delayed(Duration(milliseconds: delayMs));

              // 处理 AI 回复中的引用
              Map<String, dynamic>? metadata = message.metadata;
              if (metadata != null && metadata.containsKey('reply_id')) {
                final replyId = metadata['reply_id'] as String;
                debugPrint('[ChatProvider] 处理引用，reply_id: $replyId');
                debugPrint(
                    '[ChatProvider] 当前消息列表ID: ${chat.messages.map((m) => m.id).toList()}');
                // 查找被引用的消息
                try {
                  final replyMsg =
                      chat.messages.firstWhere((m) => m.id == replyId);
                  debugPrint(
                      '[ChatProvider] ✓ 找到被引用消息: ${replyMsg.content.substring(0, replyMsg.content.length > 30 ? 30 : replyMsg.content.length)}');

                  // 获取被引用消息的发送者名字
                  String senderName = '未知用户';
                  if (replyMsg.isMe) {
                    senderName = me.name;
                  } else {
                    senderName = role.name;
                  }

                  // 构建 quote 元数据
                  final quoteMetadata = {
                    'id': replyMsg.id,
                    'content': replyMsg.content,
                    'sender': senderName,
                    'isMe': replyMsg.isMe, // 保存被引用消息的发送者身份
                  };

                  // 合并 metadata
                  metadata = Map<String, dynamic>.from(metadata!);
                  metadata['quote'] = quoteMetadata;
                  metadata.remove('reply_id'); // 移除临时的 reply_id
                  debugPrint('[ChatProvider] ✓ 构建quote元数据成功');
                } catch (e) {
                  // 找不到引用消息，忽略引用
                  debugPrint('[ChatProvider] ❌ 找不到被引用消息: $replyId, 错误: $e');
                  metadata = Map<String, dynamic>.from(metadata!);
                  metadata.remove('reply_id');
                }
              }

              // 添加消息
              await addMessage(
                chatId,
                message.content,
                message.type,
                message.isMe,
                metadata: metadata,
                sender: role.name, // AI 消息使用角色名
              );

              // 发送通知 (仅 words 类型)
              if (message.type == MessageType.words) {
                try {
                  await NotificationService().showAiReplyNotification(
                    title: role.name,
                    message: message.content,
                    id: DateTime.now().millisecondsSinceEpoch % 100000,
                  );
                } catch (e) {
                  debugPrint('发送通知失败: $e');
                }
              }

              _typingStates[chatId] = false;
              notifyListeners();
            }
          }

          // 处理朋友圈消息
          final momentMessages = aiMessages
              .where((msg) => msg.type == MessageType.moment)
              .toList();

          if (momentMessages.isNotEmpty) {
            for (final momentMsg in momentMessages) {
              final momentUser = MomentsUser(
                id: role.id,
                name: role.name,
                avatarUrl: role.avatarPath ?? '',
              );
              onAddMoment(momentMsg.content, momentUser);
            }
          }

          // 处理记忆消息 - 自动添加到记忆库
          final memoryMessages = aiMessages
              .where((msg) => msg.type == MessageType.memory)
              .toList();

          if (memoryMessages.isNotEmpty && onAddMemory != null) {
            for (final memoryMsg in memoryMessages) {
              // 从 metadata 中获取 AI 指定的分类
              final categoryStr = memoryMsg.metadata?['category'] as String?;
              debugPrint(
                  '[ChatProvider] 检测到记忆消息: ${memoryMsg.content}, 分类: $categoryStr');
              onAddMemory(memoryMsg.content, categoryStr);
            }
          }
        }
      } catch (e) {
        debugPrint('生成回复失败: $e');
        _typingStates[chatId] = false;
        notifyListeners();
        if (e is LlmRetryException) {
          onError?.call(e.toString());
        }
      }
    }

    // 延迟回复逻辑
    if (delayedReplySeconds > 0) {
      _debounceTimers[chatId] = Timer(
        Duration(seconds: delayedReplySeconds),
        () async {
          _debounceTimers.remove(chatId);
          await performGeneration();
        },
      );
    } else {
      await performGeneration();
    }
  }

  int _calculateTypingDelay(int textLength) {
    if (textLength <= 10) {
      return textLength * 100;
    } else if (textLength <= 50) {
      return textLength * 150;
    } else {
      return textLength * 200;
    }
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '$timestamp-$random';
  }
}
