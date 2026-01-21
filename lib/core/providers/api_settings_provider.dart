import 'dart:convert';
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
  bool _isLoading = false;
  bool _isInitialized = false;
  final AppDatabase _db = AppDatabase();

  List<ApiPreset> get presets => _presets;
  String? get activePresetId => _activePresetId;
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

      // 验证 activePresetId 是否仍然有效
      if (_activePresetId != null) {
        final presetExists = _presets.any((p) => p.id == _activePresetId);
        if (!presetExists) {
          _activePresetId = null;
          await _db.deleteSetting('active_preset_id');
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
    notifyListeners();
  }

  Future<void> setActivePreset(String? id) async {
    _activePresetId = id;
    await _saveActivePresetId();
    notifyListeners();
  }

  Future<List<String>> fetchModels(ApiPreset preset) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<String> models = [];
      if (preset.provider == ApiProvider.openai) {
        models = await _fetchOpenAIModels(preset);
      } else {
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
      } else {
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
}
