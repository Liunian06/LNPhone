import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// 存储工具类，处理文件的持久化存储和相对路径转换
class StorageUtils {
  static String? _appDocPath;
  static int _lastTimestamp = 0;

  /// 获取唯一的毫秒级时间戳
  static int getUniqueTimestamp() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    if (timestamp <= _lastTimestamp) {
      timestamp = _lastTimestamp + 1;
    }
    _lastTimestamp = timestamp;
    return timestamp;
  }

  /// 初始化获取应用文档目录
  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _appDocPath = directory.path;
  }

  /// 获取应用文档目录路径
  static Future<String> getAppDocPath() async {
    if (_appDocPath == null) {
      await init();
    }
    return _appDocPath!;
  }

  /// 将绝对路径转换为相对路径（相对于应用文档目录）
  static Future<String> toRelativePath(String absolutePath) async {
    final docPath = await getAppDocPath();
    if (absolutePath.startsWith(docPath)) {
      return absolutePath
          .substring(docPath.length)
          .replaceFirst(RegExp(r'^[/\\]'), '');
    }
    return absolutePath;
  }

  /// 将相对路径转换为绝对路径
  static Future<String> toAbsolutePath(String relativePath) async {
    if (relativePath.startsWith('http') || relativePath.isEmpty)
      return relativePath;

    // 如果已经是绝对路径（以 / 或盘符开头），直接返回
    if (p.isAbsolute(relativePath)) return relativePath;

    final docPath = await getAppDocPath();
    return p.join(docPath, relativePath);
  }

  /// 确保文件存在，如果不存在且提供了备份数据，则恢复文件
  static Future<String> ensureFileExists(String path,
      {Uint8List? backupData}) async {
    if (path.isEmpty || path.startsWith('http')) return path;

    final absPath = await toAbsolutePath(path);
    final file = File(absPath);

    if (await file.exists()) {
      return absPath;
    }

    // 如果文件不存在且有备份数据，尝试恢复
    if (backupData != null && backupData.isNotEmpty) {
      try {
        // 确保目录存在
        final directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await file.writeAsBytes(backupData);
        debugPrint('[StorageUtils] 已从备份数据恢复文件: $absPath');
        return absPath;
      } catch (e) {
        debugPrint('[StorageUtils] 恢复文件失败: $e');
      }
    }

    return absPath;
  }

  /// 确保文件在持久化目录中。如果源文件在临时目录（如 cache），则将其复制到持久化目录。
  static Future<String> ensurePersistent(String sourcePath, String id,
      {String subDir = 'avatars'}) async {
    if (sourcePath.isEmpty || sourcePath.startsWith('http')) return sourcePath;

    final docPath = await getAppDocPath();
    // 如果已经在持久化目录下，直接返回
    if (sourcePath.startsWith(docPath)) return sourcePath;

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return sourcePath;

      final fileName =
          '${id}_${getUniqueTimestamp()}${p.extension(sourcePath).isEmpty ? ".jpg" : p.extension(sourcePath)}';
      final targetDir = Directory(p.join(docPath, subDir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final targetPath = p.join(targetDir.path, fileName);
      await sourceFile.copy(targetPath);
      debugPrint('[StorageUtils] 文件已从临时路径备份到持久化目录: $targetPath');

      // 返回相对路径，以便数据库存储
      return p.join(subDir, fileName);
    } catch (e) {
      debugPrint('[StorageUtils] 备份文件到持久化目录失败: $e');
      return sourcePath;
    }
  }

  /// 保存二进制数据到文件，并返回相对路径
  static Future<String?> saveBlobToFile(
      Uint8List? data, String subDir, String fileName) async {
    if (data == null || data.isEmpty) return null;

    try {
      final docPath = await getAppDocPath();
      final targetDir = Directory(p.join(docPath, subDir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsBytes(data);

      return p.join(subDir, fileName);
    } catch (e) {
      debugPrint('[StorageUtils] 保存文件失败: $e');
      return null;
    }
  }

  /// 从文件读取二进制数据
  static Future<Uint8List?> readFileToBlob(String relativePath) async {
    if (relativePath.isEmpty || relativePath.startsWith('http')) return null;

    try {
      final absPath = await toAbsolutePath(relativePath);
      final file = File(absPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('[StorageUtils] 读取文件失败: $e');
    }
    return null;
  }

  /// 删除文件
  static Future<void> deleteFile(String relativePath) async {
    if (relativePath.isEmpty || relativePath.startsWith('http')) return;

    try {
      final absPath = await toAbsolutePath(relativePath);
      final file = File(absPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[StorageUtils] 删除文件失败: $e');
    }
  }
}
