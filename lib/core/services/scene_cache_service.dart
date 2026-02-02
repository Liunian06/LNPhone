import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database.dart';
import '../utils/storage_utils.dart';
import 'image_generation_service.dart';

/// 场景缓存模型
class SceneCache {
  final String id;
  final String sessionId; // 所属会话 ID
  final String location; // 场景位置标识 (如：咖啡厅、海边)
  final String time; // 时间段 (如：下午、傍晚)
  final String weather; // 天气 (如：晴天、雨天)
  final String description; // 场景描述
  final String imagePath; // 生成的图片路径
  final int createdAt; // 创建时间

  SceneCache({
    required this.id,
    required this.sessionId,
    required this.location,
    required this.time,
    required this.weather,
    required this.description,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'location': location,
        'time': time,
        'weather': weather,
        'description': description,
        'imagePath': imagePath,
        'createdAt': createdAt,
      };

  factory SceneCache.fromJson(Map<String, dynamic> json) => SceneCache(
        id: json['id'],
        sessionId: json['sessionId'],
        location: json['location'] ?? '',
        time: json['time'] ?? '',
        weather: json['weather'] ?? '',
        description: json['description'] ?? '',
        imagePath: json['imagePath'],
        createdAt: json['createdAt'],
      );
}

/// 场景缓存服务
/// 负责管理沉浸模式下的场景图片缓存
class SceneCacheService {
  static final SceneCacheService _instance = SceneCacheService._internal();
  factory SceneCacheService() => _instance;
  SceneCacheService._internal();

  final AppDatabase _db = AppDatabase();
  final List<SceneCache> _cache = [];
  bool _isLoaded = false;

  /// 初始化缓存
  Future<void> init() async {
    if (_isLoaded) return;
    await _loadCache();
    _isLoaded = true;
  }

  /// 从数据库加载缓存
  Future<void> _loadCache() async {
    try {
      final json = await _db.getSetting('scene_cache');
      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _cache.clear();
        _cache.addAll(list.map((e) => SceneCache.fromJson(e)));
        debugPrint('[SceneCacheService] 加载了 ${_cache.length} 个场景缓存');
      }
    } catch (e) {
      debugPrint('[SceneCacheService] 加载缓存失败: $e');
    }
  }

  /// 保存缓存到数据库
  Future<void> _saveCache() async {
    try {
      final json = jsonEncode(_cache.map((e) => e.toJson()).toList());
      await _db.setSetting('scene_cache', json);
    } catch (e) {
      debugPrint('[SceneCacheService] 保存缓存失败: $e');
    }
  }

  /// 查找匹配的场景缓存
  /// 匹配规则：
  /// 1. 同一会话
  /// 2. 位置相同
  /// 3. 时间段相同
  /// 4. 天气相同
  SceneCache? findMatch({
    required String sessionId,
    required String location,
    required String time,
    required String weather,
  }) {
    if (!_isLoaded) return null;

    // 规范化比较值
    final normalizedLocation = _normalize(location);
    final normalizedTime = _normalize(time);
    final normalizedWeather = _normalize(weather);

    for (final cache in _cache) {
      if (cache.sessionId == sessionId &&
          _normalize(cache.location) == normalizedLocation &&
          _normalize(cache.time) == normalizedTime &&
          _normalize(cache.weather) == normalizedWeather) {
        // 检查图片文件是否还存在
        if (File(cache.imagePath).existsSync()) {
          debugPrint('[SceneCacheService] 找到匹配的场景缓存: ${cache.id}');
          return cache;
        } else {
          debugPrint('[SceneCacheService] 场景缓存图片已失效: ${cache.imagePath}');
        }
      }
    }
    return null;
  }

  /// 规范化字符串（用于比较）
  String _normalize(String s) {
    return s.toLowerCase().trim();
  }

  /// 生成并缓存场景图片
  /// 返回图片路径
  /// [force] 是否强制重新生成（跳过缓存）
  Future<String?> generateAndCache({
    required String sessionId,
    required String description,
    required String location,
    required String time,
    required String weather,
    String? imageApiPresetId,
    String? imageStylePresetId,
    bool force = false,
  }) async {
    debugPrint('[SceneCacheService] generateAndCache 被调用 (force=$force):');
    debugPrint('  - sessionId: $sessionId');
    debugPrint('  - location: $location');
    debugPrint('  - time: $time');
    debugPrint('  - weather: $weather');
    debugPrint('  - imageApiPresetId: $imageApiPresetId');
    debugPrint('  - imageStylePresetId: $imageStylePresetId');
    debugPrint(
        '  - description: ${description.substring(0, description.length > 100 ? 100 : description.length)}...');

    // 如果不是强制生成，先检查是否有缓存
    if (!force) {
      final cached = findMatch(
        sessionId: sessionId,
        location: location,
        time: time,
        weather: weather,
      );

      if (cached != null) {
        debugPrint('[SceneCacheService] 使用缓存的场景图片: ${cached.imagePath}');
        return cached.imagePath;
      }
    }

    // 生成新图片
    debugPrint('[SceneCacheService] 没有找到缓存，开始生成新的场景图片...');

    // 构建场景生图 prompt（第一人称视角）
    final scenePrompt = _buildScenePrompt(description);
    debugPrint('[SceneCacheService] 场景生图 Prompt:\n$scenePrompt');

    try {
      final result = await ImageGenerationService().generateImage(
        scenePrompt,
        null, // 使用默认风格
        includeCharacter: true, // 场景通常包含角色
        includeUser: false, // 第一人称视角不包含用户
        imageApiPresetId: imageApiPresetId,
        imageStylePresetId: imageStylePresetId,
      );

      debugPrint('[SceneCacheService] ImageGenerationService 返回结果: $result');

      if (result == null || result['path'] == null) {
        debugPrint('[SceneCacheService] 场景图片生成失败 - result 为空或没有 path');
        return null;
      }

      final imagePath = result['path'] as String;
      debugPrint('[SceneCacheService] 图片生成成功: $imagePath');

      // 缓存结果
      final cache = SceneCache(
        id: 'scene_${StorageUtils.getUniqueTimestamp()}',
        sessionId: sessionId,
        location: location,
        time: time,
        weather: weather,
        description: description,
        imagePath: imagePath,
        createdAt: StorageUtils.getUniqueTimestamp(),
      );

      _cache.add(cache);
      await _saveCache();

      debugPrint('[SceneCacheService] 场景图片已缓存: ${cache.id}');
      return imagePath;
    } catch (e) {
      debugPrint('[SceneCacheService] 场景图片生成异常: $e');
      return null;
    }
  }

  /// 构建场景生图 prompt
  /// 强调第一人称视角和空间物理逻辑
  String _buildScenePrompt(String description) {
    return '''
[Scene Generation - First Person POV]

IMPORTANT: This is a FIRST-PERSON perspective scene. The image should show what the user sees from their own eyes. DO NOT include the user/viewer in the image.

Camera Position: First-person view, eye level, natural human perspective
Aspect Ratio: Vertical (portrait mode, like a smartphone screen)

Scene Description:
$description

Technical Requirements:
- Photorealistic quality, 8K resolution
- Natural lighting consistent with the time and weather
- Proper depth of field and perspective
- No fish-eye distortion
- If a character is present, they should be facing TOWARDS the camera (facing the viewer)

Negative Prompt: third-person view, bird's eye view, aerial view, the viewer visible in the scene, extra limbs, deformed, blurry, low quality, watermark, text
''';
  }

  /// 获取会话的所有场景缓存
  List<SceneCache> getCachesForSession(String sessionId) {
    return _cache.where((c) => c.sessionId == sessionId).toList();
  }

  /// 清除会话的所有场景缓存
  Future<void> clearSessionCache(String sessionId) async {
    _cache.removeWhere((c) => c.sessionId == sessionId);
    await _saveCache();
    debugPrint('[SceneCacheService] 已清除会话 $sessionId 的场景缓存');
  }

  /// 清除所有场景缓存
  Future<void> clearAllCache() async {
    _cache.clear();
    await _saveCache();
    debugPrint('[SceneCacheService] 已清除所有场景缓存');
  }

  /// 清理无效的缓存（图片文件已不存在）
  Future<void> cleanupInvalidCache() async {
    final toRemove = <SceneCache>[];
    for (final cache in _cache) {
      if (!File(cache.imagePath).existsSync()) {
        toRemove.add(cache);
      }
    }
    if (toRemove.isNotEmpty) {
      _cache.removeWhere((c) => toRemove.contains(c));
      await _saveCache();
      debugPrint('[SceneCacheService] 清理了 ${toRemove.length} 个无效的场景缓存');
    }
  }
}
