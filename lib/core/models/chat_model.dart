import 'dart:convert';

/// 消息类型枚举
enum MessageType {
  // 基础消息类型
  words, // 文字消息
  action, // 动作描述
  thought, // 内心想法
  state, // 当前状态（显示在标题栏）
  // 多媒体消息类型
  emoji, // 表情包
  image, // 图片
  location, // 位置分享
  // 资金往来类型
  redpacket, // 红包
  transfer, // 转账
  // 分享类型
  product, // 商品推荐
  link, // 链接分享
  note, // 备忘提醒
  anniversary, // 纪念日卡片
  // 生活轨迹类型（不在聊天界面显示）
  memory, // 记忆
  diary, // 日记
  moment, // 朋友圈
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final bool
      isMe; // true if sent by the user persona, false if by the role persona
  final MessageType type;
  final String content;
  final int timestamp;
  final Map<String, dynamic>? metadata; // 存储消息类型特定的额外属性
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.isMe,
    required this.type,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.isRead = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isMe': isMe,
      'type': type.index,
      'content': content,
      'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      isMe: json['isMe'],
      type: MessageType.values[json['type']],
      content: json['content'],
      timestamp: json['timestamp'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      isRead: json['isRead'] ?? true,
    );
  }

  /// 获取消息的显示文本（用于预览）
  String get displayText {
    switch (type) {
      case MessageType.words:
        return content;
      case MessageType.action:
        return content;
      case MessageType.thought:
        return content;
      case MessageType.state:
        return '[状态: $content]';
      case MessageType.emoji:
        return '[表情]';
      case MessageType.image:
        return '[图片]';
      case MessageType.location:
        return '[位置]';
      case MessageType.redpacket:
        return '[红包]';
      case MessageType.transfer:
        return '[转账]';
      case MessageType.product:
        return '[商品推荐]';
      case MessageType.link:
        return '[链接]';
      case MessageType.note:
        return '[备忘录]';
      case MessageType.anniversary:
        return '[纪念日]';
      case MessageType.memory:
      case MessageType.diary:
      case MessageType.moment:
        return ''; // 这些类型不在聊天界面显示
    }
  }
}

class ChatSession {
  final String id;
  final String roleId; // ID of the ContactRole
  final String meId; // ID of the ContactMe
  final List<ChatMessage> messages;
  final int lastUpdated;
  final bool enableExtendedChat; // 是否启用扩展聊天（解析action和thought）
  final String? currentState; // 当前状态
  final bool isPinned; // 是否置顶
  final List<String> worldInfoIds; // 关联的世界书 ID 列表
  final List<String> textPresetIds; // 关联的预设 ID 列表
  final String? apiPresetId; // 独立的 API 预设 ID
  final String? backgroundImage; // 聊天背景图路径

  ChatSession({
    required this.id,
    required this.roleId,
    required this.meId,
    required this.messages,
    required this.lastUpdated,
    this.enableExtendedChat = true, // 默认开启
    this.currentState,
    this.isPinned = false, // 默认不置顶
    this.worldInfoIds = const [],
    this.textPresetIds = const [],
    this.apiPresetId,
    this.backgroundImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': roleId,
      'meId': meId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastUpdated': lastUpdated,
      'enableExtendedChat': enableExtendedChat,
      'currentState': currentState,
      'isPinned': isPinned,
      'worldInfoIds': worldInfoIds,
      'textPresetIds': textPresetIds,
      'apiPresetId': apiPresetId,
      'backgroundImage': backgroundImage,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      roleId: json['roleId'],
      meId: json['meId'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      lastUpdated: json['lastUpdated'],
      enableExtendedChat: json['enableExtendedChat'] ?? true, // 默认开启
      currentState: json['currentState'],
      isPinned: json['isPinned'] ?? false, // 默认不置顶
      worldInfoIds:
          (json['worldInfoIds'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      textPresetIds:
          (json['textPresetIds'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      apiPresetId: json['apiPresetId'],
      backgroundImage: json['backgroundImage'],
    );
  }

  /// 获取最后一条消息的预览文本
  String get lastMessagePreview {
    if (messages.isEmpty) return '';

    // 从后往前查找第一条在聊天界面显示的消息
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      // 跳过不显示的消息类型
      if (msg.type == MessageType.memory ||
          msg.type == MessageType.diary ||
          msg.type == MessageType.moment) {
        continue;
      }
      return msg.displayText;
    }

    return '';
  }

  /// 获取未读消息数量（只计算来自对方的未读消息）
  int get unreadCount {
    return messages.where((m) => !m.isMe && !m.isRead).length;
  }
}
