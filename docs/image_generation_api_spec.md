# 生图模型 API 规范文档

本文档描述了应用支持的四个生图供应商的 API 请求规范，包括请求 URL、请求体构造和响应解析规则。

---

## 目录

1. [Volcengine 火山引擎](#1-volcengine-火山引擎)
2. [Gemini](#2-gemini)
3. [OpenAI Compatible 类OpenAI接口](#3-openai-compatible-类openai接口)
4. [Groklike 类Grok接口](#4-groklike-类grok接口)

---

## 1. Volcengine 火山引擎

### 基本信息

| 项目 | 值 |
|------|-----|
| 供应商标识 | `volcengine` |
| 默认 Base URL | `https://ark.cn-beijing.volces.com/api/v3` |
| 默认模型 | `doubao-seedream-4-5-251128` |

### 请求 URL

```
POST {baseUrl}/images/generations
```

### 请求头

```http
Content-Type: application/json
Authorization: Bearer {apiKey}
```

### 请求体

```json
{
  "model": "doubao-seedream-4-5-251128",
  "prompt": "完整的图片描述提示词",
  "n": 1,
  "size": "4K",
  "watermark": false,
  "response_format": "b64_json"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| model | string | 是 | 模型名称 |
| prompt | string | 是 | 图片描述提示词 |
| n | int | 否 | 生成图片数量，默认 1 |
| size | string | 否 | 图片尺寸，火山引擎支持 `4K` |
| watermark | bool | 否 | 是否添加水印，默认 false |
| response_format | string | 否 | 响应格式，`b64_json` 返回 Base64 |

### 响应体

```json
{
  "data": [
    {
      "b64_json": "iVBORw0KGgoAAAANSUhEUgAA..."
    }
  ]
}
```

### 解析规则

1. 检查 `data` 数组是否存在且非空
2. 遍历 `data` 数组中的每个项
3. 提取 `b64_json` 字段，解码 Base64 数据
4. 保存为本地图片文件

```dart
if (jsonData['data'] != null && (jsonData['data'] as List).isNotEmpty) {
  for (final item in jsonData['data']) {
    final b64Json = item['b64_json'] as String?;
    if (b64Json != null) {
      final path = await _saveBase64Image(b64Json);
      imagePaths.add(path);
    }
  }
}
```

---

## 2. Gemini

### 基本信息

| 项目 | 值 |
|------|-----|
| 供应商标识 | `gemini` |
| 默认 Base URL | `https://generativelanguage.googleapis.com` |
| 默认模型 | `gemini-3-pro-image-preview` |

### 请求 URL

```
POST {baseUrl}/v1beta/models/{model}:generateContent?key={apiKey}
```

**注意**：API Key 通过 URL 参数传递，而非 Authorization 头。

### 请求头

```http
Content-Type: application/json
```

### 请求体

```json
{
  "contents": [
    {
      "parts": [
        {
          "text": "完整的图片描述提示词"
        },
        {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": "参考图的Base64数据（可选）"
          }
        }
      ]
    }
  ],
  "generationConfig": {
    "responseModalities": ["TEXT", "IMAGE"],
    "imageConfig": {
      "imageSize": "4K"
    }
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| contents | array | 是 | 内容数组 |
| contents[].parts | array | 是 | 内容部分，可包含文本和图片 |
| contents[].parts[].text | string | 是 | 提示词文本 |
| contents[].parts[].inline_data | object | 否 | 参考图数据 |
| generationConfig | object | 是 | 生成配置 |
| generationConfig.responseModalities | array | 是 | 响应类型，需包含 `IMAGE` |
| generationConfig.imageConfig | object | 否 | 图片配置 |

### 响应体

**格式 1：inlineData 格式（标准）**

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "inlineData": {
              "mimeType": "image/png",
              "data": "iVBORw0KGgoAAAANSUhEUgAA..."
            }
          }
        ]
      },
      "finishReason": "STOP"
    }
  ]
}
```

**格式 2：Markdown 格式**

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "![image](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...)"
          }
        ]
      }
    }
  ]
}
```

**格式 3：URL 格式**

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "![image](https://example.com/generated-image.png)"
          }
        ]
      }
    }
  ]
}
```

### 解析规则

1. 检查 `candidates` 数组是否存在且非空
2. 检查 `finishReason` 是否为 `STOP`（非 STOP 可能表示被拦截）
3. 遍历 `content.parts` 数组
4. **优先级 1**：检查 `inlineData`，提取 `data` 字段的 Base64 数据
5. **优先级 2**：检查 `text` 字段，使用正则提取 Markdown Base64 图片
6. **优先级 3**：检查 `text` 字段，使用正则提取 Markdown URL 图片

```dart
// 正则表达式
final base64Regex = RegExp(r'!\[.*?\]\(data:image\/.*?;base64,(.*?)\)');
final urlRegex = RegExp(r'!\[.*?\]\((https?:\/\/[^\s\)]+)\)');
```

---

## 3. OpenAI Compatible 类OpenAI接口

### 基本信息

| 项目 | 值 |
|------|-----|
| 供应商标识 | `openaicompatible` |
| 默认 Base URL | `https://api.openai.com/v1` |
| 默认模型 | `dall-e-3` |

### 请求 URL

```
POST {baseUrl}/images/generations
```

### 请求头

```http
Content-Type: application/json
Authorization: Bearer {apiKey}
```

### 请求体

```json
{
  "model": "dall-e-3",
  "prompt": "完整的图片描述提示词",
  "n": 1,
  "response_format": "b64_json"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| model | string | 是 | 模型名称 |
| prompt | string | 是 | 图片描述提示词 |
| n | int | 否 | 生成图片数量 |
| response_format | string | 否 | `b64_json` 或 `url` |
| image | string | 否 | 参考图 Base64（部分服务支持） |

### 响应体

**格式 1：OpenAI 标准格式（Base64）**

```json
{
  "data": [
    {
      "b64_json": "iVBORw0KGgoAAAANSUhEUgAA..."
    }
  ]
}
```

**格式 2：OpenAI 标准格式（URL）**

```json
{
  "data": [
    {
      "url": "https://example.com/generated-image.png"
    }
  ]
}
```

**格式 3：Gemini 格式（NewAPI 转发场景）**

部分 API 代理服务（如 NewAPI）可能直接返回 Gemini 格式的响应，参见 [Gemini 响应体](#响应体-1)。

### 解析规则

1. **尝试解析 OpenAI 格式**：
   - 检查 `data` 数组
   - 提取 `b64_json` 或 `url` 字段
   - 如果是 URL，下载图片

2. **尝试解析 Gemini 格式**（兼容 NewAPI）：
   - 检查 `candidates` 数组
   - 按 Gemini 规则解析

3. **错误处理**：
   - 检查 `error` 字段

```dart
// 优先解析 OpenAI 格式
if (jsonData['data'] != null) {
  final b64Json = item['b64_json'];
  final url = item['url'];
  // ...
}
// 兼容 Gemini 格式
else if (jsonData['candidates'] != null) {
  // 按 Gemini 规则解析
}
```

---

## 4. Groklike 类Grok接口

### 基本信息

| 项目 | 值 |
|------|-----|
| 供应商标识 | `groklike` |
| 默认 Base URL | `https://api.x.ai/v1` |
| 默认模型 | `grok-2-image` |

### 请求 URL

```
POST {baseUrl}/chat/completions
```

**特点**：使用聊天补全接口而非专用图片生成接口。

### 请求头

```http
Content-Type: application/json
Authorization: Bearer {apiKey}
```

### 请求体

```json
{
  "model": "grok-2-image",
  "messages": [
    {
      "role": "user",
      "content": "完整的图片描述提示词"
    }
  ],
  "stream": false
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| model | string | 是 | 模型名称 |
| messages | array | 是 | 消息数组 |
| messages[].role | string | 是 | 角色，通常为 `user` |
| messages[].content | string | 是 | 提示词内容 |
| stream | bool | 否 | 是否流式响应，生图建议 false |

### 响应体

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "![Generated Image](https://example.com/image1.png)\n\n![Another Image](https://example.com/image2.png)"
      }
    }
  ]
}
```

图片以 Markdown 格式嵌入在 `content` 字段中，可能包含多张图片。

### 解析规则

1. 检查 `choices` 数组是否存在且非空
2. 提取 `choices[0].message.content` 字段
3. 使用正则表达式提取所有 Markdown 图片 URL
4. 下载每张图片并保存到本地
5. 根据"强制唯一输出"设置决定是否只取第一张

```dart
// 正则表达式：匹配 Markdown 图片链接
final urlRegex = RegExp(r'!\[.*?\]\((https?:\/\/[^\s\)]+)\)');

// 提取所有匹配
final matches = urlRegex.allMatches(content);
for (final match in matches) {
  final imageUrl = match.group(1);
  if (imageUrl != null) {
    final path = await _downloadAndSaveImage(imageUrl);
    imagePaths.add(path);
    if (forceUniqueOutput) break; // 强制唯一输出时只取第一张
  }
}
```

---

## 通用设置

### 强制唯一输出

数据库设置项：`image_force_unique_output`

| 值 | 说明 |
|----|------|
| `true` (默认) | 只返回第一张生成的图片 |
| `false` | 返回所有生成的图片 |

该设置影响所有供应商的响应解析行为。

### 返回值格式

`generateImage()` 方法返回 `Map<String, dynamic>?`：

```dart
{
  'path': '/path/to/first/image.png',     // 第一张图片路径（兼容旧代码）
  'paths': ['/path/to/image1.png', ...],  // 所有图片路径列表
  'api_preset_name': 'My Preset',          // API 预设名称
  'style_preset_name': '动漫风格',          // 风格预设名称
  'style_prompt': '...',                   // 风格提示词
  'character_appearance': '...',           // 角色外貌（如有）
  'user_appearance': '...',                // 用户外貌（如有）
  'ref_image_paths': [...]                 // 参考图路径列表（如有）
}
```

---

## 代码位置参考

| 文件 | 说明 |
|------|------|
| [`lib/core/models/api_preset.dart`](../lib/core/models/api_preset.dart) | ApiProvider 枚举定义 |
| [`lib/core/services/image_generation_service.dart`](../lib/core/services/image_generation_service.dart) | 生图服务实现 |
| [`lib/core/providers/api_settings_provider.dart`](../lib/core/providers/api_settings_provider.dart) | 测试生图功能 |
| [`lib/screens/image_model_settings_screen.dart`](../lib/screens/image_model_settings_screen.dart) | 设置界面 |