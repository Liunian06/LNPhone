import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('[NotificationService] 开始初始化...');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NotificationService] 收到通知响应: ${response.payload}');
      },
    );

    // 获取 Android 实现
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // 1. 创建通知频道（Android 8.0+ 必需，Android 15 更加严格）
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ai_reply_channel', // 频道ID，必须与发送通知时一致
        'AI回复通知', // 频道名称
        description: 'AI角色回复消息的通知',
        importance: Importance.high, // 高优先级才能弹出通知
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(channel);
      debugPrint('[NotificationService] ✓ 通知频道已创建: ${channel.id}');

      // 2. 请求 Android 13+ (API 33+) 通知权限
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      debugPrint('[NotificationService] 通知权限请求结果: $granted');

      // 3. 检查精确闹钟权限（Android 12+）
      final bool? exactAlarmsGranted =
          await androidImplementation.requestExactAlarmsPermission();
      debugPrint('[NotificationService] 精确闹钟权限请求结果: $exactAlarmsGranted');
    }

    _initialized = true;
    debugPrint('[NotificationService] ✓ 初始化完成');
  }

  /// 显示AI回复通知
  ///
  /// [title] 通知标题（通常是角色名称）
  /// [message] 通知内容（AI回复的消息）
  /// [id] 通知ID，用于区分不同的通知
  Future<void> showAiReplyNotification({
    required String title,
    required String message,
    int id = 0,
  }) async {
    debugPrint(
        '[NotificationService] showAiReplyNotification called: title=$title, id=$id');

    if (!_initialized) {
      debugPrint('[NotificationService] 尚未初始化，先进行初始化...');
      await initialize();
    }

    // Android 通知详情
    // 注意：频道ID必须与 initialize() 中创建的频道一致
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ai_reply_channel', // 频道ID，必须与初始化时创建的一致
      'AI回复通知', // 频道名称
      channelDescription: 'AI角色回复消息的通知',
      importance: Importance.max, // 最高优先级
      priority: Priority.max, // 最高优先级
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // 使用 BigTextStyle 支持长文本
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: title,
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
      ),
      // Android 15 相关设置
      category: AndroidNotificationCategory.message, // 消息类型
      visibility: NotificationVisibility.public, // 锁屏可见
      autoCancel: true, // 点击后自动消失
      ongoing: false, // 非持续通知
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        message,
        platformChannelSpecifics,
      );
      debugPrint('[NotificationService] ✓ 通知已发送: id=$id');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] ❌ 发送通知失败: $e');
      debugPrint('[NotificationService] 堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
