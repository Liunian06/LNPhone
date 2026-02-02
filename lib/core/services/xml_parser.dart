import 'dart:convert';
import 'package:xml/xml.dart';
import '../models/chat_model.dart';
import 'image_generation_service.dart';
import '../database/database.dart';
import '../providers/regex_settings_provider.dart';
import '../utils/storage_utils.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 响应解析器
/// 解析 AI 返回的 JSON 或 XML 格式回复，转换为多条聊天消息
/// 兼容旧的 XML 格式，但优先支持 JSON 格式
class ResponseParser {
  /// 解析响应
  ///
  /// [simpleIdToRealId] - 简化ID到真实ID的映射表，用于将AI回复中的简化ID转换回真实ID
  /// 返回解析后的消息列表。如果返回空列表，表示 AI 选择沉默（不回复）
  static Future<List<ChatMessage>> parse(
    String rawResponse,
    String messageIdPrefix, {
    Map<String, String>? simpleIdToRealId,
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId, // 传入独立生图 API 预设 ID
    String? imageStylePresetId, // 传入独立生图风格预设 ID
    RegexSettingsProvider? regexProvider,
  }) async {
    print('[ResponseParser] ========== 开始解析响应 ==========');
    print('[ResponseParser] 原始响应长度: ${rawResponse.length} 字符');

    String cleanResponse = rawResponse.trim();

    // 使用 RegexSettingsProvider 进行预处理
    if (regexProvider != null) {
      print('[ResponseParser] 使用自定义正则规则处理响应...');
      cleanResponse = regexProvider.processText(cleanResponse).trim();
    } else {
      // 兼容旧逻辑：如果没有提供 provider，使用默认的硬编码逻辑
      // 1. 尝试去除 Markdown 代码块标记
      final jsonCodeBlockRegex = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$',
          caseSensitive: false, multiLine: false);
      final match = jsonCodeBlockRegex.firstMatch(cleanResponse);
      if (match != null) {
        print('[ResponseParser] 检测到 Markdown 代码块，提取内容...');
        cleanResponse = match.group(1)!.trim();
      }
    }

    // 2. 尝试解析为 JSON
    if (cleanResponse.startsWith('[') || cleanResponse.startsWith('{')) {
      try {
        print('[ResponseParser] 尝试解析为 JSON...');
        return await _parseJson(cleanResponse, messageIdPrefix,
            simpleIdToRealId: simpleIdToRealId,
            enableTextToImage: enableTextToImage,
            enableEmoji: enableEmoji,
            imageApiPresetId: imageApiPresetId,
            imageStylePresetId: imageStylePresetId);
      } catch (e) {
        print('[ResponseParser] ⚠️ JSON 解析失败: $e');

        // 如果使用了 provider，说明已经经过了正则处理，这里不再重复硬编码的修复逻辑
        // 除非 provider 为空（兼容旧逻辑）
        if (regexProvider == null) {
          // 尝试修复常见的 JSON 格式错误
          String fixedJson = cleanResponse;
          bool modified = false;

          // 1. 修复缺少逗号的情况 (}{ -> },{)
          final missingCommaRegex = RegExp(r'\}\s*\{');
          if (missingCommaRegex.hasMatch(fixedJson)) {
            print('[ResponseParser] 检测到可能的 JSON 格式错误 (缺少逗号)，尝试修复...');
            fixedJson = fixedJson.replaceAll(missingCommaRegex, '},{');
            modified = true;
          }

          // 2. 确保如果是多个对象但没有数组包裹，则包裹它
          // 如果包含 "}," 或者修复后的 "}," 且不以 "[" 开头
          if (!fixedJson.startsWith('[') && fixedJson.contains('},')) {
            print('[ResponseParser] 检测到多个 JSON 对象但缺少数组包裹，尝试包裹...');
            fixedJson = '[$fixedJson]';
            modified = true;
          }

          if (modified) {
            try {
              print('[ResponseParser] 尝试解析修复后的 JSON...');
              return await _parseJson(fixedJson, messageIdPrefix,
                  simpleIdToRealId: simpleIdToRealId,
                  enableTextToImage: enableTextToImage,
                  enableEmoji: enableEmoji,
                  imageApiPresetId: imageApiPresetId,
                  imageStylePresetId: imageStylePresetId);
            } catch (e2) {
              print('[ResponseParser] ⚠️ 修复后的 JSON 解析仍然失败: $e2');
            }
          }

          // 尝试修复其他常见的 JSON 错误
          try {
            String fixedJson = cleanResponse;
            bool modified = false;

            // 1. 修复尾随逗号 (Trailing commas)
            if (RegExp(r',\s*([\]}])').hasMatch(fixedJson)) {
              fixedJson = fixedJson.replaceAllMapped(
                  RegExp(r',\s*([\]}])'), (match) => match.group(1)!);
              modified = true;
            }

            if (modified) {
              print('[ResponseParser] 尝试解析进一步修复的 JSON...');
              return await _parseJson(fixedJson, messageIdPrefix,
                  simpleIdToRealId: simpleIdToRealId,
                  enableTextToImage: enableTextToImage,
                  enableEmoji: enableEmoji,
                  imageApiPresetId: imageApiPresetId,
                  imageStylePresetId: imageStylePresetId);
            }
          } catch (e3) {
            print('[ResponseParser] ⚠️ 进一步修复后的 JSON 解析仍然失败: $e3');
          }

          // 3. 尝试去除所有反斜杠 (针对某些过度转义的情况)
          if (cleanResponse.contains(r'\')) {
            try {
              print('[ResponseParser] 尝试去除所有反斜杠后解析...');
              final noBackslashJson = cleanResponse.replaceAll(r'\', '');
              return await _parseJson(noBackslashJson, messageIdPrefix,
                  simpleIdToRealId: simpleIdToRealId,
                  enableTextToImage: enableTextToImage,
                  enableEmoji: enableEmoji,
                  imageApiPresetId: imageApiPresetId,
                  imageStylePresetId: imageStylePresetId);
            } catch (e4) {
              print('[ResponseParser] ⚠️ 去除反斜杠后的 JSON 解析仍然失败: $e4');
            }
          }

          // 4. 尝试去除所有空格 (针对包含大量空格的情况)
          if (cleanResponse.contains(' ')) {
            try {
              print('[ResponseParser] 尝试去除所有空格后解析...');
              final noSpaceJson = cleanResponse.replaceAll(' ', '');
              return await _parseJson(noSpaceJson, messageIdPrefix,
                  simpleIdToRealId: simpleIdToRealId,
                  enableTextToImage: enableTextToImage,
                  enableEmoji: enableEmoji,
                  imageApiPresetId: imageApiPresetId,
                  imageStylePresetId: imageStylePresetId);
            } catch (e5) {
              print('[ResponseParser] ⚠️ 去除空格后的 JSON 解析仍然失败: $e5');
            }
          }
        }

        // 如果看起来像 JSON 但解析失败，直接抛出异常，触发重试
        // 不再回退到 XML 解析，因为这通常会导致错误的文本输出
        throw FormatException('JSON 解析失败，且无法修复: $e');
      }
    }

    // 3. 回退到 XML 解析
    return await _parseXml(rawResponse, messageIdPrefix,
        simpleIdToRealId: simpleIdToRealId,
        enableTextToImage: enableTextToImage,
        enableEmoji: enableEmoji,
        imageApiPresetId: imageApiPresetId,
        imageStylePresetId: imageStylePresetId,
        regexProvider: regexProvider);
  }

  static Future<List<ChatMessage>> _parseJson(
    String jsonString,
    String messageIdPrefix, {
    Map<String, String>? simpleIdToRealId,
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId,
    String? imageStylePresetId,
  }) async {
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

      final parsedMessages = await _parseJsonItem(
        item,
        '$messageIdPrefix-$messageIndex',
        simpleIdToRealId: simpleIdToRealId,
        enableTextToImage: enableTextToImage,
        enableEmoji: enableEmoji,
        imageApiPresetId: imageApiPresetId,
        imageStylePresetId: imageStylePresetId,
      );

      for (final message in parsedMessages) {
        messages.add(message);
        print(
            '[ResponseParser] ✓ 添加消息: type=${message.type}, id=${message.id}');
      }
      messageIndex++;
    }

    print(
        '[ResponseParser] ========== JSON 解析完成，共 ${messages.length} 条消息 ==========');
    return messages;
  }

  /// 解析单个 JSON 项，返回消息列表（支持多图输出）
  static Future<List<ChatMessage>> _parseJsonItem(
    Map<String, dynamic> item,
    String messageId, {
    Map<String, String>? simpleIdToRealId,
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId,
    String? imageStylePresetId,
  }) async {
    final typeStr = item['type'] as String?;

    // content 可能是 String 或 List（如 options 类型）
    String content;
    final contentValue = item['content'];
    if (contentValue is String) {
      content = contentValue;
    } else if (contentValue is List) {
      // 对于 options 等类型，content 是数组，在 switch 中单独处理
      content = '';
    } else if (contentValue != null) {
      content = contentValue.toString();
    } else {
      content = '';
    }

    // 不再自动删除内容中的空格，由正则规则控制

    final timestamp = StorageUtils.getUniqueTimestamp();

    if (typeStr == null) return [];

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
        if (!enableEmoji) {
          print(
              '[ResponseParser] ⚠️ 检测到表情包消息，但表情包功能未启用 (enableEmoji=false)，已忽略');
          return [];
        }
        type = MessageType.emoji;
        // 尝试从 content 中提取 ID，如果 content 本身就是 ID
        if (content.startsWith('emoji-id-')) {
          metadata['emoji_id'] = content;
        } else if (item.containsKey('id')) {
          metadata['emoji_id'] = item['id'];
        }
        break;
      case 'image':
        if (!enableTextToImage) {
          print(
              '[ResponseParser] ⚠️ 检测到图片消息，但文生图功能未启用 (enableTextToImage=false)，已忽略');
          return []; // 如果未启用文生图，则忽略图片消息
        }
        // 触发图片生成
        final includeCharacter = item['includeCharacter'] as bool? ?? false;
        final includeUser = item['includeUser'] as bool? ?? false;

        final imageResult = await ImageGenerationService().generateImage(
          content,
          null, // 不再传入硬编码的风格提示词，由 ImageGenerationService 根据预设 ID 获取
          includeCharacter: includeCharacter,
          includeUser: includeUser,
          imageApiPresetId: imageApiPresetId,
          imageStylePresetId: imageStylePresetId,
        );

        if (imageResult != null) {
          final paths = imageResult['paths'] as List<dynamic>?;
          final originalPrompt = item['content'] as String? ?? '';

          // 如果有多张图片，返回多条消息
          if (paths != null && paths.length > 1) {
            final imageMessages = <ChatMessage>[];
            for (int i = 0; i < paths.length; i++) {
              final imagePath = paths[i] as String;
              final imageMetadata = Map<String, dynamic>.from(metadata);
              imageMetadata['original_prompt'] = originalPrompt;
              imageMetadata['image_gen_metadata'] = imageResult;
              imageMetadata['image_index'] = i;
              imageMetadata['total_images'] = paths.length;

              imageMessages.add(ChatMessage(
                id: '$messageId-img$i',
                isMe: false,
                type: MessageType.image,
                content: imagePath,
                timestamp: StorageUtils.getUniqueTimestamp(),
                metadata: imageMetadata,
                isRead: false,
              ));
            }
            return imageMessages;
          }

          // 单张图片，正常处理
          content = imageResult['path'] as String;
          metadata['original_prompt'] = originalPrompt;
          metadata['image_gen_metadata'] = imageResult;
          type = MessageType.image;
        } else {
          content = '图片生成失败';
          type = MessageType.words; // 降级为文本
          metadata['original_prompt'] = item['content'] as String? ?? '';
        }
        break;
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
      case 'moment_comment':
        type = MessageType.momentComment;
        break;
      case 'moment_like':
        type = MessageType.momentLike;
        break;

      // ========== 沉浸模式专用类型 ==========
      case 'scene':
        type = MessageType.scene;
        // 提取场景元数据（不在此处生成图片，由 ScenarioProvider 统一处理）
        final generate = item['generate'] as bool? ?? true;
        final location = item['location'] as String?;
        final time = item['time'] as String?;
        final weather = item['weather'] as String?;

        metadata['generate'] = generate;
        if (location != null) metadata['location'] = location;
        if (time != null) metadata['time'] = time;
        if (weather != null) metadata['weather'] = weather;
        // 场景生图由 ScenarioProvider._handleSceneMessage() 统一处理
        // 这里只存储原始描述
        metadata['original_prompt'] = content;
        break;

      case 'narration':
        type = MessageType.narration;
        break;

      case 'options':
        type = MessageType.options;
        // options 的 content 是一个数组，直接从 item 获取原始值
        final optionsList = contentValue;
        if (optionsList is List) {
          metadata['options'] = optionsList;
          // 将选项转为可读文本用于 content
          content = optionsList.map((o) {
            if (o is Map) {
              return o['text'] ?? '';
            }
            return o.toString();
          }).join(' / ');
        }
        break;

      default:
        return [];
    }

    // 特殊处理 accept/reject/moment_comment/moment_like 的 target_id
    if (type == MessageType.acceptRedpacket ||
        type == MessageType.rejectRedpacket ||
        type == MessageType.acceptTransfer ||
        type == MessageType.rejectTransfer ||
        type == MessageType.momentComment ||
        type == MessageType.momentLike) {
      if (metadata.containsKey('reply_id')) {
        metadata['target_id'] = metadata['reply_id'];
        metadata.remove('reply_id');
      }
    }

    return [
      ChatMessage(
        id: messageId,
        isMe: false,
        type: type,
        content: content,
        timestamp: timestamp,
        metadata: metadata.isEmpty ? null : metadata,
        isRead: false,
      )
    ];
  }

  static Future<List<ChatMessage>> _parseXml(
    String xmlResponse,
    String messageIdPrefix, {
    Map<String, String>? simpleIdToRealId,
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId,
    String? imageStylePresetId,
    RegexSettingsProvider? regexProvider,
  }) async {
    print('[ResponseParser] (XML) 开始解析 XML...');
    final messages = <ChatMessage>[];
    int messageIndex = 0;

    try {
      String xmlToParse = xmlResponse.trim();

      // 如果使用了 provider，说明已经经过了正则处理
      if (regexProvider != null) {
        // 已经处理过了，直接使用
      } else {
        // 兼容旧逻辑
        final outputMatch = RegExp(
          r'<output>(.*?)</output>',
          dotAll: true,
        ).firstMatch(xmlToParse);

        if (outputMatch != null) {
          xmlToParse = '<output>${outputMatch.group(1)}</output>';
        }
      }

      if (xmlToParse.isEmpty) {
        return messages;
      }

      if (xmlToParse.contains('<info>') &&
          xmlToParse.toLowerCase().contains('empty message')) {
        return messages;
      }

      // 检查是否包含 output 标签，如果不包含，尝试自动包裹
      if (!xmlToParse.contains('<output>')) {
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
                timestamp: StorageUtils.getUniqueTimestamp(),
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
              timestamp: StorageUtils.getUniqueTimestamp(),
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

        final message = await _parseXmlElement(
          tagName,
          content,
          element,
          '$messageIdPrefix-$messageIndex',
          simpleIdToRealId: simpleIdToRealId,
          enableTextToImage: enableTextToImage,
          enableEmoji: enableEmoji,
          imageApiPresetId: imageApiPresetId,
          imageStylePresetId: imageStylePresetId,
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
            timestamp: StorageUtils.getUniqueTimestamp(),
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

  static Future<ChatMessage?> _parseXmlElement(
    String tagName,
    String content,
    XmlElement element,
    String messageId, {
    Map<String, String>? simpleIdToRealId,
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId,
    String? imageStylePresetId,
  }) async {
    // 不再自动删除内容中的空格，由正则规则控制

    final timestamp = StorageUtils.getUniqueTimestamp();

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
        // 默认校验规则
        bool isValidId = RegExp(r'^\d{4}$').hasMatch(idAttr);

        // 如果有自定义规则，尝试查找 ID 校验规则
        // 注意：这里我们无法直接访问 provider，因为 _parseXmlElement 是静态方法且未传递 provider
        // 但通常 ID 校验是硬编码的逻辑，如果需要自定义，可以在 provider 中添加一个专门的方法
        // 目前保持原样，因为 ID 格式通常是固定的

        if (isValidId) {
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
        if (!enableEmoji) {
          print(
              '[ResponseParser] ⚠️ (XML) 检测到表情包消息，但表情包功能未启用 (enableEmoji=false)，已忽略');
          return null;
        }
        final emojiId = element.getAttribute('id');
        if (emojiId != null && emojiId.isNotEmpty) {
          metadata['emoji_id'] = emojiId;
        }
        return ChatMessage(
          id: messageId,
          isMe: false,
          type: MessageType.emoji,
          content: content, // 这里 content 可能是含义，也可能是空的
          timestamp: timestamp,
          metadata: metadata,
          isRead: false,
        );

      case 'image':
        if (!enableTextToImage) {
          print(
              '[ResponseParser] ⚠️ (XML) 检测到图片消息，但文生图功能未启用 (enableTextToImage=false)，已忽略');
          return null; // 如果未启用文生图，则忽略图片消息
        }
        // 触发图片生成
        final includeCharacterStr = element.getAttribute('includeCharacter');
        final includeUserStr = element.getAttribute('includeUser');
        final includeCharacter = includeCharacterStr?.toLowerCase() == 'true';
        final includeUser = includeUserStr?.toLowerCase() == 'true';

        final imageResult = await ImageGenerationService().generateImage(
          content,
          null, // 不再传入硬编码的风格提示词，由 ImageGenerationService 根据预设 ID 获取
          includeCharacter: includeCharacter,
          includeUser: includeUser,
          imageApiPresetId: imageApiPresetId,
          imageStylePresetId: imageStylePresetId,
        );
        String finalContent = content;
        MessageType finalType = MessageType.image;

        if (imageResult != null) {
          finalContent = imageResult['path'] as String;
          metadata['original_prompt'] = content;
          // 将生图元数据存入消息元数据
          metadata['image_gen_metadata'] = imageResult;
        } else {
          finalContent = '图片生成失败';
          finalType = MessageType.words;
          metadata['original_prompt'] = content;
        }

        return ChatMessage(
          id: messageId,
          isMe: false,
          type: finalType,
          content: finalContent,
          timestamp: timestamp,
          metadata: metadata.isEmpty ? null : metadata,
          isRead: false,
        );

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
