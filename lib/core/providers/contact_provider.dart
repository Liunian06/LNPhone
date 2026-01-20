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

  Future<void> _loadData() async {
    // 先从数据库加载
    _roles = await _db.getAllContactRoles();
    _meList = await _db.getAllContactMes();

    // 如果数据库为空，尝试从 SharedPreferences 迁移
    if (_roles.isEmpty && _meList.isEmpty) {
      await _migrateFromSharedPreferences();
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// 从 SharedPreferences 迁移数据到数据库（兼容旧版本）
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasMigrated = false;

    // 迁移角色数据
    final rolesJson = prefs.getString('contact_roles');
    if (rolesJson != null) {
      final List<dynamic> decoded = jsonDecode(rolesJson);
      _roles = decoded.map((item) => ContactRole.fromJson(item)).toList();

      // 保存到数据库
      for (final role in _roles) {
        await _db.insertContactRole(role);
      }

      // 清除旧数据
      await prefs.remove('contact_roles');
      hasMigrated = true;
      debugPrint(
          '[ContactProvider] 已从 SharedPreferences 迁移 ${_roles.length} 个角色');
    }

    // 迁移用户数据
    final meListJson = prefs.getString('contact_me_list');
    if (meListJson != null) {
      final List<dynamic> decoded = jsonDecode(meListJson);
      _meList = decoded.map((item) => ContactMe.fromJson(item)).toList();

      // 保存到数据库
      for (final me in _meList) {
        await _db.insertContactMe(me);
      }

      // 清除旧数据
      await prefs.remove('contact_me_list');
      hasMigrated = true;
      debugPrint(
          '[ContactProvider] 已从 SharedPreferences 迁移 ${_meList.length} 个用户人设');
    }

    if (hasMigrated) {
      debugPrint('[ContactProvider] 数据迁移完成');
    }
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
    String description,
  ) async {
    try {
      final newRole = ContactRole(
        id: _generateId(),
        name: name,
        avatarPath: avatarPath,
        description: description,
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

  Future<void> addMe(String name, String? avatarPath, String info) async {
    try {
      final newMe = ContactMe(
        id: _generateId(),
        name: name,
        avatarPath: avatarPath,
        info: info,
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
    String description,
  ) async {
    try {
      final index = _roles.indexWhere((role) => role.id == id);
      if (index != -1) {
        final updatedRole = ContactRole(
          id: id,
          name: name,
          avatarPath: avatarPath,
          description: description,
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
    String info,
  ) async {
    try {
      final index = _meList.indexWhere((me) => me.id == id);
      if (index != -1) {
        final updatedMe = ContactMe(
          id: id,
          name: name,
          avatarPath: avatarPath,
          info: info,
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
