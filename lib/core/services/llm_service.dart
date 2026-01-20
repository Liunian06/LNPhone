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
  }) async {
    print('[LLM] ========== 开始生成回复 ==========');
    print('[LLM] API Provider: ${apiPreset.provider.name}');
    print('[LLM] Model: ${apiPreset.model}');
    print('[LLM] Base URL: ${apiPreset.baseUrl}');
    print('[LLM] 历史消息数量: ${history.length}');

    print('[LLM] 构建系统提示词...');
    final systemPrompt = _buildSystemPrompt(
      promptConfig,
      role,
      me,
      worldInfos,
      textPresets,
      history,
      roleMemories,
    );
    print('[LLM] 系统提示词长度: ${systemPrompt.length} 字符');

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
    for (var i = 0; i < messages.length; i++) {
      final role = messages[i]['role'];
      final content = messages[i]['content'] as String;
      final preview =
          content.length > 100 ? '${content.substring(0, 100)}...' : content;
      print('[LLM] Request Msg $i ($role): $preview');
    }

    List<String> errorLogs = [];
    String? rawResponse;
    final stopwatch = Stopwatch()..start();
    Map<String, dynamic>? responseData;

    // 重试机制：最多尝试3次
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
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
        print('[LLM] ✓ API 调用成功');
        print('[LLM] 原始响应长度: ${rawResponse.length} 字符');
        print(
          '[LLM] 原始响应内容: ${rawResponse.substring(0, rawResponse.length > 200 ? 200 : rawResponse.length)}...',
        );

        // 记录成功的API调用
        stopwatch.stop();
        await _logApiCall(
          apiPreset: apiPreset,
          responseData: responseData,
          durationSeconds: stopwatch.elapsed.inMilliseconds / 1000.0,
          error: null,
        );

        // 如果成功，跳出循环
        break;
      } catch (e, stackTrace) {
        final errorMsg = '第 $attempt 次请求失败: $e';
        print('[LLM] ❌ $errorMsg');
        print('[LLM] ❌ 堆栈跟踪: $stackTrace');
        errorLogs.add(errorMsg);

        if (attempt == 3) {
          print('[LLM] ❌ 3次尝试均失败，抛出异常');

          // 记录失败的API调用
          stopwatch.stop();
          await _logApiCall(
            apiPreset: apiPreset,
            responseData: null,
            durationSeconds: stopwatch.elapsed.inMilliseconds / 1000.0,
            error: errorLogs.join('; '),
          );

          throw LlmRetryException(errorLogs);
        }
        // 等待一小段时间再重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (rawResponse == null) {
      // 理论上不会执行到这里，因为上面会 throw
      throw LlmRetryException(errorLogs);
    }

    // 解析 XML 响应为消息列表，传入ID映射表用于将简化ID转换回真实ID
    print('[LLM] 解析 XML 响应...');
    try {
      final parsedMessages = XmlResponseParser.parse(
        rawResponse,
        messageIdPrefix,
        simpleIdToRealId: idMapping,
      );
      print('[LLM] ✓ XML 解析成功，得到 ${parsedMessages.length} 条消息');
      for (var i = 0; i < parsedMessages.length; i++) {
        print(
          '[LLM] 消息 $i: type=${parsedMessages[i].type}, content=${parsedMessages[i].content.substring(0, parsedMessages[i].content.length > 50 ? 50 : parsedMessages[i].content.length)}...',
        );
      }
      print('[LLM] ========== 生成回复完成 ==========');
      return parsedMessages;
    } catch (e, stackTrace) {
      print('[LLM] ❌ XML 解析失败: $e');
      print('[LLM] ❌ 堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  static String _buildSystemPrompt(
    PromptConfig config,
    ContactRole role,
    ContactMe me,
    List<String> worldInfos,
    List<String> textPresets,
    List<ChatMessage> history,
    List<String> roleMemories,
  ) {
    final buffer = StringBuffer();

    // 1. Roleplay Prompt
    if (config.roleplayPrompt.isNotEmpty) {
      buffer.writeln(config.roleplayPrompt);
    }

    // 2. World Info (世界书)
    if (worldInfos.isNotEmpty) {
      buffer.writeln('\n[World Info]');
      for (final info in worldInfos) {
        buffer.writeln(info);
      }
    }

    // 3. Presets (预设)
    if (textPresets.isNotEmpty) {
      buffer.writeln('\n[Style Presets]');
      for (final preset in textPresets) {
        buffer.writeln(preset);
      }
    }

    // Reality Prompt
    if (config.enableRealityPrompt && config.realityPrompt.isNotEmpty) {
      final now = DateTime.now();
      final timeStr = DateFormat('HH:mm').format(now);
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final reality = config.realityPrompt
          .replaceAll('{time}', timeStr)
          .replaceAll('{date}', dateStr);
      buffer.writeln(reality);
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

      // 构建XML格式的消息内容，使用简化ID
      final xmlContent = _buildXmlMessageContentWithSimpleId(
        msg,
        simpleId,
        realIdToSimpleId,
      );

      if (msg.type == MessageType.image) {
        // 处理图片消息
        final base64Image = await ImageUtils.imageToBase64(msg.content);
        if (base64Image != null) {
          messages.add({
            'role': msg.isMe ? 'user' : 'assistant',
            'content': '<image id="$simpleId">[图片]</image>',
            'image_data': base64Image,
            'mime_type': ImageUtils.getMimeType(msg.content),
            'type': 'image',
          });
        } else {
          // 图片加载失败，作为文本提示
          messages.add({
            'role': msg.isMe ? 'user' : 'assistant',
            'content': '<image id="$simpleId">[图片加载失败]</image>',
            'type': 'text',
          });
        }
      } else {
        // 普通文本消息，使用XML格式
        messages.add({
          'role': msg.isMe ? 'user' : 'assistant',
          'content': xmlContent,
          'type': 'text',
        });
      }
    }

    return {
      'messages': messages,
      'idMapping': idMapping,
    };
  }

  /// 将消息构建为XML格式，使用简化ID
  static String _buildXmlMessageContentWithSimpleId(
    ChatMessage msg,
    String simpleId,
    Map<String, String> realIdToSimpleId,
  ) {
    // 获取消息类型对应的标签名
    final tagName = _getTagNameForType(msg.type);

    // 构建属性字符串，使用简化ID
    final attributes = StringBuffer();
    attributes.write(' id="$simpleId"');

    // 处理引用消息，将引用的真实ID转换为简化ID
    if (msg.metadata != null && msg.metadata!.containsKey('quote')) {
      try {
        final quote = msg.metadata!['quote'] as Map<String, dynamic>;
        final quoteRealId = quote['id'] as String;
        // 查找引用消息的简化ID
        final quoteSimpleId = realIdToSimpleId[quoteRealId];
        if (quoteSimpleId != null) {
          attributes.write(' ref="$quoteSimpleId"');
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
            attributes.write(' message="$message"');
          }
          break;
        case MessageType.product:
          final name = msg.metadata!['name'] as String? ?? '';
          final price = msg.metadata!['price'] as String? ?? '';
          if (name.isNotEmpty) attributes.write(' name="$name"');
          if (price.isNotEmpty) attributes.write(' price="$price"');
          break;
        case MessageType.link:
          final title = msg.metadata!['title'] as String? ?? '';
          final url = msg.metadata!['url'] as String? ?? '';
          if (title.isNotEmpty) attributes.write(' title="$title"');
          if (url.isNotEmpty) attributes.write(' url="$url"');
          break;
        case MessageType.note:
          final title = msg.metadata!['title'] as String? ?? '';
          if (title.isNotEmpty) attributes.write(' title="$title"');
          break;
        default:
          break;
      }
    }

    return '<$tagName$attributes>${msg.content}</$tagName>';
  }

  /// 获取消息类型对应的XML标签名
  static String _getTagNameForType(MessageType type) {
    switch (type) {
      case MessageType.words:
        return 'words';
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
        const Duration(seconds: 60),
        onTimeout: () {
          print('[LLM-OpenAI] ❌ 请求超时（60秒）');
          throw Exception('OpenAI API 请求超时');
        },
      );

      print('[LLM-OpenAI] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-OpenAI] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            data['choices'][0]['message']['content'].toString().trim();
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
        const Duration(seconds: 60),
        onTimeout: () {
          print('[LLM-Gemini] ❌ 请求超时（60秒）');
          throw Exception('Gemini API 请求超时');
        },
      );

      print('[LLM-Gemini] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-Gemini] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final content = text.toString().trim();
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
        const Duration(seconds: 60),
        onTimeout: () {
          print('[LLM-OpenAI] ❌ 请求超时（60秒）');
          throw Exception('OpenAI API 请求超时');
        },
      );

      print('[LLM-OpenAI] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-OpenAI] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            data['choices'][0]['message']['content'].toString().trim();
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
        const Duration(seconds: 60),
        onTimeout: () {
          print('[LLM-Gemini] ❌ 请求超时（60秒）');
          throw Exception('Gemini API 请求超时');
        },
      );

      print('[LLM-Gemini] 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LLM-Gemini] ✓ 请求成功，解析响应...');
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final content = text.toString().trim();
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
}
