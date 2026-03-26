import 'package:flutter/services.dart';

class BackgroundReplyNativeBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.lnphone2/background_reply');

  Future<Map<String, dynamic>> getPermissionStatus() async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
          'getPermissionStatus',
        ) ??
        <String, dynamic>{};
    return Map<String, dynamic>.from(raw);
  }

  Future<void> openNotificationSettings() {
    return _channel.invokeMethod<void>('openNotificationSettings');
  }

  Future<void> openExactAlarmSettings() {
    return _channel.invokeMethod<void>('openExactAlarmSettings');
  }

  Future<void> openBatteryOptimizationSettings() {
    return _channel.invokeMethod<void>('openBatteryOptimizationSettings');
  }

  Future<void> scheduleNextWakeup(int timestampMs) {
    return _channel.invokeMethod<void>(
      'scheduleNextWakeup',
      <String, dynamic>{'timestampMs': timestampMs},
    );
  }

  Future<void> cancelNextWakeup() {
    return _channel.invokeMethod<void>('cancelNextWakeup');
  }

  Future<int?> getPersistedNextWakeup() async {
    return await _channel.invokeMethod<int>('getPersistedNextWakeup');
  }
}
