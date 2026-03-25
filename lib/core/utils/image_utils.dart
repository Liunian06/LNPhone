import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'storage_utils.dart';

class ImageUtils {
  /// 将图片文件转换为 Base64 字符串
  static Future<String?> imageToBase64(String imagePath) async {
    try {
      final resolvedPath = await _resolvePath(imagePath);
      if (resolvedPath == null) return null;

      final file = File(resolvedPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// 获取图片的 MIME 类型
  static Future<String> getMimeType(String imagePath) async {
    try {
      final resolvedPath = await _resolvePath(imagePath);
      if (resolvedPath != null) {
        final file = File(resolvedPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return detectMimeTypeFromBytes(bytes, pathHint: imagePath);
        }
      }
    } catch (e) {
      // Fall back to extension-based detection below.
    }

    return detectMimeTypeFromBytes(null, pathHint: imagePath);
  }

  /// 通过文件头优先识别 MIME 类型，必要时回退到扩展名。
  static String detectMimeTypeFromBytes(Uint8List? bytes, {String? pathHint}) {
    if (bytes != null && bytes.length >= 12) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }

      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }

      // GIF: 47 49 46 38
      if (bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x38) {
        return 'image/gif';
      }

      // WebP: RIFF....WEBP
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
    }

    final ext = p.extension(pathHint ?? '').replaceFirst('.', '').toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String extensionForMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'image/jpeg':
      default:
        return '.jpg';
    }
  }

  static Future<String?> _resolvePath(String imagePath) async {
    if (imagePath.isEmpty || imagePath.startsWith('http')) {
      return null;
    }

    return StorageUtils.toAbsolutePath(imagePath);
  }
}
