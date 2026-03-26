import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/database.dart';
import '../models/api_preset.dart';
import '../models/moments_model.dart';
import '../models/chat_model.dart';
import '../models/prompt_config.dart';
import '../models/background_reply_model.dart';
import '../services/llm_service.dart';
import '../services/app_log_service.dart';
import '../services/notification_service.dart';
import '../services/background_permission_service.dart';
import '../services/background_reply_scheduler_service.dart';
import 'package:drift/drift.dart' as drift;
import '../utils/storage_utils.dart';

// 超时异常类
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class _BackgroundReplyTriggerResult {
  final bool success;
  final bool disableSessionDueToFailure;
  final String? error;

  const _BackgroundReplyTriggerResult({
    required this.success,
    this.disableSessionDueToFailure = false,
    this.error,
  });
}

@pragma('vm:entry-point')
class BackgroundService {
  static const String _lastActiveTimeKey =
      BackgroundReplySchedulerService.lastActiveTimeKey;

  static Future<void> initializeService() async {
    // 注意：权限请求移到后面，避免阻塞服务初始化
    // 在某些设备上，权限请求可能会导致问题

    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'background_service', // id
      '汪汪机后台保活服务', // title
      description: '此频道用于维持应用后台运行，请勿关闭。',
      importance: Importance.low, // 提升到 low，确保在 Android 15 上更稳定
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'background_service',
        initialNotificationTitle: '汪汪机后台保活服务',
        initialNotificationContent: '程序正在后台运行，请不要关闭本服务',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  // 保存 ServiceInstance 的静态引用，用于从静态方法中发送 IPC 消息
  static ServiceInstance? _serviceInstance;

  // 后台 Isolate 中的通知插件实例
  static FlutterLocalNotificationsPlugin? _bgNotificationsPlugin;
  static Timer? _nextDueTimer;

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // 保存 service 实例以便在静态方法中使用
    _serviceInstance = service;

    // 在后台 Isolate 中初始化 Flutter 绑定
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // 在后台 Isolate 中初始化通知插件
    await _initBackgroundNotifications();

    // 记录后台服务启动日志
    await AppLogService.logBackgroundServiceStart();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    service.on('force_check').listen((event) async {
      // 确保在后台 Isolate 中也能收到日志
      debugPrint(
        '[BG] 收到强制检查指令 (Isolate: ${Isolate.current.debugName})',
      );
      try {
        await _checkAndTriggerActiveReply(
          force: true,
          triggerSource: 'force_check',
        );
      } catch (e, stack) {
        debugPrint('[BG] 强制检查执行失败: $e\n$stack');
      }
    });

    service.on('run_due_tasks').listen((event) async {
      try {
        final triggerSource = event?['triggerSource'] as String? ??
            'service_event_run_due_tasks';
        await _checkAndTriggerActiveReply(
          force: false,
          triggerSource: triggerSource,
        );
      } catch (e) {
        debugPrint('[BG] run_due_tasks 失败: $e');
      }
    });

    await _checkAndTriggerActiveReply(
      force: false,
      triggerSource: 'service_start',
    );
  }

  static Future<void> _checkAndTriggerActiveReply({
    bool force = false,
    String triggerSource = 'background_scheduler',
  }) async {
    try {
      debugPrint(
        '[BG] ========== 后台任务检查开始 (Force: $force, Source: $triggerSource) ==========',
      );

      await AppLogService.logBackgroundCheckStart(force: force);
      final db = AppDatabase();
      final enableActiveReply =
          await db.getSettingBool('enable_background_active_reply') ?? true;
      if (!enableActiveReply && !force) {
        await AppLogService.logBackgroundSkip('后台主动回复已关闭');
        _cancelNextDueTimer();
        _serviceInstance?.invoke('cancel_background_reply_wakeup');
        return;
      }

      final permissionSnapshot =
          await BackgroundPermissionService.getPersistedSnapshot();
      final syncedNextWakeup =
          await BackgroundReplySchedulerService.syncAllTasksFromStoredPermissions(
        triggerSource: '${triggerSource}_sync',
      );

      if (!permissionSnapshot.hasBaseRequirements && !force) {
        await AppLogService.logBackgroundSkip('后台权限链未满足，任务已暂停');
        await _scheduleNextDueTask(
          nextTriggerAt: syncedNextWakeup,
          triggerSource: triggerSource,
        );
        return;
      }

      final currentTime = StorageUtils.getUniqueTimestamp();
      final dueTasks = force
          ? (await db.getAllBackgroundReplyTasks())
              .where((task) => task.enabled)
              .take(3)
              .toList()
          : await db.getDueBackgroundReplyTasks(currentTime, limit: 3);

      if (dueTasks.isEmpty) {
        await AppLogService.logBackgroundSkip('当前没有到期的后台任务');
        await _scheduleNextDueTask(
          nextTriggerAt: syncedNextWakeup,
          triggerSource: triggerSource,
        );
        return;
      }

      for (final task in dueTasks) {
        final session = await db.getChatSessionEntity(task.sessionId);
        if (session == null) {
          await AppLogService.warning(
            '后台任务关联会话不存在，已删除任务',
            category: 'Scheduler',
            data: {'sessionId': task.sessionId},
          );
          await db.deleteBackgroundReplyTaskBySessionId(task.sessionId);
          continue;
        }

        await db.updateBackgroundReplyTaskState(
          task.sessionId,
          status: BackgroundReplyTaskStatus.running,
          enabled: true,
          lastAttemptAt: currentTime,
          triggerSource: triggerSource,
        );
        await db.updateSessionBackgroundReplySettings(
          task.sessionId,
          backgroundReplyStatus: 'running',
        );

        final result = await _triggerAiReply(
          db,
          session,
          triggerSource: triggerSource,
        );

        if (result.disableSessionDueToFailure) {
          await BackgroundReplySchedulerService.disableSessionDueToApiFailure(
            task.sessionId,
            reason: result.error ?? '后台主动回复失败',
          );
          continue;
        }

        if (!result.success) {
          await db.updateBackgroundReplyTaskState(
            task.sessionId,
            status: BackgroundReplyTaskStatus.pending,
            enabled: true,
            triggerSource: triggerSource,
          );
          await AppLogService.warning(
            '后台任务执行未成功，但未触发熔断',
            category: 'Background',
            data: {'sessionId': task.sessionId, 'triggerSource': triggerSource},
          );
        }
      }

      final nextWakeup =
          await BackgroundReplySchedulerService.syncAllTasksFromStoredPermissions(
        triggerSource: '${triggerSource}_post_run',
      );
      await _scheduleNextDueTask(
        nextTriggerAt: nextWakeup,
        triggerSource: triggerSource,
      );
      await AppLogService.logBackgroundCheckEnd();
    } catch (e, stackTrace) {
      debugPrint('[BG] ❌ 后台检查出错: $e');
      debugPrint('[BG] ❌ 堆栈跟踪: $stackTrace');
      await AppLogService.logBackgroundError('后台检查出错', e, stackTrace);
    }
  }

  /// 触发 AI 回复
  /// 注意：所有设置现在从数据库读取，SharedPreferences 已被弃用
  static Future<_BackgroundReplyTriggerResult> _triggerAiReply(
    AppDatabase db,
    ChatSessionEntity session, {
    required String triggerSource,
  }) async {
    try {
      debugPrint('[BG] >>> 开始为会话 ${session.id} 生成 AI 回复');

      // 获取角色和我的信息
      debugPrint('[BG] 获取角色信息: roleId=${session.roleId}');
      final role = await db.getContactById(session.roleId);
      debugPrint('[BG] 获取我的信息: meId=${session.meId}');
      final me = await db.getMeById(session.meId);

      if (role == null) {
        debugPrint('[BG] ❌ 未找到角色信息，roleId=${session.roleId}');
        return const _BackgroundReplyTriggerResult(success: false);
      }
      if (me == null) {
        debugPrint('[BG] ❌ 未找到用户信息，meId=${session.meId}');
        return const _BackgroundReplyTriggerResult(success: false);
      }
      debugPrint('[BG] ✓ 角色: ${role.name}, 用户: ${me.name}');

      // 加载 Prompt 设置（从数据库读取）
      debugPrint('[BG] 加载 Prompt 设置...');
      // roleplay_prompt 强制从 assets 读取
      String roleplayPrompt = '';
      try {
        roleplayPrompt = await rootBundle.loadString(
          'assets/prompts/roleplay_prompt.txt',
        );
      } catch (e) {
        debugPrint('[BG] Error loading roleplay_prompt: $e');
        roleplayPrompt = '你是一个AI助手，正在进行角色扮演任务。请完全沉浸在设定的角色中，不要暴露你是AI的身份。';
      }

      final realityPrompt = await db.getSetting('reality_prompt') ?? '';
      final enableRealityPrompt =
          await db.getSettingBool('enable_reality_prompt') ?? true;
      final contextLength = await db.getSettingInt('context_length') ?? 10;

      debugPrint(
        '[BG] Prompt 配置: contextLength=$contextLength, enableRealityPrompt=$enableRealityPrompt',
      );

      final promptConfig = PromptConfig(
        roleplayPrompt: roleplayPrompt,
        realityPrompt: realityPrompt,
        enableRealityPrompt: enableRealityPrompt,
        contextLength: contextLength,
      );
      debugPrint('[BG] ✓ Prompt 设置加载完成');

      // 加载 API Preset（从数据库读取）
      debugPrint('[BG] 加载 API Preset...');
      final currentApiId =
          session.apiPresetId ?? await db.getSetting('active_preset_id');
      debugPrint('[BG] 当前 API ID: $currentApiId');

      ApiPreset? apiPreset;
      if (currentApiId != null) {
        apiPreset = await db.getApiPreset(currentApiId);
        if (apiPreset != null) {
          debugPrint(
            '[BG] ✓ 找到 API Preset: ${apiPreset.name} (${apiPreset.provider.name})',
          );
        } else {
          debugPrint('[BG] ⚠️ 指定的 API Preset 不存在');
        }
      }

      // 如果没有找到，尝试获取第一个
      if (apiPreset == null) {
        debugPrint('[BG] 尝试获取第一个可用的 API Preset...');
        final presets = await db.getAllApiPresets();
        debugPrint('[BG] 可用 API Preset 数量: ${presets.length}');
        if (presets.isNotEmpty) {
          apiPreset = presets.first;
          debugPrint('[BG] ✓ 使用第一个 API Preset: ${apiPreset.name}');
        }
      }

      if (apiPreset == null) {
        debugPrint('[BG] ❌ 没有可用的 API Preset，无法生成回复');
        return const _BackgroundReplyTriggerResult(success: false);
      }

      // 获取历史消息
      debugPrint('[BG] 获取历史消息...');
      final messages = await db.getMessages(session.id);
      debugPrint('[BG] ✓ 历史消息数量: ${messages.length}');

      // 生成回复
      debugPrint('[BG] 🚀 开始调用 LLM API...');
      debugPrint(
        '[BG] API 配置: ${apiPreset.provider.name} - ${apiPreset.model}',
      );
      debugPrint('[BG] Base URL: ${apiPreset.baseUrl}');

      // 构造主动回复的 Prompt
      // 我们需要告诉 AI，这是它主动发起的对话，而不是回复用户的消息。
      // 可以在 history 中添加一个特殊的系统消息，或者修改 promptConfig。
      // 这里我们简单地在 history 末尾添加一个提示（不保存到数据库），引导 AI 主动发言。
      // 或者，LlmService 内部处理？
      // 目前 LlmService.generateResponse 主要是基于 history 生成回复。
      // 如果 history 最后一条是用户发的，那就是回复用户。
      // 如果 history 最后一条是 AI 发的（虽然我们前面过滤了这种情况），或者隔了很久，
      // 我们希望 AI 开启新话题或继续之前的话题。

      // 我们可以临时添加一条系统消息到 history 列表（不存库）
      // 注意：这里直接修改 messages 列表，不会影响数据库
      // messages.add(activeReplyContext);
      // 实际上 LlmService 可能会把 isMe=true 当作用户发言。
      // 更好的做法是在 promptConfig 中添加 activeReply 指令，或者 LlmService 支持 activeReply 模式。
      // 鉴于不修改 LlmService 接口，我们尝试在 promptConfig.roleplayPrompt 中追加指令。

      final activePromptConfig = PromptConfig(
        roleplayPrompt: '''${promptConfig.roleplayPrompt}

[System Instruction: The user has been silent for a long time. You should actively initiate a conversation now. Do not wait for the user to speak. Start a new topic or follow up on the previous one naturally.]''',
        realityPrompt: promptConfig.realityPrompt,
        enableRealityPrompt: promptConfig.enableRealityPrompt,
        contextLength: promptConfig.contextLength,
      );

      final timestamp = StorageUtils.getUniqueTimestamp();
      // 记录后台 API 调用开始
      await AppLogService.logApiCallStart(
        provider: apiPreset.provider.name,
        model: apiPreset.model,
        endpoint: apiPreset.baseUrl,
        sessionId: session.id,
        isBackground: true,
      );

      final apiStartTime = DateTime.now();

      final aiMessages = await LlmService.generateResponse(
        apiPreset: apiPreset,
        promptConfig: activePromptConfig, // 使用带有主动回复指令的配置
        history: messages,
        role: role,
        me: me,
        messageIdPrefix: 'ai-bg-$timestamp',
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[BG] ❌ API 调用超时（60秒）');
          // 记录超时日志
          AppLogService.logApiCallTimeout(
            provider: apiPreset!.provider.name,
            model: apiPreset.model,
            timeoutSeconds: 60,
            isBackground: true,
          );
          throw TimeoutException('LLM API 调用超时');
        },
      );

      final apiDuration =
          DateTime.now().difference(apiStartTime).inMilliseconds / 1000.0;

      debugPrint('[BG] ✓ API 调用完成，返回 ${aiMessages.length} 条消息');

      // 记录 API 调用成功
      await AppLogService.logApiCallSuccess(
        provider: apiPreset.provider.name,
        model: apiPreset.model,
        durationSeconds: apiDuration,
        messageCount: aiMessages.length,
        isBackground: true,
      );

      if (aiMessages.isNotEmpty) {
        debugPrint('[BG] 开始处理和保存消息...');
        int savedCount = 0;

        // 过滤并保存消息
        for (final msg in aiMessages) {
          debugPrint('[BG] 处理消息: type=${msg.type}, id=${msg.id}');

          if (msg.type == MessageType.state) {
            debugPrint('[BG] 跳过状态消息');
            continue; // 忽略状态消息
          }

          // 忽略 thought 和 action 除非开启了 extended chat (这里简化为忽略)
          if (msg.type != MessageType.words &&
              msg.type != MessageType.moment &&
              msg.type != MessageType.image) {
            debugPrint('[BG] 跳过非展示消息: ${msg.type}');
            continue;
          }

          final contentPreview = msg.content.isEmpty
              ? '[空内容]'
              : (msg.content.length > 50
                  ? '${msg.content.substring(0, 50)}...'
                  : msg.content);
          debugPrint('[BG] 保存消息到数据库: $contentPreview');

          // 插入消息到数据库
          await db.insertMessage(
            ChatMessagesCompanion(
              id: drift.Value(msg.id),
              sessionId: drift.Value(session.id),
              content: drift.Value(msg.content),
              isMe: drift.Value(false),
              type: drift.Value(msg.type),
              timestamp: drift.Value(StorageUtils.getUniqueTimestamp()),
              metadata: drift.Value(msg.metadata),
              isRead: drift.Value(false),
            ),
          );
          savedCount++;
          debugPrint('[BG] ✓ 消息已保存');

          // 直接在后台 Isolate 中发送通知（不依赖 IPC，更可靠）
          final notificationBody = _buildNotificationBody(msg);
          if (notificationBody != null) {
            debugPrint('[BG] 直接发送通知: ${role.name}');
            final notificationId = _nextNotificationId();
            await _showNotificationDirectly(
              title: role.name,
              message: notificationBody,
              id: notificationId,
            );
            _serviceInstance?.invoke('show_notification', {
              'title': role.name,
              'message': notificationBody,
              'id': notificationId,
            });
            await AppLogService.log(
              '后台消息已通过双通道通知派发',
              category: 'Notification',
              data: {
                'sessionId': session.id,
                'notificationId': notificationId,
                'messageType': msg.type.name,
              },
            );
          } else {
            await AppLogService.warning(
              '后台消息已生成，但当前类型不会触发通知',
              category: 'Notification',
              data: {
                'sessionId': session.id,
                'messageType': msg.type.name,
              },
            );
          }

          // 如果是朋友圈消息，添加到朋友圈
          if (msg.type == MessageType.moment) {
            debugPrint('[BG] 添加朋友圈动态');
            final now = StorageUtils.getUniqueTimestamp();
            await db.insertMoment(
              MomentsPost(
                id: now.toString(),
                user: MomentsUser(
                  id: role.id,
                  name: role.name,
                  avatarUrl: role.avatarPath ?? '',
                ),
                content: msg.content,
                createdAt: DateTime.fromMillisecondsSinceEpoch(now),
                mediaItems: [],
                likes: [],
                comments: [],
              ),
            );
          }
        }

        debugPrint('[BG] ✓ 已保存 $savedCount 条消息');

        // 记录 AI 回复保存日志
        await AppLogService.logAiReplySaved(
          sessionId: session.id,
          messageCount: savedCount,
          isBackground: true,
        );

        // 注意：不再手动调用 insertChatSession 更新会话时间戳
        // 因为 insertMessage 内部已经会自动更新 lastUpdated
        // 使用 insertChatSession(InsertMode.insertOrReplace) 会导致级联删除消息！
        debugPrint('[BG] <<< AI 回复处理完成');
        if (savedCount <= 0) {
          return const _BackgroundReplyTriggerResult(
            success: false,
            disableSessionDueToFailure: true,
            error: 'API 返回内容无法生成有效后台消息',
          );
        }
        await db.updateBackgroundReplyTaskState(
          session.id,
          status: BackgroundReplyTaskStatus.pending,
          enabled: true,
          lastSuccessAt: StorageUtils.getUniqueTimestamp(),
          triggerSource: triggerSource,
        );
        await db.updateSessionBackgroundReplySettings(
          session.id,
          backgroundReplyStatus: 'scheduled',
        );
        return const _BackgroundReplyTriggerResult(success: true);
      } else {
        debugPrint('[BG] ⚠️ API 返回了空消息列表');
        await AppLogService.warning(
          'API 返回空消息列表',
          category: 'Background',
          data: {'sessionId': session.id},
        );
        return const _BackgroundReplyTriggerResult(
          success: false,
          disableSessionDueToFailure: true,
          error: 'API 返回空消息列表',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[BG] ❌ 生成 AI 回复时出错: $e');
      debugPrint('[BG] ❌ 堆栈跟踪: $stackTrace');
      await AppLogService.logBackgroundError('生成 AI 回复时出错', e, stackTrace);
      return _BackgroundReplyTriggerResult(
        success: false,
        disableSessionDueToFailure: true,
        error: e.toString(),
      );
    }
  }

  /// 更新最后活跃时间（存储到数据库）
  /// 注意：所有设置现在存储在数据库中，SharedPreferences 已被弃用
  static Future<void> updateLastActiveTime() async {
    final db = AppDatabase();
    await db.setSettingInt(
      _lastActiveTimeKey,
      StorageUtils.getUniqueTimestamp(),
    );
  }

  static void _cancelNextDueTimer() {
    _nextDueTimer?.cancel();
    _nextDueTimer = null;
  }

  static Future<void> _scheduleNextDueTask({
    required int? nextTriggerAt,
    required String triggerSource,
  }) async {
    _cancelNextDueTimer();

    if (nextTriggerAt == null) {
      _serviceInstance?.invoke('cancel_background_reply_wakeup');
      return;
    }

    final now = StorageUtils.getUniqueTimestamp();
    final delayMs = nextTriggerAt - now;
    final safeDelayMs = delayMs <= 0 ? 1 : delayMs;

    _nextDueTimer = Timer(Duration(milliseconds: safeDelayMs), () async {
      await _checkAndTriggerActiveReply(
        force: false,
        triggerSource: 'in_memory_timer',
      );
    });

    _serviceInstance?.invoke(
      'schedule_next_background_reply_wakeup',
      {
        'timestampMs': nextTriggerAt,
        'triggerSource': triggerSource,
      },
    );

    await AppLogService.log(
      '已调度下一次后台任务',
      category: 'Scheduler',
      data: {
        'nextTriggerAt': nextTriggerAt,
        'delayMs': safeDelayMs,
        'triggerSource': triggerSource,
      },
    );
  }

  /// 在后台 Isolate 中初始化通知插件
  static Future<void> _initBackgroundNotifications() async {
    try {
      debugPrint('[BG] 初始化后台通知插件...');

      _bgNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _bgNotificationsPlugin!.initialize(initSettings);

      // 创建通知频道（Android 8.0+ 必需）
      final androidImpl = _bgNotificationsPlugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Android 16+ 需要使用更高的 importance 和额外配置
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          NotificationService.aiReplyChannelId,
          NotificationService.aiReplyChannelName,
          description: NotificationService.aiReplyChannelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );

        await androidImpl.createNotificationChannel(channel);
        debugPrint('[BG] ✓ 后台通知频道已创建');

        // Android 13+ 请求通知权限
        final notificationGranted =
            await androidImpl.requestNotificationsPermission();
        debugPrint('[BG] 通知权限状态: $notificationGranted');
      }

      debugPrint('[BG] ✓ 后台通知插件初始化完成');
    } catch (e) {
      debugPrint('[BG] ❌ 后台通知插件初始化失败: $e');
    }
  }

  /// 直接在后台 Isolate 中发送通知（不依赖 IPC）
  static Future<void> _showNotificationDirectly({
    required String title,
    required String message,
    required int id,
  }) async {
    try {
      if (_bgNotificationsPlugin == null) {
        debugPrint('[BG] 通知插件未初始化，尝试初始化...');
        await _initBackgroundNotifications();
      }

      if (_bgNotificationsPlugin == null) {
        debugPrint('[BG] ❌ 通知插件初始化失败，无法发送通知');
        return;
      }

      // Android 16+ 需要额外的配置才能弹出通知
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        NotificationService.aiReplyChannelId,
        NotificationService.aiReplyChannelName,
        channelDescription: NotificationService.aiReplyChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: title,
          htmlFormatContent: false,
          htmlFormatContentTitle: false,
        ),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        ticker: '$title: $message',
        ongoing: false,
        showProgress: false,
        channelShowBadge: true,
        enableLights: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _bgNotificationsPlugin!.show(id, title, message, details);
      debugPrint('[BG] ✓ 通知已直接发送: id=$id, title=$title');

      // 记录通知发送成功
      await AppLogService.logNotificationSent(
        title: title,
        notificationId: id,
        success: true,
      );
    } catch (e, stackTrace) {
      debugPrint('[BG] ❌ 直接发送通知失败: $e');
      debugPrint('[BG] 堆栈: $stackTrace');

      // 记录通知发送失败
      await AppLogService.logNotificationSent(
        title: title,
        notificationId: id,
        success: false,
      );
    }
  }

  static String? _buildNotificationBody(ChatMessage msg) {
    switch (msg.type) {
      case MessageType.words:
        return msg.content;
      case MessageType.image:
        return '[图片]';
      case MessageType.moment:
        return msg.content.isEmpty ? '[朋友圈动态]' : '[朋友圈] ${msg.content}';
      default:
        return null;
    }
  }

  static int _nextNotificationId() {
    return StorageUtils.getUniqueTimestamp().remainder(0x7fffffff).toInt();
  }
}
