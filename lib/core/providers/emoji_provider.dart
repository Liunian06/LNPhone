import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';
import '../models/emoji_model.dart';

class EmojiProvider extends ChangeNotifier {
  final AppDatabase _db;
  List<EmojiModel> _globalEmojis = [];
  List<EmojiModel> _roleEmojis = [];
  List<EmojiGroupEntity> _emojiGroups = [];
  bool _isLoading = false;

  EmojiProvider(this._db);

  List<EmojiModel> get globalEmojis => _globalEmojis;
  List<EmojiModel> get roleEmojis => _roleEmojis;
  List<EmojiGroupEntity> get emojiGroups => _emojiGroups;
  bool get isLoading => _isLoading;

  /// 初始化加载
  Future<void> loadEmojis(String? currentRoleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 尝试修复表结构（核弹级修复）
      try {
        await _db.customSelect('SELECT local_path FROM emojis LIMIT 1').get();
      } catch (e) {
        print('[EmojiProvider] 检测到 emojis 表结构异常，尝试重建表...');
        try {
          // 备份现有数据（如果可能）
          await _db.customStatement('DROP TABLE IF EXISTS emojis');
          await _db.customStatement('''
            CREATE TABLE IF NOT EXISTS emojis (
              id TEXT NOT NULL PRIMARY KEY,
              meaning TEXT NOT NULL,
              raw_content TEXT,
              group_id TEXT,
              local_path TEXT NOT NULL,
              type INTEGER NOT NULL,
              role_id TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
          print('[EmojiProvider] emojis 表重建成功');
        } catch (e2) {
          print('[EmojiProvider] 重建表失败: $e2');
        }
      }

      final allEmojis = await _db.getAllEmojis();
      _globalEmojis =
          allEmojis.where((e) => e.type == EmojiType.global).toList();

      if (currentRoleId != null) {
        _roleEmojis = allEmojis
            .where((e) => e.type == EmojiType.role && e.roleId == currentRoleId)
            .toList();
      } else {
        _roleEmojis = [];
      }

      _emojiGroups = await _db.getAllEmojiGroups();
    } catch (e) {
      print('Error loading emojis: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取指定角色的所有可用表情（全局 + 角色专属），并去重
  Future<List<EmojiModel>> getAvailableEmojisForRole(String roleId) async {
    final emojis = await _db.getEmojisForRole(roleId);

    // 去重逻辑：如果图片路径相同，视为重复，优先保留角色专属的
    final uniqueEmojis = <String, EmojiModel>{};
    for (final emoji in emojis) {
      if (!uniqueEmojis.containsKey(emoji.localPath) ||
          emoji.type == EmojiType.role) {
        uniqueEmojis[emoji.localPath] = emoji;
      }
    }

    return uniqueEmojis.values.toList();
  }

  /// 添加表情包
  Future<void> addEmoji({
    required String filePath,
    required String meaning,
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
        rawContent: null,
        localPath: newPath,
        type: type,
        roleId: roleId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _db.insertEmoji(emoji);
      print('[EmojiProvider] 数据库插入成功');

      if (type == EmojiType.global) {
        await loadEmojis(null);
      } else {
        await loadEmojis(roleId);
      }
    } catch (e, stack) {
      print('[EmojiProvider] ❌ 添加表情失败: $e');
      print(stack);
      rethrow;
    }
  }

  /// 批量移动表情包
  /// 批量移动表情包
  Future<void> moveEmojis({
    required List<EmojiModel> emojis,
    required EmojiType targetType,
    String? targetRoleId,
    String? targetGroupId,
  }) async {
    for (final emoji in emojis) {
      final updatedEmoji = EmojiModel(
        id: emoji.id,
        meaning: emoji.meaning,
        rawContent: emoji.rawContent,
        groupId: targetGroupId, // 允许指定目标分组
        localPath: emoji.localPath,
        type: targetType,
        roleId: targetRoleId,
        createdAt: emoji.createdAt,
      );
      await _db.insertEmoji(updatedEmoji);
    }
    await loadEmojis(targetRoleId ?? emojis.first.roleId);
  }

  /// 批量复制表情包
  Future<void> copyEmojis({
    required List<EmojiModel> emojis,
    required EmojiType targetType,
    String? targetRoleId,
    String? targetGroupId,
  }) async {
    for (final emoji in emojis) {
      final newId = await _generateOrRecycleId();
      final newEmoji = EmojiModel(
        id: newId,
        meaning: emoji.meaning,
        rawContent: emoji.rawContent,
        groupId: targetGroupId, // 允许指定目标分组
        localPath: emoji.localPath, // 复用图片文件
        type: targetType,
        roleId: targetRoleId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.insertEmoji(newEmoji);
    }
    await loadEmojis(targetRoleId ?? emojis.first.roleId);
  }

  /// 批量删除表情包
  Future<void> deleteEmojis(List<String> ids) async {
    await _db.deleteEmojis(ids);
    notifyListeners();
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

  /// 偷图逻辑
  Future<void> checkAndStealEmoji(String emojiId, String roleId) async {
    final availableEmojis = await getAvailableEmojisForRole(roleId);
    final isAvailable = availableEmojis.any((e) => e.id == emojiId);

    if (!isAvailable) {
      final allEmojis = await _db.getAllEmojis();
      final originalEmoji = allEmojis.firstWhere((e) => e.id == emojiId,
          orElse: () => throw Exception('Emoji not found'));

      final newId = await _generateOrRecycleId();
      final newEmoji = EmojiModel(
        id: newId,
        meaning: originalEmoji.meaning,
        rawContent: originalEmoji.rawContent,
        localPath: originalEmoji.localPath,
        type: EmojiType.role,
        roleId: roleId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _db.insertEmoji(newEmoji);
      await loadEmojis(roleId);
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

      if (emoji.type == EmojiType.global) {
        await loadEmojis(null);
      } else {
        await loadEmojis(emoji.roleId);
      }
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

      if (emojis.isNotEmpty) {
        if (emojis.first.type == EmojiType.global) {
          await loadEmojis(null);
        } else {
          await loadEmojis(emojis.first.roleId);
        }
      }
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
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertEmojiGroup(group);
    await loadEmojis(roleId);
  }

  Future<void> deleteEmojiGroup(String id, String? currentRoleId) async {
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
    await loadEmojis(currentRoleId);
  }

  Future<void> moveEmojisToGroup(
      List<String> emojiIds, String? groupId, String? currentRoleId) async {
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
    await loadEmojis(currentRoleId);
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
}
