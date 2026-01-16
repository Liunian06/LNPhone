import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../models/api_preset.dart';
import '../models/contact_model.dart';
import '../models/moments_model.dart';
import '../models/chat_model.dart';
import '../providers/prompt_settings_provider.dart';
import '../services/llm_service.dart';
import '../services/notification_service.dart';
import 'package:drift/drift.dart' as drift;

// 超时异常类
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class BackgroundService {
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _lastBackgroundCheckKey = 'last_background_check_time';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'background_service', // id
      '汪汪机后台保活服务', // title
      description: 'This channel is used for background service notifications.',
      importance: Importance.min, // 优先级改为最低
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

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

    // 定时检查任务
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            // 更新通知内容，显示服务正在运行
            // service.setForegroundNotificationInfo(
            //   title: "AI Phone Service",
            //   content: "Checking for active replies...",
            // );
          }
        }

        await _checkAndTriggerActiveReply();
      } catch (e) {
        debugPrint('Error in background service timer: $e');
      }
    });
  }

  static Future<void> _checkAndTriggerActiveReply() async {
    try {
      debugPrint('[BG] ========== 后台检查开始 ==========');
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // 强制刷新数据，确保获取到最新的配置和活跃时间
      debugPrint('[BG] SharedPreferences 已重新加载');

      final db = AppDatabase();

      // 1. 检查是否开启了后台主动回复
      final enableActiveReply =
          prefs.getBool('enable_background_active_reply') ?? true;
      debugPrint('[BG] 后台主动回复开关: $enableActiveReply');
      if (!enableActiveReply) {
        debugPrint('[BG] 后台主动回复已关闭，跳过检查');
        return;
      }

      // 2. 获取配置的间隔时间 (分钟)
      final intervalMinutes =
          prefs.getInt('background_active_reply_interval') ?? 60;
      final intervalMillis = intervalMinutes * 60 * 1000;
      debugPrint('[BG] 配置的间隔时间: $intervalMinutes 分钟 ($intervalMillis 毫秒)');

      // 3. 获取上次活跃时间
      final lastActiveTime = prefs.getInt(_lastActiveTimeKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final inactiveTime = currentTime - lastActiveTime;
      debugPrint('[BG] 上次活跃时间: $lastActiveTime');
      debugPrint('[BG] 当前时间: $currentTime');
      debugPrint('[BG] 不活跃时长: ${inactiveTime ~/ 1000} 秒');

      // 4. 检查是否满足触发条件：当前时间 - 上次活跃时间 > 间隔时间
      if (currentTime - lastActiveTime > intervalMillis) {
        debugPrint('[BG] 满足触发条件，开始检查会话');
        // 获取所有会话
        final sessions = await db.getAllSessions();
        debugPrint('[BG] 总会话数: ${sessions.length}');

        for (final session in sessions) {
          debugPrint('[BG] 检查会话: ${session.id}');
          // 获取该会话最后一条消息的时间
          final lastMessage = await db.getLastMessage(session.id);
          if (lastMessage != null) {
            final lastMessageTime = lastMessage.timestamp;
            final sessionInactiveTime = currentTime - lastMessageTime;
            debugPrint('[BG] 会话 ${session.id} 最后消息时间: $lastMessageTime');
            debugPrint(
              '[BG] 会话 ${session.id} 不活跃时长: ${sessionInactiveTime ~/ 1000} 秒',
            );

            if (currentTime - lastMessageTime > intervalMillis) {
              debugPrint('[BG] 会话 ${session.id} 满足条件，触发 AI 回复');
              // 触发 AI 回复
              await _triggerAiReply(db, session, prefs);
            } else {
              debugPrint('[BG] 会话 ${session.id} 不满足条件，跳过');
            }
          } else {
            debugPrint('[BG] 会话 ${session.id} 没有消息记录');
          }
        }
        debugPrint('[BG] 所有会话检查完成');
      } else {
        debugPrint('[BG] 不满足触发条件（需要不活跃 ${intervalMinutes} 分钟），跳过检查');
      }
      debugPrint('[BG] ========== 后台检查结束 ==========');
    } catch (e, stackTrace) {
      debugPrint('[BG] ❌ 后台检查出错: $e');
      debugPrint('[BG] ❌ 堆栈跟踪: $stackTrace');
    }
  }

  static Future<void> _triggerAiReply(
    AppDatabase db,
    ChatSession session,
    SharedPreferences prefs,
  ) async {
    try {
      debugPrint('[BG] >>> 开始为会话 ${session.id} 生成 AI 回复');

      // 获取角色和我的信息
      debugPrint('[BG] 获取角色信息: roleId=${session.roleId}');
      final role = await db.getContactById(session.roleId);
      debugPrint('[BG] 获取我的信息: meId=${session.meId}');
      final me = await db.getMeById(session.meId);

      if (role == null) {
        debugPrint('[BG] ❌ 未找到角色信息，roleId=${session.roleId}');
        return;
      }
      if (me == null) {
        debugPrint('[BG] ❌ 未找到用户信息，meId=${session.meId}');
        return;
      }
      debugPrint('[BG] ✓ 角色: ${role.name}, 用户: ${me.name}');

      // 加载 Prompt 设置
      debugPrint('[BG] 加载 Prompt 设置...');
      final promptSettings = PromptSettingsProvider();
      final roleplayPrompt = prefs.getString('roleplay_prompt') ?? '';
      final presettingPrompt = prefs.getString('presetting_prompt') ?? '';
      final realityPrompt = prefs.getString('reality_prompt') ?? '';
      final enableRealityPrompt =
          prefs.getBool('enable_reality_prompt') ?? true;
      final contextLength = prefs.getInt('context_length') ?? 10;

      debugPrint(
        '[BG] Prompt 配置: contextLength=$contextLength, enableRealityPrompt=$enableRealityPrompt',
      );

      await promptSettings.updateRoleplayPrompt(roleplayPrompt);
      await promptSettings.updatePresettingPrompt(presettingPrompt);
      await promptSettings.updateRealityPrompt(realityPrompt);
      await promptSettings.toggleRealityPrompt(enableRealityPrompt);
      await promptSettings.updateContextLength(contextLength);
      debugPrint('[BG] ✓ Prompt 设置加载完成');

      // 加载 API Preset
      debugPrint('[BG] 加载 API Preset...');
      final currentApiId = prefs.getString('active_preset_id');
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
        return;
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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final aiMessages =
          await LlmService.generateResponse(
            apiPreset: apiPreset,
            promptSettings: promptSettings,
            history: messages,
            role: role,
            me: me,
            messageIdPrefix: 'ai-bg-$timestamp',
          ).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              debugPrint('[BG] ❌ API 调用超时（60秒）');
              throw TimeoutException('LLM API 调用超时');
            },
          );

      debugPrint('[BG] ✓ API 调用完成，返回 ${aiMessages.length} 条消息');

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

          debugPrint(
            '[BG] 保存消息到数据库: ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}...',
          );

          // 插入消息到数据库
          await db.insertMessage(
            ChatMessagesCompanion(
              id: drift.Value(msg.id),
              sessionId: drift.Value(session.id),
              content: drift.Value(msg.content),
              isMe: drift.Value(false),
              type: drift.Value(msg.type),
              timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
              metadata: drift.Value(msg.metadata),
              isRead: drift.Value(false),
            ),
          );
          savedCount++;
          debugPrint('[BG] ✓ 消息已保存');

          // 发送通知
          if (msg.type == MessageType.words) {
            debugPrint('[BG] 发送通知: ${role.name}');
            await NotificationService().showAiReplyNotification(
              title: role.name,
              message: msg.content,
              id: DateTime.now().millisecondsSinceEpoch % 100000,
            );
          }

          // 如果是朋友圈消息，添加到朋友圈
          if (msg.type == MessageType.moment) {
            debugPrint('[BG] 添加朋友圈动态');
            await db.insertMoment(
              MomentsPost(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                user: MomentsUser(
                  id: role.id,
                  name: role.name,
                  avatarUrl: role.avatarPath ?? '',
                ),
                content: msg.content,
                createdAt: DateTime.now(),
                mediaItems: [],
                likes: [],
                comments: [],
              ),
            );
          }
        }

        debugPrint('[BG] ✓ 已保存 $savedCount 条消息');

        // 更新会话最后更新时间
        debugPrint('[BG] 更新会话时间戳');
        await db.insertChatSession(
          ChatSessionsCompanion(
            id: drift.Value(session.id),
            roleId: drift.Value(session.roleId),
            meId: drift.Value(session.meId),
            lastUpdated: drift.Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
        debugPrint('[BG] <<< AI 回复处理完成');
      } else {
        debugPrint('[BG] ⚠️ API 返回了空消息列表');
      }
    } catch (e, stackTrace) {
      debugPrint('[BG] ❌ 生成 AI 回复时出错: $e');
      debugPrint('[BG] ❌ 堆栈跟踪: $stackTrace');
    }
  }

  static Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastActiveTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
