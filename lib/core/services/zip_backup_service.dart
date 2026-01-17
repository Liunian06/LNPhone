import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ZipBackupService {
  static const String _settingsFileName = 'settings.json';
  static const String _imagesDirName = 'images';

  /// 创建备份
  /// [settings] 配置数据
  /// [files] 需要备份的文件映射 (key: 在zip中的文件名, value: 本地文件路径)
  Future<String> createBackup({
    required Map<String, dynamic> settings,
    required Map<String, String> files,
  }) async {
    final encoder = ZipFileEncoder();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = path.join(tempDir.path, 'backup_$timestamp.zip');

    try {
      encoder.create(zipPath);

      // 1. 添加设置文件
      final settingsJson = jsonEncode(settings);
      final settingsFile = File(path.join(tempDir.path, _settingsFileName));
      await settingsFile.writeAsString(settingsJson);
      encoder.addFile(settingsFile);

      // 重新实现使用 Archive 类，更灵活
      final archive = Archive();

      // 添加 settings.json
      final settingsBytes = utf8.encode(settingsJson);
      archive.addFile(
        ArchiveFile(_settingsFileName, settingsBytes.length, settingsBytes),
      );

      // 添加文件 (图片和数据库)
      for (final entry in files.entries) {
        final fileName = entry.key;
        final sourcePath = entry.value;
        final sourceFile = File(sourcePath);

        if (await sourceFile.exists()) {
          final bytes = await sourceFile.readAsBytes();
          // 如果是数据库文件，直接放在根目录，否则放在 images 目录
          String zipFileName;
          if (fileName.startsWith('db.sqlite')) {
            zipFileName = fileName;
          } else {
            zipFileName = '$_imagesDirName/$fileName';
          }
          archive.addFile(ArchiveFile(zipFileName, bytes.length, bytes));
        }
      }

      // 编码并保存
      final zipEncoder = ZipEncoder();
      final encodedZip = zipEncoder.encode(archive);
      if (encodedZip == null) throw Exception('Failed to encode zip');

      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(encodedZip);

      return zipPath;
    } catch (e) {
      rethrow;
    } finally {
      // 清理临时文件
      final settingsFile = File(path.join(tempDir.path, _settingsFileName));
      if (await settingsFile.exists()) {
        await settingsFile.delete();
      }
    }
  }

  /// 恢复备份
  /// [zipPath] 备份文件路径
  /// 返回: 解析后的配置数据，其中图片路径已更新为本地恢复后的路径
  Future<Map<String, dynamic>> restoreBackup(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      throw Exception('Backup file not found');
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final appDocDir = await getApplicationDocumentsDirectory();
    Map<String, dynamic>? settings;
    final restoredFiles = <String, String>{}; // zipFileName -> localPath

    // 1. 遍历解压
    for (final file in archive) {
      if (file.isFile) {
        if (file.name == _settingsFileName) {
          final content = utf8.decode(file.content as List<int>);
          settings = jsonDecode(content) as Map<String, dynamic>;
        } else if (file.name.startsWith('db.sqlite')) {
          // 恢复数据库文件 (包括 wal 和 shm)
          final outFile = File(path.join(appDocDir.path, file.name));
          await outFile.writeAsBytes(file.content as List<int>);
        } else if (file.name.startsWith('$_imagesDirName/')) {
          final fileName = path.basename(file.name);
          // 避免文件名冲突，添加时间戳
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final ext = path.extension(fileName);
          final nameWithoutExt = path.basenameWithoutExtension(fileName);
          final newFileName = '${nameWithoutExt}_$timestamp$ext';

          final outFile = File(path.join(appDocDir.path, newFileName));
          await outFile.writeAsBytes(file.content as List<int>);

          // 记录映射关系：zip中的相对路径 -> 本地绝对路径
          restoredFiles[file.name] = outFile.path;
          // 同时也记录纯文件名的映射，以防万一
          restoredFiles[fileName] = outFile.path;
        }
      }
    }

    if (settings == null) {
      throw Exception('Invalid backup file: settings.json not found');
    }

    // 2. 更新 settings 中的图片路径
    // 这部分逻辑需要根据 settings 的结构来定制，或者由调用者处理
    // 为了通用性，我们可以在这里返回 settings 和 restoredFiles，让调用者处理
    // 但为了方便，我们尝试在这里处理通用的替换逻辑

    // 实际上，SystemStateProvider 知道结构。
    // 我们最好返回 settings 和一个 "imageResolver" 函数或 map

    // 为了简单起见，我们将 restoredFiles 注入到 settings 中一个特殊的字段，
    // 或者直接返回一个包含两者的对象。
    // 这里我们直接修改 settings 中的 known fields，或者返回一个 Result 对象。

    // 让我们修改返回类型，或者约定 settings 中包含一个 _restoredImages 字段
    settings['_restoredImages'] = restoredFiles;

    return settings;
  }
}
