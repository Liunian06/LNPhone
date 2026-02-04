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
import '../utils/storage_utils.dart';

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
  /// 生成图片并返回结果信息
  /// 返回 Map 包含:
  /// - 'path': 生成的第一张图片本地路径（兼容旧代码）
  /// - 'paths': 生成的所有图片本地路径列表（新增，支持多图）
  /// - 'api_preset_name': 使用的 API 预设名称
  /// - 'style_preset_name': 使用的风格预设名称
  /// - 'style_prompt': 风格提示词内容
  /// - 'character_appearance': 角色外貌信息
  /// - 'user_appearance': 用户外貌信息
  /// - 'ref_image_paths': 参考图路径列表
  Future<Map<String, dynamic>?> generateImage(
    String prompt,
    String? stylePrompt, {
    bool includeCharacter = false,
    bool includeUser = false,
    String? imageApiPresetId,
    String? imageStylePresetId,
  }) async {
    ApiPreset? preset;
    String? url;
    final stopwatch = Stopwatch();
    final Map<String, dynamic> resultMetadata = {};

    try {
      // 优先使用传入的独立生图 API 预设 ID，否则使用全局默认
      String? imageModelId = imageApiPresetId;
      if (imageModelId == null) {
        // 获取当前选中的生图模型配置
        // 注意：ApiSettingsProvider 使用 'active_image_preset_id' 作为 key
        imageModelId = await _db.getSetting('active_image_api_preset_id');
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
      resultMetadata['api_preset_name'] = preset.name;

      String finalStylePrompt = '';

      // 如果传入了 stylePrompt 且不为空，则直接使用
      if (stylePrompt != null && stylePrompt.isNotEmpty) {
        finalStylePrompt = stylePrompt;
        resultMetadata['style_preset_name'] = '自定义提示词';
      } else {
        // 否则根据预设 ID 获取
        // 获取当前选定的生图预设
        String? activePresetId = imageStylePresetId;
        if (activePresetId == null || activePresetId.isEmpty) {
          activePresetId = await _db.getSetting('active_image_preset_id');
        }
        if (activePresetId == null || activePresetId.isEmpty) {
          // 兼容旧版本
          final oldStyle = await _db.getSetting('text2image_style');
          if (oldStyle != null) {
            activePresetId =
                oldStyle == 'custom' ? 't2i_custom_1' : 't2i_$oldStyle';
          } else {
            activePresetId = 't2i_realistic';
          }
        }

        final textPreset = await _db.getTextPreset(activePresetId);
        if (textPreset != null) {
          resultMetadata['style_preset_name'] = textPreset.name;
          if (textPreset.isBuiltIn) {
            try {
              finalStylePrompt =
                  await rootBundle.loadString(textPreset.content);
            } catch (e) {
              debugPrint('[ImageGeneration] Error loading built-in prompt: $e');
            }
          } else {
            finalStylePrompt = textPreset.content;
          }
        }
      }
      resultMetadata['style_prompt'] = finalStylePrompt;

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
          resultMetadata['character_appearance'] = _currentRole!.appearance;
        }
        if (_currentRole!.referenceImages.isNotEmpty) {
          // 检查参考图路径是否有效
          for (final path in _currentRole!.referenceImages) {
            if (await File(path).exists()) {
              refImagePaths.add(path);
            } else {
              debugPrint('[ImageGeneration] ⚠️ 角色参考图路径失效，已忽略: $path');
            }
          }
        }
      }

      // 添加用户外貌信息
      if (includeUser && _currentMe != null) {
        if (_currentMe!.appearance != null &&
            _currentMe!.appearance!.isNotEmpty) {
          buffer.writeln('\n[User Appearance]');
          buffer.writeln(_currentMe!.appearance);
          resultMetadata['user_appearance'] = _currentMe!.appearance;
        }
        if (_currentMe!.referenceImages.isNotEmpty) {
          // 检查参考图路径是否有效
          for (final path in _currentMe!.referenceImages) {
            if (await File(path).exists()) {
              refImagePaths.add(path);
            } else {
              debugPrint('[ImageGeneration] ⚠️ 用户参考图路径失效，已忽略: $path');
            }
          }
        }
      }

      // 如果有参考图，添加引导语
      if (refImagePaths.isNotEmpty) {
        buffer.writeln('\n以下是人物参考图，严格按照参考图中的形象生图：');
        resultMetadata['ref_image_paths'] = refImagePaths;
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
      } else if (preset.provider == ApiProvider.groklike) {
        // Grok-like 使用 chat completions 接口
        url = '$baseUrl/chat/completions';
      } else {
        // OpenAI 兼容接口
        url = '$baseUrl/images/generations';
      }

      debugPrint('[ImageGeneration] 请求 URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        // 添加浏览器特征头以绕过 Cloudflare 基本检查
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
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
      } else if (preset.provider == ApiProvider.groklike) {
        // Grok-like 使用 chat completions 格式
        body = {
          'model': preset.model,
          'messages': [
            {
              'role': 'user',
              'content': fullPrompt,
            }
          ],
          'stream': false,
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

        // 读取"强制唯一输出"设置，默认开启
        final forceUniqueOutput =
            await _db.getSettingBool('image_force_unique_output') ?? true;

        if (preset.provider == ApiProvider.groklike) {
          // Grok-like 响应解析：从 Markdown 格式提取图片 URL
          // 响应格式: {"choices": [{"message": {"content": "![image](url)\n![image](url2)"}}]}
          final imagePaths = <String>[];

          if (jsonData['choices'] != null &&
              (jsonData['choices'] as List).isNotEmpty) {
            final content =
                jsonData['choices'][0]['message']?['content'] as String?;
            if (content != null) {
              // 提取所有 Markdown 图片 URL: ![...](url)
              final urlRegex = RegExp(r'!\[.*?\]\((https?:\/\/[^\s\)]+)\)');
              final matches = urlRegex.allMatches(content);

              for (final match in matches) {
                final imageUrl = match.group(1);
                if (imageUrl != null) {
                  debugPrint(
                      '[ImageGeneration] 从 Grok-like 响应中提取到图片 URL: $imageUrl');
                  final path = await _downloadAndSaveImage(imageUrl);
                  if (path != null) {
                    imagePaths.add(path);
                    // 如果强制唯一输出，只取第一张
                    if (forceUniqueOutput) break;
                  }
                }
              }
            }
          }

          if (imagePaths.isNotEmpty) {
            return {
              'path': imagePaths.first,
              'paths': imagePaths,
              ...resultMetadata
            };
          } else {
            debugPrint('[ImageGeneration] Grok-like 响应中未找到有效图片');
            await AppLogService.log(
              '生图响应异常',
              category: 'ImageGen',
              level: LogLevel.error,
              data: {
                'error': 'No images found in Grok-like response',
                'response': jsonData
              },
            );
          }
        } else if (preset.provider == ApiProvider.gemini) {
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
              final imagePaths = <String>[];

              for (var part in parts) {
                // 1. 尝试从 inlineData 获取图片 (标准格式)
                if (part['inlineData'] != null &&
                    part['inlineData']['mimeType'] != null &&
                    part['inlineData']['mimeType'].startsWith('image/')) {
                  final b64Json = part['inlineData']['data'];
                  if (b64Json != null) {
                    final path = await _saveBase64Image(b64Json);
                    imagePaths.add(path);
                    if (forceUniqueOutput) break;
                  }
                }

                // 2. 尝试从 text 获取图片 (Markdown 格式: ![image](data:image/jpeg;base64,...))
                if (part['text'] != null &&
                    (imagePaths.isEmpty || !forceUniqueOutput)) {
                  final text = part['text'] as String;
                  // 匹配 Markdown 图片语法，提取 Base64 数据
                  // 格式通常为: ![image](data:image/jpeg;base64,BASE64_DATA)
                  final regex =
                      RegExp(r'!\[.*?\]\(data:image\/.*?;base64,(.*?)\)');
                  final matches = regex.allMatches(text);
                  for (final match in matches) {
                    final b64Json = match.group(1);
                    if (b64Json != null) {
                      debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片数据');
                      final path = await _saveBase64Image(b64Json);
                      imagePaths.add(path);
                      if (forceUniqueOutput) break;
                    }
                  }

                  // 也尝试提取 URL 格式的图片
                  if (imagePaths.isEmpty || !forceUniqueOutput) {
                    final urlRegex =
                        RegExp(r'!\[.*?\]\((https?:\/\/[^\s\)]+)\)');
                    final urlMatches = urlRegex.allMatches(text);
                    for (final urlMatch in urlMatches) {
                      final imageUrl = urlMatch.group(1);
                      if (imageUrl != null) {
                        debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片 URL');
                        final path = await _downloadAndSaveImage(imageUrl);
                        if (path != null) {
                          imagePaths.add(path);
                          if (forceUniqueOutput) break;
                        }
                      }
                    }
                  }
                }

                if (forceUniqueOutput && imagePaths.isNotEmpty) break;
              }

              if (imagePaths.isNotEmpty) {
                return {
                  'path': imagePaths.first,
                  'paths': imagePaths,
                  ...resultMetadata
                };
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
          final imagePaths = <String>[];

          if (jsonData['data'] != null &&
              (jsonData['data'] as List).isNotEmpty) {
            for (final item in jsonData['data']) {
              final b64Json = item['b64_json'] as String?;
              final imageUrl = item['url'] as String?;

              if (b64Json != null) {
                final path = await _saveBase64Image(b64Json);
                imagePaths.add(path);
                if (forceUniqueOutput) break;
              } else if (imageUrl != null) {
                final path = await _downloadAndSaveImage(imageUrl);
                if (path != null) {
                  imagePaths.add(path);
                  if (forceUniqueOutput) break;
                }
              }
            }

            if (imagePaths.isNotEmpty) {
              return {
                'path': imagePaths.first,
                'paths': imagePaths,
                ...resultMetadata
              };
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
                  final path = await _saveBase64Image(b64Json);
                  imagePaths.add(path);
                  if (forceUniqueOutput) break;
                }
              }
              // 2.2 尝试从 text 获取图片 (Markdown 格式)
              if (part['text'] != null &&
                  (imagePaths.isEmpty || !forceUniqueOutput)) {
                final text = part['text'] as String;
                final regex =
                    RegExp(r'!\[.*?\]\(data:image\/.*?;base64,(.*?)\)');
                final matches = regex.allMatches(text);
                for (final match in matches) {
                  final b64Json = match.group(1);
                  if (b64Json != null) {
                    debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片数据');
                    final path = await _saveBase64Image(b64Json);
                    imagePaths.add(path);
                    if (forceUniqueOutput) break;
                  }
                }
                // 2.3 尝试从 text 获取图片 URL (Markdown 格式)
                if (imagePaths.isEmpty || !forceUniqueOutput) {
                  final urlRegex = RegExp(r'!\[.*?\]\((https?:\/\/[^\s\)]+)\)');
                  final urlMatches = urlRegex.allMatches(text);
                  for (final urlMatch in urlMatches) {
                    final imageUrl = urlMatch.group(1);
                    if (imageUrl != null) {
                      debugPrint('[ImageGeneration] 从 Markdown 文本中提取到图片 URL');
                      final path = await _downloadAndSaveImage(imageUrl);
                      if (path != null) {
                        imagePaths.add(path);
                        if (forceUniqueOutput) break;
                      }
                    }
                  }
                }
              }

              if (forceUniqueOutput && imagePaths.isNotEmpty) break;
            }

            if (imagePaths.isNotEmpty) {
              return {
                'path': imagePaths.first,
                'paths': imagePaths,
                ...resultMetadata
              };
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
              throw Exception('${error['message']}');
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
        return {
          'error': 'API 请求失败: HTTP ${response.statusCode} ${response.body}'
        };
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
      return {'error': '发生异常: $e'};
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
    final fileName = 'img_${StorageUtils.getUniqueTimestamp()}.png';
    final file = File('${imagesDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String?> _downloadAndSaveImage(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
        },
      );
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${directory.path}/generated_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        final fileName = 'img_${StorageUtils.getUniqueTimestamp()}.png';
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
