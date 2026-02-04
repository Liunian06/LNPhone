# LLM 集成指南

本文档详细介绍 LNPhone 如何与大语言模型 (LLM) 进行集成，包括多供应商支持、上下文构建、响应解析等核心逻辑。

---

## 目录

1. [架构概览](#1-架构概览)
2. [供应商支持](#2-供应商支持)
3. [上下文构建](#3-上下文构建)
4. [API 调用](#4-api-调用)
5. [响应解析](#5-响应解析)
6. [重试机制](#6-重试机制)
7. [设计决策](#7-设计决策)

---

## 1. 架构概览

### 1.1 核心文件

| 文件 | 职责 |
|------|------|
| [`lib/core/services/llm_service.dart`](../lib/core/services/llm_service.dart) | LLM API 调用 |
| [`lib/core/services/xml_parser.dart`](../lib/core/services/xml_parser.dart) | 响应解析 |
| [`lib/core/models/api_preset.dart`](../lib/core/models/api_preset.dart) | API 预设模型 |
| [`lib/core/providers/chat_provider.dart`](../lib/core/providers/chat_provider.dart) | 聊天状态管理 |

### 1.2 调用流程

```
用户发送消息
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    ChatProvider                              │
│  1. addMessage() - 保存用户消息                               │
│  2. generateAiResponse() - 触发 AI 回复                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
       ┌───────────────────┴───────────────────┐
       │                                       │
       ▼                                       ▼
┌──────────────────┐              ┌──────────────────────────┐
│ 构建上下文        │              │ 设置 ImageGenerationSvc  │
│ - 系统提示词      │              │ - 角色/用户外貌           │
│ - 历史消息        │              │ - 参考图                 │
│ - 记忆           │              │ - API 预设               │
│ - 世界书         │              └──────────────────────────┘
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    LlmService.generateResponse()             │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              _buildSystemPrompt()                    │    │
│  │  - 基础角色扮演提示词                                  │    │
│  │  - 角色设定 (description)                             │    │
│  │  - 用户设定 (info)                                    │    │
│  │  - 记忆 (memories)                                    │    │
│  │  - 世界书 (worldInfos)                                │    │
│  │  - 输出格式指令                                        │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           _buildMessagesWithSimpleIds()              │    │
│  │  - 生成简化 ID 映射 (0001, 0002...)                   │    │
│  │  - 转换为 API 格式                                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │         _callOpenAI() / _callGemini()                │    │
│  │  - 发送 HTTP 请求                                     │    │
│  │  - 处理流式/非流式响应                                 │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  ResponseParser.parse()                      │
│  - 尝试 JSON 解析                                            │
│  - 回退到 XML 解析                                           │
│  - 处理生图触发                                              │
│  - 处理表情包                                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                   List<ChatMessage>
```

---

## 2. 供应商支持

### 2.1 支持的供应商

```dart
enum ApiProvider {
  openai,           // OpenAI 官方 (GPT-4, GPT-3.5)
  gemini,           // Google Gemini
  volcengine,       // 火山引擎（图片生成专用）
  openaicompatible, // OpenAI 兼容接口（各种中转）
  minimax,          // Minimax
  groklike,         // 类 Grok 接口
}
```

### 2.2 供应商差异

| 供应商 | 文本 API | 图片 API | 认证方式 | 特殊处理 |
|--------|----------|----------|----------|----------|
| OpenAI | ✅ | ✅ (DALL-E) | Bearer Token | 标准 |
| Gemini | ✅ | ✅ | URL 参数 | 需要特殊格式 |
| Volcengine | ❌ | ✅ | Bearer Token | 仅图片生成 |
| OpenAI Compatible | ✅ | ✅ | Bearer Token | 兼容 Gemini 响应 |
| Minimax | ✅ | ❌ | Bearer Token | 特殊请求格式 |
| Groklike | ❌ | ✅ | Bearer Token | 通过 chat 接口生图 |

### 2.3 配置示例

```dart
// OpenAI 配置
ApiPreset(
  id: 'openai-gpt4',
  name: 'GPT-4 Turbo',
  type: ApiType.text,
  provider: ApiProvider.openai,
  baseUrl: 'https://api.openai.com/v1',
  apiKey: 'sk-xxxxxxxx',
  model: 'gpt-4-turbo-preview',
)

// Gemini 配置
ApiPreset(
  id: 'gemini-pro',
  name: 'Gemini Pro',
  type: ApiType.text,
  provider: ApiProvider.gemini,
  baseUrl: 'https://generativelanguage.googleapis.com',
  apiKey: 'AIzaSyxxxxxxxx',
  model: 'gemini-pro',
)

// OpenAI 兼容中转
ApiPreset(
  id: 'custom-api',
  name: '自定义中转',
  type: ApiType.text,
  provider: ApiProvider.openaicompatible,
  baseUrl: 'https://your-proxy.com/v1',
  apiKey: 'your-key',
  model: 'gpt-4',
)
```

---

## 3. 上下文构建

### 3.1 系统提示词结构

```dart
String _buildSystemPrompt({
  required ContactRole role,
  required ContactMe me,
  required PromptConfig promptConfig,
  required List<RoleMemory> memories,
  required List<WorldInfo> worldInfos,
  required List<TextPreset> textPresets,
  required bool enableExtendedChat,
  required bool enableEmoji,
  required List<EmojiModel> availableEmojis,
}) {
  final buffer = StringBuffer();

  // 1. 基础角色扮演提示词（从文件加载）
  buffer.writeln(promptConfig.roleplayPrompt);
  buffer.writeln();

  // 2. 角色设定
  buffer.writeln('### 你扮演的角色');
  buffer.writeln('角色名称：${role.name}');
  if (role.description != null) {
    buffer.writeln('角色设定：${role.description}');
  }
  buffer.writeln();

  // 3. 用户信息
  buffer.writeln('### 与你对话的用户');
  buffer.writeln('用户名称：${me.name}');
  if (me.info != null) {
    buffer.writeln('用户信息：${me.info}');
  }
  buffer.writeln();

  // 4. 世界书（可选）
  if (worldInfos.isNotEmpty) {
    buffer.writeln('### 世界观设定');
    for (final worldInfo in worldInfos) {
      buffer.writeln(worldInfo.content);
    }
    buffer.writeln();
  }

  // 5. 记忆（可选）
  if (memories.isNotEmpty) {
    buffer.writeln('### 关于用户的记忆');
    for (final memory in memories) {
      buffer.writeln('- ${memory.content}');
    }
    buffer.writeln();
  }

  // 6. 文本预设（可选）
  for (final preset in textPresets) {
    buffer.writeln(preset.content);
  }

  // 7. 输出格式指令
  buffer.writeln('### 输出格式');
  buffer.writeln(_buildOutputFormatInstructions(
    enableExtendedChat: enableExtendedChat,
    enableEmoji: enableEmoji,
    availableEmojis: availableEmojis,
  ));

  return buffer.toString();
}
```

### 3.2 输出格式指令

```dart
String _buildOutputFormatInstructions({
  required bool enableExtendedChat,
  required bool enableEmoji,
  required List<EmojiModel> availableEmojis,
}) {
  final buffer = StringBuffer();

  buffer.writeln('请使用 JSON 数组格式输出，每个元素包含 type 和 content 字段。');
  buffer.writeln('支持的消息类型：');
  buffer.writeln('- word: 普通对话文字');
  
  if (enableExtendedChat) {
    buffer.writeln('- action: 动作描写（用于描述肢体动作）');
    buffer.writeln('- thought: 内心想法（用于描述心理活动）');
    buffer.writeln('- state: 当前状态（简短的状态描述）');
  }

  if (enableEmoji) {
    buffer.writeln('- emoji: 表情包（使用表情的 meaning 字段）');
    buffer.writeln('可用表情：');
    for (final emoji in availableEmojis) {
      buffer.writeln('  - ${emoji.meaning}: ${emoji.rawContent ?? ""}');
    }
  }

  buffer.writeln();
  buffer.writeln('示例输出：');
  buffer.writeln('```json');
  buffer.writeln('[');
  buffer.writeln('  {"type": "word", "content": "你好呀！"},');
  if (enableExtendedChat) {
    buffer.writeln('  {"type": "action", "content": "*微笑着挥手*"},');
  }
  buffer.writeln(']');
  buffer.writeln('```');

  return buffer.toString();
}
```

### 3.3 消息 ID 简化策略

**问题**: AI 难以正确处理长 ID（如 `1738552800000-12345`）

**解决方案**: 使用简化 ID 映射

```dart
Map<String, String> _buildMessagesWithSimpleIds(List<ChatMessage> history) {
  final idMapping = <String, String>{}; // simpleId -> realId
  var counter = 1;

  final messages = <Map<String, dynamic>>[];
  
  for (final message in history) {
    final simpleId = counter.toString().padLeft(4, '0'); // 0001, 0002...
    idMapping[simpleId] = message.id;
    
    messages.add({
      'id': simpleId,
      'role': message.isMe ? 'user' : 'assistant',
      'type': message.type.name,
      'content': message.content,
    });
    
    counter++;
  }

  return {
    'messages': messages,
    'idMapping': idMapping,
  };
}
```

**使用示例**:

```
发送给 AI 的消息格式:
[
  {"id": "0001", "role": "user", "type": "word", "content": "你好"},
  {"id": "0002", "role": "assistant", "type": "word", "content": "你好呀！"},
  {"id": "0003", "role": "user", "type": "word", "content": "今天天气怎么样？"}
]

AI 可以引用: "正如我在 0002 说的..."
解析时通过 idMapping 还原真实 ID
```

---

## 4. API 调用

### 4.1 OpenAI / OpenAI Compatible

```dart
Future<String> _callOpenAI({
  required ApiPreset preset,
  required String systemPrompt,
  required List<Map<String, dynamic>> messages,
}) async {
  final url = '${preset.baseUrl}/chat/completions';
  
  final body = {
    'model': preset.model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      ...messages.map((m) => {
        'role': m['role'],
        'content': m['content'],
      }),
    ],
    'temperature': preset.params?['temperature'] ?? 0.7,
    'max_tokens': preset.params?['max_tokens'] ?? 4096,
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${preset.apiKey}',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('API Error: ${response.statusCode} - ${response.body}');
  }
}
```

### 4.2 Gemini

```dart
Future<String> _callGemini({
  required ApiPreset preset,
  required String systemPrompt,
  required List<Map<String, dynamic>> messages,
}) async {
  // Gemini 使用 URL 参数传递 API Key
  final url = '${preset.baseUrl}/v1beta/models/${preset.model}:generateContent?key=${preset.apiKey}';

  // Gemini 使用不同的消息格式
  final contents = <Map<String, dynamic>>[];
  
  // 系统提示词作为第一条 user 消息
  contents.add({
    'role': 'user',
    'parts': [{'text': systemPrompt}],
  });
  contents.add({
    'role': 'model',
    'parts': [{'text': '我理解了，让我们开始对话。'}],
  });

  // 转换消息格式
  for (final message in messages) {
    contents.add({
      'role': message['role'] == 'user' ? 'user' : 'model',
      'parts': [{'text': message['content']}],
    });
  }

  final body = {
    'contents': contents,
    'generationConfig': {
      'temperature': preset.params?['temperature'] ?? 0.7,
      'maxOutputTokens': preset.params?['max_tokens'] ?? 4096,
    },
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  } else {
    throw Exception('Gemini Error: ${response.statusCode} - ${response.body}');
  }
}
```

### 4.3 供应商路由

```dart
static Future<List<ChatMessage>> generateResponse({
  required ApiPreset apiPreset,
  required PromptConfig promptConfig,
  required List<ChatMessage> history,
  required ContactRole role,
  required ContactMe me,
  // ... other params
}) async {
  // 构建系统提示词
  final systemPrompt = _buildSystemPrompt(...);
  
  // 构建消息列表（带简化 ID）
  final result = _buildMessagesWithSimpleIds(history);
  final messages = result['messages'];
  final idMapping = result['idMapping'];

  // 根据供应商调用对应 API
  String responseText;
  switch (apiPreset.provider) {
    case ApiProvider.openai:
    case ApiProvider.openaicompatible:
    case ApiProvider.minimax:
      responseText = await _callOpenAI(
        preset: apiPreset,
        systemPrompt: systemPrompt,
        messages: messages,
      );
      break;
    case ApiProvider.gemini:
      responseText = await _callGemini(
        preset: apiPreset,
        systemPrompt: systemPrompt,
        messages: messages,
      );
      break;
    default:
      throw Exception('Unsupported provider: ${apiPreset.provider}');
  }

  // 解析响应
  return ResponseParser.parse(
    responseText,
    idMapping: idMapping,
    enableExtendedChat: enableExtendedChat,
    // ... other params
  );
}
```

---

## 5. 响应解析

### 5.1 解析器架构

**文件**: [`lib/core/services/xml_parser.dart`](../lib/core/services/xml_parser.dart)

```dart
class ResponseParser {
  /// 解析 AI 响应，返回消息列表
  static Future<List<ChatMessage>> parse(
    String response, {
    required Map<String, String> idMapping,
    required bool enableExtendedChat,
    required bool enableEmoji,
    required bool enableTextToImage,
    required List<EmojiModel> availableEmojis,
  }) async {
    // 1. 预处理（正则替换等）
    response = _preprocess(response);

    // 2. 尝试 JSON 解析
    final jsonResult = _tryParseJson(response);
    if (jsonResult != null) {
      return _processJsonResult(jsonResult, ...);
    }

    // 3. 回退到 XML 解析
    final xmlResult = _tryParseXml(response);
    if (xmlResult != null) {
      return _processXmlResult(xmlResult, ...);
    }

    // 4. 无法解析时，作为纯文本返回
    return [ChatMessage(
      type: MessageType.words,
      content: response,
    )];
  }
}
```

### 5.2 JSON 解析

```dart
List<Map<String, dynamic>>? _tryParseJson(String response) {
  // 尝试直接解析
  try {
    final decoded = jsonDecode(response);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
  } catch (_) {}

  // 尝试提取 JSON 代码块
  final jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final match = jsonBlockRegex.firstMatch(response);
  if (match != null) {
    try {
      final decoded = jsonDecode(match.group(1)!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }

  return null;
}
```

### 5.3 XML 解析

```dart
List<Map<String, dynamic>>? _tryParseXml(String response) {
  try {
    // 包装成完整 XML
    final wrapped = '<root>$response</root>';
    final document = XmlDocument.parse(wrapped);
    final root = document.rootElement;

    final results = <Map<String, dynamic>>[];

    // 遍历所有元素
    for (final element in root.childElements) {
      final type = element.name.local; // words, action, thought 等
      final content = element.innerText.trim();
      
      if (content.isNotEmpty) {
        results.add({
          'type': _normalizeType(type),
          'content': content,
        });
      }
    }

    return results.isEmpty ? null : results;
  } catch (_) {
    return null;
  }
}

String _normalizeType(String type) {
  // 标准化类型名称
  switch (type.toLowerCase()) {
    case 'words':
    case 'word':
    case 'text':
      return 'word';
    case 'actions':
    case 'action':
      return 'action';
    case 'thoughts':
    case 'thought':
      return 'thought';
    // ... 其他类型
    default:
      return type;
  }
}
```

### 5.4 特殊消息处理

#### 生图触发

```dart
Future<List<ChatMessage>> _processJsonResult(
  List<Map<String, dynamic>> items,
  // ...
) async {
  final messages = <ChatMessage>[];

  for (final item in items) {
    final type = item['type'] as String;
    final content = item['content'] as String;

    if (type == 'image') {
      // 检测生图触发
      if (enableTextToImage) {
        // 调用 ImageGenerationService
        final result = await ImageGenerationService.generateImage(
          prompt: content,
        );
        if (result != null) {
          messages.add(ChatMessage(
            type: MessageType.image,
            content: result['path'],
            metadata: {
              'prompt': content,
              'api_preset_name': result['api_preset_name'],
            },
          ));
          continue;
        }
      }
    }

    if (type == 'emoji') {
      // 匹配表情
      final emoji = _findEmoji(content, availableEmojis);
      if (emoji != null) {
        messages.add(ChatMessage(
          type: MessageType.emoji,
          content: emoji.id,
          metadata: {'meaning': emoji.meaning},
        ));
        continue;
      }
    }

    // 其他普通消息
    messages.add(ChatMessage(
      type: _typeFromString(type),
      content: content,
    ));
  }

  return messages;
}
```

#### 表情匹配

```dart
EmojiModel? _findEmoji(String meaning, List<EmojiModel> emojis) {
  // 精确匹配
  for (final emoji in emojis) {
    if (emoji.meaning.toLowerCase() == meaning.toLowerCase()) {
      return emoji;
    }
  }

  // 模糊匹配
  for (final emoji in emojis) {
    if (emoji.meaning.toLowerCase().contains(meaning.toLowerCase()) ||
        meaning.toLowerCase().contains(emoji.meaning.toLowerCase())) {
      return emoji;
    }
  }

  return null;
}
```

---

## 6. 重试机制

### 6.1 重试策略

```dart
static const int maxRetries = 3;
static const Duration retryDelay = Duration(seconds: 2);

static Future<List<ChatMessage>> generateResponse(...) async {
  Exception? lastException;

  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // 调用 API
      final responseText = await _callApi(apiPreset, ...);
      
      // 解析响应
      return ResponseParser.parse(responseText, ...);
      
    } catch (e) {
      lastException = e as Exception;
      
      // 记录日志
      AppLogService.e('LLM API attempt $attempt failed: $e');
      
      // 最后一次尝试不等待
      if (attempt < maxRetries) {
        await Future.delayed(retryDelay * attempt); // 指数退避
      }
    }
  }

  throw lastException ?? Exception('Unknown error after $maxRetries retries');
}
```

### 6.2 错误处理

```dart
try {
  final messages = await LlmService.generateResponse(...);
  // 成功处理
} on SocketException catch (e) {
  // 网络错误
  _showError('网络连接失败，请检查网络');
} on TimeoutException catch (e) {
  // 超时
  _showError('请求超时，请稍后重试');
} on FormatException catch (e) {
  // 解析错误
  _showError('响应格式错误');
} catch (e) {
  // 其他错误
  _showError('发生错误: $e');
}
```

---

## 7. 设计决策

### 7.1 为什么使用 JSON 而非纯文本？

| 方案 | 优点 | 缺点 |
|------|------|------|
| 纯文本 | 简单、自然 | 难以区分消息类型 |
| JSON | 结构化、易解析 | 需要格式指令 |
| XML | 结构化、容错好 | 标签冗余 |

**选择**: JSON 优先，XML 兼容

**理由**:
1. JSON 更紧凑，节省 Token
2. 现代 LLM 对 JSON 支持更好
3. XML 作为回退，处理 LLM 输出不规范的情况

### 7.2 为什么使用简化 ID？

**问题**:
```
真实消息 ID: 1738552800000-12345
AI 经常错误引用: 1738552800000-12346 (差一位)
```

**解决方案**:
```
简化 ID: 0001, 0002, 0003...
AI 引用准确率大幅提升
```

**权衡**:
- 优点: 引用准确率高
- 缺点: 需要维护 ID 映射

### 7.3 系统提示词分离

**设计**: 系统提示词存储在文件中，而非硬编码

```
assets/prompts/
├── roleplay_prompt.txt    # 角色扮演基础提示词
├── reality_prompt.txt     # 现实向提示词
├── scenario_prompt.txt    # 剧情向提示词
└── ...
```

**优点**:
1. 易于修改，无需重新编译
2. 支持运行时切换
3. 用户可自定义

### 7.4 多供应商抽象

**设计原则**: 统一接口，内部适配

```dart
// 统一入口
LlmService.generateResponse(apiPreset: preset, ...);

// 内部根据 provider 类型选择实现
switch (preset.provider) {
  case ApiProvider.openai:
    return _callOpenAI(...);
  case ApiProvider.gemini:
    return _callGemini(...);
  // ...
}
```

**好处**:
1. 调用方无需关心供应商差异
2. 新增供应商只需添加适配器
3. 响应解析统一处理

---

## 相关文档

- [架构总览](./架构总览.md)
- [消息解析](./消息解析.md)
- [生图 API 规范](./image_generation_api_spec.md)
- [后台服务](./后台服务.md)

---

*文档版本: 1.0.0 | 最后更新: 2026-02-03*