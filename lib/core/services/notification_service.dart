import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/src/platform_specifics/android/icon.dart';
import 'package:image/image.dart' as img;
import '../utils/storage_utils.dart';
import 'app_log_service.dart';

/// 本地通知服务
class NotificationService {
  // 新的AI消息通知频道（低优先级，普通通知，带头像）
  static const String aiMessageChannelId = 'ai_message_channel';
  static const String aiMessageChannelName = 'AI消息通知';
  static const String aiMessageChannelDescription = 'AI角色发送的消息通知（显示角色头像）';

  // 旧的AI回复通知频道（保留用于兼容，高优先级）
  static const String aiReplyChannelId = 'ai_reply_channel_v2';
  static const String aiReplyChannelName = 'AI回复通知';
  static const String aiReplyChannelDescription = 'AI角色回复消息的通知';

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
    await AppLogService.info('通知服务初始化开始', category: 'Notification');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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
      // 1. 创建新的AI消息通知频道（低优先级，不弹窗但显示）
      const AndroidNotificationChannel aiMessageChannel =
          AndroidNotificationChannel(
        aiMessageChannelId,
        aiMessageChannelName,
        description: aiMessageChannelDescription,
        importance: Importance.low, // 低优先级，不弹窗但显示在通知栏
        playSound: false,
        enableVibration: false,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(aiMessageChannel);
      debugPrint('[NotificationService] ✓ AI消息频道已创建: ${aiMessageChannel.id}');
      await AppLogService.log(
        'AI消息通知频道已创建',
        category: 'Notification',
        data: {'channelId': aiMessageChannel.id, 'importance': 'low'},
      );

      // 2. 请求 Android 13+ (API 33+) 通知权限
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      debugPrint('[NotificationService] 通知权限请求结果: $granted');
      await AppLogService.log(
        '通知权限检查完成',
        category: 'Notification',
        data: {'granted': granted},
      );
    }

    _initialized = true;
    debugPrint('[NotificationService] ✓ 初始化完成');
    await AppLogService.info('通知服务初始化完成', category: 'Notification');
  }

  /// 压缩图片数据到指定大小以下
  ///
  /// [imageData] 原始图片数据
  /// [maxSizeBytes] 最大大小（字节），默认 100KB
  /// [targetWidth] 目标宽度，默认 256（通知图标尺寸）
  /// 返回压缩后的图片数据，如果压缩失败返回 null
  Future<Uint8List?> _compressImage(
    Uint8List imageData, {
    int maxSizeBytes = 100 * 1024, // 100KB
    int targetWidth = 256,
  }) async {
    try {
      debugPrint('[NotificationService] 开始压缩图片，原始大小: ${imageData.length} bytes');

      // 解码图片
      img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        debugPrint('[NotificationService] ❌ 无法解码图片');
        return null;
      }

      debugPrint('[NotificationService] 原始图片尺寸: ${image.width}x${image.height}');

      // 如果图片宽度大于目标宽度，缩小图片
      if (image.width > targetWidth) {
        final targetHeight = (image.height * targetWidth / image.width).round();
        image = img.copyResize(image, width: targetWidth, height: targetHeight);
        debugPrint('[NotificationService] 缩放后尺寸: ${image.width}x${image.height}');
      }

      // 尝试不同的质量级别进行压缩
      for (int quality = 85; quality >= 50; quality -= 10) {
        final compressed = img.encodeJpg(image, quality: quality);
        debugPrint('[NotificationService] 质量 $quality: ${compressed.length} bytes');

        if (compressed.length <= maxSizeBytes) {
          debugPrint('[NotificationService] ✓ 压缩成功: ${compressed.length} bytes (质量: $quality)');
          return Uint8List.fromList(compressed);
        }
      }

      // 如果还是太大，进一步缩小尺寸
      final smallerWidth = (targetWidth * 0.7).round();
      final smallerHeight = (image.height * 0.7).round();
      image = img.copyResize(image, width: smallerWidth, height: smallerHeight);
      final compressed = img.encodeJpg(image, quality: 50);

      debugPrint('[NotificationService] ✓ 最终压缩: ${compressed.length} bytes (尺寸: ${image.width}x${image.height})');
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('[NotificationService] ❌ 压缩图片失败: $e');
      return null;
    }
  }

  /// 显示AI回复通知（消息风格，普通通知）
  ///
  /// [title] 通知标题（通常是角色名称）
  /// [message] 通知内容（AI回复的消息）
  /// [id] 通知ID，用于区分不同的通知
  /// [avatarPath] 角色头像路径（可选，显示在通知左侧）
  /// [avatarData] 角色头像二进制数据（可选，优先级高于 avatarPath）
  Future<void> showAiReplyNotification({
    required String title,
    required String message,
    int id = 0,
    String? avatarPath,
    Uint8List? avatarData,
  }) async {
    // 步骤 1: 记录调用开始
    debugPrint('[NotificationService] ========== 开始发送通知 ==========');
    debugPrint('[NotificationService] 参数: title=$title, id=$id, messageLength=${message.length}');

    await AppLogService.log(
      '开始发送前台通知',
      category: 'Notification',
      level: LogLevel.info,
      data: {
        'step': '1_start',
        'title': title,
        'id': id,
        'avatarPath': avatarPath ?? 'null',
        'avatarDataLength': avatarData?.length ?? 0,
        'messagePreview': message.length > 50 ? '${message.substring(0, 50)}...' : message,
      },
    );

    // 步骤 2: 检查初始化状态
    await AppLogService.log(
      '检查初始化状态',
      category: 'Notification',
      level: LogLevel.debug,
      data: {
        'step': '2_check_init',
        'initialized': _initialized,
      },
    );

    if (!_initialized) {
      debugPrint('[NotificationService] 尚未初始化，先进行初始化...');
      await AppLogService.log(
        '通知服务未初始化，开始初始化',
        category: 'Notification',
        level: LogLevel.info,
        data: {'step': '2a_init_start'},
      );
      await initialize();
      await AppLogService.log(
        '通知服务初始化完成',
        category: 'Notification',
        level: LogLevel.info,
        data: {'step': '2b_init_done', 'initialized': _initialized},
      );
    }

    // 步骤 3: 加载头像
    await AppLogService.log(
      '开始加载头像',
      category: 'Notification',
      level: LogLevel.debug,
      data: {
        'step': '3_load_avatar_start',
        'hasAvatarData': avatarData != null && avatarData.isNotEmpty,
        'hasAvatarPath': avatarPath != null && avatarPath.isNotEmpty,
      },
    );

    AndroidIcon<Object>? personIcon;
    try {
      if (avatarData != null && avatarData.isNotEmpty) {
        debugPrint('[NotificationService] 使用内存头像数据，原始大小: ${avatarData.length} bytes');
        await AppLogService.log(
          '使用内存头像数据',
          category: 'Notification',
          level: LogLevel.info,
          data: {
            'step': '3a_avatar_from_memory',
            'originalSize': avatarData.length,
          },
        );

        // 检查是否需要压缩（超过 500KB 就压缩）
        Uint8List finalData = avatarData;
        if (avatarData.length > 500 * 1024) {
          debugPrint('[NotificationService] 头像过大，开始压缩...');
          await AppLogService.log(
            '头像数据过大，开始压缩',
            category: 'Notification',
            level: LogLevel.info,
            data: {
              'step': '3a1_compress_start',
              'originalSize': avatarData.length,
            },
          );

          final compressed = await _compressImage(avatarData);
          if (compressed != null) {
            finalData = compressed;
            debugPrint('[NotificationService] ✓ 压缩成功: ${finalData.length} bytes');
            await AppLogService.log(
              '头像压缩成功',
              category: 'Notification',
              level: LogLevel.info,
              data: {
                'step': '3a2_compress_success',
                'originalSize': avatarData.length,
                'compressedSize': finalData.length,
                'ratio': '${(finalData.length * 100 / avatarData.length).toStringAsFixed(1)}%',
              },
            );
          } else {
            debugPrint('[NotificationService] ❌ 压缩失败，跳过头像');
            await AppLogService.warning(
              '头像压缩失败',
              category: 'Notification',
              data: {
                'step': '3a3_compress_failed',
                'originalSize': avatarData.length,
              },
            );
            // 压缩失败，不使用头像
            finalData = Uint8List(0);
          }
        }

        if (finalData.isNotEmpty) {
          personIcon = ByteArrayAndroidIcon(finalData);
          debugPrint('[NotificationService] ✓ 创建 ByteArrayAndroidIcon 成功（内存数据）');
        }
      } else if (avatarPath != null && avatarPath.isNotEmpty) {
        await AppLogService.log(
          '尝试从文件加载头像',
          category: 'Notification',
          level: LogLevel.debug,
          data: {
            'step': '3b_avatar_from_file',
            'originalPath': avatarPath,
          },
        );

        final absolutePath = await StorageUtils.toAbsolutePath(avatarPath);
        debugPrint('[NotificationService] 转换后的绝对路径: $absolutePath');

        await AppLogService.log(
          '路径转换结果',
          category: 'Notification',
          level: LogLevel.debug,
          data: {
            'step': '3c_path_converted',
            'absolutePath': absolutePath,
          },
        );

        final file = File(absolutePath);
        final exists = await file.exists();

        await AppLogService.log(
          '检查文件是否存在',
          category: 'Notification',
          level: LogLevel.debug,
          data: {
            'step': '3d_file_check',
            'exists': exists,
            'absolutePath': absolutePath,
          },
        );

        if (exists) {
          final bytes = await file.readAsBytes();
          debugPrint('[NotificationService] 从文件读取头像成功，原始大小: ${bytes.length} bytes');
          await AppLogService.log(
            '从文件读取头像成功',
            category: 'Notification',
            level: LogLevel.info,
            data: {
              'step': '3e_file_read_success',
              'originalSize': bytes.length,
            },
          );

          // 检查是否需要压缩
          Uint8List finalData = bytes;
          if (bytes.length > 500 * 1024) {
            debugPrint('[NotificationService] 文件头像过大，开始压缩...');
            await AppLogService.log(
              '文件头像过大，开始压缩',
              category: 'Notification',
              level: LogLevel.info,
              data: {
                'step': '3e1_compress_start',
                'originalSize': bytes.length,
              },
            );

            final compressed = await _compressImage(bytes);
            if (compressed != null) {
              finalData = compressed;
              debugPrint('[NotificationService] ✓ 压缩成功: ${finalData.length} bytes');
              await AppLogService.log(
                '文件头像压缩成功',
                category: 'Notification',
                level: LogLevel.info,
                data: {
                  'step': '3e2_compress_success',
                  'originalSize': bytes.length,
                  'compressedSize': finalData.length,
                  'ratio': '${(finalData.length * 100 / bytes.length).toStringAsFixed(1)}%',
                },
              );
            } else {
              debugPrint('[NotificationService] ❌ 压缩失败，跳过头像');
              await AppLogService.warning(
                '文件头像压缩失败',
                category: 'Notification',
                data: {
                  'step': '3e3_compress_failed',
                  'originalSize': bytes.length,
                },
              );
              // 压缩失败，不使用头像
              finalData = Uint8List(0);
            }
          }

          if (finalData.isNotEmpty) {
            personIcon = ByteArrayAndroidIcon(finalData);
            debugPrint('[NotificationService] ✓ 创建 ByteArrayAndroidIcon 成功');
          }
        } else {
          debugPrint('[NotificationService] 头像文件不存在: $absolutePath');
          await AppLogService.warning(
            '头像文件不存在',
            category: 'Notification',
            data: {
              'step': '3f_file_not_found',
              'absolutePath': absolutePath,
              'originalPath': avatarPath,
            },
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] 加载头像失败: $e');
      await AppLogService.error(
        '加载头像失败',
        category: 'Notification',
        data: {
          'step': '3g_avatar_error',
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      personIcon = null;
    }

    await AppLogService.log(
      '头像加载完成',
      category: 'Notification',
      level: LogLevel.info,
      data: {
        'step': '3h_avatar_done',
        'hasIcon': personIcon != null,
      },
    );

    // 保存压缩后的图标数据用于 largeIcon
    Uint8List? largeIconData;
    if (personIcon != null) {
      // 从 personIcon 中提取数据（如果是 ByteArrayAndroidIcon）
      if (personIcon is ByteArrayAndroidIcon) {
        largeIconData = personIcon.data as Uint8List?;
      }
    }

    // 步骤 4: 创建 BigTextStyle（普通文本通知）
    await AppLogService.log(
      '创建 BigTextStyle',
      category: 'Notification',
      level: LogLevel.debug,
      data: {
        'step': '4_create_bigtext_style',
        'messageLength': message.length,
      },
    );

    final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
      message,
      contentTitle: title,
      summaryText: null,
    );

    // 步骤 5: 创建通知详情
    await AppLogService.log(
      '创建 AndroidNotificationDetails',
      category: 'Notification',
      level: LogLevel.debug,
      data: {
        'step': '5_create_details',
        'channelId': aiMessageChannelId,
        'channelName': aiMessageChannelName,
        'importance': 'low',
        'priority': 'low',
        'hasLargeIcon': largeIconData != null,
      },
    );

    // 创建 largeIcon（如果有压缩后的数据）
    AndroidBitmap<Object>? largeIcon;
    if (largeIconData != null && largeIconData.isNotEmpty) {
      largeIcon = ByteArrayAndroidBitmap(largeIconData);
      debugPrint('[NotificationService] ✓ 创建 largeIcon (ByteArrayAndroidBitmap)');
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      aiMessageChannelId,
      aiMessageChannelName,
      channelDescription: aiMessageChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
      enableVibration: false,
      playSound: false,
      styleInformation: bigTextStyle, // 使用 BigTextStyle
      largeIcon: largeIcon, // 添加 largeIcon（右侧显示）
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      ongoing: false,
      channelShowBadge: true,
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

    // 步骤 7: 发送通知
    await AppLogService.log(
      '准备调用 show 方法',
      category: 'Notification',
      level: LogLevel.info,
      data: {
        'step': '7_before_show',
        'id': id,
        'title': title,
      },
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        message,
        platformChannelSpecifics,
      );

      debugPrint('[NotificationService] ✓ show() 方法调用完成: id=$id');
      await AppLogService.log(
        'show() 方法调用完成',
        category: 'Notification',
        level: LogLevel.info,
        data: {
          'step': '7a_show_done',
          'id': id,
          'success': true,
        },
      );

      await AppLogService.logNotificationSent(
        title: title,
        notificationId: id,
        success: true,
      );

      debugPrint('[NotificationService] ========== 通知发送流程完成 ==========');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] ❌ show() 方法调用失败: $e');
      debugPrint('[NotificationService] 堆栈: $stackTrace');

      await AppLogService.error(
        'show() 方法调用失败',
        category: 'Notification',
        data: {
          'step': '7b_show_error',
          'id': id,
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );

      await AppLogService.logNotificationSent(
        title: title,
        notificationId: id,
        success: false,
      );

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
