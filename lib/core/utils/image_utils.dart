import 'dart:convert';
import 'dart:io';

class ImageUtils {
  /// 将图片文件转换为 Base64 字符串
  static Future<String?> imageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// 获取图片的 MIME 类型
  static String getMimeType(String imagePath) {
    final ext = imagePath.split('.').last.toLowerCase();
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
}
