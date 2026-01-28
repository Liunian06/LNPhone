import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';
import '../models/emoji_model.dart';
import '../models/contact_model.dart';
import '../services/emoji_zip_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart' as fp;

class EmojiProvider extends ChangeNotifier {
  final AppDatabase _db;
  List<EmojiModel> _allEmojis = [];
  List<EmojiGroupEntity> _emojiGroups = [];
  bool _isLoading = false;
  final _zipService = EmojiZipService();

  EmojiProvider(this._db) {
    loadEmojis();
  }

  List<EmojiModel> get allEmojis => _allEmojis;
  List<EmojiGroupEntity> get emojiGroups => _emojiGroups;
  bool get isLoading => _isLoading;

  /// 初始化加载
  Future<void> loadEmojis([String? _]) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allEmojis = await _db.getAllEmojis();
      _emojiGroups = await _db.getAllEmojiGroups();
    } catch (e) {
      print('Error loading emojis: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取指定角色的所有可用表情（统一池模式下：订阅的分组 + 订阅的个体ID + 未分组全局资源）
  Future<List<EmojiModel>> getAvailableEmojisForRole(String roleId) async {
    final allEmojis = await _db.getAllEmojis();
    final role = await _db.getContactRole(roleId);
    if (role == null) return allEmojis;

    return allEmojis.where((e) {
      // 1. 订阅的个体表情 ID（包含偷来的图）
      if (role.subscribedEmojiIds.contains(e.id)) return true;
      // 2. 订阅的分组内的表情
      if (e.groupId != null && role.subscribedGroupIds.contains(e.groupId)) {
        return true;
      }
      // 注意：不再包含未分组的全局表情，除非它在 subscribedEmojiIds 中

      return false;
    }).toList();
  }

  /// 添加表情包
  /// 返回新生成的 ID
  Future<String> addEmoji({
    required String filePath,
    required String meaning,
    String? rawContent,
    String? groupId,
    required EmojiType type,
    String? roleId,
  }) async {
    print(
        '[EmojiProvider] 开始添加表情: path=$filePath, meaning=$meaning, type=$type, roleId=$roleId');
    try {
      final id = await _generateOrRecycleId();
      print('[EmojiProvider] 生成/回收ID: $id');

      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(filePath)}';
      final newPath = p.join(appDir.path, 'emojis', fileName);

      final emojiDir = Directory(p.dirname(newPath));
      if (!await emojiDir.exists()) {
        await emojiDir.create(recursive: true);
      }

      await File(filePath).copy(newPath);

      final emoji = EmojiModel(
        id: id,
        meaning: meaning,
        rawContent: rawContent,
        groupId: groupId,
        localPath: newPath,
        type: type,
        roleId: roleId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _db.insertEmoji(emoji);
      print('[EmojiProvider] 数据库插入成功');

      await loadEmojis(null);
      return id;
    } catch (e, stack) {
      print('[EmojiProvider] ❌ 添加表情失败: $e');
      print(stack);
      rethrow;
    }
  }

  /// 批量移动表情包（统一池模式：仅改变分组）
  Future<void> moveEmojis({
    required List<EmojiModel> emojis,
    String? targetGroupId,
    // 以下参数在统一池模式下已失效，保留仅为兼容
    EmojiType? targetType,
    String? targetRoleId,
  }) async {
    for (final emoji in emojis) {
      final updatedEmoji = EmojiModel(
        id: emoji.id,
        meaning: emoji.meaning,
        rawContent: emoji.rawContent,
        groupId: targetGroupId,
        localPath: emoji.localPath,
        type: EmojiType.global,
        roleId: null,
        createdAt: emoji.createdAt,
      );
      await _db.insertEmoji(updatedEmoji);
    }
    await loadEmojis(null);
  }

  /// 批量复制表情包（统一池模式：生成新ID并指定分组）
  Future<void> copyEmojis({
    required List<EmojiModel> emojis,
    String? targetGroupId,
    // 以下参数在统一池模式下已失效，保留仅为兼容
    EmojiType? targetType,
    String? targetRoleId,
  }) async {
    for (final emoji in emojis) {
      final newId = await _generateOrRecycleId();
      final newEmoji = EmojiModel(
        id: newId,
        meaning: emoji.meaning,
        rawContent: emoji.rawContent,
        groupId: targetGroupId,
        localPath: emoji.localPath,
        type: EmojiType.global,
        roleId: null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.insertEmoji(newEmoji);
    }
    await loadEmojis(null);
  }

  /// 批量删除表情包
  Future<void> deleteEmojis(List<String> ids) async {
    await _db.deleteEmojis(ids);
    await loadEmojis();
  }

  /// 尝试回收并重用已删除的表情ID
  Future<String> _generateOrRecycleId() async {
    final allEmojis = await _db.getAllEmojis();
    final existingIds = allEmojis.map((e) => e.id).toSet();

    int index = 1;
    while (true) {
      final candidateId = 'emoji-id-${index.toString().padLeft(5, '0')}';
      if (!existingIds.contains(candidateId)) {
        return candidateId;
      }
      index++;
    }
  }

  /// 偷图逻辑（颗粒度细化：如果该表情不在角色的订阅范围内，则直接将该 ID 加入角色的订阅列表）
  Future<void> checkAndStealEmoji(String emojiId, String roleId) async {
    final role = await _db.getContactRole(roleId);
    if (role == null) return;

    // 检查该表情是否已经在角色的可用范围内
    final availableEmojis = await getAvailableEmojisForRole(roleId);
    final isAlreadyOwned = availableEmojis.any((e) => e.id == emojiId);

    if (!isAlreadyOwned) {
      // 直接将 ID 加入角色的订阅列表，不再创建副本
      final updatedEmojiIds = List<String>.from(role.subscribedEmojiIds);
      if (!updatedEmojiIds.contains(emojiId)) {
        updatedEmojiIds.add(emojiId);
        await updateRoleEmojiSubscriptions(roleId, updatedEmojiIds);
        print(
            '[EmojiProvider] Steal logic: Emoji ID $emojiId added to role $roleId subscriptions');
      }
    }
  }

  /// 更新角色的个体表情订阅
  Future<void> updateRoleEmojiSubscriptions(
      String roleId, List<String> subscribedEmojiIds) async {
    final role = await _db.getContactRole(roleId);
    if (role != null) {
      final updatedRole = ContactRole(
        id: role.id,
        name: role.name,
        avatarPath: role.avatarPath,
        description: role.description,
        appearance: role.appearance,
        referenceImages: role.referenceImages,
        subscribedGroupIds: role.subscribedGroupIds,
        subscribedEmojiIds: subscribedEmojiIds,
      );
      await _db.insertContactRole(updatedRole);
      notifyListeners();
    }
  }

  /// [已弃用] 请使用 updateEmojiContent
  Future<void> updateEmojiMeaning(String id, String newMeaning) async {
    await updateEmojiContent(id: id, meaning: newMeaning);
  }

  /// 更新表情内容（人工修改）
  Future<void> updateEmojiContent({
    required String id,
    required String meaning,
    String? rawContent,
    String? groupId,
  }) async {
    final allEmojis = await _db.getAllEmojis();
    try {
      final emoji = allEmojis.firstWhere((e) => e.id == id);
      final updatedEmoji = EmojiModel(
        id: emoji.id,
        meaning: meaning,
        rawContent: rawContent,
        groupId: groupId ?? emoji.groupId,
        localPath: emoji.localPath,
        type: emoji.type,
        roleId: emoji.roleId,
        createdAt: emoji.createdAt,
      );
      await _db.insertEmoji(updatedEmoji);

      await loadEmojis(null);
    } catch (e) {
      print('Error updating emoji content: $e');
    }
  }

  /// 批量重新打标
  Future<void> batchReTagEmojis({
    required List<EmojiModel> emojis,
    required Future<Map<String, String>> Function(String path) onTagging,
    int maxConcurrent = 3,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (int i = 0; i < emojis.length; i += maxConcurrent) {
        final end = (i + maxConcurrent < emojis.length)
            ? i + maxConcurrent
            : emojis.length;
        final chunk = emojis.sublist(i, end);

        await Future.wait(chunk.map((emoji) async {
          try {
            final tags = await onTagging(emoji.localPath);
            final updatedEmoji = EmojiModel(
              id: emoji.id,
              meaning: tags['simple_content'] ?? emoji.meaning,
              rawContent: tags['raw_content'] ?? emoji.rawContent,
              groupId: emoji.groupId,
              localPath: emoji.localPath,
              type: emoji.type,
              roleId: emoji.roleId,
              createdAt: emoji.createdAt,
            );
            await _db.insertEmoji(updatedEmoji);
          } catch (e) {
            print('Error re-tagging emoji ${emoji.id}: $e');
          }
        }));
      }

      await loadEmojis(null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 批量导入表情包（带AI打标，支持并发）
  Future<void> batchImportEmojis({
    required List<String> filePaths,
    required EmojiType type,
    String? roleId,
    required Future<Map<String, String>> Function(String path) onTagging,
    int maxConcurrent = 3, // 默认最大并发数为 3
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (int i = 0; i < filePaths.length; i += maxConcurrent) {
        final end = (i + maxConcurrent < filePaths.length)
            ? i + maxConcurrent
            : filePaths.length;
        final chunk = filePaths.sublist(i, end);

        await Future.wait(chunk.map((path) async {
          try {
            final tags = await onTagging(path);
            final meaning = tags['simple_content'] ?? '表情';
            final rawContent = tags['raw_content'];

            final id = await _generateOrRecycleId();

            final appDir = await getApplicationDocumentsDirectory();
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}';
            final newPath = p.join(appDir.path, 'emojis', fileName);

            final emojiDir = Directory(p.dirname(newPath));
            if (!await emojiDir.exists()) {
              await emojiDir.create(recursive: true);
            }
            await File(path).copy(newPath);

            final emoji = EmojiModel(
              id: id,
              meaning: meaning,
              rawContent: rawContent,
              localPath: newPath,
              type: type,
              roleId: roleId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            );

            await _db.insertEmoji(emoji);
          } catch (e) {
            print('Error importing emoji $path: $e');
          }
        }));
      }

      if (type == EmojiType.global) {
        await loadEmojis(null);
      } else {
        await loadEmojis(roleId);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 纯批量导入（无 AI 打标）
  Future<void> pureBatchImportEmojis({
    required List<String> filePaths,
    required EmojiType type,
    String? roleId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (final path in filePaths) {
        try {
          final id = await _generateOrRecycleId();
          final appDir = await getApplicationDocumentsDirectory();
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}';
          final newPath = p.join(appDir.path, 'emojis', fileName);

          final emojiDir = Directory(p.dirname(newPath));
          if (!await emojiDir.exists()) {
            await emojiDir.create(recursive: true);
          }
          await File(path).copy(newPath);

          final emoji = EmojiModel(
            id: id,
            meaning: '未命名',
            rawContent: null,
            localPath: newPath,
            type: type,
            roleId: roleId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );

          await _db.insertEmoji(emoji);
        } catch (e) {
          print('Error importing emoji $path: $e');
        }
      }

      await loadEmojis(null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 分组管理 ---

  Future<void> addEmojiGroup({
    required String name,
    required EmojiType type,
    String? roleId,
  }) async {
    final group = EmojiGroupEntity(
      id: 'group-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      roleId: roleId,
      isVisible: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertEmojiGroup(group);
    await loadEmojis(null);
  }

  Future<void> toggleGroupVisibility(String groupId, bool isVisible,
      [String? _]) async {
    final groups = await _db.getAllEmojiGroups();
    try {
      final group = groups.firstWhere((g) => g.id == groupId);
      final updatedGroup = EmojiGroupEntity(
        id: group.id,
        name: group.name,
        type: group.type,
        roleId: group.roleId,
        isVisible: isVisible,
        createdAt: group.createdAt,
      );
      await _db.insertEmojiGroup(updatedGroup);
      await loadEmojis(null);
    } catch (e) {
      print('Error toggling group visibility: $e');
    }
  }

  /// 更新角色的订阅分组
  Future<void> updateRoleSubscriptions(
      String roleId, List<String> subscribedGroupIds) async {
    // 使用数据库事务或确保原子性
    final role = await _db.getContactRole(roleId);
    if (role != null) {
      // 需求：已订阅分组内的表情，也要向 subscribedEmojiIds 迁移
      final allEmojis = await _db.getAllEmojis();
      final newEmojiIds = Set<String>.from(role.subscribedEmojiIds);

      for (final groupId in subscribedGroupIds) {
        final groupEmojis = allEmojis.where((e) => e.groupId == groupId);
        for (final emoji in groupEmojis) {
          newEmojiIds.add(emoji.id);
        }
      }

      // 转换为列表并去重
      final finalEmojiIds = newEmojiIds.toList();

      final updatedRole = ContactRole(
        id: role.id,
        name: role.name,
        avatarPath: role.avatarPath,
        description: role.description,
        appearance: role.appearance,
        referenceImages: role.referenceImages,
        subscribedGroupIds: subscribedGroupIds,
        subscribedEmojiIds: finalEmojiIds,
      );
      await _db.insertContactRole(updatedRole);

      // 立即重新加载表情池，确保 UI 状态同步
      await loadEmojis(null);
      notifyListeners();
    }
  }

  Future<void> deleteEmojiGroup(String id, [String? _]) async {
    await _db.deleteEmojiGroup(id);
    final allEmojis = await _db.getAllEmojis();
    for (final emoji in allEmojis.where((e) => e.groupId == id)) {
      await _db.insertEmoji(EmojiModel(
        id: emoji.id,
        meaning: emoji.meaning,
        rawContent: emoji.rawContent,
        groupId: null,
        localPath: emoji.localPath,
        type: emoji.type,
        roleId: emoji.roleId,
        createdAt: emoji.createdAt,
      ));
    }
    await loadEmojis(null);
  }

  Future<void> moveEmojisToGroup(List<String> emojiIds, String? groupId,
      [String? _]) async {
    final allEmojis = await _db.getAllEmojis();
    for (final id in emojiIds) {
      try {
        final emoji = allEmojis.firstWhere((e) => e.id == id);
        await _db.insertEmoji(EmojiModel(
          id: emoji.id,
          meaning: emoji.meaning,
          rawContent: emoji.rawContent,
          groupId: groupId,
          localPath: emoji.localPath,
          type: emoji.type,
          roleId: emoji.roleId,
          createdAt: emoji.createdAt,
        ));
      } catch (e) {
        print('Error moving emoji to group: $e');
      }
    }
    await loadEmojis(null);
  }

  /// 根据ID获取表情包
  Future<EmojiModel?> getEmojiById(String id) async {
    try {
      final allEmojis = await _db.getAllEmojis();
      return allEmojis.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- 导入导出 ---

  /// 导出选中的表情
  Future<void> exportSelectedEmojis(List<EmojiModel> emojis) async {
    if (emojis.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final zipPath = await _zipService.exportEmojis(emojis);
      await Share.shareXFiles([XFile(zipPath)], text: '导出表情包');
    } catch (e) {
      print('Error exporting emojis: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 导入表情包 ZIP
  Future<void> importEmojisFromZip({String? targetGroupId}) async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final metadataList =
          await _zipService.parseImportZip(result.files.single.path!);

      for (final item in metadataList) {
        final tempPath = item['tempPath'] as String?;
        if (tempPath == null || !await File(tempPath).exists()) continue;

        // 需求：导入时重新分配 ID，并支持指定分组
        await addEmoji(
          filePath: tempPath,
          meaning: item['meaning'] ?? '未命名',
          rawContent: item['rawContent'],
          groupId: targetGroupId,
          type: EmojiType.global,
        );
      }

      await loadEmojis(null);
    } catch (e) {
      print('Error importing emojis: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
