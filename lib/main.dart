import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/system_shell.dart';
import 'core/providers/system_state_provider.dart';
import 'core/providers/contact_provider.dart';
import 'core/providers/api_settings_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/prompt_settings_provider.dart';
import 'core/providers/moments_provider.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化后台服务
  await BackgroundService.initializeService();

  // 设置全屏模式
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

  runApp(const LnPhoneApp());
}

/// LnPhone - AI Native 手机系统应用
class LnPhoneApp extends StatelessWidget {
  const LnPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SystemStateProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => ApiSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PromptSettingsProvider()),
        ChangeNotifierProvider(create: (_) => MomentsProvider()),
      ],
      child: MaterialApp(
        title: 'LnPhone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.dark,
          ),
          fontFamily: '.SF Pro Display',
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.dark,
          ),
          fontFamily: '.SF Pro Display',
          scaffoldBackgroundColor: Colors.black,
        ),
        themeMode: ThemeMode.dark,
        home: const SystemShell(),
      ),
    );
  }
}
