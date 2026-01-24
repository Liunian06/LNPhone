import 'dart:convert';
import 'package:xml/xml.dart';
import '../models/chat_model.dart';

/// 响应解析器
/// 解析 AI 返回的 JSON 或 XML 格式回复，转换为多条聊天消息
/// 兼容旧的 XML 格式，但优先支持 JSON 格式
class ResponseParser {
  /// 解析响应
  ///
  /// [simpleIdToRealId] - 简化ID到真实ID的映射表，用于将AI回复中的简化ID转换回真实ID
  /// 返回解析后的消息列表。如果返回空列表，表示 AI 选择沉默（不回复）
  static List<ChatMessage> parse(
    String rawResponse,
    String messageIdPrefix, {
    Map<String, String>? simpleIdToRealId,
  }) {
    print('[ResponseParser] ========== 开始解析响应 ==========');
    print('[ResponseParser] 原始响应长度: ${rawResponse.length} 字符');

    String cleanResponse = rawResponse.trim();

    // 1. 尝试去除 Markdown 代码块标记
    final jsonCodeBlockRegex = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$',
        caseSensitive: false, multiLine: false);
    final match = jsonCodeBlockRegex.firstMatch(cleanResponse);
    if (match != null) {
      print('[ResponseParser] 检测到 Markdown 代码块，提取内容...');
      cleanResponse = match.group(1)!.trim();
    }

    // 2. 尝试解析为 JSON
    if (cleanResponse.startsWith('[') || cleanResponse.startsWith('{')) {
      try {
        print('[ResponseParser] 尝试解析为 JSON...');
        return _parseJson(cleanResponse, messageIdPrefix,
            simpleIdToRealId: simpleIdToRealId);
      } catch (e) {
        print('[ResponseParser] ⚠️ JSON 解析失败: $e');

        // 尝试修复常见的 JSON 格式错误：缺少逗号
        // 例如: {"a":1}{"b":2} -> {"a":1},{"b":2}
        // 注意：这只是一个简单的启发式修复，可能无法处理所有情况
        if (cleanResponse.contains('}{')) {
          print('[ResponseParser] 检测到可能的 JSON 格式错误 (缺少逗号)，尝试修复...');
          final fixedJson = cleanResponse.replaceAll('}{', '},{');
          try {
            // 如果原始字符串不是数组包裹的，尝试包裹它
            String jsonToParse = fixedJson;
            if (!jsonToParse.startsWith('[')) {
              jsonToParse = '[$jsonToParse]';
            }

            print('[ResponseParser] 尝试解析修复后的 JSON...');
            return _parseJson(jsonToParse, messageIdPrefix,
                simpleIdToRealId: simpleIdToRealId);
          } catch (e2) {
            print('[ResponseParser] ⚠️ 修复后的 JSON 解析仍然失败: $e2');
          }
        }

        // 尝试修复其他常见的 JSON 错误
        try {
          String fixedJson = cleanResponse;
          bool modified = false;

          // 1. 修复尾随逗号 (Trailing commas)
          // e.g., [{"a":1},] -> [{"a":1}]
          if (RegExp(r',\s*([\]}])').hasMatch(fixedJson)) {
            fixedJson = fixedJson.replaceAllMapped(
                RegExp(r',\s*([\]}])'), (match) => match.group(1)!);
            modified = true;
          }

          // 2. 修复未转义的换行符 (Unescaped newlines)
          // JSON 字符串中不允许直接换行，必须是 \n
          if (fixedJson.contains('\n')) {
            // 这是一个比较激进的修复，可能会破坏格式化的 JSON
            // 我们只在解析失败后尝试
            // 简单的策略：如果换行符不在引号内，保留；如果在引号内，替换为 \\n
            // 但这很难用正则完美实现。
            // 替代策略：直接将所有换行符替换为 \\n，但这会破坏多行 JSON 的结构
            // 所以这里只处理明显的错误：比如 content 字段中的换行
            // 暂时跳过这个复杂的修复，避免引入更多问题
          }

          if (modified) {
            print('[ResponseParser] 尝试解析进一步修复的 JSON...');
            return _parseJson(fixedJson, messageIdPrefix,
                simpleIdToRealId: simpleIdToRealId);
          }
        } catch (e3) {
          print('[ResponseParser] ⚠️ 进一步修复后的 JSON 解析仍然失败: $e3');
        }

        print('[ResponseParser] 尝试回退到 XML 解析...');
      }
    }

    // 3. 回退到 XML 解析
    return _parseXml(rawResponse, messageIdPrefix,
        simpleIdToRealId: simpleIdToRealId);
  }

  static List<ChatMessage> _parseJson(
    String jsonString,
    String messageIdPrefix, {
    Map<String, String>? simpleIdToRealId,
  }) {
    final messages = <ChatMessage>[];
    dynamic decoded;

    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      rethrow;
    }

    List<dynamic> jsonList;
    if (decoded is List) {
      jsonList = decoded;
    } else if (decoded is Map) {
      jsonList = [decoded];
    } else {
      throw FormatException('JSON 根元素必须是数组或对象');
    }

    int messageIndex = 0;
    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;

      // 检查是否是系统空消息
      if (item['type'] == 'system' && item['content'] == 'empty') {
        print('[ResponseParser] 检测到 empty message，AI 选择不回复');
        return [];
      }

      final message = _parseJsonItem(
        item,
        '$messageIdPrefix-$messageIndex',
        simpleIdToRealId: simpleIdToRealId,
      );

      if (message != null) {
        messages.add(message);
        messageIndex++;
        print(
            '[ResponseParser] ✓ 添加消息: type=${message.type}, id=${message.id}');
      }
    }

    print(
        '[ResponseParser] ========== JSON 解析完成，共 ${messages.length} 条消息 ==========');
    return messages;
  }

  static ChatMessage? _parseJsonItem(
    Map<String, dynamic> item,
    String messageId, {
    Map<String, String>? simpleIdToRealId,
  }) {
    final typeStr = item['type'] as String?;
    final content = item['content'] as String? ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (typeStr == null) return null;

    // 处理引用 ID
    String? refId = item['ref'] as String?;
    final Map<String, dynamic> metadata = {};

    if (refId != null && refId.isNotEmpty) {
      if (simpleIdToRealId != null && simpleIdToRealId.containsKey(refId)) {
        final realId = simpleIdToRealId[refId]!;
        metadata['reply_id'] = realId;
      } else {
        metadata['reply_id'] = refId;
      }
    }

    // 提取其他可能的元数据字段
    item.forEach((key, value) {
      if (key != 'type' && key != 'content' && key != 'ref' && key != 'id') {
        if (value is String) {
          metadata[key] = value;
        }
      }
    });

    MessageType type;
    switch (typeStr) {
      case 'word':
        type = MessageType.words;
        break;
      case 'action':
        type = MessageType.action;
        break;
      case 'thought':
        type = MessageType.thought;
        break;
      case 'state':
        type = MessageType.state;
        break;
      case 'emoji':
        return null; // 暂不支持
      case 'location':
        type = MessageType.location;
        break;
      case 'redpacket':
        type = MessageType.redpacket;
        break;
      case 'transfer':
        type = MessageType.transfer;
        break;

      // 兼容 Prompt 中的 accept/reject
      case 'accept':
        type = MessageType.acceptRedpacket;
        break;
      case 'reject':
        type = MessageType.rejectRedpacket;
        break;

      case 'accept_redpacket':
        type = MessageType.acceptRedpacket;
        break;
      case 'reject_redpacket':
        type = MessageType.rejectRedpacket;
        break;
      case 'accept_transfer':
        type = MessageType.acceptTransfer;
        break;
      case 'reject_transfer':
        type = MessageType.rejectTransfer;
        break;

      case 'product':
        type = MessageType.product;
        break;
      case 'link':
        type = MessageType.link;
        break;
      case 'note':
        type = MessageType.note;
        break;
      case 'anniversary':
        type = MessageType.anniversary;
        break;
      case 'memory':
        type = MessageType.memory;
        break;
      case 'diary':
        type = MessageType.diary;
        break;
      case 'moment':
        type = MessageType.moment;
        break;
      default:
        return null;
    }

    // 特殊处理 accept/reject 的 target_id
    if (type == MessageType.acceptRedpacket ||
        type == MessageType.rejectRedpacket ||
        type == MessageType.acceptTransfer ||
        type == MessageType.rejectTransfer) {
      if (metadata.containsKey('reply_id')) {
        metadata['target_id'] = metadata['reply_id'];
        metadata.remove('reply_id');
      }
    }

    return ChatMessage(
      id: messageId,
      isMe: false,
      type: type,
      content: content,
      timestamp: timestamp,
      metadata: metadata.isEmpty ? null : metadata,
      isRead: false,
    );
  }

  static List<ChatMessage> _parseXml(
    String xmlResponse,
    String messageIdPrefix, {
    Map<String, String>? simpleIdToRealId,
  }) {
    print('[ResponseParser] (XML) 开始解析 XML...');
    final messages = <ChatMessage>[];
    int messageIndex = 0;

    try {
      String xmlToParse = xmlResponse.trim();

      if (xmlToParse.isEmpty) {
        return messages;
      }

      if (xmlToParse.contains('<info>') &&
          xmlToParse.toLowerCase().contains('empty message')) {
        return messages;
      }

      final outputMatch = RegExp(
        r'<output>(.*?)</output>',
        dotAll: true,
      ).firstMatch(xmlToParse);

      if (outputMatch != null) {
        xmlToParse = '<output>${outputMatch.group(1)}</output>';
      } else {
        final knownTags = [
          'words',
          'action',
          'thought',
          'state',
          'emoji',
          'location',
          'redpacket',
          'transfer',
          'accept_redpacket',
          'reject_redpacket',
          'accept_transfer',
          'reject_transfer',
          'product',
          'link',
          'note',
          'anniversary',
          'memory',
          'diary',
          'moment',
        ];

        bool hasKnownTags = false;
        for (final tag in knownTags) {
          if (xmlToParse.contains('<$tag>') || xmlToParse.contains('<$tag ')) {
            hasKnownTags = true;
            break;
          }
        }

        if (!hasKnownTags) {
          if (xmlToParse.isNotEmpty) {
            messages.add(
              ChatMessage(
                id: '$messageIdPrefix-0',
                isMe: false,
                type: MessageType.words,
                content: xmlToParse,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                isRead: false,
              ),
            );
          }
          return messages;
        }

        xmlToParse = '<output>$xmlToParse</output>';
      }

      final document = XmlDocument.parse(xmlToParse);
      final outputElement = document.findElements('output').firstOrNull;

      if (outputElement == null) {
        final content = xmlResponse.trim();
        if (content.isNotEmpty) {
          messages.add(
            ChatMessage(
              id: '$messageIdPrefix-0',
              isMe: false,
              type: MessageType.words,
              content: content,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              isRead: false,
            ),
          );
        }
        return messages;
      }

      for (final element in outputElement.children) {
        if (element is! XmlElement) continue;

        final tagName = element.name.local.toLowerCase();
        final content = element.innerText.trim();

        if (content.isEmpty && !_requiresEmptyContent(tagName)) {
          continue;
        }

        final message = _parseXmlElement(
          tagName,
          content,
          element,
          '$messageIdPrefix-$messageIndex',
          simpleIdToRealId: simpleIdToRealId,
        );

        if (message != null) {
          messages.add(message);
          messageIndex++;
        }
      }
    } catch (e, stackTrace) {
      print('[ResponseParser] ❌ XML 解析异常: $e');
      print('[ResponseParser] ❌ 堆栈跟踪: $stackTrace');
      final content = xmlResponse.trim();
      if (content.isNotEmpty) {
        messages.add(
          ChatMessage(
            id: '$messageIdPrefix-0',
            isMe: false,
            type: MessageType.words,
            content: content,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isRead: false,
          ),
        );
      }
    }

    return messages;
  }

  static bool _requiresEmptyContent(String tagName) {
    return ['state', 'emoji', 'location'].contains(tagName);
  }

  static ChatMessage? _parseXmlElement(
    String tagName,
    String content,
    XmlElement element,
    String messageId, {
    Map<String, String>? simpleIdToRealId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    String? refId = element.getAttribute('ref');
    if (refId == null || refId.isEmpty) {
      refId = element.getAttribute('quote');
    }
    if (refId == null || refId.isEmpty) {
      refId = element.getAttribute('reply');
    }
    if (refId == null || refId.isEmpty) {
      final idAttr = element.getAttribute('id');
      if (idAttr != null && idAttr.isNotEmpty) {
        if (RegExp(r'^\d{4}$').hasMatch(idAttr)) {
          refId = idAttr;
        }
      }
    }

    final Map<String, dynamic> metadata = {};

    if (refId != null && refId.isNotEmpty) {
      if (simpleIdToRealId != null && simpleIdToRealId.containsKey(refId)) {
        final realId = simpleIdToRealId[refId]!;
        metadata['reply_id'] = realId;
      } else {
        metadata['reply_id'] = refId;
      }
    }

    switch (tagName) {
      case 'words':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.words,
          content: content,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

      case 'action':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.action,
          content: content,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

      case 'thought':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.thought,
          content: content,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

      case 'state':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.state,
          content: content,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

      case 'emoji':
        return null;

      case 'location':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.location,
          content: content,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

      case 'redpacket':
        final message = element.getAttribute('message') ?? '';
        metadata['message'] = message;
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.redpacket,
          content: content,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'transfer':
        final message = element.getAttribute('message') ?? '';
        metadata['message'] = message;
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.transfer,
          content: content,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'accept_redpacket':
        String? targetId = element.getAttribute('ref');
        String responseContent = content;
        try {
          if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
            final json = jsonDecode(content) as Map<String, dynamic>;
            if (json.containsKey('ref')) {
              targetId = json['ref'] as String;
            }
            if (json.containsKey('content')) {
              responseContent = json['content'] as String;
            }
          }
        } catch (e) {
          // ignore
        }
        if (targetId != null && targetId.isNotEmpty) {
          if (simpleIdToRealId != null &&
              simpleIdToRealId.containsKey(targetId)) {
            metadata['target_id'] = simpleIdToRealId[targetId];
          } else {
            metadata['target_id'] = targetId;
          }
        }
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.acceptRedpacket,
          content: responseContent,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'reject_redpacket':
        String? targetId = element.getAttribute('ref');
        String responseContent = content;
        try {
          if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
            final json = jsonDecode(content) as Map<String, dynamic>;
            if (json.containsKey('ref')) {
              targetId = json['ref'] as String;
            }
            if (json.containsKey('content')) {
              responseContent = json['content'] as String;
            }
          }
        } catch (e) {
          // ignore
        }
        if (targetId != null && targetId.isNotEmpty) {
          if (simpleIdToRealId != null &&
              simpleIdToRealId.containsKey(targetId)) {
            metadata['target_id'] = simpleIdToRealId[targetId];
          } else {
            metadata['target_id'] = targetId;
          }
        }
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.rejectRedpacket,
          content: responseContent,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'accept_transfer':
        String? targetId = element.getAttribute('ref');
        String responseContent = content;
        try {
          if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
            final json = jsonDecode(content) as Map<String, dynamic>;
            if (json.containsKey('ref')) {
              targetId = json['ref'] as String;
            }
            if (json.containsKey('content')) {
              responseContent = json['content'] as String;
            }
          }
        } catch (e) {
          // ignore
        }
        if (targetId != null && targetId.isNotEmpty) {
          if (simpleIdToRealId != null &&
              simpleIdToRealId.containsKey(targetId)) {
            metadata['target_id'] = simpleIdToRealId[targetId];
          } else {
            metadata['target_id'] = targetId;
          }
        }
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.acceptTransfer,
          content: responseContent,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'reject_transfer':
        String? targetId = element.getAttribute('ref');
        String responseContent = content;
        try {
          if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
            final json = jsonDecode(content) as Map<String, dynamic>;
            if (json.containsKey('ref')) {
              targetId = json['ref'] as String;
            }
            if (json.containsKey('content')) {
              responseContent = json['content'] as String;
            }
          }
        } catch (e) {
          // ignore
        }
        if (targetId != null && targetId.isNotEmpty) {
          if (simpleIdToRealId != null &&
              simpleIdToRealId.containsKey(targetId)) {
            metadata['target_id'] = simpleIdToRealId[targetId];
          } else {
            metadata['target_id'] = targetId;
          }
        }
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.rejectTransfer,
          content: responseContent,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'product':
        final name = element.getAttribute('name') ?? '';
        final price = element.getAttribute('price') ?? '';
        final image = element.getAttribute('image');
        metadata['name'] = name;
        metadata['price'] = price;
        if (image != null) metadata['image'] = image;
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.product,
          content: content,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'link':
        final title = element.getAttribute('title') ?? '';
        final url = element.getAttribute('url') ?? '';
        metadata['title'] = title;
        metadata['url'] = url;
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.link,
          content: content,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'note':
        final title = element.getAttribute('title') ?? '';
        metadata['title'] = title;
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.note,
          content: content,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'anniversary':
        final id = element.getAttribute('id') ?? '';
        final title = element.getAttribute('title') ?? '';
        final days = element.getAttribute('days') ?? '';
        final label = element.getAttribute('label') ?? '';
        final date = element.getAttribute('date') ?? '';
        final background = element.getAttribute('background');
        metadata['anniversary_id'] = id;
        metadata['title'] = title;
        metadata['days'] = days;
        metadata['label'] = label;
        metadata['date'] = date;
        if (background != null) metadata['background'] = background;
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.anniversary,
          content: content,
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'memory':
        final category = element.getAttribute('category');
        if (category != null && category.isNotEmpty) {
          metadata['category'] = category;
        }
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.memory,
          content: content,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

      case 'diary':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.diary,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      case 'moment':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.moment,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      default:
        return null;
    }
  }
}

// 兼容旧代码的别名
class XmlResponseParser extends ResponseParser {}
