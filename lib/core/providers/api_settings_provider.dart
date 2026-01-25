import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/api_preset.dart';
import '../database/database.dart';

/// API 设置提供者
/// 注意：所有设置现在存储在数据库中
/// SharedPreferences 已被弃用，仅用于兼容迁移
class ApiSettingsProvider extends ChangeNotifier {
  List<ApiPreset> _presets = [];
  String? _activePresetId;
  String? _activeImagePresetId;
  bool _isLoading = false;
  bool _isInitialized = false;
  final AppDatabase _db = AppDatabase();

  List<ApiPreset> get presets => _presets;
  List<ApiPreset> get chatPresets =>
      _presets.where((p) => p.type == ApiPresetType.chat).toList();
  List<ApiPreset> get imagePresets =>
      _presets.where((p) => p.type == ApiPresetType.image).toList();

  String? get activePresetId => _activePresetId;
  String? get activeImagePresetId => _activeImagePresetId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  ApiPreset? get activePreset {
    if (_activePresetId == null) return null;
    try {
      return _presets.firstWhere((p) => p.id == _activePresetId);
    } catch (e) {
      return null;
    }
  }

  ApiPreset? get activeImagePreset {
    if (_activeImagePresetId == null) return null;
    try {
      return _presets.firstWhere((p) => p.id == _activeImagePresetId);
    } catch (e) {
      return null;
    }
  }

  ApiSettingsProvider() {
    _loadPresets();
  }

  /// 重新从数据库加载数据（用于数据导入后刷新）
  Future<void> reload() async {
    _presets = await _db.getAllApiPresetsFromDb();

    // 验证 activePresetId 是否仍然有效
    if (_activePresetId != null) {
      final presetExists = _presets.any((p) => p.id == _activePresetId);
      if (!presetExists) {
        _activePresetId = null;
        await _saveActivePresetId();
      }
    }

    // 验证 activeImagePresetId 是否仍然有效
    if (_activeImagePresetId != null) {
      final presetExists = _presets.any((p) => p.id == _activeImagePresetId);
      if (!presetExists) {
        _activeImagePresetId = null;
        await _saveActiveImagePresetId();
      }
    }

    notifyListeners();
  }

  Future<void> _loadPresets() async {
    try {
      // 无论数据库是否有数据，都尝试从 SharedPreferences 迁移
      // 这样可以确保从任何中间版本升级时都不会丢失数据
      await _migrateFromSharedPreferences();

      // 从数据库加载最新数据
      _presets = await _db.getAllApiPresetsFromDb();

      // 加载活动预设 ID（从数据库读取）
      _activePresetId = await _db.getSetting('active_preset_id');
      _activeImagePresetId = await _db.getSetting('active_image_preset_id');

      // 验证 activePresetId 是否仍然有效
      if (_activePresetId != null) {
        final presetExists = _presets.any((p) => p.id == _activePresetId);
        if (!presetExists) {
          _activePresetId = null;
          await _db.deleteSetting('active_preset_id');
        }
      }

      // 验证 activeImagePresetId 是否仍然有效
      if (_activeImagePresetId != null) {
        final presetExists = _presets.any((p) => p.id == _activeImagePresetId);
        if (!presetExists) {
          _activeImagePresetId = null;
          await _db.deleteSetting('active_image_preset_id');
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading API presets: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 从 SharedPreferences 迁移所有数据到数据库（兼容旧版本）
  /// 使用增量更新策略：只添加数据库中不存在的数据，不覆盖已有数据
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasMigrated = false;

    // 迁移预设数据（增量更新：只添加数据库中没有的）
    final presetsJson = prefs.getStringList('api_presets');
    if (presetsJson != null && presetsJson.isNotEmpty) {
      try {
        final presetsFromPrefs = presetsJson
            .map((json) => ApiPreset.fromJson(jsonDecode(json)))
            .toList();

        // 获取数据库中已有的预设 ID
        final existingPresets = await _db.getAllApiPresetsFromDb();
        final existingPresetIds = existingPresets.map((p) => p.id).toSet();

        // 只添加数据库中不存在的预设
        int addedCount = 0;
        for (final preset in presetsFromPrefs) {
          if (!existingPresetIds.contains(preset.id)) {
            await _db.insertApiPreset(preset);
            addedCount++;
          }
        }

        // 迁移成功后清除旧数据
        await prefs.remove('api_presets');
        hasMigrated = true;
        if (addedCount > 0) {
          debugPrint(
              '[ApiSettingsProvider] 已从 SharedPreferences 增量添加 $addedCount 个 API 预设');
        }
      } catch (e) {
        debugPrint('[ApiSettingsProvider] 增量添加预设数据失败: $e');
      }
    }

    // 迁移活动预设 ID（只在数据库中没有时才添加）
    final activeId = prefs.getString('active_preset_id');
    if (activeId != null) {
      try {
        // 只有数据库中没有 active_preset_id 时才添加
        final existingActiveId = await _db.getSetting('active_preset_id');
        if (existingActiveId == null) {
          await _db.setSetting('active_preset_id', activeId);
          debugPrint(
              '[ApiSettingsProvider] 已从 SharedPreferences 增量添加 active_preset_id');
        }

        // 迁移成功后清除旧数据
        await prefs.remove('active_preset_id');
        hasMigrated = true;
      } catch (e) {
        debugPrint('[ApiSettingsProvider] 增量添加 active_preset_id 失败: $e');
      }
    }

    if (hasMigrated) {
      debugPrint('[ApiSettingsProvider] 数据迁移完成');
    }
  }

  /// 保存活动预设ID到数据库
  Future<void> _saveActivePresetId() async {
    if (_activePresetId != null) {
      await _db.setSetting('active_preset_id', _activePresetId!);
    } else {
      await _db.deleteSetting('active_preset_id');
    }
  }

  /// 保存活动生图预设ID到数据库
  Future<void> _saveActiveImagePresetId() async {
    if (_activeImagePresetId != null) {
      await _db.setSetting('active_image_preset_id', _activeImagePresetId!);
    } else {
      await _db.deleteSetting('active_image_preset_id');
    }
  }

  Future<void> addPreset(ApiPreset preset) async {
    if (_presets.length >= 50) {
      throw Exception('最多只能存储50个预设');
    }
    _presets.add(preset);
    await _db.insertApiPreset(preset);
    notifyListeners();
  }

  Future<void> updatePreset(ApiPreset preset) async {
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      _presets[index] = preset;
      await _db.insertApiPreset(preset);
      notifyListeners();
    }
  }

  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    await _db.deleteApiPreset(id);
    if (_activePresetId == id) {
      _activePresetId = null;
      await _saveActivePresetId();
    }
    if (_activeImagePresetId == id) {
      _activeImagePresetId = null;
      await _saveActiveImagePresetId();
    }
    notifyListeners();
  }

  Future<void> setActivePreset(String? id) async {
    _activePresetId = id;
    await _saveActivePresetId();
    notifyListeners();
  }

  Future<void> setActiveImagePreset(String? id) async {
    _activeImagePresetId = id;
    await _saveActiveImagePresetId();
    notifyListeners();
  }

  Future<List<String>> fetchModels(ApiPreset preset) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<String> models = [];
      if (preset.provider == ApiProvider.openai) {
        models = await _fetchOpenAIModels(preset);
      } else if (preset.provider == ApiProvider.gemini) {
        models = await _fetchGeminiModels(preset);
      }
      return models;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> _fetchOpenAIModels(ApiPreset preset) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://api.openai.com/v1';
    }
    // Ensure no trailing slash
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.get(
      Uri.parse('$cleanBaseUrl/models'),
      headers: {'Authorization': 'Bearer ${preset.apiKey}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> dataList = data['data'];
      return dataList.map<String>((e) => e['id'].toString()).toList();
    } else {
      throw Exception('Failed to fetch models: ${response.body}');
    }
  }

  Future<List<String>> _fetchGeminiModels(ApiPreset preset) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://generativelanguage.googleapis.com';
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.get(
      Uri.parse('$cleanBaseUrl/v1beta/models?key=${preset.apiKey}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> models = data['models'];
      return models
          .map<String>((e) => e['name'].toString().replaceFirst('models/', ''))
          .toList();
    } else {
      throw Exception('Failed to fetch models: ${response.body}');
    }
  }

  Future<void> testConnection(ApiPreset preset) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (preset.provider == ApiProvider.openai) {
        await _testOpenAIConnection(preset);
      } else if (preset.provider == ApiProvider.gemini) {
        await _testGeminiConnection(preset);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _testOpenAIConnection(ApiPreset preset) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://api.openai.com/v1';
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.post(
      Uri.parse('$cleanBaseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${preset.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': preset.model,
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
        'max_tokens': 5,
        if (!preset.enableThinking) 'enable_thinking': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Connection failed: ${response.body}');
    }
  }

  Future<void> _testGeminiConnection(ApiPreset preset) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://generativelanguage.googleapis.com';
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.post(
      Uri.parse(
        '$cleanBaseUrl/v1beta/models/${preset.model}:generateContent?key=${preset.apiKey}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Hi'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Connection failed: ${response.body}');
    }
  }

  Future<Uint8List> testImageGeneration(ApiPreset preset, String prompt) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (preset.provider == ApiProvider.volcengine) {
        return await _testVolcengineImageGeneration(preset, prompt);
      } else if (preset.provider == ApiProvider.gemini) {
        return await _testGeminiImageGeneration(preset, prompt);
      } else if (preset.provider == ApiProvider.openaicompatible) {
        return await _testOpenAICompatibleImageGeneration(preset, prompt);
      } else {
        throw Exception(
            'Only Volcengine, Gemini and OpenAI Compatible are supported for image generation test');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List> _testVolcengineImageGeneration(
      ApiPreset preset, String prompt) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.post(
      Uri.parse('$cleanBaseUrl/images/generations'),
      headers: {
        'Authorization': 'Bearer ${preset.apiKey}',
        'Content-Type': 'application/json',
      },

      /// 这里保持size为4K,保持水印为false
      body: jsonEncode({
        'model': preset.model,
        'prompt': prompt,
        'size': '4K',
        "watermark": false,
        'response_format': 'b64_json',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['data'] != null && (data['data'] as List).isNotEmpty) {
        final b64Json = data['data'][0]['b64_json'];
        if (b64Json != null) {
          return base64Decode(b64Json);
        }
      }
      throw Exception(
          'Image generation response format error: ${response.body}');
    } else {
      throw Exception('Image generation failed: ${response.body}');
    }
  }

  Future<Uint8List> _testGeminiImageGeneration(
      ApiPreset preset, String prompt) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://generativelanguage.googleapis.com';
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.post(
      Uri.parse(
          '$cleanBaseUrl/v1beta/models/${preset.model}:generateContent?key=${preset.apiKey}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["TEXT", "IMAGE"],
          "imageConfig": {
            "imageSize": "4K",
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['candidates'] != null &&
          (data['candidates'] as List).isNotEmpty) {
        final parts = data['candidates'][0]['content']['parts'] as List;
        for (var part in parts) {
          if (part['inlineData'] != null &&
              part['inlineData']['mimeType'].startsWith('image/')) {
            final b64Json = part['inlineData']['data'];
            if (b64Json != null) {
              return base64Decode(b64Json);
            }
          }
        }
      }
      throw Exception(
          'Image generation response format error: ${response.body}');
    } else {
      throw Exception('Image generation failed: ${response.body}');
    }
  }

  Future<Uint8List> _testOpenAICompatibleImageGeneration(
      ApiPreset preset, String prompt) async {
    var baseUrl = preset.baseUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = 'https://api.openai.com/v1';
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.post(
      Uri.parse('$cleanBaseUrl/images/generations'),
      headers: {
        'Authorization': 'Bearer ${preset.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': preset.model,
        'prompt': prompt,
        'n': 1,
        // 'size': '1024x1024', // Remove size constraint for compatibility
        'response_format': 'b64_json',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // 1. 尝试解析标准 OpenAI 格式
      if (data['data'] != null && (data['data'] as List).isNotEmpty) {
        final b64Json = data['data'][0]['b64_json'];
        final url = data['data'][0]['url'];

        if (b64Json != null) {
          return base64Decode(b64Json);
        } else if (url != null) {
          // If only URL is returned, download the image
          final imageResponse = await http.get(Uri.parse(url));
          if (imageResponse.statusCode == 200) {
            return imageResponse.bodyBytes;
          }
        }
      }
      // 2. 尝试解析 Gemini 格式 (NewAPI 转发可能直接返回 Gemini 格式)
      else if (data['candidates'] != null &&
          (data['candidates'] as List).isNotEmpty) {
        final parts = data['candidates'][0]['content']['parts'] as List;
        for (var part in parts) {
          // 2.1 尝试从 inlineData 获取图片
          if (part['inlineData'] != null &&
              part['inlineData']['mimeType'].startsWith('image/')) {
            final b64Json = part['inlineData']['data'];
            if (b64Json != null) {
              return base64Decode(b64Json);
            }
          }
          // 2.2 尝试从 text 获取图片 (Markdown 格式)
          if (part['text'] != null) {
            final text = part['text'] as String;
            final regex = RegExp(r'!\[.*?\]\(data:image\/.*?;base64,(.*?)\)');
            final match = regex.firstMatch(text);
            if (match != null) {
              final b64Json = match.group(1);
              if (b64Json != null) {
                return base64Decode(b64Json);
              }
            }
            // 2.3 尝试从 text 获取图片 URL (Markdown 格式)
            final urlRegex = RegExp(r'!\[.*?\]\((https?:\/\/.*?)\)');
            final urlMatch = urlRegex.firstMatch(text);
            if (urlMatch != null) {
              final url = urlMatch.group(1);
              if (url != null) {
                final imageResponse = await http.get(Uri.parse(url));
                if (imageResponse.statusCode == 200) {
                  return imageResponse.bodyBytes;
                }
              }
            }
          }
        }
      }

      throw Exception(
          'Image generation response format error: ${response.body}');
    } else {
      // 尝试解析错误信息
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorData['error'] != null) {
          final error = errorData['error'];
          if (error is Map) {
            throw Exception(
                'Image generation failed: ${error['message'] ?? error.toString()}');
          } else {
            throw Exception('Image generation failed: $error');
          }
        }
      } catch (e) {
        // 解析失败，直接抛出原始响应体
      }
      throw Exception('Image generation failed: ${response.body}');
    }
  }
}
