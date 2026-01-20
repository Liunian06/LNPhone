import 'package:flutter/material.dart';

/// 微信风格的应用主题
/// 支持亮色和暗色模式，根据用户提供的黑夜模式配色示例设计
class AppTheme {
  AppTheme._();

  // ============= 亮色模式颜色 =============
  static const Color lightBackground = Color(0xFFEDEDED);
  static const Color lightSurface = Colors.white;
  static const Color lightInputBackground = Color(0xFFF7F7F7);
  static const Color lightPrimaryText = Colors.black;
  static const Color lightSecondaryText = Colors.grey;
  static const Color lightDivider = Color(0xFFDCDCDC);
  static const Color lightAppBarBackground = Color(0xFFEDEDED);

  // ============= 暗色模式颜色 (根据用户示例图) =============
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF2C2C2E); // 输入框背景，比输入区域亮一点
  static const Color darkInputBackground = Color(0xFF1C1C1E); // 输入区域背景
  static const Color darkPrimaryText = Color(0xFFE8E8E8);
  static const Color darkSecondaryText = Color(0xFF8E8E8E);
  static const Color darkDivider = Color(0xFF2A2A2A);
  static const Color darkAppBarBackground = Color(0xFF111111);

  // ============= 共用颜色 =============
  static const Color wechatGreen = Color(0xFF07C160);
  static const Color myMessageBubble = Color(0xFF95EC69); // 我的消息气泡 (亮色模式)
  static const Color myMessageBubbleDark = Color(0xFF3EB573); // 我的消息气泡 (暗色模式)
  static const Color otherMessageBubble = Colors.white; // 他人消息气泡 (亮色模式)
  static const Color otherMessageBubbleDark =
      Color(0xFF2A2A2A); // 他人消息气泡 (暗色模式)

  // ============= 亮色主题 =============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: wechatGreen,
        brightness: Brightness.light,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightAppBarBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: lightPrimaryText),
        titleTextStyle: TextStyle(
          color: lightPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightInputBackground,
        selectedItemColor: wechatGreen,
        unselectedItemColor: lightSecondaryText,
      ),
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 0.5,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightPrimaryText),
        bodyMedium: TextStyle(color: lightPrimaryText),
        bodySmall: TextStyle(color: lightSecondaryText),
        titleLarge: TextStyle(color: lightPrimaryText),
        titleMedium: TextStyle(color: lightPrimaryText),
        titleSmall: TextStyle(color: lightSecondaryText),
      ),
      iconTheme: const IconThemeData(color: lightPrimaryText),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurface,
        titleTextStyle: TextStyle(
          color: lightPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: lightPrimaryText,
          fontSize: 16,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: lightPrimaryText,
        iconColor: lightPrimaryText,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return wechatGreen;
          }
          return null;
        }),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: lightSurface,
        textStyle: TextStyle(color: lightPrimaryText),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  // ============= 暗色主题 =============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: wechatGreen,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkAppBarBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: darkPrimaryText),
        titleTextStyle: TextStyle(
          color: darkPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: wechatGreen,
        unselectedItemColor: darkSecondaryText,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 0.5,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkInputBackground,
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkPrimaryText),
        bodyMedium: TextStyle(color: darkPrimaryText),
        bodySmall: TextStyle(color: darkSecondaryText),
        titleLarge: TextStyle(color: darkPrimaryText),
        titleMedium: TextStyle(color: darkPrimaryText),
        titleSmall: TextStyle(color: darkSecondaryText),
      ),
      iconTheme: const IconThemeData(color: darkPrimaryText),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 16,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: darkPrimaryText,
        iconColor: darkPrimaryText,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return wechatGreen;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: darkSurface,
        textStyle: TextStyle(color: darkPrimaryText),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}

/// 主题相关的扩展方法
extension ThemeExtension on BuildContext {
  /// 判断当前是否为暗色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 获取聊天界面背景色
  Color get chatBackground =>
      isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground;

  /// 获取卡片/表面背景色
  Color get surfaceColor =>
      isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;

  /// 获取输入框背景色
  Color get inputBackground =>
      isDarkMode ? AppTheme.darkInputBackground : AppTheme.lightInputBackground;

  /// 获取主要文字颜色
  Color get primaryTextColor =>
      isDarkMode ? AppTheme.darkPrimaryText : AppTheme.lightPrimaryText;

  /// 获取次要文字颜色
  Color get secondaryTextColor =>
      isDarkMode ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

  /// 获取分割线颜色
  Color get dividerColor =>
      isDarkMode ? AppTheme.darkDivider : AppTheme.lightDivider;

  /// 获取 AppBar 背景色
  Color get appBarBackground => isDarkMode
      ? AppTheme.darkAppBarBackground
      : AppTheme.lightAppBarBackground;

  /// 获取"我的消息"气泡颜色
  Color get myMessageBubbleColor =>
      isDarkMode ? AppTheme.myMessageBubbleDark : AppTheme.myMessageBubble;

  /// 获取"他人消息"气泡颜色
  Color get otherMessageBubbleColor => isDarkMode
      ? AppTheme.otherMessageBubbleDark
      : AppTheme.otherMessageBubble;

  /// 获取气泡内文字颜色 (我的消息)
  Color get myMessageTextColor => Colors.black;

  /// 获取气泡内文字颜色 (他人消息)
  Color get otherMessageTextColor =>
      isDarkMode ? AppTheme.darkPrimaryText : Colors.black;
}
