import 'dart:io';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../utils/storage_utils.dart';
import '../models/emoji_model.dart';
import 'emoji_file_backup_service.dart';

/// 表情包备份数据迁移服务
/// 使用字节复制方式创建备份，保持 GIF 透明通道
class EmojiBackupMigration {
  final AppDatabase _db;

  EmojiBackupMigration(this._db);

  /// 执行迁移：从二进制备份迁移到文件备份
  Future<MigrationReport> migrate() async {
    debugPrint('[EmojiBackupMigration] 开始迁移表情包备份数据（二进制 -> 文件）...');

    final report = MigrationReport();

    try {
      final emojis = await _db.getAllEmojis();
      debugPrint('[EmojiBackupMigration] 找到 ${emojis.length} 个表情包');

      for (final emoji in emojis) {
        report.totalEmojis++;

        // 跳过已有文件备份的表情包
        if (emoji.backupPath != null && emoji.backupPath!.isNotEmpty) {
          final backupExists =
              await EmojiFileBackupService.backupExists(emoji.backupPath!);
          if (backupExists) {
            report.alreadyHasBackup++;
            continue;
          }
        }

        // 跳过网络图片
        if (emoji.localPath.isEmpty || emoji.localPath.startsWith('http')) {
          report.skipped++;
          continue;
        }

        try {
          // 检查原始文件是否存在
          final absPath = await StorageUtils.toAbsolutePath(emoji.localPath);
          final file = File(absPath);

          if (!await file.exists()) {
            // 原始文件不存在，尝试从二进制备份恢复
            if (emoji.emojiData != null && emoji.emojiData!.isNotEmpty) {
              try {
                // 确保目录存在
                final directory = file.parent;
                if (!await directory.exists()) {
                  await directory.create(recursive: true);
                }

                // 从二进制备份恢复文件
                await file.writeAsBytes(emoji.emojiData!);
                report.restoredFromBinary++;
                debugPrint('[EmojiBackupMigration] 从二进制备份恢复文件: ${emoji.id}');
              } catch (e) {
                report.failed++;
                debugPrint('[EmojiBackupMigration] 从二进制备份恢复失败 ${emoji.id}: $e');
                continue;
              }
            } else {
              report.fileNotFound++;
              debugPrint(
                  '[EmojiBackupMigration] 文件不存在且无备份: ${emoji.id} - ${emoji.localPath}');
              continue;
            }
          }

          // 创建文件备份
          final backupPath =
              await EmojiFileBackupService.createBackup(emoji.localPath);

          if (backupPath != null) {
            // 更新数据库，添加文件备份路径，清除二进制备份
            final updatedEmoji = EmojiModel(
              id: emoji.id,
              meaning: emoji.meaning,
              rawContent: emoji.rawContent,
              groupId: emoji.groupId,
              localPath: emoji.localPath,
              emojiData: null, // 清除二进制备份，节省数据库空间
              backupPath: backupPath, // 使用文件备份
              type: emoji.type,
              roleId: emoji.roleId,
              createdAt: emoji.createdAt,
            );

            await _db.insertEmoji(updatedEmoji);
            report.migrated++;

            if (report.migrated % 10 == 0) {
              debugPrint(
                  '[EmojiBackupMigration] 已迁移 ${report.migrated} 个表情包...');
            }
          } else {
            report.failed++;
            debugPrint('[EmojiBackupMigration] 创建文件备份失败: ${emoji.id}');
          }
        } catch (e) {
          report.failed++;
          debugPrint('[EmojiBackupMigration] 迁移失败 ${emoji.id}: $e');
        }
      }

      debugPrint('[EmojiBackupMigration] 迁移完成: ${report.summary}');
    } catch (e) {
      debugPrint('[EmojiBackupMigration] 迁移过程出错: $e');
      report.error = e.toString();
    }

    return report;
  }

  /// 清理孤立的备份文件
  Future<int> cleanOrphanedBackups() async {
    try {
      final emojis = await _db.getAllEmojis();
      final validBackupPaths = emojis
          .where((e) => e.backupPath != null && e.backupPath!.isNotEmpty)
          .map((e) => e.backupPath!)
          .toSet();

      return await EmojiFileBackupService.cleanOrphanedBackups(
          validBackupPaths);
    } catch (e) {
      debugPrint('[EmojiBackupMigration] 清理孤立备份失败: $e');
      return 0;
    }
  }
}

/// 迁移报告
class MigrationReport {
  int totalEmojis = 0; // 总表情包数
  int alreadyHasBackup = 0; // 已有文件备份的数量
  int skipped = 0; // 跳过的数量（网络图片等）
  int fileNotFound = 0; // 文件不存在的数量
  int restoredFromBinary = 0; // 从二进制备份恢复的数量
  int migrated = 0; // 成功迁移的数量
  int failed = 0; // 失败的数量
  String? error; // 错误信息

  String get summary {
    return '总计 $totalEmojis 个表情包，'
        '已有文件备份 $alreadyHasBackup 个，'
        '跳过 $skipped 个，'
        '文件不存在 $fileNotFound 个，'
        '从二进制恢复 $restoredFromBinary 个，'
        '成功迁移 $migrated 个，'
        '失败 $failed 个';
  }

  bool get hasIssues => fileNotFound > 0 || failed > 0 || error != null;
}
