import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';

class ContactProvider extends ChangeNotifier {
  List<ContactRole> _roles = [];
  List<ContactMe> _meList = [];
  bool _isLoaded = false;

  List<ContactRole> get roles => _roles;
  List<ContactMe> get meList => _meList;
  bool get isLoaded => _isLoaded;

  ContactProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Roles
    final rolesJson = prefs.getString('contact_roles');
    if (rolesJson != null) {
      final List<dynamic> decoded = jsonDecode(rolesJson);
      _roles = decoded.map((item) => ContactRole.fromJson(item)).toList();
    }

    // Load Me List
    final meListJson = prefs.getString('contact_me_list');
    if (meListJson != null) {
      final List<dynamic> decoded = jsonDecode(meListJson);
      _meList = decoded.map((item) => ContactMe.fromJson(item)).toList();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_roles.map((e) => e.toJson()).toList());
    await prefs.setString('contact_roles', encoded);
  }

  Future<void> _saveMeList() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_meList.map((e) => e.toJson()).toList());
    await prefs.setString('contact_me_list', encoded);
  }

  Future<void> addRole(
    String name,
    String? avatarPath,
    String description,
  ) async {
    final newRole = ContactRole(
      id: _generateId(),
      name: name,
      avatarPath: avatarPath,
      description: description,
    );
    _roles.add(newRole);
    await _saveRoles();
    notifyListeners();
  }

  Future<void> addMe(String name, String? avatarPath, String info) async {
    final newMe = ContactMe(
      id: _generateId(),
      name: name,
      avatarPath: avatarPath,
      info: info,
    );
    _meList.add(newMe);
    await _saveMeList();
    notifyListeners();
  }

  Future<void> updateRole(
    String id,
    String name,
    String? avatarPath,
    String description,
  ) async {
    final index = _roles.indexWhere((role) => role.id == id);
    if (index != -1) {
      _roles[index] = ContactRole(
        id: id,
        name: name,
        avatarPath: avatarPath,
        description: description,
      );
      await _saveRoles();
      notifyListeners();
    }
  }

  Future<void> deleteRole(String id) async {
    _roles.removeWhere((role) => role.id == id);
    await _saveRoles();
    notifyListeners();
  }

  Future<void> updateMe(
    String id,
    String name,
    String? avatarPath,
    String info,
  ) async {
    final index = _meList.indexWhere((me) => me.id == id);
    if (index != -1) {
      _meList[index] = ContactMe(
        id: id,
        name: name,
        avatarPath: avatarPath,
        info: info,
      );
      await _saveMeList();
      notifyListeners();
    }
  }

  Future<void> deleteMe(String id) async {
    _meList.removeWhere((me) => me.id == id);
    await _saveMeList();
    notifyListeners();
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

      await _saveRoles();
      await _saveMeList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import contact data failed: $e');
      return false;
    }
  }
}
