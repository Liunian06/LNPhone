import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/emoji_model.dart';

class EmojiZipService {
  static const String _metadataFileName = 'emojis_metadata.json';
  static const String _imagesDirName = 'images';

  /// 导出表情包到 ZIP
  /// [emojis] 需要导出的表情列表
  /// 返回 ZIP 文件的本地路径
  Future<String> exportEmojis(List<EmojiModel> emojis) async {
    final archive = Archive();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = path.join(tempDir.path, 'emojis_export_$timestamp.zip');

    // 1. 准备元数据
    final List<Map<String, dynamic>> metadataList = emojis
        .map((e) => {
              'id': e.id,
              'meaning': e.meaning,
              'rawContent': e.rawContent,
              'fileName': path.basename(e.localPath),
            })
        .toList();

    final metadataJson = jsonEncode(metadataList);
    final metadataBytes = utf8.encode(metadataJson);
    archive.addFile(
      ArchiveFile(_metadataFileName, metadataBytes.length, metadataBytes),
    );

    // 2. 添加图片文件
    for (final emoji in emojis) {
      final sourceFile = File(emoji.localPath);
      if (await sourceFile.exists()) {
        final bytes = await sourceFile.readAsBytes();
        final fileName = path.basename(emoji.localPath);
        archive.addFile(
          ArchiveFile('$_imagesDirName/$fileName', bytes.length, bytes),
        );
      }
    }

    // 3. 编码并保存
    final zipEncoder = ZipEncoder();
    final encodedZip = zipEncoder.encode(archive);
    if (encodedZip == null) throw Exception('Failed to encode zip');

    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(encodedZip);

    return zipPath;
  }

  /// 从 ZIP 导入表情包
  /// [zipPath] ZIP 文件路径
  /// 返回解析后的元数据列表和对应的临时图片路径
  Future<List<Map<String, dynamic>>> parseImportZip(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      throw Exception('Import file not found');
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final importTempDir = Directory(path.join(
        tempDir.path, 'emoji_import_${DateTime.now().millisecondsSinceEpoch}'));
    await importTempDir.create(recursive: true);

    List<Map<String, dynamic>>? metadata;
    final Map<String, String> fileNameToTempPath = {};

    // 1. 遍历解压
    for (final file in archive) {
      if (file.isFile) {
        if (file.name == _metadataFileName) {
          final content = utf8.decode(file.content as List<int>);
          metadata = (jsonDecode(content) as List<dynamic>)
              .cast<Map<String, dynamic>>();
        } else if (file.name.startsWith('$_imagesDirName/')) {
          final fileName = path.basename(file.name);
          final outFile = File(path.join(importTempDir.path, fileName));
          await outFile.writeAsBytes(file.content as List<int>);
          fileNameToTempPath[fileName] = outFile.path;
        }
      }
    }

    if (metadata == null) {
      throw Exception('Invalid emoji zip: metadata not found');
    }

    // 2. 关联元数据与临时路径
    for (var item in metadata) {
      final fileName = item['fileName'];
      item['tempPath'] = fileNameToTempPath[fileName];
    }

    return metadata;
  }
}
