import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'screens/system_shell.dart';
import 'core/database/database.dart';
import 'core/providers/system_state_provider.dart';
import 'core/providers/contact_provider.dart';
import 'core/providers/api_settings_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/prompt_settings_provider.dart';
import 'core/providers/moments_provider.dart';
import 'core/providers/memory_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/regex_settings_provider.dart';
import 'core/providers/emoji_provider.dart';
import 'core/services/background_service.dart';
import 'core/services/background_permission_service.dart';
import 'core/services/background_reply_scheduler_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_log_service.dart';
import 'core/services/storage_permission_service.dart';
import 'core/services/file_integrity_service.dart';
import 'core/services/emoji_backup_migration.dart';
import 'core/theme/app_theme.dart';

/// 全局数据库实例
/// 注意：所有应用设置现在存储在数据库中，SharedPreferences 已被弃用
final AppDatabase database = AppDatabase();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置全屏模式（这是同步操作，优先执行）
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // 锁定竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 记录应用启动日志
  await AppLogService.logAppStart();

  // 先启动应用，然后在后台初始化服务
  runApp(const LnPhoneApp());

  // 延迟初始化服务，避免阻塞应用启动
  // 给予主 Isolate 足够的时间完成数据库迁移和初始化
  Future.delayed(const Duration(seconds: 2), () {
    _initializeServicesAsync();
  });
}

/// 异步初始化服务，不阻塞应用启动
Future<void> _initializeServicesAsync() async {
  // 1. 请求存储权限（优先级最高，影响文件保活）
  try {
    debugPrint('[Init] 请求存储权限...');
    final permissionService = StoragePermissionService();
    final hasPermission = await permissionService.requestStoragePermission();

    if (hasPermission) {
      debugPrint('[Init] ✓ 存储权限已授予');

      // 权限授予后，立即运行文件完整性检查
      try {
        debugPrint('[Init] 开始文件完整性检查...');
        final integrityService = FileIntegrityService(database);
        final report = await integrityService.checkAndRestoreAll();

        if (report.hasIssues) {
          debugPrint('[Init] ⚠ 文件完整性检查发现问题:');
          debugPrint('[Init] ${report.summary}');
          if (report.errors.isNotEmpty) {
            debugPrint('[Init] 错误详情:');
            for (final error in report.errors) {
              debugPrint('[Init]   - $error');
            }
          }
        } else {
          debugPrint('[Init] ✓ 文件完整性检查通过');
        }
      } catch (e, stackTrace) {
        debugPrint('[Init] ❌ 文件完整性检查失败: $e');
        debugPrint('[Init] Stack trace: $stackTrace');
      }

      // 表情包备份数据迁移已禁用
      // 原因：自动迁移会在启动时为所有表情包创建备份，影响启动速度
      // 如需迁移，请在表情管理界面手动触发
      debugPrint('[Init] 表情包自动迁移已禁用（可在表情管理界面手动触发）');
    } else {
      debugPrint('[Init] ⚠ 存储权限未授予，文件保活能力受限');
    }
  } catch (e, stackTrace) {
    debugPrint('[Init] ❌ 请求存储权限失败: $e');
    debugPrint('[Init] Stack trace: $stackTrace');
  }

  // 2. 初始化通知服务
  try {
    debugPrint('[Init] 初始化通知服务...');
    await NotificationService().initialize();
    debugPrint('[Init] ✓ 通知服务已初始化');
  } catch (e, stackTrace) {
    debugPrint('[Init] ❌ 通知服务初始化失败: $e');
    debugPrint('[Init] Stack trace: $stackTrace');
  }

  // 3. 初始化后台服务
  try {
    debugPrint('[Init] 初始化后台服务...');
    await BackgroundService.initializeService();
    debugPrint('[Init] ✓ 后台服务已初始化');
  } catch (e, stackTrace) {
    debugPrint('[Init] ❌ 后台服务初始化失败: $e');
    debugPrint('[Init] Stack trace: $stackTrace');
  }

  // 4. 监听后台服务发来的通知请求（IPC 机制）
  _setupBackgroundServiceListener();

  // 5. 刷新权限快照并同步后台任务
  try {
    final snapshot = await BackgroundPermissionService.refreshAndPersistSnapshot();
    final nextWakeup = await BackgroundReplySchedulerService.syncAllTasks(
      permissionSnapshot: snapshot,
      triggerSource: 'app_init',
    );
    if (nextWakeup != null) {
      await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
    } else {
      await BackgroundPermissionService.cancelNextWakeup();
    }
    FlutterBackgroundService().invoke(
      'run_due_tasks',
      {'triggerSource': 'app_init'},
    );
    debugPrint('[Init] ✓ 后台权限与任务同步完成');
    await AppLogService.log(
      '启动后后台权限与任务同步完成',
      category: 'Scheduler',
      data: {'nextWakeup': nextWakeup},
    );
  } catch (e, stackTrace) {
    debugPrint('[Init] ❌ 后台权限与任务同步失败: $e');
    debugPrint('[Init] Stack trace: $stackTrace');
    await AppLogService.error(
      '启动后后台权限与任务同步失败',
      category: 'Scheduler',
      data: {'error': e.toString()},
    );
  }
}

/// 设置后台服务监听器，接收后台 Isolate 发来的通知请求
void _setupBackgroundServiceListener() {
  final service = FlutterBackgroundService();

  // 监听后台服务发来的通知请求
  service.on('show_notification').listen((event) async {
    if (event == null) return;

    final title = event['title'] as String?;
    final message = event['message'] as String?;
    final id = event['id'] as int? ?? 0;

    if (title != null && message != null) {
      debugPrint(
          '[Main] 收到后台通知请求: $title - ${message.length > 30 ? '${message.substring(0, 30)}...' : message}');
      await AppLogService.log(
        '主进程收到后台通知请求',
        category: 'Notification',
        data: {'title': title, 'id': id},
      );
      try {
        await NotificationService().showAiReplyNotification(
          title: title,
          message: message,
          id: id,
        );
        debugPrint('[Main] ✓ 通知发送成功');
      } catch (e) {
        debugPrint('[Main] ❌ 通知发送失败: $e');
      }
    }
  });

  service.on('schedule_next_background_reply_wakeup').listen((event) async {
    if (event == null) return;
    final timestampMs = event['timestampMs'] as int?;
    if (timestampMs == null) return;

    try {
      await BackgroundPermissionService.scheduleNextWakeup(timestampMs);
      debugPrint('[Main] 已同步原生后台唤醒时间: $timestampMs');
      await AppLogService.log(
        '主进程已同步原生后台唤醒时间',
        category: 'Scheduler',
        data: {'timestampMs': timestampMs},
      );
    } catch (e) {
      debugPrint('[Main] 同步原生后台唤醒时间失败: $e');
      await AppLogService.error(
        '主进程同步原生后台唤醒时间失败',
        category: 'Scheduler',
        data: {'error': e.toString()},
      );
    }
  });

  service.on('cancel_background_reply_wakeup').listen((event) async {
    try {
      await BackgroundPermissionService.cancelNextWakeup();
      debugPrint('[Main] 已取消原生后台唤醒');
      await AppLogService.info('主进程已取消原生后台唤醒', category: 'Scheduler');
    } catch (e) {
      debugPrint('[Main] 取消原生后台唤醒失败: $e');
      await AppLogService.error(
        '主进程取消原生后台唤醒失败',
        category: 'Scheduler',
        data: {'error': e.toString()},
      );
    }
  });

  debugPrint('[Main] 后台服务通知监听器已设置');
}

/// LnPhone - AI Native 手机系统应用
class LnPhoneApp extends StatefulWidget {
  const LnPhoneApp({super.key});

  @override
  State<LnPhoneApp> createState() => _LnPhoneAppState();
}

class _LnPhoneAppState extends State<LnPhoneApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 应用退出时刷新日志缓冲区
    AppLogService.flush();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台
        AppLogService.logAppBackground();
        // 刷新日志缓冲区
        AppLogService.flush();
        break;
      case AppLifecycleState.resumed:
        // 应用返回前台
        AppLogService.logAppForeground();
        _refreshBackgroundRuntimeState();
        break;
      default:
        break;
    }
  }

  void _refreshBackgroundRuntimeState() {
    Future(() async {
      try {
        final snapshot =
            await BackgroundPermissionService.refreshAndPersistSnapshot();
        final nextWakeup = await BackgroundReplySchedulerService.syncAllTasks(
          permissionSnapshot: snapshot,
          triggerSource: 'app_resumed',
        );
        if (nextWakeup != null) {
          await BackgroundPermissionService.scheduleNextWakeup(nextWakeup);
        } else {
          await BackgroundPermissionService.cancelNextWakeup();
        }
        FlutterBackgroundService().invoke(
          'run_due_tasks',
          {'triggerSource': 'app_resumed'},
        );
        await AppLogService.log(
          '应用恢复前台后已刷新后台权限与任务',
          category: 'Scheduler',
          data: {'nextWakeup': nextWakeup},
        );
      } catch (e, stackTrace) {
        debugPrint('[Main] 恢复后台状态失败: $e');
        debugPrint('[Main] Stack trace: $stackTrace');
        await AppLogService.error(
          '应用恢复前台后刷新后台权限与任务失败',
          category: 'Scheduler',
          data: {'error': e.toString()},
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SystemStateProvider(database)),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => ApiSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PromptSettingsProvider(database)),
        ChangeNotifierProvider(create: (_) => MomentsProvider()),
        ChangeNotifierProvider(create: (_) => MemoryProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider(database)),
        ChangeNotifierProvider(create: (_) => RegexSettingsProvider(database)),
        ChangeNotifierProvider(create: (_) => EmojiProvider(database)),
      ],
      child: MaterialApp(
        title: 'LnPhone',
        debugShowCheckedModeBanner: false,
        // 使用 AppTheme 定义的亮色和暗色主题
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // 设置为 system 模式，自动跟随系统设置切换
        themeMode: ThemeMode.system,
        home: const SystemShell(),
      ),
    );
  }
}
