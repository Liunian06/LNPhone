import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/api_preset.dart';
import '../models/chat_model.dart';
import '../models/contact_model.dart';
import '../providers/prompt_settings_provider.dart';
import '../utils/image_utils.dart';
import 'xml_parser.dart';

class LlmService {
  /// 生成回复，返回解析后的消息列表
  static Future<List<ChatMessage>> generateResponse({
    required ApiPreset apiPreset,
    required PromptSettingsProvider promptSettings,
    required List<ChatMessage> history,
    required ContactRole role,
    required ContactMe me,
    required String messageIdPrefix,
  }) async {
    print('[LLM] ========== 开始生成回复 ==========');
    print('[LLM] API Provider: ${apiPreset.provider.name}');
    print('[LLM] Model: ${apiPreset.model}');
    print('[LLM] Base URL: ${apiPreset.baseUrl}');
    print('[LLM] 历史消息数量: ${history.length}');

    print('[LLM] 构建系统提示词...');
    final systemPrompt = _buildSystemPrompt(promptSettings, role, me);
    print('[LLM] 系统提示词长度: ${systemPrompt.length} 字符');

    print('[LLM] 构建消息列表（上下文长度: ${promptSettings.contextLength}）...');
    final messages = await _buildMessages(
      history,
      systemPrompt,
      promptSettings.contextLength,
    );
    print('[LLM] 消息列表构建完成，共 ${messages.length} 条');

    // 调用 API 获取原始响应
    String rawResponse;
    print('[LLM] 准备调用 API...');
    try {
      if (apiPreset.provider == ApiProvider.openai) {
        print('[LLM] 调用 OpenAI API...');
        rawResponse = await _callOpenAI(apiPreset, messages);
      } else {
        print('[LLM] 调用 Gemini API...');
        rawResponse = await _callGemini(apiPreset, messages);
      }
      print('[LLM] ✓ API 调用成功');
      print('[LLM] 原始响应长度: ${rawResponse.length} 字符');
      print(
        '[LLM] 原始响应内容: ${rawResponse.substring(0, rawResponse.length > 200 ? 200 : rawResponse.length)}...',
      );
    } catch (e, stackTrace) {
      print('[LLM] ❌ API 调用失败: $e');
      print('[LLM] ❌ 堆栈跟踪: $stackTrace');
      rethrow;
    }

    // 解析 XML 响应为消息列表
    print('[LLM] 解析 XML 响应...');
    try {
      final parsedMessages = XmlResponseParser.parse(
        rawResponse,
        messageIdPrefix,
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
    PromptSettingsProvider settings,
    ContactRole role,
    ContactMe me,
  ) {
    final buffer = StringBuffer();

    // Roleplay Prompt
    if (settings.roleplayPrompt.isNotEmpty) {
      buffer.writeln(settings.roleplayPrompt);
    }

    // Presetting Prompt
    if (settings.presettingPrompt.isNotEmpty) {
      buffer.writeln(settings.presettingPrompt);
    }

    // Reality Prompt
    if (settings.enableRealityPrompt && settings.realityPrompt.isNotEmpty) {
      final now = DateTime.now();
      final timeStr = DateFormat('HH:mm').format(now);
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final reality = settings.realityPrompt
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

    return buffer.toString();
  }

  static Future<List<Map<String, dynamic>>> _buildMessages(
    List<ChatMessage> history,
    String systemPrompt,
    int contextLength,
  ) async {
    final messages = <Map<String, dynamic>>[];

    // System Message
    messages.add({'role': 'system', 'content': systemPrompt});

    // Chat History (Take last N)
    final start = (history.length - contextLength).clamp(0, history.length);
    final recentHistory = history.sublist(start);

    for (final msg in recentHistory) {
      if (msg.type == MessageType.image) {
        // 处理图片消息
        final base64Image = await ImageUtils.imageToBase64(msg.content);
        if (base64Image != null) {
          messages.add({
            'role': msg.isMe ? 'user' : 'assistant',
            'content': '', // 占位，实际内容在 type 中区分
            'image_data': base64Image,
            'mime_type': ImageUtils.getMimeType(msg.content),
            'type': 'image',
          });
        } else {
          // 图片加载失败，作为文本提示
          messages.add({
            'role': msg.isMe ? 'user' : 'assistant',
            'content': '[图片加载失败: ${msg.content}]',
            'type': 'text',
          });
        }
      } else {
        // 普通文本消息
        messages.add({
          'role': msg.isMe ? 'user' : 'assistant',
          'content': msg.content,
          'type': 'text',
        });
      }
    }

    return messages;
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
        final content = data['choices'][0]['message']['content']
            .toString()
            .trim();
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
