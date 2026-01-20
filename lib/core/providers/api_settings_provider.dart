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
      // 先从数据库加载
      _presets = await _db.getAllApiPresetsFromDb();

      // 如果数据库为空，尝试从 SharedPreferences 迁移预设
      if (_presets.isEmpty) {
        await _migratePresetsFromSharedPreferences();
      }

      // 加载活动预设 ID（从数据库读取）
      _activePresetId = await _db.getSetting('active_preset_id');

      // 如果数据库中没有，尝试从 SharedPreferences 迁移
      if (_activePresetId == null) {
        await _migrateActivePresetIdFromSharedPreferences();
      }

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

  /// 从 SharedPreferences 迁移预设数据到数据库（兼容旧版本）
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migratePresetsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getStringList('api_presets') ?? [];

    if (presetsJson.isNotEmpty) {
      _presets = presetsJson
          .map((json) => ApiPreset.fromJson(jsonDecode(json)))
          .toList();

      // 保存到数据库
      for (final preset in _presets) {
        await _db.insertApiPreset(preset);
      }

      // 清除旧数据
      await prefs.remove('api_presets');
      debugPrint(
          '[ApiSettingsProvider] 已从 SharedPreferences 迁移 ${_presets.length} 个 API 预设');
    }
  }

  /// 从 SharedPreferences 迁移活动预设ID到数据库
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migrateActivePresetIdFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString('active_preset_id');

    if (activeId != null) {
      _activePresetId = activeId;
      await _db.setSetting('active_preset_id', activeId);
      await prefs.remove('active_preset_id');
      debugPrint(
          '[ApiSettingsProvider] 已从 SharedPreferences 迁移 active_preset_id');
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
