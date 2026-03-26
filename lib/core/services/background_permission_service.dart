import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../database/database.dart';
import '../models/background_reply_model.dart';
import 'app_log_service.dart';
import 'background_reply_native_bridge.dart';

class BackgroundPermissionService {
  static const String notificationsGrantedKey =
      'background_perm_notifications_granted';
  static const String exactAlarmGrantedKey =
      'background_perm_exact_alarm_granted';
  static const String batteryOptimizationIgnoredKey =
      'background_perm_battery_optimization_ignored';
  static const String exactAlarmSupportedKey =
      'background_perm_exact_alarm_supported';
  static const String batteryOptimizationSupportedKey =
      'background_perm_battery_optimization_supported';
  static const String permissionsLastCheckedAtKey =
      'background_perm_last_checked_at';

  static final AppDatabase _db = AppDatabase();
  static final BackgroundReplyNativeBridge _nativeBridge =
      BackgroundReplyNativeBridge();

  static Future<BackgroundPermissionSnapshot> refreshAndPersistSnapshot() async {
    if (!Platform.isAndroid) {
      const snapshot = BackgroundPermissionSnapshot(
        notificationsGranted: true,
        exactAlarmGranted: true,
        batteryOptimizationIgnored: true,
        exactAlarmSupported: false,
        batteryOptimizationSupported: false,
      );
      await _persistSnapshot(snapshot);
      return snapshot;
    }

    final nativeStatus = await _nativeBridge.getPermissionStatus();
    final snapshot = BackgroundPermissionSnapshot(
      notificationsGranted:
          nativeStatus['notificationsGranted'] as bool? ?? false,
      exactAlarmGranted: nativeStatus['exactAlarmGranted'] as bool? ?? false,
      batteryOptimizationIgnored:
          nativeStatus['batteryOptimizationIgnored'] as bool? ?? false,
      exactAlarmSupported:
          nativeStatus['exactAlarmSupported'] as bool? ?? true,
      batteryOptimizationSupported:
          nativeStatus['batteryOptimizationSupported'] as bool? ?? true,
    );
    await _persistSnapshot(snapshot);
    await AppLogService.log(
      '后台权限快照已刷新',
      category: 'Permission',
      data: {
        'notificationsGranted': snapshot.notificationsGranted,
        'exactAlarmGranted': snapshot.exactAlarmGranted,
        'batteryOptimizationIgnored': snapshot.batteryOptimizationIgnored,
        'hasBaseRequirements': snapshot.hasBaseRequirements,
      },
    );
    return snapshot;
  }

  static Future<BackgroundPermissionSnapshot> getPersistedSnapshot() async {
    return BackgroundPermissionSnapshot(
      notificationsGranted:
          await _db.getSettingBool(notificationsGrantedKey) ?? false,
      exactAlarmGranted: await _db.getSettingBool(exactAlarmGrantedKey) ?? false,
      batteryOptimizationIgnored:
          await _db.getSettingBool(batteryOptimizationIgnoredKey) ?? false,
      exactAlarmSupported:
          await _db.getSettingBool(exactAlarmSupportedKey) ?? true,
      batteryOptimizationSupported:
          await _db.getSettingBool(batteryOptimizationSupportedKey) ?? true,
    );
  }

  static Future<int?> getPersistedLastCheckedAt() {
    return _db.getSettingInt(permissionsLastCheckedAtKey);
  }

  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    await AppLogService.log(
      '请求通知权限完成',
      category: 'Permission',
      data: {'granted': result.isGranted},
    );
    return result.isGranted;
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    final result = await Permission.ignoreBatteryOptimizations.request();
    await AppLogService.log(
      '请求忽略电池优化完成',
      category: 'Permission',
      data: {'granted': result.isGranted},
    );
    return result.isGranted;
  }

  static Future<void> openNotificationSettings() {
    if (!Platform.isAndroid) return Future.value();
    AppLogService.info('打开通知设置页', category: 'Permission');
    return _nativeBridge.openNotificationSettings();
  }

  static Future<void> openExactAlarmSettings() {
    if (!Platform.isAndroid) return Future.value();
    AppLogService.info('打开精确闹钟设置页', category: 'Permission');
    return _nativeBridge.openExactAlarmSettings();
  }

  static Future<void> openBatteryOptimizationSettings() {
    if (!Platform.isAndroid) return Future.value();
    AppLogService.info('打开电池优化设置页', category: 'Permission');
    return _nativeBridge.openBatteryOptimizationSettings();
  }

  static Future<void> scheduleNextWakeup(int timestampMs) async {
    if (!Platform.isAndroid) return Future.value();
    await AppLogService.log(
      '同步原生后台唤醒时间',
      category: 'Scheduler',
      data: {'timestampMs': timestampMs},
    );
    return _nativeBridge.scheduleNextWakeup(timestampMs);
  }

  static Future<void> cancelNextWakeup() async {
    if (!Platform.isAndroid) return Future.value();
    await AppLogService.info('取消原生后台唤醒', category: 'Scheduler');
    return _nativeBridge.cancelNextWakeup();
  }

  static Future<int?> getPersistedNextWakeup() {
    if (!Platform.isAndroid) return Future.value(null);
    return _nativeBridge.getPersistedNextWakeup();
  }

  static Future<void> _persistSnapshot(
    BackgroundPermissionSnapshot snapshot,
  ) async {
    await _db.setSettingBool(
      notificationsGrantedKey,
      snapshot.notificationsGranted,
    );
    await _db.setSettingBool(
      exactAlarmGrantedKey,
      snapshot.exactAlarmGranted,
    );
    await _db.setSettingBool(
      batteryOptimizationIgnoredKey,
      snapshot.batteryOptimizationIgnored,
    );
    await _db.setSettingBool(
      exactAlarmSupportedKey,
      snapshot.exactAlarmSupported,
    );
    await _db.setSettingBool(
      batteryOptimizationSupportedKey,
      snapshot.batteryOptimizationSupported,
    );
    await _db.setSettingInt(
      permissionsLastCheckedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
