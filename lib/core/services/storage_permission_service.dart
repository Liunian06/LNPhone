import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// 存储权限管理服务
/// 用于请求和管理本地文件存储权限，提高文件保活程度
class StoragePermissionService {
  static final StoragePermissionService _instance =
      StoragePermissionService._internal();
  factory StoragePermissionService() => _instance;
  StoragePermissionService._internal();

  /// 检查并请求存储权限
  ///
  /// 重要说明：
  /// - 应用私有目录（getApplicationDocumentsDirectory）不需要任何权限
  /// - 但为了提高文件保活能力，我们请求管理外部存储权限
  /// - Android 13+ 会显示"访问相册"，这是系统的细粒度权限设计
  ///
  /// 返回 true 表示已授予权限或不需要权限，false 表示被拒绝
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // iOS 不需要显式请求存储权限
      return true;
    }

    try {
      // 优先请求管理外部存储权限（Android 11+）
      // 这个权限可以提供最高级别的文件保活能力
      final hasManagePermission = await requestManageExternalStorage();
      if (hasManagePermission) {
        debugPrint('[StoragePermission] ✓ 已获得管理外部存储权限（最高级别）');
        return true;
      }

      // 如果管理外部存储权限被拒绝，降级请求基础权限
      debugPrint('[StoragePermission] 管理外部存储权限未授予，请求基础权限...');

      // Android 13+ 使用新的媒体权限
      if (await _isAndroid13OrHigher()) {
        return await _requestMediaPermissions();
      } else {
        // Android 12 及以下使用传统存储权限
        return await _requestLegacyStoragePermission();
      }
    } catch (e) {
      debugPrint('[StoragePermission] 请求权限时出错: $e');
      // 即使权限请求失败，应用私有目录仍然可用
      debugPrint('[StoragePermission] 注意：应用私有目录不需要权限，文件仍可正常使用');
      return true; // 返回 true 以继续文件完整性检查
    }
  }

  /// 检查是否为 Android 13 或更高版本
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // Android 13 对应 API Level 33
      final apiLevel = androidInfo.version.sdkInt;
      debugPrint('[StoragePermission] Android API Level: $apiLevel');
      return apiLevel >= 33;
    } catch (e) {
      debugPrint('[StoragePermission] 获取 Android 版本失败: $e');
      // 降级处理：假设是较低版本
      return false;
    }
  }

  /// 请求 Android 13+ 的媒体权限
  /// 注意：这些权限在系统对话框中显示为"访问相册"、"访问视频"
  /// 但应用私有目录不需要这些权限
  Future<bool> _requestMediaPermissions() async {
    debugPrint('[StoragePermission] 请求 Android 13+ 媒体权限（系统会显示"访问相册"）...');
    debugPrint('[StoragePermission] 说明：应用私有目录不需要此权限，但可提高文件保活能力');

    // 请求图片和视频权限
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.videos,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      debugPrint('[StoragePermission] ✓ 媒体权限已授予');
    } else {
      debugPrint('[StoragePermission] ⚠ 部分媒体权限被拒绝（不影响应用私有目录使用）');
      _logPermissionStatuses(statuses);
    }

    return allGranted;
  }

  /// 请求 Android 12 及以下的传统存储权限
  Future<bool> _requestLegacyStoragePermission() async {
    debugPrint('[StoragePermission] 请求传统存储权限...');

    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      debugPrint('[StoragePermission] ✓ 存储权限已授予');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('[StoragePermission] ✗ 存储权限被永久拒绝，需要引导用户到设置');
      return false;
    } else {
      debugPrint('[StoragePermission] ✗ 存储权限被拒绝');
      return false;
    }
  }

  /// 检查存储权限状态
  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      if (await _isAndroid13OrHigher()) {
        // Android 13+ 检查媒体权限
        bool photosGranted = await Permission.photos.isGranted;
        bool videosGranted = await Permission.videos.isGranted;
        return photosGranted && videosGranted;
      } else {
        // Android 12 及以下检查存储权限
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('[StoragePermission] 检查权限时出错: $e');
      return false;
    }
  }

  /// 打开应用设置页面
  Future<void> openAppSettings() async {
    debugPrint('[StoragePermission] 打开应用设置页面...');
    await openAppSettings();
  }

  /// 请求管理外部存储权限（Android 11+）
  /// 这个权限可以提供更高的文件保活能力
  Future<bool> requestManageExternalStorage() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // 检查是否为 Android 11 或更高版本 (API Level 30)
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final apiLevel = androidInfo.version.sdkInt;

      if (apiLevel < 30) {
        debugPrint(
            '[StoragePermission] Android API Level $apiLevel < 30，不需要管理外部存储权限');
        return true;
      }

      debugPrint('[StoragePermission] 请求管理外部存储权限...');

      PermissionStatus status =
          await Permission.manageExternalStorage.request();

      if (status.isGranted) {
        debugPrint('[StoragePermission] ✓ 管理外部存储权限已授予');
        return true;
      } else {
        debugPrint('[StoragePermission] ✗ 管理外部存储权限被拒绝');
        return false;
      }
    } catch (e) {
      debugPrint('[StoragePermission] 请求管理外部存储权限时出错: $e');
      return false;
    }
  }

  /// 检查管理外部存储权限状态
  Future<bool> checkManageExternalStorage() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final apiLevel = androidInfo.version.sdkInt;

      if (apiLevel < 30) {
        return true;
      }
      return await Permission.manageExternalStorage.isGranted;
    } catch (e) {
      debugPrint('[StoragePermission] 检查管理外部存储权限时出错: $e');
      return false;
    }
  }

  /// 记录权限状态
  void _logPermissionStatuses(Map<Permission, PermissionStatus> statuses) {
    statuses.forEach((permission, status) {
      debugPrint(
          '[StoragePermission] ${permission.toString()}: ${status.toString()}');
    });
  }

  /// 获取权限状态的友好描述
  String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授予';
      case PermissionStatus.denied:
        return '已拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limited:
        return '有限授予';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.provisional:
        return '临时授予';
      default:
        return '未知';
    }
  }
}
