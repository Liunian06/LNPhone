import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';
import '../models/chat_model.dart';
import '../models/contact_model.dart';
import '../models/moments_model.dart';
import '../models/world_info_model.dart';
import '../models/text_preset_model.dart';
import '../models/memory_model.dart';
import '../models/wallet_model.dart';
import '../models/emoji_model.dart';
import '../utils/storage_utils.dart';

/// JSON 明文导出服务
///
/// 提供将所有用户数据导出为明文 JSON 的功能，
/// 支持包含图片二进制数据 (base64) 以实现完整数据迁移。
/// 注意：不导出 API Key 等敏感信息。
class JsonExportService {
  final AppDatabase _db;

  JsonExportService() : _db = AppDatabase();

  /// 导出选项
  static const int exportOptionAll = 0xFF;
  static const int exportOptionContacts = 0x01;
  static const int exportOptionChats = 0x02;
  static const int exportOptionMoments = 0x04;
  static const int exportOptionMemories = 0x08;
  static const int exportOptionWallet = 0x10;
  static const int exportOptionEmojis = 0x20;
  static const int exportOptionPresets = 0x40;
  static const int exportOptionSettings = 0x80;

  /// 导出所有数据为 JSON
  ///
  /// [options] 导出选项，默认导出全部
  /// [includeMetadata] 是否包含导出元数据（时间戳、版本等）
  /// [prettyPrint] 是否格式化输出
  /// [includeImageData] 是否包含图片二进制数据 (base64)，默认为 true，启用后可完整迁移数据
  ///
  /// 返回 JSON 文件路径
  Future<String> exportToJson({
    int options = exportOptionAll,
    bool includeMetadata = true,
    bool prettyPrint = true,
    bool includeImageData = true,
  }) async {
    final exportData = <String, dynamic>{};

    // 添加元数据
    if (includeMetadata) {
      exportData['_metadata'] = {
        'exportVersion': '2.0.0', // 升级版本号，表示支持图片数据导出
        'exportTimestamp': DateTime.now().toIso8601String(),
        'exportTimestampMs': DateTime.now().millisecondsSinceEpoch,
        'schemaVersion': _db.schemaVersion,
        'platform': Platform.operatingSystem,
        'includeImageData': includeImageData,
      };
    }

    // 导出联系人（角色和用户人设）
    if (options & exportOptionContacts != 0) {
      exportData['contacts'] = await _exportContacts(includeImageData);
    }

    // 导出聊天数据
    if (options & exportOptionChats != 0) {
      exportData['chats'] = await _exportChats(includeImageData);
    }

    // 导出朋友圈数据
    if (options & exportOptionMoments != 0) {
      exportData['moments'] = await _exportMoments(includeImageData);
    }

    // 导出记忆数据
    if (options & exportOptionMemories != 0) {
      exportData['memories'] = await _exportMemories();
    }

    // 导出钱包数据
    if (options & exportOptionWallet != 0) {
      exportData['wallet'] = await _exportWallet();
    }

    // 导出表情包数据
    if (options & exportOptionEmojis != 0) {
      exportData['emojis'] = await _exportEmojis(includeImageData);
    }

    // 导出预设数据（世界书、文本预设，不包含 API 预设）
    if (options & exportOptionPresets != 0) {
      exportData['presets'] = await _exportPresets();
    }

    // 导出应用设置
    if (options & exportOptionSettings != 0) {
      exportData['settings'] = await _exportSettings();
    }

    // 生成 JSON 字符串
    final encoder =
        prettyPrint ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    final jsonString = encoder.convert(exportData);

    // 保存到文件
    final tempDir = await getTemporaryDirectory();
    final timestamp = StorageUtils.getUniqueTimestamp();
    final fileName = 'LNPhone-Export-$timestamp.json';
    final filePath = p.join(tempDir.path, fileName);

    final file = File(filePath);
    await file.writeAsString(jsonString);

    debugPrint('[JsonExportService] 导出完成: $filePath');
    debugPrint('[JsonExportService] 文件大小: ${await file.length()} bytes');

    return filePath;
  }

  /// 导出联系人数据
  Future<Map<String, dynamic>> _exportContacts(bool includeImageData) async {
    final roles = await _db.getAllContactRoles();
    final meList = await _db.getAllContactMes();

    return {
      'roles':
          roles.map((r) => _serializeContactRole(r, includeImageData)).toList(),
      'meList':
          meList.map((m) => _serializeContactMe(m, includeImageData)).toList(),
    };
  }

  /// 序列化角色人设
  Map<String, dynamic> _serializeContactRole(
      ContactRole role, bool includeImageData) {
    final result = <String, dynamic>{
      'id': role.id,
      'name': role.name,
      'avatarPath': role.avatarPath,
      'description': role.description,
      'appearance': role.appearance,
      'referenceImages': role.referenceImages,
      'subscribedGroupIds': role.subscribedGroupIds,
      'subscribedEmojiIds': role.subscribedEmojiIds,
    };

    if (includeImageData) {
      // 导出头像二进制数据 (base64)
      if (role.avatarData != null) {
        result['avatarData'] = base64Encode(role.avatarData!);
      }
      // 导出参考图二进制数据 (base64 列表)
      if (role.referenceImagesData != null) {
        result['referenceImagesData'] = role.referenceImagesData;
      }
    }

    return result;
  }

  /// 序列化用户人设
  Map<String, dynamic> _serializeContactMe(
      ContactMe me, bool includeImageData) {
    final result = <String, dynamic>{
      'id': me.id,
      'name': me.name,
      'avatarPath': me.avatarPath,
      'info': me.info,
      'appearance': me.appearance,
      'referenceImages': me.referenceImages,
    };

    if (includeImageData) {
      // 导出头像二进制数据 (base64)
      if (me.avatarData != null) {
        result['avatarData'] = base64Encode(me.avatarData!);
      }
      // 导出参考图二进制数据 (base64 列表)
      if (me.referenceImagesData != null) {
        result['referenceImagesData'] = me.referenceImagesData;
      }
    }

    return result;
  }

  /// 导出聊天数据
  Future<Map<String, dynamic>> _exportChats(bool includeImageData) async {
    final sessions = await _db.getAllSessions();
    final worldInfos = await _db.getAllWorldInfos();
    final textPresets = await _db.getAllTextPresets();

    return {
      'sessions': await Future.wait(
        sessions
            .map((s) => _serializeChatSession(s, includeImageData))
            .toList(),
      ),
      'worldInfos': worldInfos.map((w) => w.toJson()).toList(),
      'textPresets': textPresets.map((t) => _serializeTextPreset(t)).toList(),
    };
  }

  /// 序列化聊天会话
  Future<Map<String, dynamic>> _serializeChatSession(
      ChatSession session, bool includeImageData) async {
    // 获取所有消息（不只是前30条）
    final allMessages = await _db.getMessages(session.id);

    final result = <String, dynamic>{
      'id': session.id,
      'roleId': session.roleId,
      'meId': session.meId,
      'lastUpdated': session.lastUpdated,
      'enableExtendedChat': session.enableExtendedChat,
      'enableTextToImage': session.enableTextToImage,
      'enableEmoji': session.enableEmoji,
      'enableIndependentSendButton': session.enableIndependentSendButton,
      'enableBackgroundReply': session.enableBackgroundReply,
      'backgroundReplyIntervalMinutes': session.backgroundReplyIntervalMinutes,
      'backgroundReplyStatus': session.backgroundReplyStatus.name,
      'backgroundReplyLastError': session.backgroundReplyLastError,
      'backgroundReplyDisabledByFailure':
          session.backgroundReplyDisabledByFailure,
      'currentState': session.currentState,
      'isPinned': session.isPinned,
      'worldInfoIds': session.worldInfoIds,
      'textPresetIds': session.textPresetIds,
      // 注意：不导出 apiPresetId 和 imageApiPresetId，因为它们关联到包含敏感信息的 API 设置
      'backgroundImage': session.backgroundImage,
      'messages': allMessages
          .map((m) => _serializeChatMessage(m, includeImageData))
          .toList(),
      '_messageCount': allMessages.length,
    };

    if (includeImageData && session.backgroundImageData != null) {
      result['backgroundImageData'] =
          base64Encode(session.backgroundImageData!);
    }

    return result;
  }

  /// 序列化聊天消息
  Map<String, dynamic> _serializeChatMessage(
      ChatMessage message, bool includeImageData) {
    final result = <String, dynamic>{
      'id': message.id,
      'isMe': message.isMe,
      'sender': message.sender,
      'type': message.type.index,
      'typeName': message.type.name,
      'content': message.content,
      'timestamp': message.timestamp,
      'timestampFormatted':
          DateTime.fromMillisecondsSinceEpoch(message.timestamp)
              .toIso8601String(),
      'metadata': message.metadata,
      'isRead': message.isRead,
    };

    if (includeImageData && message.messageData != null) {
      result['messageData'] = base64Encode(message.messageData!);
    }

    return result;
  }

  /// 序列化文本预设
  Map<String, dynamic> _serializeTextPreset(TextPreset preset) {
    return {
      'id': preset.id,
      'name': preset.name,
      'content': preset.content,
      'type': preset.type.index,
      'typeName': preset.type.name,
      'isBuiltIn': preset.isBuiltIn,
      'createdAt': preset.createdAt,
      'updatedAt': preset.updatedAt,
    };
  }

  /// 导出朋友圈数据
  Future<Map<String, dynamic>> _exportMoments(bool includeImageData) async {
    // 获取所有朋友圈动态（不分页）
    final posts = await _db.getAllMoments(limit: 10000, offset: 0);
    final userSettings = await _db.getMomentsUserSettings();

    Map<String, dynamic>? userSettingsData;
    if (userSettings != null) {
      userSettingsData = {
        'name': userSettings.name,
        'avatarUrl': userSettings.avatarUrl,
        'coverImageUrl': userSettings.coverImageUrl,
        'signature': userSettings.signature,
      };
      if (includeImageData) {
        if (userSettings.avatarData != null) {
          userSettingsData['avatarData'] =
              base64Encode(userSettings.avatarData!);
        }
        if (userSettings.coverImageData != null) {
          userSettingsData['coverImageData'] =
              base64Encode(userSettings.coverImageData!);
        }
      }
    }

    return {
      'posts':
          posts.map((p) => _serializeMomentsPost(p, includeImageData)).toList(),
      'currentUser': userSettingsData,
      '_postCount': posts.length,
    };
  }

  /// 序列化朋友圈动态
  Map<String, dynamic> _serializeMomentsPost(
      MomentsPost post, bool includeImageData) {
    final result = <String, dynamic>{
      'id': post.id,
      'user': _serializeMomentsUser(post.user, includeImageData),
      'content': post.content,
      'mediaItems': post.mediaItems.map((m) => m.toJson()).toList(),
      'createdAt': post.createdAt.toIso8601String(),
      'createdAtMs': post.createdAt.millisecondsSinceEpoch,
      'likes': post.likes
          .map((l) => _serializeMomentLike(l, includeImageData))
          .toList(),
      'comments': post.comments
          .map((c) => _serializeMomentsComment(c, includeImageData))
          .toList(),
      'location': post.location,
      '_likeCount': post.likes.where((l) => !l.isCancelled).length,
      '_commentCount': post.comments.length,
    };

    if (includeImageData && post.mediaData != null) {
      result['mediaData'] = post.mediaData;
    }

    return result;
  }

  /// 序列化朋友圈用户
  Map<String, dynamic> _serializeMomentsUser(
      MomentsUser user, bool includeImageData) {
    final result = <String, dynamic>{
      'id': user.id,
      'name': user.name,
      'avatarUrl': user.avatarUrl,
      'coverImageUrl': user.coverImageUrl,
      'signature': user.signature,
    };

    if (includeImageData) {
      if (user.avatarData != null) {
        result['avatarData'] = base64Encode(user.avatarData!);
      }
      if (user.coverImageData != null) {
        result['coverImageData'] = base64Encode(user.coverImageData!);
      }
    }

    return result;
  }

  /// 序列化点赞
  Map<String, dynamic> _serializeMomentLike(
      MomentLike like, bool includeImageData) {
    return {
      'user': _serializeMomentsUser(like.user, includeImageData),
      'createdAt': like.createdAt.toIso8601String(),
      'isCancelled': like.isCancelled,
    };
  }

  /// 序列化评论
  Map<String, dynamic> _serializeMomentsComment(
      MomentsComment comment, bool includeImageData) {
    return {
      'id': comment.id,
      'user': _serializeMomentsUser(comment.user, includeImageData),
      'content': comment.content,
      'createdAt': comment.createdAt.toIso8601String(),
      'replyTo': comment.replyTo != null
          ? _serializeMomentsUser(comment.replyTo!, includeImageData)
          : null,
    };
  }

  /// 导出记忆数据
  Future<Map<String, dynamic>> _exportMemories() async {
    final memories = await _db.getAllMemories();

    return {
      'items': memories.map((m) => _serializeMemory(m)).toList(),
      '_totalCount': memories.length,
    };
  }

  /// 序列化记忆
  Map<String, dynamic> _serializeMemory(RoleMemory memory) {
    return {
      'id': memory.id,
      'roleId': memory.roleId,
      'content': memory.content,
      'createdAt': memory.createdAt,
      'createdAtFormatted':
          DateTime.fromMillisecondsSinceEpoch(memory.createdAt)
              .toIso8601String(),
      'updatedAt': memory.updatedAt,
      'updatedAtFormatted':
          DateTime.fromMillisecondsSinceEpoch(memory.updatedAt)
              .toIso8601String(),
      'sourceSessionId': memory.sourceSessionId,
      'category': memory.category.index,
      'categoryName': memory.category.name,
      'categoryDisplayName': memory.category.displayName,
    };
  }

  /// 导出钱包数据
  Future<Map<String, dynamic>> _exportWallet() async {
    final balance = await _db.getWalletBalance();
    final transactions = await _db.getAllWalletTransactions();

    return {
      'balance': balance,
      'transactions':
          transactions.map((t) => _serializeTransaction(t)).toList(),
      '_transactionCount': transactions.length,
    };
  }

  /// 序列化交易记录
  Map<String, dynamic> _serializeTransaction(WalletTransaction transaction) {
    return {
      'id': transaction.id,
      'type': transaction.type.index,
      'typeName': transaction.type.name,
      'typeDisplayName': transaction.typeDisplayName,
      'direction': transaction.direction.index,
      'directionName': transaction.direction.name,
      'amount': transaction.amount,
      'amountDisplayText': transaction.amountDisplayText,
      'description': transaction.description,
      'relatedContactName': transaction.relatedContactName,
      'relatedSessionId': transaction.relatedSessionId,
      'relatedMessageId': transaction.relatedMessageId,
      'timestamp': transaction.timestamp,
      'timestampFormatted':
          DateTime.fromMillisecondsSinceEpoch(transaction.timestamp)
              .toIso8601String(),
    };
  }

  /// 导出表情包数据
  Future<Map<String, dynamic>> _exportEmojis(bool includeImageData) async {
    final emojis = await _db.getAllEmojis();
    final groups = await _db.getAllEmojiGroups();

    // 如果需要包含图片数据，尝试从备份路径或本地路径加载图片
    final List<Map<String, dynamic>> emojisList = [];
    for (final emoji in emojis) {
      emojisList.add(await _serializeEmoji(emoji, includeImageData));
    }

    return {
      'emojis': emojisList,
      'groups': groups.map((g) => _serializeEmojiGroup(g)).toList(),
      '_emojiCount': emojis.length,
      '_groupCount': groups.length,
    };
  }

  /// 序列化表情包
  Future<Map<String, dynamic>> _serializeEmoji(
      EmojiModel emoji, bool includeImageData) async {
    final result = <String, dynamic>{
      'id': emoji.id,
      'meaning': emoji.meaning,
      'rawContent': emoji.rawContent,
      'groupId': emoji.groupId,
      'localPath': emoji.localPath,
      'backupPath': emoji.backupPath,
      'type': emoji.type.index,
      'typeName': emoji.type.name,
      'roleId': emoji.roleId,
      'createdAt': emoji.createdAt,
      'createdAtFormatted': DateTime.fromMillisecondsSinceEpoch(emoji.createdAt)
          .toIso8601String(),
    };

    if (includeImageData) {
      // 优先使用 emojiData，如果没有则尝试从备份路径加载
      if (emoji.emojiData != null) {
        result['emojiData'] = base64Encode(emoji.emojiData!);
      } else if (emoji.backupPath != null) {
        try {
          final backupFile = File(emoji.backupPath!);
          if (await backupFile.exists()) {
            final bytes = await backupFile.readAsBytes();
            result['emojiData'] = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('[JsonExportService] 读取表情备份文件失败: ${emoji.backupPath}, $e');
        }
      } else if (emoji.localPath.isNotEmpty) {
        // 尝试从本地路径加载
        try {
          final localFile = File(emoji.localPath);
          if (await localFile.exists()) {
            final bytes = await localFile.readAsBytes();
            result['emojiData'] = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('[JsonExportService] 读取表情本地文件失败: ${emoji.localPath}, $e');
        }
      }
    }

    return result;
  }

  /// 序列化表情包分组
  Map<String, dynamic> _serializeEmojiGroup(EmojiGroupEntity group) {
    return {
      'id': group.id,
      'name': group.name,
      'type': group.type.index,
      'typeName': group.type.name,
      'roleId': group.roleId,
      'isVisible': group.isVisible,
      'createdAt': group.createdAt,
      'createdAtFormatted': DateTime.fromMillisecondsSinceEpoch(group.createdAt)
          .toIso8601String(),
    };
  }

  /// 导出预设数据
  /// 注意：不再导出 API 预设，因为它们包含敏感的 API Key 信息
  Future<Map<String, dynamic>> _exportPresets() async {
    final worldInfos = await _db.getAllWorldInfos();
    final textPresets = await _db.getAllTextPresets();

    return {
      // 不导出 apiPresets，因为包含敏感的 API Key 信息
      'worldInfos': worldInfos.map((w) => _serializeWorldInfo(w)).toList(),
      'textPresets': textPresets.map((t) => _serializeTextPreset(t)).toList(),
    };
  }

  /// 序列化世界书
  Map<String, dynamic> _serializeWorldInfo(WorldInfo info) {
    return {
      'id': info.id,
      'name': info.name,
      'content': info.content,
      'createdAt': info.createdAt,
      'createdAtFormatted':
          DateTime.fromMillisecondsSinceEpoch(info.createdAt).toIso8601String(),
      'updatedAt': info.updatedAt,
      'updatedAtFormatted':
          DateTime.fromMillisecondsSinceEpoch(info.updatedAt).toIso8601String(),
      '_contentLength': info.content.length,
    };
  }

  /// 导出应用设置
  /// 注意：会过滤掉包含敏感信息的设置项
  Future<Map<String, dynamic>> _exportSettings() async {
    final allSettings = await _db.getAllSettings();

    // 过滤敏感字段
    final safeSettings = <String, String>{};
    for (final entry in allSettings.entries) {
      // 跳过可能包含敏感信息的设置（如 API Key、Secret、Token 等）
      final lowerKey = entry.key.toLowerCase();
      if (lowerKey.contains('key') ||
          lowerKey.contains('secret') ||
          lowerKey.contains('token') ||
          lowerKey.contains('api') ||
          lowerKey.contains('password')) {
        // 不导出敏感设置
        continue;
      }
      safeSettings[entry.key] = entry.value;
    }

    return {
      'items': safeSettings,
      '_count': safeSettings.length,
    };
  }

  /// 获取导出数据的摘要信息
  Future<Map<String, dynamic>> getExportSummary() async {
    final roles = await _db.getAllContactRoles();
    final meList = await _db.getAllContactMes();
    final sessions = await _db.getAllSessions();
    final moments = await _db.getAllMoments(limit: 10000, offset: 0);
    final memories = await _db.getAllMemories();
    final balance = await _db.getWalletBalance();
    final transactions = await _db.getAllWalletTransactions();
    final emojis = await _db.getAllEmojis();
    final groups = await _db.getAllEmojiGroups();
    final worldInfos = await _db.getAllWorldInfos();
    final textPresets = await _db.getAllTextPresets();

    int totalMessages = 0;
    for (final session in sessions) {
      final messages = await _db.getMessages(session.id);
      totalMessages += messages.length;
    }

    return {
      'contacts': {
        'roleCount': roles.length,
        'meCount': meList.length,
      },
      'chats': {
        'sessionCount': sessions.length,
        'messageCount': totalMessages,
      },
      'moments': {
        'postCount': moments.length,
      },
      'memories': {
        'count': memories.length,
      },
      'wallet': {
        'balance': balance,
        'transactionCount': transactions.length,
      },
      'emojis': {
        'emojiCount': emojis.length,
        'groupCount': groups.length,
      },
      'presets': {
        // 不再统计 apiPresets，因为不导出
        'worldInfoCount': worldInfos.length,
        'textPresetCount': textPresets.length,
      },
    };
  }
}
