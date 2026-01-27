import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/api_preset.dart';
import '../database/database.dart';
import 'app_log_service.dart';
import 'api_log_service.dart';
import '../models/api_log.dart';

import '../models/contact_model.dart';
import '../utils/image_utils.dart';

class ImageGenerationService {
  static final ImageGenerationService _instance =
      ImageGenerationService._internal();
  factory ImageGenerationService() => _instance;
  ImageGenerationService._internal();

  final AppDatabase _db = AppDatabase();

  // 暂存当前上下文信息
  ContactRole? _currentRole;
  ContactMe? _currentMe;

  void setCurrentContext(ContactRole? role, ContactMe? me) {
    _currentRole = role;
    _currentMe = me;
  }

  /// 生成图片
  /// [prompt] 图片描述
  /// [stylePrompt] 风格提示词
  /// [includeCharacter] 是否包含角色外貌信息
  /// [includeUser] 是否包含用户外貌信息
  /// [imageApiPresetId] 独立的生图 API 预设 ID
  /// 返回生成的图片本地路径
  Future<String?> generateImage(
    String prompt,
    String stylePrompt, {
    bool includeCharacter = false,
    bool includeUser = false,
    String? imageApiPresetId,
  }) async {
    ApiPreset? preset;
    String? url;
    final stopwatch = Stopwatch();

    try {
      // 优先使用传入的独立生图 API 预设 ID，否则使用全局默认
      String? imageModelId = imageApiPresetId;
      if (imageModelId == null) {
        // 获取当前选中的生图模型配置
        // 注意：ApiSettingsProvider 使用 'active_image_preset_id' 作为 key
        imageModelId = await _db.getSetting('active_image_preset_id');
      }

      if (imageModelId == null) {
        debugPrint(
            '[ImageGeneration] 未配置生图模型 (active_image_preset_id is null)');
        return null;
      }

      final apiPresets = await _db.getAllApiPresets();
      try {
        preset = apiPresets.firstWhere((p) => p.id == imageModelId);
      } catch (e) {
        debugPrint('[ImageGeneration] 找不到ID为 $imageModelId 的API预设');
        return null;
      }

      debugPrint(
          '[ImageGeneration] 使用预设: ${preset.name}, Provider: ${preset.provider}, BaseURL: ${preset.baseUrl}, Model: ${preset.model}');

      // 从数据库读取当前选定的生图风格
      final style = await _db.getSetting('text2image_style') ?? 'realistic';

      String finalStylePrompt = '';

      if (style == 'custom') {
        finalStylePrompt =
            await _db.getSetting('custom_text2image_prompt') ?? '';
      } else {
        // 根据风格确定 asset 路径
        String assetPath;
        switch (style) {
          case 'anime':
            assetPath = 'assets/prompts/t2i_anime.txt';
            break;
          case 'cyberpunk':
            assetPath = 'assets/prompts/t2i_cyberpunk.txt';
            break;
          case 'oil_painting':
            assetPath = 'assets/prompts/t2i_oil_painting.txt';
            break;
          case 'ink_painting':
            assetPath = 'assets/prompts/t2i_ink_painting.txt';
            break;
          case 'webtoon':
            assetPath = 'assets/prompts/t2i_webtoon.txt';
            break;
          case 'beautiful_lighting':
            assetPath = 'assets/prompts/t2i_beautiful_lighting.txt';
            break;
          case 'realistic':
          default:
            assetPath = 'assets/prompts/text2image_prompt.txt';
            break;
        }

        try {
          finalStylePrompt = await rootBundle.loadString(assetPath);
        } catch (e) {
          debugPrint(
              '[ImageGeneration] Error loading style prompt ($assetPath): $e');
          // 如果加载失败，尝试加载默认风格
          try {
            finalStylePrompt = await rootBundle
                .loadString('assets/prompts/text2image_prompt.txt');
          } catch (_) {}
        }
      }

      final buffer = StringBuffer();
      if (finalStylePrompt.isNotEmpty) {
        buffer.writeln(finalStylePrompt);
      }
      buffer.writeln(prompt);

      final List<String> refImagePaths = [];

      // 添加角色外貌信息
      if (includeCharacter && _currentRole != null) {
        if (_currentRole!.appearance != null &&
            _currentRole!.appearance!.isNotEmpty) {
          buffer.writeln('\n[Character Appearance]');
          buffer.writeln(_currentRole!.appearance);
        }
        if (_currentRole!.referenceImages.isNotEmpty) {
          refImagePaths.addAll(_currentRole!.referenceImages);
        }
      }

      // 添加用户外貌信息
      if (includeUser && _currentMe != null) {
        if (_currentMe!.appearance != null &&
            _currentMe!.appearance!.isNotEmpty) {
          buffer.writeln('\n[User Appearance]');
          buffer.writeln(_currentMe!.appearance);
        }
        if (_currentMe!.referenceImages.isNotEmpty) {
          refImagePaths.addAll(_currentMe!.referenceImages);
        }
      }

      // 如果有参考图，添加引导语
      if (refImagePaths.isNotEmpty) {
        buffer.writeln('\n以下是人物参考图，严格按照参考图中的形象生图：');
      }

      final fullPrompt = buffer.toString();
      debugPrint('[ImageGeneration] 开始生成图片，Prompt: $fullPrompt');

      stopwatch.start();

      // 记录生图开始日志
      await AppLogService.log(
        '开始生成图片',
        category: 'ImageGen',
        level: LogLevel.info,
        data: {
          'provider': preset.provider.name,
          'model': preset.model,
          'baseUrl': preset.baseUrl,
          'prompt': prompt,
          'stylePrompt': finalStylePrompt,
          'fullPrompt': fullPrompt,
        },
      );

      // 根据不同的提供商调用不同的API
      // 目前主要支持 OpenAI (DALL-E) 和 SiliconFlow (Flux/SD)
      // 这里以兼容 OpenAI 接口格式为例（大多数生图API都兼容）

      // 处理 baseUrl，确保没有尾随斜杠
      var baseUrl = preset.baseUrl.trim();
      if (baseUrl.isEmpty) {
        // 如果 baseUrl 为空，根据 provider 设置默认值
        if (preset.provider == ApiProvider.volcengine) {
          baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
        } else if (preset.provider == ApiProvider.gemini) {
          baseUrl = 'https://generativelanguage.googleapis.com';
        } else if (preset.provider == ApiProvider.openaicompatible) {
          baseUrl = 'https://api.openai.com/v1';
        } else {
          // 默认 OpenAI
          baseUrl = 'https://api.openai.com/v1';
        }
      }

      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      // 构建请求 URL
      if (preset.provider == ApiProvider.gemini) {
        url =
            '$baseUrl/v1beta/models/${preset.model}:generateContent?key=${preset.apiKey}';
      } else {
        // OpenAI 兼容接口
        url = '$baseUrl/images/generations';
      }

      debugPrint('[ImageGeneration] 请求 URL: $url');

      final headers = {
        'Content-Type': 'application/json',
      };

      if (preset.provider != ApiProvider.gemini) {
        headers['Authorization'] = 'Bearer ${preset.apiKey}';
      }

      Map<String, dynamic> body;

      if (preset.provider == ApiProvider.gemini) {
        final parts = <Map<String, dynamic>>[
          {"text": fullPrompt}
        ];

        // 将参考图添加到 Gemini 请求中
        int imageCount = 0;
        for (final imagePath in refImagePaths) {
          final base64 = await ImageUtils.imageToBase64(imagePath);
          if (base64 != null) {
            debugPrint('[ImageGeneration] 添加参考图: $imagePath');
            parts.add({
              "inline_data": {
                "mime_type": ImageUtils.getMimeType(imagePath),
                "data": base64
              }
            });
            imageCount++;
          } else {
            debugPrint('[ImageGeneration] ⚠️ 参考图加载失败: $imagePath');
          }
        }
        debugPrint('[ImageGeneration] 共添加 $imageCount 张参考图到请求中');

        body = {
          "contents": [
            {"parts": parts}
          ],
          "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "imageConfig": {
              "imageSize": "4K",
            }
          }
        };
      } else {
        // OpenAI / Volcengine / OpenAI Compatible
        body = {
          'model': preset.model,
          'prompt': fullPrompt,
          'n': 1,
          // 'size': '1024x1024', // Remove size constraint for compatibility
          'response_format': 'b64_json',
        };

        // 如果有参考图，且是 OpenAI Compatible，尝试将参考图添加到请求体中
        // 针对 NewAPI 转发 Gemini 等场景，可能支持 'image' 字段传入 Base64
        if (refImagePaths.isNotEmpty &&
            preset.provider == ApiProvider.openaicompatible) {
          final imagePath = refImagePaths.first;
          final base64 = await ImageUtils.imageToBase64(imagePath);
          if (base64 != null) {
            body['image'] = base64;
            debugPrint(
                '[ImageGeneration] 添加参考图(Base64)到 OpenAI Compatible 请求中');
          }
        } else if (refImagePaths.isNotEmpty) {
          debugPrint(
              '[ImageGeneration] ⚠️ 当前 Provider (${preset.provider}) 可能不支持参考图 (img2img)，参考图将被忽略');
        }

        // Volcengine 特殊处理
        if (preset.provider == ApiProvider.volcengine) {
          body['size'] = '4K'; // 豆包模型可能需要特定的 size 格式
          body['watermark'] = false;
        }
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: preset.timeout));

      // 记录 API 响应
      await AppLogService.log(
        '生图 API 响应',
        category: 'ImageGen',
        level: LogLevel.debug,
        data: {
          'statusCode': response.statusCode,
          // 截断 body，防止 Base64 数据过大导致内存溢出 (OOM)
          'body': response.body.length > 1000
              ? '${response.body.substring(0, 1000)}... [truncated]'
              : response.body,
        },
      );

      if (response.statusCode == 200) {
        // 尝试解码响应体，处理可能的编码问题
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          // 如果 UTF-8 解码失败，尝试直接使用 body (通常是 latin1)
          responseBody = response.body;
        }

        final jsonData = jsonDecode(responseBody);

        if (preset.provider == ApiProvider.gemini) {
          if (jsonData['candidates'] != null &&
              (jsonData['candidates'] as List).isNotEmpty) {
            final candidate = jsonData['candidates'][0];
            // 检查是否有 finishReason
            if (candidate['finishReason'] != null &&
                candidate['finishReason'] != 'STOP') {
              final reason = candidate['finishReason'];
              debugPrint('[ImageGeneration] Gemini 生成停止，原因: $reason');
              await AppLogService.log(
                '生图被拦截',
                category: 'ImageGen',
                level: LogLevel.warning,
                data: {'finishReason': reason, 'response': jsonData},
              );
            }

            if (candidate['content'] != null &&
                candidate['content']['parts'] != null) {
              final parts = candidate['content']['parts'] as List;
              for (var part in parts) {
                // 1. 尝试从 inlineData 获取图片 (标准格式)
                if (part['inlineData'] != null &&
                    part['inlineData']['mimeType'] != null &&
                    part['inlineData']['mimeType'].startsWith('image/')) {
                  final b64Json = part['inlineData']['data'];
                  if (b64Json != null) {
                    return await _saveBase64Image(b64Json);
                  }
                }

                // 2. 尝试从 text 获取图片 (Markdown 格式: ![image](data:image/jpeg;base64,...))
                if (part['text'] != null) {
                  final text = part['text'] as String;
                  // 匹配 Markdown 图片语法，提取 Base64 数据
                  // 格式通常为: ![image](data:image/jpeg;base64,BASE64_DATA)
                  final regex =
                      RegExp(r'!\[.*?\]\(data:image\/.*?;base64,(.*?)\)');
                  final match = regex.firstMatch(text);
                  if (match != null) {
                    final b64Json = match.group(1);
                    if (b64Json != null) {
                      debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片数据');
                      return await _saveBase64Image(b64Json);
                    }
                  }
                }
              }
            }
          } else {
            debugPrint('[ImageGeneration] Gemini 响应中没有 candidates');
            await AppLogService.log(
              '生图响应异常',
              category: 'ImageGen',
              level: LogLevel.error,
              data: {'error': 'No candidates found', 'response': jsonData},
            );
          }
        } else {
          // 尝试解析 OpenAI 格式
          if (jsonData['data'] != null &&
              (jsonData['data'] as List).isNotEmpty) {
            final b64Json = jsonData['data'][0]['b64_json'] as String?;
            final imageUrl = jsonData['data'][0]['url'] as String?;

            if (b64Json != null) {
              return await _saveBase64Image(b64Json);
            } else if (imageUrl != null) {
              return await _downloadAndSaveImage(imageUrl);
            }
          }
          // 2. 尝试解析 Gemini 格式 (NewAPI 转发可能直接返回 Gemini 格式)
          else if (jsonData['candidates'] != null &&
              (jsonData['candidates'] as List).isNotEmpty) {
            final parts = jsonData['candidates'][0]['content']['parts'] as List;
            for (var part in parts) {
              // 2.1 尝试从 inlineData 获取图片
              if (part['inlineData'] != null &&
                  part['inlineData']['mimeType'].startsWith('image/')) {
                final b64Json = part['inlineData']['data'];
                if (b64Json != null) {
                  return await _saveBase64Image(b64Json);
                }
              }
              // 2.2 尝试从 text 获取图片 (Markdown 格式)
              if (part['text'] != null) {
                final text = part['text'] as String;
                final regex =
                    RegExp(r'!\[.*?\]\(data:image\/.*?;base64,(.*?)\)');
                final match = regex.firstMatch(text);
                if (match != null) {
                  final b64Json = match.group(1);
                  if (b64Json != null) {
                    debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片数据');
                    return await _saveBase64Image(b64Json);
                  }
                }
                // 2.3 尝试从 text 获取图片 URL (Markdown 格式)
                final urlRegex = RegExp(r'!\[.*?\]\((https?:\/\/.*?)\)');
                final urlMatch = urlRegex.firstMatch(text);
                if (urlMatch != null) {
                  final url = urlMatch.group(1);
                  if (url != null) {
                    debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片 URL');
                    return await _downloadAndSaveImage(url);
                  }
                }
              }
            }
          } else if (jsonData['error'] != null) {
            final error = jsonData['error'];
            debugPrint('[ImageGeneration] OpenAI API 返回错误: $error');
            await AppLogService.log(
              '生图 API 返回错误',
              category: 'ImageGen',
              level: LogLevel.error,
              data: {'error': error},
            );
            // 抛出异常以便上层捕获
            if (error is Map && error['message'] != null) {
              throw Exception(error['message']);
            } else {
              throw Exception(error.toString());
            }
          } else {
            debugPrint('[ImageGeneration] OpenAI 响应格式无法解析');
            await AppLogService.log(
              '生图响应异常',
              category: 'ImageGen',
              level: LogLevel.error,
              data: {'error': 'Unknown response format', 'response': jsonData},
            );
          }
        }
      } else {
        debugPrint(
            '[ImageGeneration] API请求失败: ${response.statusCode} ${response.body}');
        await AppLogService.log(
          '生图 API 请求失败',
          category: 'ImageGen',
          level: LogLevel.error,
          data: {
            'statusCode': response.statusCode,
            'body': response.body,
          },
        );
      }

      // 记录成功的 API 调用日志
      if (preset != null && url != null) {
        stopwatch.stop();
        final durationSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;
        await ApiLogService.logApiCall(ApiLog(
          callTime: DateTime.now().toIso8601String(),
          provider: preset.provider.name,
          apiUrl: url!,
          modelId: preset.model,
          durationSeconds: durationSeconds,
        ));
      }
    } catch (e) {
      debugPrint('[ImageGeneration] 生成图片异常: $e');
      await AppLogService.log(
        '生成图片异常',
        category: 'ImageGen',
        level: LogLevel.error,
        data: {'error': e.toString()},
      );

      if (preset != null && url != null) {
        if (stopwatch.isRunning) stopwatch.stop();
        final durationSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;
        await ApiLogService.logApiCall(ApiLog(
          callTime: DateTime.now().toIso8601String(),
          provider: preset.provider.name,
          apiUrl: url!,
          modelId: preset.model,
          durationSeconds: durationSeconds,
          error: e.toString(),
        ));
      }
    }
    return null;
  }

  Future<String> _saveBase64Image(String b64Json) async {
    final bytes = base64Decode(b64Json);
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/generated_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${imagesDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String?> _downloadAndSaveImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${directory.path}/generated_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${imagesDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('[ImageGeneration] 下载图片失败: $e');
    }
    return null;
  }
}
