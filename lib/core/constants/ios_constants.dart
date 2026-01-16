import 'package:flutter/material.dart';

/// iOS系统设计常量
class IOSConstants {
  // 状态栏高度
  static const double statusBarHeight = 44.0;

  // Dock栏高度
  static const double dockHeight = 100.0;
  static const double dockPadding = 16.0;
  static const double dockMarginBottom = 30.0;

  // 应用图标尺寸
  static const double appIconSize = 60.0;
  static const double appIconRadius = 13.5;
  static const double appIconSpacing = 20.0;
  static const double appLabelSize = 11.0;

  // 网格布局
  static const int gridColumns = 4;
  static const int gridRowsPerPage = 6;
  static const double gridPaddingHorizontal = 20.0;
  static const double gridPaddingTop = 20.0;

  // 时间组件
  static const double timeWidgetHeight = 120.0;

  // 动画时长
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration iconPressDuration = Duration(milliseconds: 100);

  // 模糊效果
  static const double blurSigma = 30.0;
  static const double dockBlurSigma = 25.0;

  // 页面指示器
  static const double pageIndicatorSize = 8.0;
  static const double pageIndicatorSpacing = 8.0;

  // 文件夹
  static const double folderPreviewSize = 45.0;
  static const double folderIconSize = 18.0;
  static const int folderPreviewIcons = 9;
}

/// iOS系统颜色常量
class IOSColors {
  // 状态栏颜色
  static const Color statusBarText = Colors.white;
  static const Color statusBarIcon = Colors.white;

  // 时间颜色
  static const Color timeText = Colors.white;
  static const Color dateText = Colors.white70;

  // Dock背景
  static Color dockBackground = Colors.white.withOpacity(0.25);
  static Color dockBorder = Colors.white.withOpacity(0.3);

  // 应用标签
  static const Color appLabelText = Colors.white;
  static Color appLabelShadow = Colors.black.withOpacity(0.5);

  // 页面指示器
  static const Color pageIndicatorActive = Colors.white;
  static Color pageIndicatorInactive = Colors.white.withOpacity(0.4);

  // 搜索栏
  static Color searchBackground = Colors.white.withOpacity(0.2);
  static const Color searchText = Colors.white70;
  static const Color searchIcon = Colors.white70;

  // 通知徽章
  static const Color badgeBackground = Color(0xFFFF3B30);
  static const Color badgeText = Colors.white;

  // 系统应用图标渐变色
  static const List<List<Color>> systemAppGradients = [
    // 电话 - 绿色
    [Color(0xFF5AC45A), Color(0xFF4CD964)],
    // Safari - 蓝色
    [Color(0xFF1DA1F2), Color(0xFF00D4FF)],
    // 邮件 - 蓝色
    [Color(0xFF007AFF), Color(0xFF5AC8FA)],
    // 音乐 - 红橙渐变
    [Color(0xFFFA233B), Color(0xFFFC5C65)],
    // 照片 - 彩虹渐变
    [
      Color(0xFFFF9500),
      Color(0xFFFF3B30),
      Color(0xFFAF52DE),
      Color(0xFF007AFF),
    ],
    // 相机 - 灰色
    [Color(0xFF8E8E93), Color(0xFF636366)],
    // 时钟 - 黑色
    [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
    // 地图 - 绿色地图
    [Color(0xFF30D158), Color(0xFF34C759)],
    // 天气 - 蓝色天空
    [Color(0xFF5AC8FA), Color(0xFF007AFF)],
    // 备忘录 - 黄色
    [Color(0xFFFFCC00), Color(0xFFFFD60A)],
    // 提醒事项 - 蓝色
    [Color(0xFF007AFF), Color(0xFF5856D6)],
    // 设置 - 灰色齿轮
    [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
    // 消息 - 绿色
    [Color(0xFF34C759), Color(0xFF30D158)],
    // FaceTime - 绿色
    [Color(0xFF30D158), Color(0xFF34C759)],
    // App Store - 蓝色
    [Color(0xFF007AFF), Color(0xFF5AC8FA)],
    // 钱包 - 黑色
    [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
    // 健康 - 红心
    [Color(0xFFFF2D55), Color(0xFFFF375F)],
    // 日历 - 白色红顶
    [Color(0xFFFFFFFF), Color(0xFFF2F2F7)],
    // 计算器 - 橙黑
    [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
    // 股市 - 黑色
    [Color(0xFF1C1C1E), Color(0xFF000000)],
    // 文件 - 蓝色
    [Color(0xFF007AFF), Color(0xFF5AC8FA)],
  ];
}

/// iOS系统字体样式
class IOSTextStyles {
  static const TextStyle statusBarTime = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: IOSColors.statusBarText,
    letterSpacing: 0.5,
  );

  static const TextStyle largeTime = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.w200,
    color: IOSColors.timeText,
    letterSpacing: -2,
    height: 1.0,
  );

  static const TextStyle dateText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: IOSColors.dateText,
  );

  static TextStyle appLabel = TextStyle(
    fontSize: IOSConstants.appLabelSize,
    fontWeight: FontWeight.w500,
    color: IOSColors.appLabelText,
    shadows: [
      Shadow(
        color: IOSColors.appLabelShadow,
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static const TextStyle searchPlaceholder = TextStyle(
    fontSize: 16,
    color: IOSColors.searchText,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: IOSColors.badgeText,
  );
}
