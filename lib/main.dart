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
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_log_service.dart';
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
  _initializeServicesAsync();
}

/// 异步初始化服务，不阻塞应用启动
Future<void> _initializeServicesAsync() async {
  try {
    // 1. 初始化通知服务
    debugPrint('Initializing Notification Service...');
    await NotificationService().initialize();
    debugPrint('Notification Service Initialized');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Notification Service: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  try {
    // 2. 初始化后台服务
    debugPrint('Initializing Background Service...');
    await BackgroundService.initializeService();
    debugPrint('Background Service Initialized');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Background Service: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // 3. 监听后台服务发来的通知请求（IPC 机制）
  _setupBackgroundServiceListener();
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
        break;
      default:
        break;
    }
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
