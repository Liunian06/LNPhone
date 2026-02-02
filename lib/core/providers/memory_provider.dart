import 'dart:math';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/memory_model.dart';
import '../utils/storage_utils.dart';

/// 记忆管理 Provider
/// 管理角色的持久化记忆，支持跨会话保存
class MemoryProvider extends ChangeNotifier {
  final AppDatabase _database;

  // 按角色ID缓存的记忆列表
  final Map<String, List<RoleMemory>> _memoriesByRole = {};

  // 加载状态
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  MemoryProvider() : _database = AppDatabase() {
    _loadAllMemories();
  }

  /// 获取指定角色的所有记忆
  List<RoleMemory> getMemoriesForRole(String roleId) {
    return _memoriesByRole[roleId] ?? [];
  }

  /// 获取指定角色记忆的格式化文本（用于提示词）
  String getMemoriesPromptForRole(String roleId) {
    final memories = getMemoriesForRole(roleId);
    if (memories.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Role Memories]');
    for (final memory in memories) {
      buffer.writeln('- ${memory.category.icon} ${memory.content}');
    }
    return buffer.toString();
  }

  /// 加载所有记忆
  Future<void> _loadAllMemories() async {
    try {
      final allMemories = await _database.getAllMemories();
      _memoriesByRole.clear();

      for (final memory in allMemories) {
        if (!_memoriesByRole.containsKey(memory.roleId)) {
          _memoriesByRole[memory.roleId] = [];
        }
        _memoriesByRole[memory.roleId]!.add(memory);
      }

      _isLoaded = true;
      notifyListeners();
      debugPrint('[MemoryProvider] 加载完成，共 ${allMemories.length} 条记忆');
    } catch (e) {
      debugPrint('[MemoryProvider] 加载记忆失败: $e');
    }
  }

  /// 刷新指定角色的记忆
  Future<void> refreshMemoriesForRole(String roleId) async {
    try {
      final memories = await _database.getMemoriesByRoleId(roleId);
      _memoriesByRole[roleId] = memories;
      notifyListeners();
    } catch (e) {
      debugPrint('[MemoryProvider] 刷新角色记忆失败: $e');
    }
  }

  /// 添加新记忆
  Future<void> addMemory({
    required String roleId,
    required String content,
    String? sourceSessionId,
    MemoryCategory category = MemoryCategory.general,
  }) async {
    final now = StorageUtils.getUniqueTimestamp();
    final memory = RoleMemory(
      id: _generateId(),
      roleId: roleId,
      content: content,
      createdAt: now,
      updatedAt: now,
      sourceSessionId: sourceSessionId,
      category: category,
    );

    try {
      await _database.insertMemory(memory);

      // 更新缓存
      if (!_memoriesByRole.containsKey(roleId)) {
        _memoriesByRole[roleId] = [];
      }
      _memoriesByRole[roleId]!.insert(0, memory);

      notifyListeners();
      debugPrint(
          '[MemoryProvider] 添加记忆成功: ${content.substring(0, content.length > 30 ? 30 : content.length)}...');
    } catch (e) {
      debugPrint('[MemoryProvider] 添加记忆失败: $e');
      rethrow;
    }
  }

  /// 更新记忆
  Future<void> updateMemory({
    required String id,
    required String content,
    MemoryCategory category = MemoryCategory.general,
  }) async {
    try {
      await _database.updateMemoryContent(id, content, category);

      // 更新缓存
      for (final roleId in _memoriesByRole.keys) {
        final memories = _memoriesByRole[roleId]!;
        final index = memories.indexWhere((m) => m.id == id);
        if (index != -1) {
          memories[index] = memories[index].copyWith(
            content: content,
            category: category,
            updatedAt: StorageUtils.getUniqueTimestamp(),
          );
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[MemoryProvider] 更新记忆失败: $e');
      rethrow;
    }
  }

  /// 删除记忆
  Future<void> deleteMemory(String id) async {
    try {
      await _database.deleteMemory(id);

      // 更新缓存
      for (final roleId in _memoriesByRole.keys) {
        _memoriesByRole[roleId]!.removeWhere((m) => m.id == id);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[MemoryProvider] 删除记忆失败: $e');
      rethrow;
    }
  }

  /// 删除指定角色的所有记忆
  Future<void> deleteAllMemoriesForRole(String roleId) async {
    try {
      await _database.deleteMemoriesByRoleId(roleId);
      _memoriesByRole.remove(roleId);
      notifyListeners();
    } catch (e) {
      debugPrint('[MemoryProvider] 删除角色所有记忆失败: $e');
      rethrow;
    }
  }

  /// 从 AI 回复中解析并添加记忆
  /// 在 chat_provider 中调用此方法
  ///
  /// [categoryStr] - 可选的分类字符串，来自 XML 的 category 属性
  /// 有效值: general, important, preference, relationship, promise, secret
  Future<void> addMemoryFromAiResponse({
    required String roleId,
    required String content,
    String? sourceSessionId,
    String? categoryStr,
  }) async {
    // 优先使用 AI 指定的分类，否则自动分类
    final category =
        _parseCategoryStr(categoryStr) ?? _autoClassifyMemory(content);
    await addMemory(
      roleId: roleId,
      content: content,
      sourceSessionId: sourceSessionId,
      category: category,
    );
  }

  /// 解析分类字符串
  MemoryCategory? _parseCategoryStr(String? categoryStr) {
    if (categoryStr == null || categoryStr.isEmpty) return null;

    switch (categoryStr.toLowerCase()) {
      case 'general':
        return MemoryCategory.general;
      case 'important':
        return MemoryCategory.important;
      case 'preference':
        return MemoryCategory.preference;
      case 'relationship':
        return MemoryCategory.relationship;
      case 'promise':
        return MemoryCategory.promise;
      case 'secret':
        return MemoryCategory.secret;
      case 'time':
        return MemoryCategory.time;
      case 'location':
        return MemoryCategory.location;
      case 'task':
        return MemoryCategory.task;
      case 'item':
        return MemoryCategory.item;
      default:
        debugPrint('[MemoryProvider] 未知的记忆分类: $categoryStr，将自动分类');
        return null;
    }
  }

  /// 自动分类记忆内容
  MemoryCategory _autoClassifyMemory(String content) {
    final lowerContent = content.toLowerCase();

    // 重要时间
    if (lowerContent.contains('生日') ||
        lowerContent.contains('纪念日') ||
        lowerContent.contains('周年') ||
        lowerContent.contains('几月') ||
        lowerContent.contains('几号') ||
        lowerContent.contains('日期') ||
        lowerContent.contains('时间是')) {
      return MemoryCategory.time;
    }

    // 重要地点
    if (lowerContent.contains('住在') ||
        lowerContent.contains('地址') ||
        lowerContent.contains('在哪') ||
        lowerContent.contains('位于') ||
        lowerContent.contains('公司在') ||
        lowerContent.contains('家在')) {
      return MemoryCategory.location;
    }

    // 待办任务
    if (lowerContent.contains('要去') ||
        lowerContent.contains('需要') ||
        lowerContent.contains('待办') ||
        lowerContent.contains('别忘了') ||
        lowerContent.contains('记得') ||
        lowerContent.contains('提醒')) {
      return MemoryCategory.task;
    }

    // 重要物品
    if (lowerContent.contains('最喜欢的') ||
        lowerContent.contains('想要') ||
        lowerContent.contains('想买') ||
        lowerContent.contains('礼物') ||
        lowerContent.contains('收藏')) {
      return MemoryCategory.item;
    }

    // 承诺约定
    if (lowerContent.contains('约定') ||
        lowerContent.contains('承诺') ||
        lowerContent.contains('答应') ||
        lowerContent.contains('保证')) {
      return MemoryCategory.promise;
    }

    // 偏好喜好
    if (lowerContent.contains('喜欢') ||
        lowerContent.contains('讨厌') ||
        lowerContent.contains('爱吃') ||
        lowerContent.contains('不喜欢') ||
        lowerContent.contains('偏好')) {
      return MemoryCategory.preference;
    }

    // 重要事件
    if (lowerContent.contains('重要') || lowerContent.contains('第一次')) {
      return MemoryCategory.important;
    }

    // 人际关系
    if (lowerContent.contains('朋友') ||
        lowerContent.contains('家人') ||
        lowerContent.contains('同事') ||
        lowerContent.contains('认识了')) {
      return MemoryCategory.relationship;
    }

    // 秘密心事
    if (lowerContent.contains('秘密') ||
        lowerContent.contains('不要告诉') ||
        lowerContent.contains('只有你知道')) {
      return MemoryCategory.secret;
    }

    return MemoryCategory.general;
  }

  /// 重新加载所有数据（导入备份后使用）
  Future<void> reloadData() async {
    _memoriesByRole.clear();
    _isLoaded = false;
    await _loadAllMemories();
  }

  String _generateId() {
    return 'mem-${StorageUtils.getUniqueTimestamp()}';
  }
}
