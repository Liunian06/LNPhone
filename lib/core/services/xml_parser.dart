import 'package:xml/xml.dart';
import '../models/chat_model.dart';

/// XML 响应解析器
/// 解析 AI 返回的 XML 格式回复，转换为多条聊天消息
class XmlResponseParser {
  /// 解析 XML 响应
  ///
  /// 返回解析后的消息列表。如果返回空列表，表示 AI 选择沉默（不回复）
  static List<ChatMessage> parse(String xmlResponse, String messageIdPrefix) {
    print('[XML-Parser] ========== 开始解析 XML 响应 ==========');
    print('[XML-Parser] 原始响应长度: ${xmlResponse.length} 字符');

    final messages = <ChatMessage>[];
    int messageIndex = 0;

    try {
      // 先尝试提取 <output> 或 <info> 标签的内容
      String xmlToParse = xmlResponse.trim();
      print('[XML-Parser] 去除空白后长度: ${xmlToParse.length}');

      // 如果响应为空，直接返回空列表
      if (xmlToParse.isEmpty) {
        print('[XML-Parser] 响应为空，返回空列表');
        return messages;
      }

      // 检查是否包含 <info>empty message</info>
      if (xmlToParse.contains('<info>') &&
          xmlToParse.toLowerCase().contains('empty message')) {
        print('[XML-Parser] 检测到 empty message，AI 选择不回复');
        return messages; // 返回空列表，表示不回复
      }

      // 尝试提取 <output> 标签及其内容
      print('[XML-Parser] 查找 <output> 标签...');
      final outputMatch = RegExp(
        r'<output>(.*?)</output>',
        dotAll: true,
      ).firstMatch(xmlToParse);

      if (outputMatch != null) {
        print('[XML-Parser] ✓ 找到 <output> 标签');
        // 找到了 output 标签，只解析这部分
        xmlToParse = '<output>${outputMatch.group(1)}</output>';
      } else {
        print('[XML-Parser] ⚠️ 未找到 <output> 标签，检查是否有裸露的消息标签...');
        // 没找到 output 标签，检查是否有裸露的标签（没有 output 包装）
        // 如果有任何已知的消息标签，尝试包装它们
        final knownTags = [
          'words',
          'action',
          'thought',
          'state',
          'emoji',
          'location',
          'redpacket',
          'transfer',
          'product',
          'link',
          'note',
          'anniversary',
          'memory',
          'diary',
          'moment',
        ];

        bool hasKnownTags = false;
        String foundTag = '';
        for (final tag in knownTags) {
          if (xmlToParse.contains('<$tag>') || xmlToParse.contains('<$tag ')) {
            hasKnownTags = true;
            foundTag = tag;
            break;
          }
        }

        if (!hasKnownTags) {
          print('[XML-Parser] ⚠️ 未找到任何已知标签，作为纯文本消息处理');
          // 没有找到任何已知标签，作为普通文本消息返回
          // 只有当内容不为空时才添加
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
            print('[XML-Parser] ✓ 添加纯文本消息');
          }
          return messages;
        }

        print('[XML-Parser] ✓ 找到已知标签: $foundTag，添加 <output> 包装');
        // 有已知标签但没有 output 包装，尝试包装它们
        xmlToParse = '<output>$xmlToParse</output>';
      }

      // 解析 XML
      print('[XML-Parser] 开始解析 XML 文档...');
      final document = XmlDocument.parse(xmlToParse);
      final outputElement = document.findElements('output').firstOrNull;

      if (outputElement == null) {
        print('[XML-Parser] ❌ 解析后未找到 output 元素，返回原始文本');
        // 理论上不应该到这里
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

      print('[XML-Parser] ✓ XML 解析成功，开始遍历子元素...');
      // 遍历所有子元素，按顺序解析
      for (final element in outputElement.children) {
        if (element is! XmlElement) continue;

        final tagName = element.name.local.toLowerCase();
        final content = element.innerText.trim();
        print('[XML-Parser] 处理标签: <$tagName>, 内容长度: ${content.length}');

        if (content.isEmpty && !_requiresEmptyContent(tagName)) {
          print('[XML-Parser] 跳过空内容标签: $tagName');
          continue;
        }

        final message = _parseElement(
          tagName,
          content,
          element,
          '$messageIdPrefix-$messageIndex',
        );

        if (message != null) {
          messages.add(message);
          messageIndex++;
          print('[XML-Parser] ✓ 添加消息: type=${message.type}, id=${message.id}');
        } else {
          print('[XML-Parser] ⚠️ 标签 $tagName 未生成消息（可能是不支持的类型）');
        }
      }

      print('[XML-Parser] ========== 解析完成，共 ${messages.length} 条消息 ==========');
    } catch (e, stackTrace) {
      print('[XML-Parser] ❌ XML 解析异常: $e');
      print('[XML-Parser] ❌ 堆栈跟踪: $stackTrace');
      print('[XML-Parser] 将原始文本作为普通消息返回');
      // XML 解析失败，将原始文本作为普通消息返回
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
        print('[XML-Parser] ✓ 添加回退消息');
      }
    }

    return messages;
  }

  /// 判断标签是否允许空内容
  static bool _requiresEmptyContent(String tagName) {
    return ['state', 'emoji', 'location'].contains(tagName);
  }

  /// 解析单个元素为消息
  static ChatMessage? _parseElement(
    String tagName,
    String content,
    XmlElement element,
    String messageId,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    switch (tagName) {
      // ========== 基础消息类型 ==========
      case 'words':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.words,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      case 'action':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.action,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      case 'thought':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.thought,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      case 'state':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.state,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      // ========== 多媒体消息类型 ==========
      case 'emoji':
        return null; // 暂时不支持表情包

      case 'location':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.location,
          content: content,
          timestamp: timestamp,
          isRead: false,
        );

      // ========== 资金往来类型 ==========
      case 'redpacket':
        final message = element.getAttribute('message') ?? '';
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.redpacket,
          content: content, // 金额
          timestamp: timestamp,
          metadata: {'message': message},
          isRead: false,
        );

      case 'transfer':
        final message = element.getAttribute('message') ?? '';
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.transfer,
          content: content, // 金额
          timestamp: timestamp,
          metadata: {'message': message},
          isRead: false,
        );

      // ========== 分享类型 ==========
      case 'product':
        final name = element.getAttribute('name') ?? '';
        final price = element.getAttribute('price') ?? '';
        final image = element.getAttribute('image');
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.product,
          content: content, // 商品描述
          timestamp: timestamp,
          metadata: {
            'name': name,
            'price': price,
            if (image != null) 'image': image,
          },
          isRead: false,
        );

      case 'link':
        final title = element.getAttribute('title') ?? '';
        final url = element.getAttribute('url') ?? '';
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.link,
          content: content, // 链接描述
          timestamp: timestamp,
          metadata: {'title': title, 'url': url},
          isRead: false,
        );

      case 'note':
        final title = element.getAttribute('title') ?? '';
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.note,
          content: content, // 备忘详细内容
          timestamp: timestamp,
          metadata: {'title': title},
          isRead: false,
        );

      case 'anniversary':
        final id = element.getAttribute('id') ?? '';
        final title = element.getAttribute('title') ?? '';
        final days = element.getAttribute('days') ?? '';
        final label = element.getAttribute('label') ?? '';
        final date = element.getAttribute('date') ?? '';
        final background = element.getAttribute('background');
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.anniversary,
          content: content, // 祝福语或感想
          timestamp: timestamp,
          metadata: {
            'anniversary_id': id,
            'title': title,
            'days': days,
            'label': label,
            'date': date,
            if (background != null) 'background': background,
          },
          isRead: false,
        );

      // ========== 生活轨迹类型 ==========
      case 'memory':
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.memory,
          content: content,
          timestamp: timestamp,
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
        return null; // 未知标签，跳过
    }
  }
}
