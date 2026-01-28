import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../database/database.dart';

class ContactProvider extends ChangeNotifier {
  List<ContactRole> _roles = [];
  List<ContactMe> _meList = [];
  bool _isLoaded = false;
  final AppDatabase _db = AppDatabase();

  List<ContactRole> get roles => _roles;
  List<ContactMe> get meList => _meList;
  bool get isLoaded => _isLoaded;

  ContactProvider() {
    _loadData();
  }

  /// 重新从数据库加载数据（用于数据导入后刷新）
  Future<void> reload() async {
    _roles = await _db.getAllContactRoles();
    _meList = await _db.getAllContactMes();
    notifyListeners();
  }

  /// 加载联系人数据（公开方法，用于外部调用）
  Future<void> loadContacts() async {
    if (!_isLoaded) {
      await _loadData();
    } else {
      // 如果已经加载过，直接刷新
      await reload();
    }
  }

  Future<void> _loadData() async {
    // 无论数据库是否有数据，都尝试从 SharedPreferences 迁移
    // 这样可以确保从任何中间版本升级时都不会丢失数据
    await _migrateFromSharedPreferences();

    // 从数据库加载最新数据
    _roles = await _db.getAllContactRoles();
    _meList = await _db.getAllContactMes();

    _isLoaded = true;
    notifyListeners();
  }

  /// 从 SharedPreferences 迁移数据到数据库（兼容旧版本）
  /// 使用增量更新策略：只添加数据库中不存在的数据，不覆盖已有数据
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasMigrated = false;

    // 检查数据库是否为空，如果为空则强制尝试恢复
    final existingRoles = await _db.getAllContactRoles();
    final existingMeList = await _db.getAllContactMes();
    final isDbEmpty = existingRoles.isEmpty && existingMeList.isEmpty;

    if (isDbEmpty) {
      debugPrint('[ContactProvider] 数据库为空，尝试从 SharedPreferences 恢复数据...');
    }

    // 迁移角色数据
    final rolesJson = prefs.getString('contact_roles');
    if (rolesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rolesJson);
        final rolesFromPrefs =
            decoded.map((item) => ContactRole.fromJson(item)).toList();

        final existingRoleIds = existingRoles.map((r) => r.id).toSet();

        int addedCount = 0;
        for (final role in rolesFromPrefs) {
          if (!existingRoleIds.contains(role.id)) {
            await _db.insertContactRole(role);
            addedCount++;
          }
        }

        // 只有在成功迁移且数据库不为空时才删除旧数据，或者如果数据库本来就是空的（首次迁移）
        // 为了安全起见，我们暂时不删除 SharedPreferences 中的数据，直到确认迁移完全成功
        // await prefs.remove('contact_roles');

        if (addedCount > 0) {
          hasMigrated = true;
          debugPrint(
              '[ContactProvider] 已从 SharedPreferences 恢复 $addedCount 个角色');
        }
      } catch (e) {
        debugPrint('[ContactProvider] 迁移角色数据失败: $e');
      }
    }

    // 迁移用户数据
    final meListJson = prefs.getString('contact_me_list');
    if (meListJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(meListJson);
        final meListFromPrefs =
            decoded.map((item) => ContactMe.fromJson(item)).toList();

        final existingMeIds = existingMeList.map((m) => m.id).toSet();

        int addedCount = 0;
        for (final me in meListFromPrefs) {
          if (!existingMeIds.contains(me.id)) {
            await _db.insertContactMe(me);
            addedCount++;
          }
        }

        // await prefs.remove('contact_me_list');

        if (addedCount > 0) {
          hasMigrated = true;
          debugPrint(
              '[ContactProvider] 已从 SharedPreferences 恢复 $addedCount 个用户人设');
        }
      } catch (e) {
        debugPrint('[ContactProvider] 迁移用户人设失败: $e');
      }
    }

    if (hasMigrated) {
      debugPrint('[ContactProvider] 数据迁移/恢复完成');
    } else if (isDbEmpty) {
      debugPrint('[ContactProvider] 警告: 数据库为空且未从 SharedPreferences 找到可恢复的数据');
    }
  }

  /// 强制从旧版存储恢复数据（公开方法，用于设置界面手动触发）
  Future<void> forceRestoreFromLegacy() async {
    debugPrint('[ContactProvider] 手动触发旧版数据恢复...');
    await _migrateFromSharedPreferences();
    // 刷新内存中的数据
    _roles = await _db.getAllContactRoles();
    _meList = await _db.getAllContactMes();
    notifyListeners();
  }

  Future<void> _saveRole(ContactRole role) async {
    try {
      await _db.insertContactRole(role);
      debugPrint('[ContactProvider] 角色保存成功: ${role.name}');
    } catch (e) {
      debugPrint('[ContactProvider] 保存角色失败: $e');
      rethrow;
    }
  }

  Future<void> _saveMe(ContactMe me) async {
    try {
      await _db.insertContactMe(me);
      debugPrint('[ContactProvider] 用户人设保存成功: ${me.name}');
    } catch (e) {
      debugPrint('[ContactProvider] 保存用户人设失败: $e');
      rethrow;
    }
  }

  Future<void> addRole(
    String name,
    String? avatarPath,
    String description, {
    String? appearance,
    List<String> referenceImages = const [],
  }) async {
    try {
      final id = _generateId();
      // 保存图片到持久化存储
      final savedAvatarPath = await _saveProfileImage(avatarPath, id);

      // 保存参考图到持久化存储
      final List<String> savedReferenceImages = [];
      for (var i = 0; i < referenceImages.length; i++) {
        final savedPath =
            await _saveProfileImage(referenceImages[i], '${id}_ref_$i');
        if (savedPath != null) {
          savedReferenceImages.add(savedPath);
        }
      }

      final newRole = ContactRole(
        id: id,
        name: name,
        avatarPath: savedAvatarPath,
        description: description,
        appearance: appearance,
        referenceImages: savedReferenceImages,
      );
      _roles.add(newRole);
      await _saveRole(newRole);
      notifyListeners();
      debugPrint('[ContactProvider] 添加角色成功，当前角色数: ${_roles.length}');
    } catch (e) {
      debugPrint('[ContactProvider] 添加角色失败: $e');
      rethrow;
    }
  }

  Future<void> addMe(
    String name,
    String? avatarPath,
    String info, {
    String? appearance,
    List<String> referenceImages = const [],
  }) async {
    try {
      final id = _generateId();
      // 保存图片到持久化存储
      final savedAvatarPath = await _saveProfileImage(avatarPath, id);

      // 保存参考图到持久化存储
      final List<String> savedReferenceImages = [];
      for (var i = 0; i < referenceImages.length; i++) {
        final savedPath =
            await _saveProfileImage(referenceImages[i], '${id}_ref_$i');
        if (savedPath != null) {
          savedReferenceImages.add(savedPath);
        }
      }

      final newMe = ContactMe(
        id: id,
        name: name,
        avatarPath: savedAvatarPath,
        info: info,
        appearance: appearance,
        referenceImages: savedReferenceImages,
      );
      _meList.add(newMe);
      await _saveMe(newMe);
      notifyListeners();
      debugPrint('[ContactProvider] 添加用户人设成功，当前用户人设数: ${_meList.length}');
    } catch (e) {
      debugPrint('[ContactProvider] 添加用户人设失败: $e');
      rethrow;
    }
  }

  Future<void> updateRole(
    String id,
    String name,
    String? avatarPath,
    String description, {
    String? appearance,
    List<String> referenceImages = const [],
  }) async {
    try {
      final index = _roles.indexWhere((role) => role.id == id);
      if (index != -1) {
        final oldRole = _roles[index];
        String? finalAvatarPath = avatarPath;

        // 如果头像路径变了，保存新图片
        if (avatarPath != oldRole.avatarPath) {
          finalAvatarPath = await _saveProfileImage(avatarPath, id);
        }

        // 处理参考图更新
        // 简单起见，我们重新保存所有参考图（如果它们不在持久化目录中）
        // 实际优化可以比较路径，但考虑到参考图数量通常不多，直接处理是可以接受的
        final List<String> savedReferenceImages = [];
        for (var i = 0; i < referenceImages.length; i++) {
          // 检查是否已经是持久化路径
          final path = referenceImages[i];
          // 如果路径变了或者是新的临时路径，保存它
          // _saveProfileImage 内部会检查是否已经在文档目录下
          final savedPath = await _saveProfileImage(path, '${id}_ref_$i');
          if (savedPath != null) {
            savedReferenceImages.add(savedPath);
          }
        }

        final updatedRole = ContactRole(
          id: id,
          name: name,
          avatarPath: finalAvatarPath,
          description: description,
          appearance: appearance,
          referenceImages: savedReferenceImages,
          subscribedGroupIds: oldRole.subscribedGroupIds,
          subscribedEmojiIds: oldRole.subscribedEmojiIds,
        );
        _roles[index] = updatedRole;
        await _saveRole(updatedRole);
        notifyListeners();
        debugPrint('[ContactProvider] 更新角色成功: $name');
      } else {
        debugPrint('[ContactProvider] 未找到角色ID: $id');
      }
    } catch (e) {
      debugPrint('[ContactProvider] 更新角色失败: $e');
      rethrow;
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      _roles.removeWhere((role) => role.id == id);
      await _db.deleteContactRole(id);
      notifyListeners();
      debugPrint('[ContactProvider] 删除角色成功: $id');
    } catch (e) {
      debugPrint('[ContactProvider] 删除角色失败: $e');
      rethrow;
    }
  }

  Future<void> updateMe(
    String id,
    String name,
    String? avatarPath,
    String info, {
    String? appearance,
    List<String> referenceImages = const [],
  }) async {
    try {
      final index = _meList.indexWhere((me) => me.id == id);
      if (index != -1) {
        final oldMe = _meList[index];
        String? finalAvatarPath = avatarPath;

        // 如果头像路径变了，保存新图片
        if (avatarPath != oldMe.avatarPath) {
          finalAvatarPath = await _saveProfileImage(avatarPath, id);
        }

        // 处理参考图更新
        final List<String> savedReferenceImages = [];
        for (var i = 0; i < referenceImages.length; i++) {
          final path = referenceImages[i];
          final savedPath = await _saveProfileImage(path, '${id}_ref_$i');
          if (savedPath != null) {
            savedReferenceImages.add(savedPath);
          }
        }

        final updatedMe = ContactMe(
          id: id,
          name: name,
          avatarPath: finalAvatarPath,
          info: info,
          appearance: appearance,
          referenceImages: savedReferenceImages,
        );
        _meList[index] = updatedMe;
        await _saveMe(updatedMe);
        notifyListeners();
        debugPrint('[ContactProvider] 更新用户人设成功: $name');
      } else {
        debugPrint('[ContactProvider] 未找到用户人设ID: $id');
      }
    } catch (e) {
      debugPrint('[ContactProvider] 更新用户人设失败: $e');
      rethrow;
    }
  }

  Future<void> deleteMe(String id) async {
    try {
      _meList.removeWhere((me) => me.id == id);
      await _db.deleteContactMe(id);
      notifyListeners();
      debugPrint('[ContactProvider] 删除用户人设成功: $id');
    } catch (e) {
      debugPrint('[ContactProvider] 删除用户人设失败: $e');
      rethrow;
    }
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '$timestamp-$random';
  }

  /// 将图片保存到应用文档目录，防止临时文件被清理
  Future<String?> _saveProfileImage(String? sourcePath, String id) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final appDir = await getApplicationDocumentsDirectory();
      // 检查源文件是否已经在文档目录下（避免重复复制）
      // 注意：在 iOS 上路径可能会变化，这里主要防止当次操作的重复复制
      if (sourcePath.startsWith(appDir.path)) {
        return sourcePath;
      }

      final fileName =
          'avatar_${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await sourceFile.copy('${appDir.path}/$fileName');
      debugPrint('[ContactProvider] 图片已保存到持久化目录: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      debugPrint('[ContactProvider] 保存图片失败: $e');
      return sourcePath; // 失败时返回原路径
    }
  }

  // 辅助方法：读取文件为Base64
  Future<String?> _fileToBase64(String? path) async {
    if (path == null) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error reading file to base64: $e');
    }
    return null;
  }

  // 辅助方法：保存Base64到文件
  Future<String?> _base64ToFile(String? base64String, String fileName) async {
    if (base64String == null) return null;
    try {
      final bytes = base64Decode(base64String);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving base64 to file: $e');
      return null;
    }
  }

  // 导出数据
  Future<String> exportData() async {
    // 导出角色头像
    final rolesData = <String, String>{};
    for (final role in _roles) {
      if (role.avatarPath != null) {
        final base64Data = await _fileToBase64(role.avatarPath);
        if (base64Data != null) {
          rolesData[role.id] = base64Data;
        }
      }
    }

    // 导出我的头像
    final meData = <String, String>{};
    for (final me in _meList) {
      if (me.avatarPath != null) {
        final base64Data = await _fileToBase64(me.avatarPath);
        if (base64Data != null) {
          meData[me.id] = base64Data;
        }
      }
    }

    final data = {
      'roles': _roles.map((e) => e.toJson()).toList(),
      'meList': _meList.map((e) => e.toJson()).toList(),
      'rolesImages': rolesData,
      'meImages': meData,
    };

    return jsonEncode(data);
  }

  // 导入数据
  Future<bool> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // 导入角色
      if (data['roles'] != null) {
        final rolesList = data['roles'] as List;
        _roles = rolesList.map((item) => ContactRole.fromJson(item)).toList();

        // 恢复角色头像
        if (data['rolesImages'] != null) {
          final images = Map<String, String>.from(data['rolesImages']);
          for (var i = 0; i < _roles.length; i++) {
            final role = _roles[i];
            if (images.containsKey(role.id)) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final newPath = await _base64ToFile(
                images[role.id],
                'role_${role.id}_$timestamp.jpg',
              );
              if (newPath != null) {
                _roles[i] = ContactRole(
                  id: role.id,
                  name: role.name,
                  avatarPath: newPath,
                  description: role.description,
                  appearance: role.appearance,
                  referenceImages: role.referenceImages,
                );
              }
            }
          }
        }
      }

      // 导入我的列表
      if (data['meList'] != null) {
        final meList = data['meList'] as List;
        _meList = meList.map((item) => ContactMe.fromJson(item)).toList();

        // 恢复我的头像
        if (data['meImages'] != null) {
          final images = Map<String, String>.from(data['meImages']);
          for (var i = 0; i < _meList.length; i++) {
            final me = _meList[i];
            if (images.containsKey(me.id)) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final newPath = await _base64ToFile(
                images[me.id],
                'me_${me.id}_$timestamp.jpg',
              );
              if (newPath != null) {
                _meList[i] = ContactMe(
                  id: me.id,
                  name: me.name,
                  avatarPath: newPath,
                  info: me.info,
                  appearance: me.appearance,
                  referenceImages: me.referenceImages,
                );
              }
            }
          }
        }
      }

      // 保存到数据库
      for (final role in _roles) {
        await _db.insertContactRole(role);
      }
      for (final me in _meList) {
        await _db.insertContactMe(me);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import contact data failed: $e');
      return false;
    }
  }
}
