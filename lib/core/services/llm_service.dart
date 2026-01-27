import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/api_preset.dart';
import '../models/chat_model.dart';
import '../models/contact_model.dart';
import '../models/api_log.dart';
import '../models/prompt_config.dart';
import '../utils/image_utils.dart';
import 'xml_parser.dart';
import 'api_log_service.dart';
import 'app_log_service.dart';
import '../providers/regex_settings_provider.dart';

class LlmRetryException implements Exception {
  final List<String> errors;
  LlmRetryException(this.errors);

  @override
  String toString() => errors.join('\n');
}

class LlmService {
  /// 生成回复，返回解析后的消息列表
  static Future<List<ChatMessage>> generateResponse({
    required ApiPreset apiPreset,
    required PromptConfig promptConfig,
    required List<ChatMessage> history,
    required ContactRole role,
    required ContactMe me,
    required String messageIdPrefix,
    List<String> worldInfos = const [],
    List<String> textPresets = const [],
    List<String> roleMemories = const [], // 角色记忆列表
    List<String> availableEmojis = const [], // 可用表情列表 (格式: id:meaning)
    bool enableTextToImage = false,
    bool enableEmoji = true,
    String? imageApiPresetId, // 传入独立生图 API 预设 ID
    RegexSettingsProvider? regexProvider,
  }) async {
    print('[LLM] ========== 开始生成回复 ==========');
    print('[LLM] API Provider: ${apiPreset.provider.name}');
    print('[LLM] Model: ${apiPreset.model}');
    print('[LLM] Base URL: ${apiPreset.baseUrl}');
    print('[LLM] 历史消息数量: ${history.length}');

    // 记录详细的调用参数
    await AppLogService.log(
      '开始生成回复',
      category: 'LLM',
      level: LogLevel.info,
      data: {
        'provider': apiPreset.provider.name,
        'model': apiPreset.model,
        'baseUrl': apiPreset.baseUrl,
        'historyCount': history.length,
        'roleName': role.name,
        'userName': me.name,
      },
    );

    // 记录 API 调用开始日志
    await AppLogService.logApiCallStart(
      provider: apiPreset.provider.name,
      model: apiPreset.model,
      endpoint: apiPreset.baseUrl.isEmpty
          ? (apiPreset.provider == ApiProvider.openai
              ? 'https://api.openai.com/v1'
              : 'https://generativelanguage.googleapis.com')
          : apiPreset.baseUrl,
    );

    print('[LLM] 构建系统提示词...');
    final systemPrompt = _buildSystemPrompt(
      promptConfig,
      role,
      me,
      worldInfos,
      textPresets,
      history,
      roleMemories,
      availableEmojis,
    );
    print('[LLM] 系统提示词长度: ${systemPrompt.length} 字符');

    // 记录系统提示词
    await AppLogService.log(
      '系统提示词构建完成',
      category: 'LLM',
      level: LogLevel.debug,
      data: {'systemPrompt': systemPrompt},
    );

    print('[LLM] 构建消息列表（上下文长度: ${promptConfig.contextLength}）...');
    // 使用简化ID构建消息，并获取ID映射表
    final buildResult = await _buildMessagesWithSimpleIds(
      history,
      systemPrompt,
      promptConfig.contextLength,
    );
    final messages = buildResult['messages'] as List<Map<String, dynamic>>;
    final idMapping = buildResult['idMapping'] as Map<String, String>;
    print('[LLM] 消息列表构建完成，共 ${messages.length} 条');
    print('[LLM] ID映射表: $idMapping');

    // 记录请求消息
    await AppLogService.log(
      '请求消息构建完成',
      category: 'LLM',
      level: LogLevel.debug,
      data: {
        'messages': messages,
        'idMapping': idMapping,
      },
    );

    for (var i = 0; i < messages.length; i++) {
      // 仅打印第一条（通常是系统提示词）和最后一条消息，中间的省略
      if (i > 0 && i < messages.length - 1) {
        if (i == 1) {
          print('[LLM] ... 省略 ${messages.length - 2} 条中间历史消息 ...');
        }
        continue;
      }

      final role = messages[i]['role'];
      final rawContent = messages[i]['content'];
      String preview;
      if (rawContent is String) {
        preview = rawContent.length > 100
            ? '${rawContent.substring(0, 100)}...'
            : rawContent;
      } else if (rawContent is List) {
        preview = '[图片/多媒体内容]';
      } else {
        preview = rawContent?.toString() ?? '[空内容]';
      }
      print('[LLM] Request Msg $i ($role): $preview');
    }

    List<String> errorLogs = [];
    final stopwatch = Stopwatch()..start();

    // 重试机制：最多尝试3次
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        String rawResponse;
        Map<String, dynamic>? responseData;

        print('[LLM] 准备调用 API (第 $attempt 次尝试)...');
        if (apiPreset.provider == ApiProvider.openai) {
          print('[LLM] 调用 OpenAI API...');
          final result = await _callOpenAIWithMetadata(apiPreset, messages);
          rawResponse = result['content'] as String;
          responseData = result;
        } else {
          print('[LLM] 调用 Gemini API...');
          final result = await _callGeminiWithMetadata(apiPreset, messages);
          rawResponse = result['content'] as String;
          responseData = result;
        }

        if (rawResponse.trim().isEmpty) {
          throw Exception('API返回内容为空');
        }

        print('[LLM] ✓ API 调用成功');
        print('[LLM] 原始响应长度: ${rawResponse.length} 字符');

        // 记录原始响应
        await AppLogService.log(
          '收到 API 原始响应',
          category: 'LLM',
          level: LogLevel.debug,
          data: {'rawResponse': rawResponse},
        );

        if (rawResponse.isNotEmpty) {
          print('[LLM] 原始响应内容: $rawResponse');
        } else {
          print('[LLM] 原始响应内容: [空]');
        }

        // 解析响应为消息列表，传入ID映射表用于将简化ID转换回真实ID
        // 将解析逻辑移入重试循环，以便在解析失败时也能重试
        print('[LLM] 解析响应...');
        final parsedMessages = await ResponseParser.parse(
          rawResponse,
          messageIdPrefix,
          simpleIdToRealId: idMapping,
          enableTextToImage: enableTextToImage,
          enableEmoji: enableEmoji,
          imageApiPresetId: imageApiPresetId,
          regexProvider: regexProvider,
        );
        print('[LLM] ✓ 解析成功，得到 ${parsedMessages.length} 条消息');

        // 记录解析结果
        await AppLogService.log(
          '响应解析完成',
          category: 'LLM',
          level: LogLevel.info,
          data: {
            'parsedMessages': parsedMessages
                .map((m) => {
                      'type': m.type.toString(),
                      'content': m.content,
                      'metadata': m.metadata,
                    })
                .toList(),
          },
        );

        for (var i = 0; i < parsedMessages.length; i++) {
          final msgContent = parsedMessages[i].content;
          final contentPreview = msgContent.isEmpty
              ? '[空]'
              : (msgContent.length > 50
                  ? '${msgContent.substring(0, 50)}...'
                  : msgContent);
          print(
              '[LLM] 消息 $i: type=${parsedMessages[i].type}, content=$contentPreview');
        }

        // 记录成功的API调用
        stopwatch.stop();
        final durationSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;

        await _logApiCall(
          apiPreset: apiPreset,
          responseData: responseData,
          durationSeconds: durationSeconds,
          error: null,
        );

        // 记录 API 调用成功日志
        await AppLogService.logApiCallSuccess(
          provider: apiPreset.provider.name,
          model: apiPreset.model,
          durationSeconds: durationSeconds,
          inputTokens: responseData?['inputTokens'] as int?,
          outputTokens: responseData?['outputTokens'] as int?,
        );

        print('[LLM] ========== 生成回复完成 ==========');
        return parsedMessages;
      } catch (e, stackTrace) {
        final errorMsg = '第 $attempt 次请求或解析失败: $e';
        print('[LLM] ❌ $errorMsg');
        print('[LLM] ❌ 堆栈跟踪: $stackTrace');
        errorLogs.add(errorMsg);

        if (attempt == 3) {
          print('[LLM] ❌ 3次尝试均失败，抛出异常');

          // 记录失败的API调用
          stopwatch.stop();
          final durationSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;

          await _logApiCall(
            apiPreset: apiPreset,
            responseData: null,
            durationSeconds: durationSeconds,
            error: errorLogs.join('; '),
          );

          // 记录 API 调用失败日志
          await AppLogService.logApiCallError(
            provider: apiPreset.provider.name,
            model: apiPreset.model,
            error: errorLogs.join('; '),
            durationSeconds: durationSeconds,
          );

          throw LlmRetryException(errorLogs);
        }
        // 等待一小段时间再重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    throw LlmRetryException(errorLogs);
  }

  static String _buildSystemPrompt(
    PromptConfig config,
    ContactRole role,
    ContactMe me,
    List<String> worldInfos,
    List<String> textPresets,
    List<ChatMessage> history,
    List<String> roleMemories,
    List<String> availableEmojis,
  ) {
    final buffer = StringBuffer();

    // 1. Reality Prompt (Moved to top)
    if (config.enableRealityPrompt && config.realityPrompt.isNotEmpty) {
      // 强制使用 UTC+8 时间
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final timeStr = DateFormat('HH:mm').format(now);
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final reality = config.realityPrompt
          .replaceAll('{time}', timeStr)
          .replaceAll('{date}', dateStr);
      buffer.writeln(reality);
      buffer.writeln(); // Add a newline after reality prompt
    }

    // 2. Roleplay Prompt
    if (config.roleplayPrompt.isNotEmpty) {
      buffer.writeln(config.roleplayPrompt);
    }

    // 3. World Info (世界书)
    if (worldInfos.isNotEmpty) {
      buffer.writeln('\n[World Info]');
      for (final info in worldInfos) {
        buffer.writeln(info);
      }
    }

    // 4. Presets (预设)
    if (textPresets.isNotEmpty) {
      buffer.writeln('\n[Style Presets]');
      for (final preset in textPresets) {
        buffer.writeln(preset);
      }
    }

    // Personas Prompt
    buffer.writeln('\n[Character Info]');
    buffer.writeln('Name: ${role.name}');
    if (role.description.isNotEmpty) {
      buffer.writeln('Description: ${role.description}');
    }

    buffer.writeln('\n[User Info]');
    buffer.writeln('Name: ${me.name}');
    if (me.info.isNotEmpty) {
      buffer.writeln('Info: ${me.info}');
    }

    // 7. Role Memories (角色记忆)
    if (roleMemories.isNotEmpty) {
      buffer.writeln('\n[Role Memories]');
      buffer.writeln(
          'The following are important memories that ${role.name} has accumulated. Use these to maintain consistency and reference past events when relevant:');
      for (final memory in roleMemories) {
        buffer.writeln('- $memory');
      }
    }

    // 8. Available Emojis (可用表情)
    if (availableEmojis.isNotEmpty) {
      buffer.writeln('\n[Available Emojis]');
      buffer.writeln(
          'You can use the following emojis to express emotions. Use the <emoji> tag with the emoji ID.');
      buffer
          .writeln('Format: <emoji id="emoji-id-xxxxx">simple content</emoji>');
      buffer.writeln('List (Format: {id}: {simple content}: {raw content}):');
      for (final emoji in availableEmojis) {
        buffer.writeln(emoji);
      }
    }

    // Text2Image Prompt (不再使用 config 中的 text2image_prompt，而是直接从 assets 读取)
    // 但由于 _buildSystemPrompt 是同步方法，无法直接读取 assets
    // 考虑到 text2image_prompt 主要用于生图时的 prompt 拼接，
    // 在 system prompt 中是否需要包含它取决于是否希望 LLM 知道生图风格。
    // 如果需要，应该在调用 _buildSystemPrompt 之前读取并传入，或者改为异步方法。
    // 鉴于目前架构，我们暂时保留 config.text2ImagePrompt 的使用，
    // 但在 PromptSettingsProvider 中我们已经将其强制设为从 assets 读取的内容（虽然是异步的，但在初始化时完成）。
    // 不过，为了确保一致性，如果 config.text2ImagePrompt 为空（例如初始化未完成），
    // 我们可能需要一种机制。
    // 实际上，PromptSettingsProvider 初始化时会加载 assets 到 _text2ImagePrompt。
    // 所以这里直接使用 config.text2ImagePrompt 应该是安全的，前提是 Provider 已初始化。

    if (config.text2ImagePrompt.isNotEmpty) {
      buffer.writeln('\n[Image Generation Style]');
      buffer.writeln(config.text2ImagePrompt);
    }

    // Add Appearance Info for Image Generation
    if (role.appearance != null && role.appearance!.isNotEmpty) {
      buffer.writeln('\n[Character Appearance]');
      buffer.writeln(role.appearance);
    }
    if (me.appearance != null && me.appearance!.isNotEmpty) {
      buffer.writeln('\n[User Appearance]');
      buffer.writeln(me.appearance);
    }

    return buffer.toString();
  }

  /// 使用简化ID构建消息列表，返回消息列表和ID映射表
  /// 简化ID格式: 0001, 0002, 0003...
  /// 这样AI更容易理解和正确引用
  static Future<Map<String, dynamic>> _buildMessagesWithSimpleIds(
    List<ChatMessage> history,
    String systemPrompt,
    int contextLength,
  ) async {
    final messages = <Map<String, dynamic>>[];
    // 简化ID -> 真实ID 的映射表
    final idMapping = <String, String>{};

    // System Message
    messages.add({'role': 'system', 'content': systemPrompt});

    // Chat History (Take last N)
    final start = (history.length - contextLength).clamp(0, history.length);
    final recentHistory = history.sublist(start);

    // 为每条消息分配简化ID
    int simpleIdCounter = 1;
    final realIdToSimpleId = <String, String>{};

    for (final msg in recentHistory) {
      final simpleId = simpleIdCounter.toString().padLeft(4, '0');
      realIdToSimpleId[msg.id] = simpleId;
      idMapping[simpleId] = msg.id;
      simpleIdCounter++;
    }

    for (final msg in recentHistory) {
      final simpleId = realIdToSimpleId[msg.id]!;

      // 构建JSON格式的消息内容，使用简化ID
      final jsonContent = _buildJsonMessageContentWithSimpleId(
        msg,
        simpleId,
        realIdToSimpleId,
      );

      if (msg.type == MessageType.image || msg.type == MessageType.moment) {
        // 处理图片消息或朋友圈（可能包含多张图片）
        final List<String> images = [];
        if (msg.type == MessageType.image) {
          images.add(msg.content);
        } else if (msg.metadata != null &&
            msg.metadata!.containsKey('mediaItems')) {
          final mediaItems = msg.metadata!['mediaItems'] as List;
          for (var item in mediaItems) {
            if (item is Map && item['type'] == 'image') {
              images.add(item['url']);
            }
          }
        }

        if (images.isNotEmpty) {
          final List<Map<String, String>> imageDataList = [];
          for (var path in images) {
            final base64 = await ImageUtils.imageToBase64(path);
            if (base64 != null) {
              imageDataList.add({
                'data': base64,
                'mime': ImageUtils.getMimeType(path),
              });
            }
          }

          if (imageDataList.isNotEmpty) {
            messages.add({
              'role': msg.isMe ? 'user' : 'assistant',
              'content': jsonContent,
              'images': imageDataList, // 存储多张图片
              'type': 'multi_modal',
            });
          } else {
            messages.add({
              'role': msg.isMe ? 'user' : 'assistant',
              'content': jsonContent,
              'type': 'text',
            });
          }
        } else {
          messages.add({
            'role': msg.isMe ? 'user' : 'assistant',
            'content': jsonContent,
            'type': 'text',
          });
        }
      } else {
        // 普通文本消息，使用JSON格式
        messages.add({
          'role': msg.isMe ? 'user' : 'assistant',
          'content': jsonContent,
          'type': 'text',
        });
      }
    }

    return {
      'messages': messages,
      'idMapping': idMapping,
    };
  }

  /// 将消息构建为JSON格式，使用简化ID
  static String _buildJsonMessageContentWithSimpleId(
    ChatMessage msg,
    String simpleId,
    Map<String, String> realIdToSimpleId,
  ) {
    final Map<String, dynamic> jsonMap = {
      'id': simpleId,
      'type': _getTypeNameForJson(msg.type),
      'content': msg.content,
    };

    // 处理引用消息，将引用的真实ID转换为简化ID
    if (msg.metadata != null && msg.metadata!.containsKey('quote')) {
      try {
        final quote = msg.metadata!['quote'] as Map<String, dynamic>;
        final quoteRealId = quote['id'] as String;
        // 查找引用消息的简化ID
        final quoteSimpleId = realIdToSimpleId[quoteRealId];
        if (quoteSimpleId != null) {
          jsonMap['ref'] = quoteSimpleId;
        }
      } catch (e) {
        // 忽略引用解析错误
      }
    }

    // 处理特定类型的额外属性
    if (msg.metadata != null) {
      switch (msg.type) {
        case MessageType.redpacket:
        case MessageType.transfer:
          final message = msg.metadata!['message'] as String? ?? '';
          if (message.isNotEmpty) {
            jsonMap['message'] = message;
          }
          break;
        case MessageType.product:
          final name = msg.metadata!['name'] as String? ?? '';
          final price = msg.metadata!['price'] as String? ?? '';
          if (name.isNotEmpty) jsonMap['name'] = name;
          if (price.isNotEmpty) jsonMap['price'] = price;
          break;
        case MessageType.link:
          final title = msg.metadata!['title'] as String? ?? '';
          final url = msg.metadata!['url'] as String? ?? '';
          if (title.isNotEmpty) jsonMap['title'] = title;
          if (url.isNotEmpty) jsonMap['url'] = url;
          break;
        case MessageType.note:
          final title = msg.metadata!['title'] as String? ?? '';
          if (title.isNotEmpty) jsonMap['title'] = title;
          break;
        case MessageType.momentComment:
          final replyTo = msg.metadata!['reply_to'] as String? ?? '';
          if (replyTo.isNotEmpty) jsonMap['reply_to'] = replyTo;
          // 增加 root_id 感知，让 AI 知道这条评论属于哪条朋友圈
          final postId = msg.metadata!['post_id'] as String? ?? '';
          if (postId.isNotEmpty) {
            final postSimpleId = realIdToSimpleId['v-post-$postId'];
            if (postSimpleId != null) {
              jsonMap['root_id'] = postSimpleId;
            }
          }
          break;
        case MessageType.momentLike:
          // 增加 root_id 感知，让 AI 知道这个点赞属于哪条朋友圈
          final postId = msg.metadata!['post_id'] as String? ?? '';
          if (postId.isNotEmpty) {
            final postSimpleId = realIdToSimpleId['v-post-$postId'];
            if (postSimpleId != null) {
              jsonMap['root_id'] = postSimpleId;
            }
          }
          break;
        default:
          break;
      }
    }

    return jsonEncode(jsonMap);
  }

  /// 获取消息类型对应的JSON类型名
  static String _getTypeNameForJson(MessageType type) {
    switch (type) {
      case MessageType.words:
        return 'word';
      case MessageType.action:
        return 'action';
      case MessageType.thought:
        return 'thought';
      case MessageType.state:
        return 'state';
      case MessageType.emoji:
        return 'emoji';
      case MessageType.image:
        return 'image';
      case MessageType.location:
        return 'location';
      case MessageType.redpacket:
        return 'redpacket';
      case MessageType.transfer:
        return 'transfer';
      case MessageType.acceptRedpacket:
        return 'accept';
      case MessageType.rejectRedpacket:
        return 'reject';
      case MessageType.acceptTransfer:
        return 'accept';
      case MessageType.rejectTransfer:
        return 'reject';
      case MessageType.product:
        return 'product';
      case MessageType.link:
        return 'link';
      case MessageType.note:
        return 'note';
      case MessageType.anniversary:
        return 'anniversary';
      case MessageType.memory:
        return 'memory';
      case MessageType.diary:
        return 'diary';
      case MessageType.moment:
        return 'moment';
      case MessageType.momentComment:
        return 'moment_comment';
      case MessageType.momentLike:
        return 'moment_like';
    }
  }

  /// 记录API调用日志
  static Future<void> _logApiCall({
    required ApiPreset apiPreset,
    required Map<String, dynamic>? responseData,
    required double durationSeconds,
    required String? error,
  }) async {
    try {
      final log = ApiLog(
        callTime: DateTime.now().toIso8601String(),
        provider:
            apiPreset.provider == ApiProvider.openai ? 'OpenAI' : 'Gemini',
        apiUrl: apiPreset.baseUrl.isNotEmpty
            ? apiPreset.baseUrl
            : (apiPreset.provider == ApiProvider.openai
                ? 'https://api.openai.com/v1'
                : 'https://generativelanguage.googleapis.com'),
        modelId: apiPreset.model,
        inputTokens: responseData?['inputTokens'] as int?,
        outputTokens: responseData?['outputTokens'] as int?,
        totalTokens: responseData?['totalTokens'] as int?,
        durationSeconds: durationSeconds,
        error: error,
      );

      await ApiLogService.logApiCall(log);
    } catch (e) {
      print('[LLM] ❌ 记录API日志失败: $e');
      // 日志记录失败不应影响主流程
    }
  }

  static Future<Map<String, dynamic>> _callOpenAIWithMetadata(
    ApiPreset preset,
    List<Map<String, dynamic>> messages,
  ) async {
    print('[LLM-OpenAI] 准备调用 OpenAI API');
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) baseUrl = 'https://api.openai.com/v1';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    print('[LLM-OpenAI] Base URL: $baseUrl');
    print('[LLM-OpenAI] Model: ${preset.model}');
    print('[LLM-OpenAI] Enable Thinking: ${preset.enableThinking}');

    // 转换消息格式为 OpenAI Vision 格式
    print('[LLM-OpenAI] 转换消息格式...');
    final openAIMessages = messages.map((msg) {
      if (msg['role'] == 'system') {
        return {'role': 'system', 'content': msg['content']};
      }

      if (msg['type'] == 'image') {
        return {
          'role': msg['role'],
          'content': [
            {
              'type': 'text',
              'text': msg['content'],
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:${msg['mime_type']};base64,${msg['image_data']}',
              },
            },
          ],
        };
      } else if (msg['type'] == 'multi_modal') {
        final List<Map<String, dynamic>> content = [
          {
            'type': 'text',
            'text': msg['content'],
          }
        ];
        final images = msg['images'] as List<Map<String, String>>;
        for (var img in images) {
          content.add({
            'type': 'image_url',
            'image_url': {
              'url': 'data:${img['mime']};base64,${img['data']}',
            },
          });
        }
        return {
          'role': msg['role'],
          'content': content,
        };
      } else {
        return {'role': msg['role'], 'content': msg['content']};
      }
    }).toList();
    print('[LLM-OpenAI] 消息格式转换完成，共 ${openAIMessages.length} 条');

    try {
      final url = '$baseUrl/chat/completions';
      print('[LLM-OpenAI] 请求 URL: $url');

      final requestBody = {
        'model': preset.model,
        'messages': openAIMessages,
        if (!preset.enableThinking) 'enable_thinking': false,
      };
      print('[LLM-OpenAI] 发送 HTTP POST 请求...');

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${preset.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          print('[LLM-OpenAI] ❌ 请求超时（300秒）');
          throw Exception('OpenAI API 请求超时');
        },
      );

      print('[LLM-OpenAI] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-OpenAI] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // 检查 choices 数组是否存在且非空
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          // 检查是否有 finish_reason 或 error 信息
          final finishReason =
              choices?.isNotEmpty == true ? choices![0]['finish_reason'] : null;
          print('[LLM-OpenAI] ❌ choices 数组为空或不存在');
          print('[LLM-OpenAI] ❌ 完整响应: ${response.body}');
          throw Exception(
            'OpenAI API 返回空响应: choices 数组为空。可能原因: 内容被安全过滤器拦截、模型无法生成输出、或API异常。finish_reason: $finishReason',
          );
        }

        // 检查 message 和 content 是否存在
        final message = choices[0]['message'] as Map<String, dynamic>?;
        if (message == null) {
          print('[LLM-OpenAI] ❌ message 对象不存在');
          print('[LLM-OpenAI] ❌ choice[0]: ${choices[0]}');
          throw Exception('OpenAI API 返回异常: message 对象不存在');
        }

        final contentRaw = message['content'];
        if (contentRaw == null) {
          // 某些模型可能使用 function_call 或 tool_calls 而非 content
          print('[LLM-OpenAI] ❌ content 为 null');
          print('[LLM-OpenAI] ❌ message: $message');
          throw Exception(
              'OpenAI API 返回异常: content 为 null，可能是 function_call 响应');
        }

        final content = contentRaw.toString().trim();
        if (content.isEmpty) {
          print('[LLM-OpenAI] ⚠ 内容为空字符串');
        }
        print('[LLM-OpenAI] ✓ 响应内容长度: ${content.length}');

        // 提取token使用信息
        int? inputTokens;
        int? outputTokens;
        int? totalTokens;
        if (data.containsKey('usage')) {
          final usage = data['usage'];
          inputTokens = usage['prompt_tokens'] as int?;
          outputTokens = usage['completion_tokens'] as int?;
          totalTokens = usage['total_tokens'] as int?;
          print(
              '[LLM-OpenAI] Token使用: 输入=$inputTokens, 输出=$outputTokens, 总计=$totalTokens');
        }

        return {
          'content': content,
          'inputTokens': inputTokens,
          'outputTokens': outputTokens,
          'totalTokens': totalTokens,
        };
      } else {
        print('[LLM-OpenAI] ❌ API 错误: ${response.statusCode}');
        print('[LLM-OpenAI] ❌ 错误内容: ${response.body}');
        throw Exception(
          'OpenAI API Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('[LLM-OpenAI] ❌ 调用失败: $e');
      print('[LLM-OpenAI] ❌ 堆栈跟踪: $stackTrace');
      throw Exception('Failed to call OpenAI: $e');
    }
  }

  static Future<Map<String, dynamic>> _callGeminiWithMetadata(
    ApiPreset preset,
    List<Map<String, dynamic>> messages,
  ) async {
    print('[LLM-Gemini] 准备调用 Gemini API');
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) baseUrl = 'https://generativelanguage.googleapis.com';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    print('[LLM-Gemini] Base URL: $baseUrl');
    print('[LLM-Gemini] Model: ${preset.model}');

    // Extract system message
    print('[LLM-Gemini] 提取系统消息...');
    final systemMessage = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    );
    print('[LLM-Gemini] 系统消息长度: ${systemMessage['content'].toString().length}');

    print('[LLM-Gemini] 转换消息格式...');
    final contents = messages.where((m) => m['role'] != 'system').map((m) {
      if (m['type'] == 'image') {
        return {
          'role': m['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': m['content']},
            {
              'inline_data': {
                'mime_type': m['mime_type'],
                'data': m['image_data'],
              },
            },
          ],
        };
      } else if (m['type'] == 'multi_modal') {
        final List<Map<String, dynamic>> parts = [
          {'text': m['content']}
        ];
        final images = m['images'] as List<Map<String, String>>;
        for (var img in images) {
          parts.add({
            'inline_data': {
              'mime_type': img['mime'],
              'data': img['data'],
            },
          });
        }
        return {
          'role': m['role'] == 'user' ? 'user' : 'model',
          'parts': parts,
        };
      } else {
        return {
          'role': m['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': m['content']},
          ],
        };
      }
    }).toList();
    print('[LLM-Gemini] 消息格式转换完成，共 ${contents.length} 条（不含系统消息）');

    try {
      final url =
          '$baseUrl/v1beta/models/${preset.model}:generateContent?key=${preset.apiKey}';
      print('[LLM-Gemini] 请求 URL: $url');

      final requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {'text': systemMessage['content']},
          ],
        },
      };
      print('[LLM-Gemini] 发送 HTTP POST 请求...');

      final response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          print('[LLM-Gemini] ❌ 请求超时（300秒）');
          throw Exception('Gemini API 请求超时');
        },
      );

      print('[LLM-Gemini] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-Gemini] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // 检查 candidates 数组是否存在且非空
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          print('[LLM-Gemini] ❌ candidates 数组为空或不存在');
          print('[LLM-Gemini] ❌ 完整响应: ${response.body}');
          throw Exception(
            'Gemini API 返回空响应: candidates 数组为空。可能原因: 内容被安全过滤器拦截、模型无法生成输出、或API异常。',
          );
        }

        // 检查 content 和 parts 是否存在
        final contentObj = candidates[0]['content'] as Map<String, dynamic>?;
        if (contentObj == null) {
          print('[LLM-Gemini] ❌ content 对象不存在');
          throw Exception('Gemini API 返回异常: content 对象不存在');
        }

        final parts = contentObj['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          print('[LLM-Gemini] ❌ parts 数组为空或不存在');
          throw Exception('Gemini API 返回异常: parts 数组为空');
        }

        final textRaw = parts[0]['text'];
        if (textRaw == null) {
          print('[LLM-Gemini] ❌ text 为 null');
          throw Exception('Gemini API 返回异常: text 为 null');
        }

        final content = textRaw.toString().trim();
        print('[LLM-Gemini] ✓ 响应内容长度: ${content.length}');

        // 提取token使用信息
        int? inputTokens;
        int? outputTokens;
        int? totalTokens;
        if (data.containsKey('usageMetadata')) {
          final usage = data['usageMetadata'];
          inputTokens = usage['promptTokenCount'] as int?;
          outputTokens = usage['candidatesTokenCount'] as int?;
          totalTokens = usage['totalTokenCount'] as int?;
          print(
              '[LLM-Gemini] Token使用: 输入=$inputTokens, 输出=$outputTokens, 总计=$totalTokens');
        }

        return {
          'content': content,
          'inputTokens': inputTokens,
          'outputTokens': outputTokens,
          'totalTokens': totalTokens,
        };
      } else {
        print('[LLM-Gemini] ❌ API 错误: ${response.statusCode}');
        print('[LLM-Gemini] ❌ 错误内容: ${response.body}');
        throw Exception(
          'Gemini API Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('[LLM-Gemini] ❌ 调用失败: $e');
      print('[LLM-Gemini] ❌ 堆栈跟踪: $stackTrace');
      throw Exception('Failed to call Gemini: $e');
    }
  }

  static Future<String> _callOpenAI(
    ApiPreset preset,
    List<Map<String, dynamic>> messages,
  ) async {
    print('[LLM-OpenAI] 准备调用 OpenAI API');
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) baseUrl = 'https://api.openai.com/v1';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    print('[LLM-OpenAI] Base URL: $baseUrl');
    print('[LLM-OpenAI] Model: ${preset.model}');
    print('[LLM-OpenAI] Enable Thinking: ${preset.enableThinking}');

    // 转换消息格式为 OpenAI Vision 格式
    print('[LLM-OpenAI] 转换消息格式...');
    final openAIMessages = messages.map((msg) {
      if (msg['role'] == 'system') {
        return {'role': 'system', 'content': msg['content']};
      }

      if (msg['type'] == 'image') {
        return {
          'role': msg['role'],
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:${msg['mime_type']};base64,${msg['image_data']}',
              },
            },
          ],
        };
      } else {
        return {'role': msg['role'], 'content': msg['content']};
      }
    }).toList();
    print('[LLM-OpenAI] 消息格式转换完成，共 ${openAIMessages.length} 条');

    try {
      final url = '$baseUrl/chat/completions';
      print('[LLM-OpenAI] 请求 URL: $url');

      final requestBody = {
        'model': preset.model,
        'messages': openAIMessages,
        if (!preset.enableThinking) 'enable_thinking': false,
      };
      print('[LLM-OpenAI] 发送 HTTP POST 请求...');

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${preset.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          print('[LLM-OpenAI] ❌ 请求超时（300秒）');
          throw Exception('OpenAI API 请求超时');
        },
      );

      print('[LLM-OpenAI] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-OpenAI] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // 检查 choices 数组是否存在且非空
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          print('[LLM-OpenAI] ❌ choices 数组为空或不存在');
          print('[LLM-OpenAI] ❌ 完整响应: ${response.body}');
          throw Exception(
            'OpenAI API 返回空响应: choices 数组为空。可能原因: 内容被安全过滤器拦截、模型无法生成输出、或API异常。',
          );
        }

        final message = choices[0]['message'] as Map<String, dynamic>?;
        if (message == null) {
          throw Exception('OpenAI API 返回异常: message 对象不存在');
        }

        final contentRaw = message['content'];
        if (contentRaw == null) {
          throw Exception('OpenAI API 返回异常: content 为 null');
        }

        final content = contentRaw.toString().trim();
        print('[LLM-OpenAI] ✓ 响应内容长度: ${content.length}');
        return content;
      } else {
        print('[LLM-OpenAI] ❌ API 错误: ${response.statusCode}');
        print('[LLM-OpenAI] ❌ 错误内容: ${response.body}');
        throw Exception(
          'OpenAI API Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('[LLM-OpenAI] ❌ 调用失败: $e');
      print('[LLM-OpenAI] ❌ 堆栈跟踪: $stackTrace');
      throw Exception('Failed to call OpenAI: $e');
    }
  }

  static Future<String> _callGemini(
    ApiPreset preset,
    List<Map<String, dynamic>> messages,
  ) async {
    print('[LLM-Gemini] 准备调用 Gemini API');
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) baseUrl = 'https://generativelanguage.googleapis.com';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    print('[LLM-Gemini] Base URL: $baseUrl');
    print('[LLM-Gemini] Model: ${preset.model}');

    // Extract system message
    print('[LLM-Gemini] 提取系统消息...');
    final systemMessage = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    );
    print('[LLM-Gemini] 系统消息长度: ${systemMessage['content'].toString().length}');

    print('[LLM-Gemini] 转换消息格式...');
    final contents = messages.where((m) => m['role'] != 'system').map((m) {
      if (m['type'] == 'image') {
        return {
          'role': m['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {
              'inline_data': {
                'mime_type': m['mime_type'],
                'data': m['image_data'],
              },
            },
          ],
        };
      } else {
        return {
          'role': m['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': m['content']},
          ],
        };
      }
    }).toList();
    print('[LLM-Gemini] 消息格式转换完成，共 ${contents.length} 条（不含系统消息）');

    try {
      final url =
          '$baseUrl/v1beta/models/${preset.model}:generateContent?key=${preset.apiKey}';
      print('[LLM-Gemini] 请求 URL: $url');

      final requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {'text': systemMessage['content']},
          ],
        },
      };
      print('[LLM-Gemini] 发送 HTTP POST 请求...');

      final response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          print('[LLM-Gemini] ❌ 请求超时（300秒）');
          throw Exception('Gemini API 请求超时');
        },
      );

      print('[LLM-Gemini] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-Gemini] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // 检查 candidates 数组是否存在且非空
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          print('[LLM-Gemini] ❌ candidates 数组为空或不存在');
          print('[LLM-Gemini] ❌ 完整响应: ${response.body}');
          throw Exception(
            'Gemini API 返回空响应: candidates 数组为空。',
          );
        }

        final contentObj = candidates[0]['content'] as Map<String, dynamic>?;
        if (contentObj == null) {
          throw Exception('Gemini API 返回异常: content 对象不存在');
        }

        final parts = contentObj['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception('Gemini API 返回异常: parts 数组为空');
        }

        final textRaw = parts[0]['text'];
        if (textRaw == null) {
          throw Exception('Gemini API 返回异常: text 为 null');
        }

        final content = textRaw.toString().trim();
        print('[LLM-Gemini] ✓ 响应内容长度: ${content.length}');
        return content;
      } else {
        print('[LLM-Gemini] ❌ API 错误: ${response.statusCode}');
        print('[LLM-Gemini] ❌ 错误内容: ${response.body}');
        throw Exception(
          'Gemini API Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('[LLM-Gemini] ❌ 调用失败: $e');
      print('[LLM-Gemini] ❌ 堆栈跟踪: $stackTrace');
      throw Exception('Failed to call Gemini: $e');
    }
  }

  /// 分析图片内容（用于表情包打标）
  static Future<Map<String, String>> analyzeImage({
    required ApiPreset apiPreset,
    required String imagePath,
    required String systemPrompt,
  }) async {
    print('[LLM] 开始分析图片: $imagePath');

    final base64Image = await ImageUtils.imageToBase64(imagePath);
    if (base64Image == null) {
      throw Exception('无法读取图片文件');
    }
    String mimeType = ImageUtils.getMimeType(imagePath);

    // 关键修复：处理 GIF 不支持的问题
    // 大多数多模态 API 不支持 image/gif。
    // 我们将其伪装成 image/png，后端通常会提取第一帧进行分析。
    if (mimeType == 'image/gif') {
      print('[LLM] 检测到 GIF，将其 MIME 类型转换为 image/png 以兼容 AI 分析');
      mimeType = 'image/png';
    }

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content': 'Please analyze this emoji.',
        'type': 'image',
        'image_data': base64Image,
        'mime_type': mimeType,
      }
    ];

    try {
      String rawResponse;
      if (apiPreset.provider == ApiProvider.openai) {
        final result = await _callOpenAIWithMetadata(apiPreset, messages);
        rawResponse = result['content'] as String;
      } else {
        final result = await _callGeminiWithMetadata(apiPreset, messages);
        rawResponse = result['content'] as String;
      }

      print('[LLM] 图片分析结果: $rawResponse');

      // 解析结果 (假设 Prompt 要求输出 simple_content 和 raw_content)
      // 这里做一个简单的解析，实际可能需要更复杂的 XML 解析
      // 假设输出格式为:
      // <simple>开心</simple>
      // <raw>一个黄色圆脸，笑得合不拢嘴，眼睛眯成一条缝</raw>

      String simpleContent = rawResponse;
      String? rawContent;

      // 尝试提取 XML 标签
      final simpleMatch = RegExp(r'<simple>(.*?)</simple>', dotAll: true)
          .firstMatch(rawResponse);
      if (simpleMatch != null) {
        simpleContent = simpleMatch.group(1)!.trim();
      }

      final rawMatch =
          RegExp(r'<raw>(.*?)</raw>', dotAll: true).firstMatch(rawResponse);
      if (rawMatch != null) {
        rawContent = rawMatch.group(1)!.trim();
      } else {
        // 如果没有 raw 标签，尝试把整个回复作为 rawContent (如果它比 simpleContent 长)
        if (rawResponse.length > simpleContent.length) {
          rawContent = rawResponse;
        }
      }

      // 如果没有 XML 标签，尝试按行分割 (兼容旧 Prompt)
      if (simpleMatch == null) {
        final lines = rawResponse.split('\n');
        if (lines.isNotEmpty) {
          simpleContent = lines.first.trim();
          if (lines.length > 1) {
            rawContent = lines.sublist(1).join('\n').trim();
          }
        }
      }

      return {
        'simple_content': simpleContent,
        'raw_content': rawContent ?? '',
      };
    } catch (e) {
      print('[LLM] 图片分析失败: $e');
      return {
        'simple_content': '表情',
        'raw_content': '',
      };
    }
  }
}
