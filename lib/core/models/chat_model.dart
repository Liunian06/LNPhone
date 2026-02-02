import 'dart:convert';
import 'dart:typed_data';

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
  // 红包/转账响应类型（不在聊天界面显示，用于更新原消息状态）
  acceptRedpacket, // 接受红包
  rejectRedpacket, // 拒绝红包
  acceptTransfer, // 接受转账
  rejectTransfer, // 拒绝转账
  // 分享类型
  product, // 商品推荐
  link, // 链接分享
  note, // 备忘提醒
  anniversary, // 纪念日卡片
  // 生活轨迹类型（不在聊天界面显示）
  memory, // 记忆
  diary, // 日记
  moment, // 朋友圈
  momentComment, // 朋友圈评论
  momentLike, // 朋友圈点赞/取消点赞
  // 沉浸模式专用类型
  scene, // 场景描述（用于生成/切换背景图）
  narration, // 旁白（环境描写、心理活动、微表情）
  options, // 互动选项（建议用户的行动）
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final bool
      isMe; // true if sent by the user persona, false if by the role persona
  final String? sender; // 发送者名称（用于引用显示，避免依赖 isMe 判断）
  final MessageType type;
  final String content;
  final int timestamp;
  final Map<String, dynamic>? metadata; // 存储消息类型特定的额外属性
  final Uint8List? messageData; // 消息二进制数据（如图片）
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.isMe,
    this.sender,
    required this.type,
    required this.content,
    this.messageData,
    required this.timestamp,
    this.metadata,
    this.isRead = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isMe': isMe,
      if (sender != null) 'sender': sender,
      'type': type.index,
      'content': content,
      'messageData': messageData != null ? base64Encode(messageData!) : null,
      'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      isMe: json['isMe'],
      sender: json['sender'],
      type: MessageType.values[json['type']],
      content: json['content'],
      messageData: json['messageData'] != null
          ? base64Decode(json['messageData'])
          : null,
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
      case MessageType.momentComment:
      case MessageType.momentLike:
      case MessageType.acceptRedpacket:
      case MessageType.rejectRedpacket:
      case MessageType.acceptTransfer:
      case MessageType.rejectTransfer:
      case MessageType.scene:
        return ''; // 这些类型不在聊天界面显示（场景用于控制背景）
      case MessageType.narration:
        return content; // 旁白直接显示内容
      case MessageType.options:
        return '[选项]';
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
  final bool enableTextToImage; // 是否启用文生图
  final bool enableEmoji; // 是否启用表情包
  final bool enableIndependentSendButton; // 是否启用独立发送/续写按钮
  final String? currentState; // 当前状态
  final bool isPinned; // 是否置顶
  final List<String> worldInfoIds; // 关联的世界书 ID 列表
  final List<String> textPresetIds; // 关联的预设 ID 列表
  final String? apiPresetId; // 独立的 API 预设 ID
  final String? imageApiPresetId; // 独立的生图 API 预设 ID
  final String? backgroundImage; // 聊天背景图路径
  final Uint8List? backgroundImageData; // 聊天背景图二进制数据
  final int? unreadCountOverride; // 预计算的未读数

  ChatSession({
    required this.id,
    required this.roleId,
    required this.meId,
    required this.messages,
    required this.lastUpdated,
    this.unreadCountOverride,
    this.enableExtendedChat = true, // 默认开启
    this.enableTextToImage = false, // 默认关闭
    this.enableEmoji = true, // 默认开启
    this.enableIndependentSendButton = false, // 默认关闭
    this.currentState,
    this.isPinned = false, // 默认不置顶
    this.worldInfoIds = const [],
    this.textPresetIds = const [],
    this.apiPresetId,
    this.imageApiPresetId,
    this.backgroundImage,
    this.backgroundImageData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': roleId,
      'meId': meId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastUpdated': lastUpdated,
      'enableExtendedChat': enableExtendedChat,
      'enableTextToImage': enableTextToImage,
      'enableEmoji': enableEmoji,
      'enableIndependentSendButton': enableIndependentSendButton,
      'currentState': currentState,
      'isPinned': isPinned,
      'worldInfoIds': worldInfoIds,
      'textPresetIds': textPresetIds,
      'apiPresetId': apiPresetId,
      'imageApiPresetId': imageApiPresetId,
      'backgroundImage': backgroundImage,
      'backgroundImageData': backgroundImageData != null
          ? base64Encode(backgroundImageData!)
          : null,
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
      enableTextToImage: json['enableTextToImage'] ?? false, // 默认关闭
      enableEmoji: json['enableEmoji'] ?? true, // 默认开启
      enableIndependentSendButton:
          json['enableIndependentSendButton'] ?? false, // 默认关闭
      currentState: json['currentState'],
      isPinned: json['isPinned'] ?? false, // 默认不置顶
      worldInfoIds:
          (json['worldInfoIds'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      textPresetIds:
          (json['textPresetIds'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      apiPresetId: json['apiPresetId'],
      imageApiPresetId: json['imageApiPresetId'],
      backgroundImage: json['backgroundImage'],
      backgroundImageData: json['backgroundImageData'] != null
          ? base64Decode(json['backgroundImageData'])
          : null,
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
          msg.type == MessageType.moment ||
          msg.type == MessageType.momentComment ||
          msg.type == MessageType.momentLike ||
          msg.type == MessageType.acceptRedpacket ||
          msg.type == MessageType.rejectRedpacket ||
          msg.type == MessageType.acceptTransfer ||
          msg.type == MessageType.rejectTransfer) {
        continue;
      }
      return msg.displayText;
    }

    return '';
  }

  /// 获取未读消息数量（只计算来自对方的未读消息）
  int get unreadCount {
    if (unreadCountOverride != null) return unreadCountOverride!;
    return messages.where((m) => !m.isMe && !m.isRead).length;
  }
}
