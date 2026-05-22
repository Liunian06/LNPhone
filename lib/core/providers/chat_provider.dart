import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import '../models/api_preset.dart';
import '../models/contact_model.dart';
import '../models/moments_model.dart';
import '../models/world_info_model.dart';
import '../models/text_preset_model.dart';
import '../models/wallet_model.dart';
import '../providers/prompt_settings_provider.dart';
import '../providers/regex_settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/llm_service.dart';
import '../models/prompt_config.dart';
import '../services/app_log_service.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';
import '../services/background_permission_service.dart';
import '../services/background_reply_scheduler_service.dart';
import '../services/image_generation_service.dart';
import '../database/database.dart' as db;
import '../utils/image_utils.dart';
import '../utils/storage_utils.dart';

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
  final Map<String, int> _chatOffsets = {}; // 记录每个会话已加载的消息偏移量
  bool _isLoadingMore = false;

  List<ChatSession> get chats => _chats;
  bool get isLoadingMore => _isLoadingMore;
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

    // 2. 执行 Blob 到文件的迁移
    await _database.migrateBlobsToFiles();

    // 3. 从数据库加载数据
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
    final newSessions = await _database.getAllSessions();

    // 优化：保留已经在内存中加载了更多消息的会话状态
    for (int i = 0; i < newSessions.length; i++) {
      final newSession = newSessions[i];
      final existingIndex = _chats.indexWhere((c) => c.id == newSession.id);

      if (existingIndex != -1) {
        final existingSession = _chats[existingIndex];
        // 优化：合并消息列表。保留内存中已加载的旧消息，同时加入数据库中可能存在的新消息
        final Map<String, ChatMessage> mergedMessages = {};
        for (var m in existingSession.messages) {
          mergedMessages[m.id] = m;
        }
        for (var m in newSession.messages) {
          mergedMessages[m.id] = m;
        }

        final sortedMessages = mergedMessages.values.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        newSessions[i] = ChatSession(
          id: newSession.id,
          roleId: newSession.roleId,
          meId: newSession.meId,
          messages: sortedMessages,
          lastUpdated: newSession.lastUpdated,
          enableExtendedChat: newSession.enableExtendedChat,
          enableTextToImage: newSession.enableTextToImage,
          enableEmoji: newSession.enableEmoji,
          enableIndependentSendButton: newSession.enableIndependentSendButton,
          currentState: newSession.currentState,
          isPinned: newSession.isPinned,
          worldInfoIds: newSession.worldInfoIds,
          textPresetIds: newSession.textPresetIds,
          apiPresetId: newSession.apiPresetId,
          imageApiPresetId: newSession.imageApiPresetId,
          backgroundImage: newSession.backgroundImage,
          backgroundImageData: newSession.backgroundImageData,
          unreadCountOverride: newSession.unreadCountOverride,
          enableBackgroundReply: newSession.enableBackgroundReply,
          backgroundReplyIntervalMinutes:
              newSession.backgroundReplyIntervalMinutes,
          backgroundReplyStatus: newSession.backgroundReplyStatus,
          backgroundReplyLastError: newSession.backgroundReplyLastError,
          backgroundReplyDisabledByFailure:
              newSession.backgroundReplyDisabledByFailure,
        );
      }
    }

    _chats = newSessions;

    // 恢复状态
    for (final chat in _chats) {
      if (chat.currentState != null) {
        _currentStates[chat.id] = chat.currentState!;
      }
      // 更新偏移量
      _chatOffsets[chat.id] = chat.messages.length;
    }
    notifyListeners();
  }

  /// 加载更多消息
  Future<void> loadMoreMessages(String chatId) async {
    if (_isLoadingMore) return;

    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex == -1) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final currentOffset = _chatOffsets[chatId] ?? 0;
      final moreMessages = await _database.getMessagesPaged(
        chatId,
        limit: 30,
        offset: currentOffset,
      );

      if (moreMessages.isNotEmpty) {
        final chat = _chats[chatIndex];
        // 将新加载的消息插入到列表前面（因为是向上滚动加载更旧的消息）
        final updatedMessages = [...moreMessages, ...chat.messages];

        _chats[chatIndex] = ChatSession(
          id: chat.id,
          roleId: chat.roleId,
          meId: chat.meId,
          messages: updatedMessages,
          lastUpdated: chat.lastUpdated,
          enableExtendedChat: chat.enableExtendedChat,
          enableTextToImage: chat.enableTextToImage,
          enableEmoji: chat.enableEmoji,
          enableIndependentSendButton: chat.enableIndependentSendButton,
          currentState: chat.currentState,
          isPinned: chat.isPinned,
          worldInfoIds: chat.worldInfoIds,
          textPresetIds: chat.textPresetIds,
          apiPresetId: chat.apiPresetId,
          imageApiPresetId: chat.imageApiPresetId,
          backgroundImage: chat.backgroundImage,
          backgroundImageData: chat.backgroundImageData,
          unreadCountOverride: chat.unreadCountOverride,
          enableBackgroundReply: chat.enableBackgroundReply,
          backgroundReplyIntervalMinutes: chat.backgroundReplyIntervalMinutes,
          backgroundReplyStatus: chat.backgroundReplyStatus,
          backgroundReplyLastError: chat.backgroundReplyLastError,
          backgroundReplyDisabledByFailure:
              chat.backgroundReplyDisabledByFailure,
        );

        _chatOffsets[chatId] = currentOffset + moreMessages.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatProvider] 加载更多消息失败: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 进入聊天详情时，确保加载了初始消息
  Future<void> enterChat(String chatId) async {
    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex == -1) return;

    // 如果当前消息数少于 30 条，尝试加载更多以填满初始屏幕
    if (_chats[chatIndex].messages.length < 30) {
      final fullChat = await _database.getChatSession(chatId, limit: 30);
      if (fullChat != null) {
        _chats[chatIndex] = fullChat;
        _chatOffsets[chatId] = fullChat.messages.length;
        notifyListeners();
      }
    }
  }

  Future<void> refreshWorldInfos() async {
    _worldInfos = await _database.getAllWorldInfos();
    notifyListeners();
  }

  Future<void> refreshTextPresets() async {
    _textPresets = await _database.getAllTextPresets();
    // 检查是否需要初始化内置生图预设
    await _initializeBuiltInImagePresets();
    notifyListeners();
  }

  /// 初始化内置生图预设
  Future<void> _initializeBuiltInImagePresets() async {
    final hasBuiltIn = _textPresets.any((p) => p.isBuiltIn);
    if (hasBuiltIn) return;

    debugPrint('[ChatProvider] 初始化内置生图预设...');
    final now = StorageUtils.getUniqueTimestamp();
    final builtInPresets = [
      TextPreset(
        id: 't2i_realistic',
        name: '极致摄影写实',
        content: 'assets/prompts/text2image_prompt.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      TextPreset(
        id: 't2i_anime',
        name: '二次元动漫',
        content: 'assets/prompts/t2i_anime.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      TextPreset(
        id: 't2i_cyberpunk',
        name: '赛博朋克',
        content: 'assets/prompts/t2i_cyberpunk.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      TextPreset(
        id: 't2i_oil_painting',
        name: '油画风格',
        content: 'assets/prompts/t2i_oil_painting.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      TextPreset(
        id: 't2i_ink_painting',
        name: '水墨画风格',
        content: 'assets/prompts/t2i_ink_painting.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      TextPreset(
        id: 't2i_webtoon',
        name: '韩漫风格',
        content: 'assets/prompts/t2i_webtoon.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      TextPreset(
        id: 't2i_beautiful_lighting',
        name: '唯美光影',
        content: 'assets/prompts/t2i_beautiful_lighting.txt',
        type: TextPresetType.image,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final preset in builtInPresets) {
      await _database.insertTextPreset(preset);
    }

    // 迁移旧的自定义生图预设
    final prefs = await SharedPreferences.getInstance();
    final customPrompt = await _database.getSetting('custom_text2image_prompt');
    if (customPrompt != null && customPrompt.isNotEmpty) {
      final customPreset = TextPreset(
        id: 't2i_custom_1',
        name: '自定义生图预设 1',
        content: customPrompt,
        type: TextPresetType.image,
        isBuiltIn: false,
        createdAt: now,
        updatedAt: now,
      );
      await _database.insertTextPreset(customPreset);
      // 清除旧设置以防重复迁移
      await _database.deleteSetting('custom_text2image_prompt');
      debugPrint('[ChatProvider] 已迁移旧的自定义生图预设');
    }

    _textPresets = await _database.getAllTextPresets();
  }

  Future<void> addWorldInfo(WorldInfo info) async {
    await _database.insertWorldInfo(info);
    await refreshWorldInfos();
  }

  Future<void> deleteWorldInfo(String id) async {
    await _database.deleteWorldInfo(id);
    await refreshWorldInfos();
  }

  Future<void> deleteWorldInfos(List<String> ids) async {
    await _database.deleteWorldInfos(ids);
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

  Future<void> deleteTextPresets(List<String> ids) async {
    await _database.deleteTextPresets(ids);
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
      final newTime = StorageUtils.getUniqueTimestamp();

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
    final timestamp = StorageUtils.getUniqueTimestamp();

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
    Uint8List? messageData,
  }) async {
    String finalContent = content;

    // 优化：如果是图片消息，优先保存为文件，不再存储 Blob
    if (type == MessageType.image && content.isNotEmpty) {
      final msgId = _generateId();
      final result = await _saveImageWithData(content, 'msg_$msgId');
      if (result != null) {
        // 存储相对路径
        finalContent = await StorageUtils.toRelativePath(result.path);
      }
    }

    final newMessage = db.ChatMessagesCompanion(
      id: drift.Value(_generateId()),
      sessionId: drift.Value(chatId),
      content: drift.Value(finalContent),
      messageData: const drift.Value(null), // 强制不存 Blob
      isMe: drift.Value(isMe),
      sender: drift.Value(sender),
      type: drift.Value(type),
      timestamp: drift.Value(StorageUtils.getUniqueTimestamp()),
      metadata: drift.Value(metadata),
      isRead: drift.Value(isMe), // 自己发的消息默认已读，对方发的默认未读
    );

    await _database.insertMessage(newMessage);
    await _refreshChats();

    if (isMe) {
      await BackgroundService.updateLastActiveTime();
      final nextWakeup =
          await BackgroundReplySchedulerService.recordForegroundUserActivity(
        triggerSource: 'user_message',
      );
      try {
        if (nextWakeup != null) {
          await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
        } else {
          await BackgroundPermissionService.cancelNextWakeup();
        }
      } catch (_) {}
      FlutterBackgroundService().invoke(
        'run_due_tasks',
        {'triggerSource': 'user_message'},
      );
    } else {
      final nextWakeup =
          await BackgroundReplySchedulerService.syncAllTasksFromStoredPermissions(
        triggerSource: 'message_added',
      );
      try {
        if (nextWakeup != null) {
          await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
        } else {
          await BackgroundPermissionService.cancelNextWakeup();
        }
      } catch (_) {}
      FlutterBackgroundService().invoke(
        'run_due_tasks',
        {'triggerSource': 'message_added'},
      );
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
            messageData: drift.Value(m.messageData),
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
    final nextWakeup =
        await BackgroundReplySchedulerService.syncAllTasksFromStoredPermissions(
      triggerSource: 'delete_chat',
    );
    try {
      if (nextWakeup != null) {
        await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
      } else {
        await BackgroundPermissionService.cancelNextWakeup();
      }
    } catch (_) {}
    FlutterBackgroundService().invoke(
      'run_due_tasks',
      {'triggerSource': 'delete_chat'},
    );
  }

  /// 清空聊天记录
  Future<void> clearChatMessages(String chatId) async {
    await _database.clearSessionMessages(chatId);
    await _refreshChats();
    final nextWakeup =
        await BackgroundReplySchedulerService.syncAllTasksFromStoredPermissions(
      triggerSource: 'clear_chat_messages',
    );
    try {
      if (nextWakeup != null) {
        await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
      } else {
        await BackgroundPermissionService.cancelNextWakeup();
      }
    } catch (_) {}
    FlutterBackgroundService().invoke(
      'run_due_tasks',
      {'triggerSource': 'clear_chat_messages'},
    );
  }

  /// 更新消息内容
  Future<void> updateMessage(String messageId, String newContent) async {
    await _database.updateMessageContent(messageId, newContent);
    // 同步更新内存中的消息，防止被旧缓存覆盖
    for (var chat in _chats) {
      final idx = chat.messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final m = chat.messages[idx];
        chat.messages[idx] = ChatMessage(
          id: m.id,
          isMe: m.isMe,
          sender: m.sender,
          type: m.type,
          content: newContent,
          messageData: m.messageData,
          timestamp: m.timestamp,
          metadata: m.metadata,
          isRead: m.isRead,
        );
        break;
      }
    }
    await _refreshChats();
  }

  /// 更新消息元数据
  Future<void> updateMessageMetadata(
      String messageId, Map<String, dynamic> newMetadata) async {
    await _database.updateMessageMetadata(messageId, newMetadata);
    // 同步更新内存
    for (var chat in _chats) {
      final idx = chat.messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final m = chat.messages[idx];
        chat.messages[idx] = ChatMessage(
          id: m.id,
          isMe: m.isMe,
          sender: m.sender,
          type: m.type,
          content: m.content,
          messageData: m.messageData,
          timestamp: m.timestamp,
          metadata: newMetadata,
          isRead: m.isRead,
        );
        break;
      }
    }
    await _refreshChats();
  }

  /// 删除单条消息
  Future<void> deleteMessage(String messageId) async {
    await _database.deleteMessage(messageId);
    // 同步从内存移除，防止刷新时被合并回来
    for (var chat in _chats) {
      chat.messages.removeWhere((m) => m.id == messageId);
    }
    await _refreshChats();
  }

  /// 批量删除消息
  Future<void> deleteMessages(List<String> messageIds) async {
    await _database.deleteMessages(messageIds);
    // 同步从内存移除
    for (var chat in _chats) {
      chat.messages.removeWhere((m) => messageIds.contains(m.id));
    }
    await _refreshChats();
  }

  /// 回溯：删除指定时间之后的消息
  Future<void> backtrack(String sessionId, int timestamp) async {
    await _database.deleteMessagesAfter(sessionId, timestamp);
    // 同步清理内存中的消息，确保回溯后界面立即更新且不会被合并逻辑恢复
    final chatIndex = _chats.indexWhere((c) => c.id == sessionId);
    if (chatIndex != -1) {
      _chats[chatIndex].messages.removeWhere((m) => m.timestamp > timestamp);
    }
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
    bool? enableTextToImage,
    bool? enableEmoji,
    bool? enableIndependentSendButton,
  }) async {
    await _database.updateSessionSettings(
      chatId,
      enableExtendedChat: enableExtendedChat,
      enableTextToImage: enableTextToImage,
      enableEmoji: enableEmoji,
      enableIndependentSendButton: enableIndependentSendButton,
    );
    await _refreshChats();
  }

  Future<void> updateChatBackgroundReplySettings(
    String chatId, {
    bool? enableBackgroundReply,
    int? backgroundReplyIntervalMinutes,
    bool clearFailure = false,
  }) async {
    await AppLogService.log(
      '修改角色后台主动回复设置',
      category: 'Scheduler',
      data: {
        'chatId': chatId,
        'enableBackgroundReply': enableBackgroundReply,
        'backgroundReplyIntervalMinutes': backgroundReplyIntervalMinutes,
        'clearFailure': clearFailure,
      },
    );
    if (clearFailure) {
      await _database.clearSessionBackgroundReplyFailure(chatId);
    }

    await _database.updateSessionBackgroundReplySettings(
      chatId,
      enableBackgroundReply: enableBackgroundReply,
      backgroundReplyIntervalMinutes: backgroundReplyIntervalMinutes,
    );

    await _refreshChats();

    final snapshot = await BackgroundPermissionService.getPersistedSnapshot();
    final nextWakeup = await BackgroundReplySchedulerService.syncAllTasks(
      permissionSnapshot: snapshot,
      triggerSource: 'chat_background_reply_settings',
    );
    if (nextWakeup != null) {
      try {
        await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
      } catch (_) {}
    } else {
      try {
        await BackgroundPermissionService.cancelNextWakeup();
      } catch (_) {}
    }
    FlutterBackgroundService().invoke(
      'run_due_tasks',
      {'triggerSource': 'chat_background_reply_settings'},
    );
  }

  /// 更新聊天的配置（世界书、预设、API预设）
  Future<void> updateChatConfig(
    String chatId, {
    List<String>? worldInfoIds,
    List<String>? textPresetIds,
    String? apiPresetId,
    String? imageApiPresetId,
  }) async {
    await _database.updateSessionConfig(
      chatId,
      worldInfoIds: worldInfoIds,
      textPresetIds: textPresetIds,
      apiPresetId: apiPresetId,
      imageApiPresetId: imageApiPresetId,
    );
    await _refreshChats();
  }

  /// 更新聊天的背景图
  Future<void> updateChatBackgroundImage(
      String chatId, String? imagePath) async {
    final result = await _saveImageWithData(imagePath, 'chat_bg_$chatId');
    await _database.updateSessionBackgroundImage(
      chatId,
      result?.path ?? imagePath,
      result?.data,
    );
    await _refreshChats();
  }

  /// 将图片保存到应用文档目录，并返回路径和二进制数据
  Future<({String path, Uint8List data})?> _saveImageWithData(
      String? sourcePath, String id) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    if (sourcePath.startsWith('http')) return null;

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final bytes = await sourceFile.readAsBytes();
      final appDir = await getApplicationDocumentsDirectory();
      String finalPath = sourcePath;

      if (!sourcePath.startsWith(appDir.path)) {
        final timestamp = _generateId();
        final mimeType =
            ImageUtils.detectMimeTypeFromBytes(bytes, pathHint: sourcePath);
        final extension = ImageUtils.extensionForMimeType(mimeType);
        final fileName = 'chat_image_${id}_$timestamp$extension';
        final savedImage = await sourceFile.copy('${appDir.path}/$fileName');
        finalPath = savedImage.path;
        debugPrint('[ChatProvider] 图片已从临时路径复制到持久化目录: $finalPath');
      }

      return (path: finalPath, data: bytes);
    } catch (e) {
      debugPrint('[ChatProvider] 处理图片失败: $e');
      return null;
    }
  }

  /// 生成 AI 回复
  Future<void> generateAiResponse({
    required String chatId,
    required ApiPreset apiPreset,
    required PromptConfig promptConfig,
    required ContactRole role,
    required ContactMe me,
    required Function(String content, MomentsUser user) onAddMoment,
    Function()? onMomentsChanged, // 朋友圈数据变化的回调
    Function(String error)? onError,
    bool enableExtendedChat = true,
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId, // 传入独立生图 API 预设 ID
    String? imageStylePresetId, // 传入独立生图风格预设 ID
    int delayedReplySeconds = 0,
    List<String> roleMemories = const [], // 角色记忆列表
    Function(String content, String? categoryStr)? onAddMemory, // 添加记忆的回调（带分类）
    RegexSettingsProvider? regexProvider, // 正则设置提供者
    List<String> availableEmojis = const [], // 可用表情列表
    WalletProvider? walletProvider, // 钱包提供者，用于处理退款
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

        // 1. 获取朋友圈动态并转换为虚拟消息
        final allMoments = await _database.getAllMoments();
        final List<ChatMessage> virtualMessages = [];

        for (var post in allMoments) {
          // 朋友圈动态本身
          virtualMessages.add(ChatMessage(
            id: 'v-post-${post.id}',
            isMe: post.user.id == me.id,
            sender: post.user.name,
            type: MessageType.moment,
            content: post.content ?? '',
            timestamp: post.createdAt.millisecondsSinceEpoch,
            metadata: {
              'mediaItems': post.mediaItems.map((e) => e.toJson()).toList(),
              'location': post.location,
            },
          ));

          // 评论
          for (var comment in post.comments) {
            final metadata = <String, dynamic>{
              'post_id': post.id,
            };
            // reply_to 存储评论ID（如果是回复评论），而不是用户名
            if (comment.replyTo != null) {
              // 查找被回复的评论ID
              final replyToComment = post.comments.firstWhere(
                (c) => c.user.id == comment.replyTo!.id,
                orElse: () => comment, // 如果找不到，使用当前评论（不应该发生）
              );
              metadata['reply_to'] = replyToComment.id;
            }

            virtualMessages.add(ChatMessage(
              id: 'v-comment-${comment.id}',
              isMe: comment.user.id == me.id,
              sender: comment.user.name,
              type: MessageType.momentComment,
              content: comment.content,
              timestamp: comment.createdAt.millisecondsSinceEpoch,
              metadata: metadata,
            ));
          }

          // 点赞
          for (var like in post.likes) {
            virtualMessages.add(ChatMessage(
              id: 'v-like-${post.id}-${like.user.id}-${like.createdAt.millisecondsSinceEpoch}',
              isMe: like.user.id == me.id,
              sender: like.user.name,
              type: MessageType.momentLike,
              content: like.isCancelled ? '取消了点赞' : '点赞了这条朋友圈',
              timestamp: like.createdAt.millisecondsSinceEpoch,
              metadata: {
                'post_id': post.id,
                'is_cancelled': like.isCancelled,
              },
            ));
          }
        }

        // 2. 合并并排序所有消息
        final combinedHistory = [...chat.messages, ...virtualMessages];
        combinedHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
              // 仅聊天预设会被注入到 LLM 上下文中
              if (preset.type == TextPresetType.chat &&
                  preset.content.isNotEmpty) {
                textPresets.add(preset.content);
              }
            } catch (e) {
              // 忽略找不到的预设
            }
          }
        }

        final timestamp = StorageUtils.getUniqueTimestamp();

        // 重新从数据库获取最新的角色和用户信息，确保包含最新的参考图
        final currentRole = (await _database.getContactRole(role.id)) ?? role;
        final currentMe = (await _database.getContactMe(me.id)) ?? me;

        // 关键修复：在调用 LLM 生成回复之前，必须先设置 ImageGenerationService 的上下文
        // 否则在解析 LLM 响应并触发图片生成时，ImageGenerationService 拿不到最新的参考图数据
        ImageGenerationService().setCurrentContext(currentRole, currentMe);

        final aiMessages = await LlmService.generateResponse(
          apiPreset: apiPreset,
          promptConfig: promptConfig,
          history: combinedHistory,
          role: currentRole,
          me: currentMe,
          messageIdPrefix: 'ai-$timestamp',
          worldInfos: worldInfos,
          textPresets: textPresets,
          roleMemories: roleMemories, // 传入角色记忆
          availableEmojis: availableEmojis, // 传入可用表情
          enableTextToImage: enableTextToImage,
          enableEmoji: enableEmoji,
          imageApiPresetId: imageApiPresetId, // 传入独立生图 API 预设 ID
          imageStylePresetId: imageStylePresetId, // 传入独立生图风格预设 ID
          regexProvider: regexProvider, // 传入正则提供者
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

          // 处理红包/转账响应消息（这些消息不会显示在聊天中，只更新原消息状态）
          final redpacketTransferResponses = aiMessages.where((msg) =>
              msg.type == MessageType.acceptRedpacket ||
              msg.type == MessageType.rejectRedpacket ||
              msg.type == MessageType.acceptTransfer ||
              msg.type == MessageType.rejectTransfer);

          for (final responseMsg in redpacketTransferResponses) {
            final targetId = responseMsg.metadata?['target_id'] as String?;
            if (targetId != null && targetId.isNotEmpty) {
              // 查找目标消息
              final targetMsgIndex =
                  chat.messages.indexWhere((m) => m.id == targetId);
              if (targetMsgIndex != -1) {
                final targetMsg = chat.messages[targetMsgIndex];

                // 根据响应类型更新目标消息状态
                String newStatus;
                bool shouldRefund = false; // 是否需要退款

                // 智能判断：如果 AI 使用了通用的 accept/reject (被解析为 acceptRedpacket/rejectRedpacket)
                // 但目标消息是转账，则自动修正状态
                if (responseMsg.type == MessageType.acceptRedpacket) {
                  if (targetMsg.type == MessageType.transfer) {
                    newStatus = 'accepted'; // 转账被接受
                  } else {
                    newStatus = 'opened'; // 红包被领取
                  }
                } else if (responseMsg.type == MessageType.rejectRedpacket) {
                  if (targetMsg.type == MessageType.transfer) {
                    newStatus = 'rejected'; // 转账被拒绝
                    shouldRefund = true; // 转账被拒绝需要退款
                  } else {
                    newStatus = 'refunded'; // 红包被退回
                    shouldRefund = true; // 红包被退回需要退款
                  }
                } else if (responseMsg.type == MessageType.acceptTransfer) {
                  newStatus = 'accepted';
                } else if (responseMsg.type == MessageType.rejectTransfer) {
                  newStatus = 'rejected';
                  shouldRefund = true; // 转账被拒绝需要退款
                } else {
                  continue;
                }

                // 更新原消息的 metadata
                final newMetadata =
                    Map<String, dynamic>.from(targetMsg.metadata ?? {});
                newMetadata['status'] = newStatus;
                await _database.updateMessageMetadata(targetId, newMetadata);

                debugPrint('[ChatProvider] 更新红包/转账状态: $targetId -> $newStatus');

                // 如果需要退款，将金额返还给用户钱包
                if (shouldRefund && targetMsg.isMe && walletProvider != null) {
                  final amount = double.tryParse(targetMsg.content) ?? 0.0;
                  if (amount > 0) {
                    final transactionType =
                        targetMsg.type == MessageType.redpacket
                            ? WalletTransactionType.redpacket
                            : WalletTransactionType.transfer;

                    await walletProvider.addIncome(
                      type: transactionType,
                      amount: amount,
                      description: targetMsg.type == MessageType.redpacket
                          ? '红包退还'
                          : '转账退还',
                      relatedContactName: role.name,
                      relatedSessionId: chatId,
                      relatedMessageId: targetId,
                    );

                    debugPrint('[ChatProvider] ✓ 已退款: ¥$amount 到用户钱包');
                  }
                }
              } else {
                debugPrint('[ChatProvider] ❌ 找不到目标消息: $targetId');
              }
            }
          }

          // 刷新聊天数据以获取最新状态
          await _refreshChats();

          // 记录原始消息类型
          debugPrint('[ChatProvider] ====== AI 消息分析 ======');
          debugPrint('[ChatProvider] aiMessages 总数: ${aiMessages.length}');
          for (var msg in aiMessages) {
            debugPrint('[ChatProvider] - 消息类型: ${msg.type.name}, 内容长度: ${msg.content.length}');
          }
          await AppLogService.log(
            'AI 消息列表',
            category: 'ChatProvider',
            level: LogLevel.info,
            data: {
              'step': 'ai_messages_received',
              'totalCount': aiMessages.length,
              'messageTypes': aiMessages.map((m) => m.type.name).toList(),
            },
          );

          // 过滤消息（排除红包/转账响应消息，它们只用于更新状态）
          final filteredMessages = aiMessages.where((msg) {
            if (msg.type == MessageType.state) return false;
            // 过滤掉红包/转账响应消息以及朋友圈互动消息
            if (msg.type == MessageType.acceptRedpacket ||
                msg.type == MessageType.rejectRedpacket ||
                msg.type == MessageType.acceptTransfer ||
                msg.type == MessageType.rejectTransfer ||
                msg.type == MessageType.moment ||
                msg.type == MessageType.momentComment ||
                msg.type == MessageType.momentLike) {
              return false;
            }
            if (!enableExtendedChat) {
              return msg.type != MessageType.action &&
                  msg.type != MessageType.thought;
            }
            return true;
          }).toList();

          debugPrint('[ChatProvider] filteredMessages 数量: ${filteredMessages.length}');
          for (var msg in filteredMessages) {
            debugPrint('[ChatProvider] - 过滤后消息类型: ${msg.type.name}');
          }
          await AppLogService.log(
            '过滤后的消息列表',
            category: 'ChatProvider',
            level: LogLevel.info,
            data: {
              'step': 'filtered_messages',
              'filteredCount': filteredMessages.length,
              'messageTypes': filteredMessages.map((m) => m.type.name).toList(),
            },
          );

          if (filteredMessages.isNotEmpty) {
            for (final message in filteredMessages) {
              // 计算延迟时间
              // 如果是图片消息，不计算延迟，直接发送
              int delayMs = 0;
              if (message.type != MessageType.image) {
                final textLength = message.content.length;
                delayMs = _calculateTypingDelay(textLength);
              }

              _typingStates[chatId] = true;
              notifyListeners();

              if (delayMs > 0) {
                await Future.delayed(Duration(milliseconds: delayMs));
              }

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

              // 发送通知（使用 currentRole 获取最新的头像数据）
              // 先记录日志，确认是否进入通知逻辑
              debugPrint('[ChatProvider] ====== 开始通知流程 ======');
              debugPrint('[ChatProvider] 消息类型: ${message.type}');
              debugPrint('[ChatProvider] 角色名称: ${currentRole.name}');
              debugPrint('[ChatProvider] 角色头像路径: ${currentRole.avatarPath}');
              debugPrint('[ChatProvider] 角色头像数据: ${currentRole.avatarData?.length ?? 0} bytes');

              await AppLogService.log(
                '准备发送前台通知',
                category: 'ChatProvider',
                level: LogLevel.info,
                data: {
                  'step': 'before_notification',
                  'messageType': message.type.name,
                  'roleName': currentRole.name,
                  'avatarPath': currentRole.avatarPath ?? 'null',
                  'avatarDataLength': currentRole.avatarData?.length ?? 0,
                  'chatId': chatId,
                },
              );

              final notificationBody =
                  _buildAiNotificationBody(message.type, message.content);

              debugPrint('[ChatProvider] notificationBody 结果: ${notificationBody ?? "null"}');

              await AppLogService.log(
                'notificationBody 结果',
                category: 'ChatProvider',
                level: LogLevel.info,
                data: {
                  'step': 'notification_body_check',
                  'notificationBody': notificationBody ?? 'null',
                  'messageType': message.type.name,
                },
              );

              if (notificationBody != null) {
                try {
                  final notificationId = _nextNotificationId();

                  await AppLogService.log(
                    '调用 NotificationService.showAiReplyNotification',
                    category: 'ChatProvider',
                    level: LogLevel.info,
                    data: {
                      'step': 'call_notification_service',
                      'notificationId': notificationId,
                      'title': currentRole.name,
                    },
                  );

                  await NotificationService().showAiReplyNotification(
                    title: currentRole.name,
                    message: notificationBody,
                    id: notificationId,
                    avatarPath: currentRole.avatarPath,
                    avatarData: currentRole.avatarData,
                  );
                  debugPrint('[ChatProvider] ✓ 通知服务调用完成');
                  await AppLogService.log(
                    '前台 AI 消息已发送通知',
                    category: 'Notification',
                    level: LogLevel.info,
                    data: {
                      'chatId': chatId,
                      'notificationId': notificationId,
                      'messageType': message.type.name,
                      'success': true,
                    },
                  );
                } catch (e, stackTrace) {
                  debugPrint('[ChatProvider] ❌ 发送通知失败: $e');
                  debugPrint('[ChatProvider] 堆栈: $stackTrace');
                  await AppLogService.error(
                    '前台 AI 消息发送通知失败',
                    category: 'Notification',
                    data: {
                      'chatId': chatId,
                      'error': e.toString(),
                      'stackTrace': stackTrace.toString(),
                    },
                  );
                }
              } else {
                debugPrint('[ChatProvider] notificationBody 为 null，不发送通知');
                await AppLogService.warning(
                  'notificationBody 为 null，跳过通知',
                  category: 'ChatProvider',
                  data: {
                    'step': 'skip_notification',
                    'messageType': message.type.name,
                  },
                );
              }

              _typingStates[chatId] = false;
              notifyListeners();
            }
          }

          // 处理朋友圈消息、评论和点赞
          for (final msg in aiMessages) {
            if (msg.type == MessageType.moment) {
              final momentUser = MomentsUser(
                id: role.id,
                name: role.name,
                avatarUrl: role.avatarPath ?? '',
              );
              onAddMoment(msg.content, momentUser);
            } else if (msg.type == MessageType.momentComment) {
              final targetId = msg.metadata?['target_id'] as String?;
              if (targetId != null) {
                // 查找目标朋友圈或评论
                final moments = await _database.getAllMoments();
                String? postId;
                String? replyToCommentId; // 改为存储评论ID

                for (var post in moments) {
                  if (post.id == targetId || 'v-post-${post.id}' == targetId) {
                    // 直接评论朋友圈动态
                    postId = post.id;
                    break;
                  }
                  for (var comment in post.comments) {
                    if (comment.id == targetId ||
                        'v-comment-${comment.id}' == targetId) {
                      // 回复某条评论
                      postId = post.id;
                      replyToCommentId = comment.id; // 存储评论ID
                      break;
                    }
                  }
                  if (postId != null) break;
                }

                if (postId != null) {
                  final momentUser = MomentsUser(
                    id: role.id,
                    name: role.name,
                    avatarUrl: role.avatarPath ?? '',
                  );
                  final post = await _database.getMoment(postId);
                  if (post != null) {
                    final comments = List<MomentsComment>.from(post.comments);

                    // 根据评论ID查找被回复的用户
                    MomentsUser? replyToUser;
                    if (replyToCommentId != null) {
                      try {
                        final replyToComment = post.comments.firstWhere(
                          (c) => c.id == replyToCommentId,
                        );
                        replyToUser = replyToComment.user;
                      } catch (e) {
                        debugPrint(
                            '[ChatProvider] ⚠️ 找不到被回复的评论: $replyToCommentId');
                      }
                    }

                    comments.add(MomentsComment(
                      id: 'c_ai_${StorageUtils.getUniqueTimestamp()}',
                      user: momentUser,
                      content: msg.content,
                      createdAt: DateTime.now(),
                      replyTo: replyToUser, // 使用查找到的用户信息
                    ));
                    await _database
                        .insertMoment(post.copyWith(comments: comments));
                    debugPrint('[ChatProvider] AI 自动回复了朋友圈评论');
                  }
                }
              }
            } else if (msg.type == MessageType.momentLike) {
              final targetId = msg.metadata?['target_id'] as String?;
              if (targetId != null) {
                final moments = await _database.getAllMoments();
                String? postId;
                for (var post in moments) {
                  if (post.id == targetId || 'v-post-${post.id}' == targetId) {
                    postId = post.id;
                    break;
                  }
                }

                if (postId != null) {
                  final post = await _database.getMoment(postId);
                  if (post != null) {
                    final likes = List<MomentLike>.from(post.likes);
                    final isCancelled = msg.content.toLowerCase() == 'unlike';

                    final existingIndex =
                        likes.indexWhere((l) => l.user.id == role.id);
                    if (existingIndex != -1) {
                      likes[existingIndex] = MomentLike(
                        user: likes[existingIndex].user,
                        createdAt: DateTime.now(),
                        isCancelled: isCancelled,
                      );
                    } else if (!isCancelled) {
                      likes.add(MomentLike(
                        user: MomentsUser(
                          id: role.id,
                          name: role.name,
                          avatarUrl: role.avatarPath ?? '',
                        ),
                        createdAt: DateTime.now(),
                        isCancelled: false,
                      ));
                    }
                    await _database.insertMoment(post.copyWith(likes: likes));
                    debugPrint('[ChatProvider] AI 自动点赞/取消点赞了朋友圈');
                  }
                }
              }
            }
          }

          // 触发朋友圈刷新回调
          if (aiMessages.any((msg) =>
              msg.type == MessageType.moment ||
              msg.type == MessageType.momentComment ||
              msg.type == MessageType.momentLike)) {
            onMomentsChanged?.call();
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

  /// 重新生成图片消息内容
  Future<void> regenerateImageMessage({
    required String chatId,
    required String messageId,
    required String prompt,
    required ApiPreset apiPreset,
    String? stylePresetName,
    String? stylePrompt,
    String? characterAppearance,
    String? userAppearance,
  }) async {
    _typingStates[chatId] = true;
    notifyListeners();

    try {
      // 1. 设置生图上下文（角色和用户信息，用于获取参考图）
      final chat = getChat(chatId);
      if (chat != null) {
        final role = await _database.getContactRole(chat.roleId);
        final me = await _database.getContactMe(chat.meId);
        ImageGenerationService().setCurrentContext(role, me);
      }

      // 2. 调用生图服务重新生成图片
      final result = await ImageGenerationService().generateImage(
        prompt,
        stylePrompt,
        includeCharacter: characterAppearance != null,
        includeUser: userAppearance != null,
        imageApiPresetId: apiPreset.id,
      );

      if (result != null && result['path'] != null) {
        final String newPath = result['path'];
        // 转换为相对路径存储
        final relativePath = await StorageUtils.toRelativePath(newPath);

        // 2. 更新消息内容和元数据
        final chat = getChat(chatId);
        if (chat != null) {
          final msgIndex = chat.messages.indexWhere((m) => m.id == messageId);
          if (msgIndex != -1) {
            final oldMsg = chat.messages[msgIndex];
            final newMetadata =
                Map<String, dynamic>.from(oldMsg.metadata ?? {});

            // 更新元数据中的生图详情
            newMetadata['image_gen_metadata'] = {
              'api_preset_id': apiPreset.id,
              'api_preset_name': result['api_preset_name'] ?? apiPreset.name,
              'style_preset_name':
                  result['style_preset_name'] ?? stylePresetName,
              'style_prompt': result['style_prompt'] ?? stylePrompt,
              'character_appearance':
                  result['character_appearance'] ?? characterAppearance,
              'user_appearance': result['user_appearance'] ?? userAppearance,
              'ref_image_paths': result['ref_image_paths'],
            };

            await updateMessageMetadata(messageId, newMetadata);
            // 关键：更新内存中的消息类型，因为之前可能是 words (失败提示)
            oldMsg.metadata?['image_gen_metadata'] =
                newMetadata['image_gen_metadata'];
            final updatedMsg = ChatMessage(
              id: oldMsg.id,
              isMe: oldMsg.isMe,
              sender: oldMsg.sender,
              type: MessageType.image,
              content: relativePath,
              timestamp: oldMsg.timestamp,
              metadata: newMetadata,
              isRead: oldMsg.isRead,
            );
            chat.messages[msgIndex] = updatedMsg;

            await _database.updateMessageContent(messageId, relativePath);
            await _database.updateMessageType(messageId, MessageType.image);
            await _database.updateMessageMetadata(messageId, newMetadata);

            await _refreshChats();
          }
        }
      } else {
        throw Exception('生图失败，返回结果为空');
      }
    } finally {
      _typingStates[chatId] = false;
      notifyListeners();
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
    return StorageUtils.getUniqueTimestamp().toString();
  }

  String? _buildAiNotificationBody(MessageType type, String content) {
    switch (type) {
      case MessageType.words:
        return content;
      case MessageType.image:
        return '[图片]';
      case MessageType.moment:
        return content.isEmpty ? '[朋友圈动态]' : '[朋友圈] $content';
      case MessageType.action:
        return '*$content*'; // 动作描述
      case MessageType.thought:
        return '(想法) $content'; // 内心想法
      case MessageType.emoji:
        return '[表情]'; // 表情包
      case MessageType.location:
        return '[位置]'; // 位置分享
      case MessageType.redpacket:
        return '[红包]'; // 红包
      case MessageType.transfer:
        return '[转账]'; // 转账
      case MessageType.product:
        return '[商品推荐]'; // 商品
      case MessageType.link:
        return '[链接]'; // 链接
      case MessageType.note:
        return '[备忘提醒]'; // 备忘
      case MessageType.anniversary:
        return '[纪念日]'; // 纪念日
      case MessageType.scene:
        return content.isEmpty ? '[场景]' : content; // 场景描述
      case MessageType.narration:
        return content; // 旁白
      case MessageType.options:
        return '[互动选项]'; // 互动选项
      default:
        return null;
    }
  }

  int _nextNotificationId() {
    return StorageUtils.getUniqueTimestamp().remainder(0x7fffffff).toInt();
  }
}
