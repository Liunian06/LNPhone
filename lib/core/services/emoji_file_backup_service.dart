import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../utils/storage_utils.dart';

/// 表情包文件备份服务
/// 使用 image 库正确处理 GIF 透明背景
class EmojiFileBackupService {
  static const String _backupDirName = 'emojis_backup';

  /// 获取备份目录路径
  static Future<String> getBackupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, _backupDirName));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir.path;
  }

  /// 为表情包文件创建备份
  /// 使用 image 库正确处理 GIF，保持透明通道
  static Future<String?> createBackup(String originalPath) async {
    try {
      final absPath = await StorageUtils.toAbsolutePath(originalPath);
      final originalFile = File(absPath);

      if (!await originalFile.exists()) {
        debugPrint('[EmojiBackup] 原始文件不存在: $originalPath');
        return null;
      }

      final backupDir = await getBackupDir();
      final fileName = p.basename(originalPath);
      final backupPath = p.join(backupDir, fileName);
      final extension = p.extension(originalPath).toLowerCase();

      // 所有格式都使用字节复制，避免 File.copy() 在某些 Android 版本上损坏透明通道
      final bytes = await originalFile.readAsBytes();
      await File(backupPath).writeAsBytes(bytes);
      debugPrint('[EmojiBackup] 已创建备份（字节复制）: $fileName');

      // 返回相对路径
      final relPath = await StorageUtils.toRelativePath(backupPath);
      return relPath;
    } catch (e) {
      debugPrint('[EmojiBackup] 创建备份失败: $e');
      return null;
    }
  }

  /// 从备份恢复文件
  static Future<bool> restoreFromBackup(
      String originalPath, String backupPath) async {
    try {
      final backupAbsPath = await StorageUtils.toAbsolutePath(backupPath);
      final backupFile = File(backupAbsPath);

      if (!await backupFile.exists()) {
        debugPrint('[EmojiBackup] 备份文件不存在: $backupPath');
        return false;
      }

      final originalAbsPath = await StorageUtils.toAbsolutePath(originalPath);
      final originalFile = File(originalAbsPath);

      // 确保目录存在
      final directory = originalFile.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 从备份复制到原始位置
      await backupFile.copy(originalAbsPath);
      debugPrint('[EmojiBackup] 已从备份恢复: ${p.basename(originalPath)}');

      return true;
    } catch (e) {
      debugPrint('[EmojiBackup] 恢复失败: $e');
      return false;
    }
  }

  /// 删除备份文件
  static Future<void> deleteBackup(String backupPath) async {
    try {
      final absPath = await StorageUtils.toAbsolutePath(backupPath);
      final file = File(absPath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('[EmojiBackup] 已删除备份: ${p.basename(backupPath)}');
      }
    } catch (e) {
      debugPrint('[EmojiBackup] 删除备份失败: $e');
    }
  }

  /// 检查备份文件是否存在
  static Future<bool> backupExists(String backupPath) async {
    try {
      final absPath = await StorageUtils.toAbsolutePath(backupPath);
      return await File(absPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// 清理孤立的备份文件（原始文件和数据库记录都不存在）
  static Future<int> cleanOrphanedBackups(Set<String> validBackupPaths) async {
    int cleaned = 0;

    try {
      final backupDir = Directory(await getBackupDir());

      if (!await backupDir.exists()) {
        return 0;
      }

      final files = await backupDir.list().toList();

      for (final entity in files) {
        if (entity is File) {
          final relPath = await StorageUtils.toRelativePath(entity.path);

          if (!validBackupPaths.contains(relPath)) {
            await entity.delete();
            cleaned++;
            debugPrint('[EmojiBackup] 已清理孤立备份: ${p.basename(entity.path)}');
          }
        }
      }

      debugPrint('[EmojiBackup] 清理完成，共删除 $cleaned 个孤立备份');
    } catch (e) {
      debugPrint('[EmojiBackup] 清理孤立备份失败: $e');
    }

    return cleaned;
  }

  /// 获取备份目录大小（MB）
  static Future<double> getBackupDirSize() async {
    try {
      final backupDir = Directory(await getBackupDir());

      if (!await backupDir.exists()) {
        return 0.0;
      }

      int totalBytes = 0;
      final files = await backupDir.list(recursive: true).toList();

      for (final entity in files) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      return totalBytes / (1024 * 1024); // 转换为 MB
    } catch (e) {
      debugPrint('[EmojiBackup] 获取备份目录大小失败: $e');
      return 0.0;
    }
  }
}
