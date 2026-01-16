import 'package:flutter/material.dart';

/// 应用类型
enum AppType {
  system, // 系统应用
  thirdParty, // 第三方应用
  folder, // 文件夹
  widget, // 小组件
}

/// 应用图标类型
enum IconType {
  icon, // 图标字体
  gradient, // 渐变背景+图标
  image, // 图片
  custom, // 自定义绘制
}

/// 应用数据模型
class AppModel {
  final String id;
  final String name;
  final AppType type;
  final IconType iconType;
  final IconData? icon;
  final List<Color>? gradientColors;
  final String? imagePath;
  final int badge;
  final bool isRemovable;
  final List<AppModel>? folderApps;
  final VoidCallback? onTap;

  const AppModel({
    required this.id,
    required this.name,
    this.type = AppType.thirdParty,
    this.iconType = IconType.gradient,
    this.icon,
    this.gradientColors,
    this.imagePath,
    this.badge = 0,
    this.isRemovable = true,
    this.folderApps,
    this.onTap,
  });

  AppModel copyWith({
    String? id,
    String? name,
    AppType? type,
    IconType? iconType,
    IconData? icon,
    List<Color>? gradientColors,
    String? imagePath,
    int? badge,
    bool? isRemovable,
    List<AppModel>? folderApps,
    VoidCallback? onTap,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconType: iconType ?? this.iconType,
      icon: icon ?? this.icon,
      gradientColors: gradientColors ?? this.gradientColors,
      imagePath: imagePath ?? this.imagePath,
      badge: badge ?? this.badge,
      isRemovable: isRemovable ?? this.isRemovable,
      folderApps: folderApps ?? this.folderApps,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// 主屏幕页面数据
class HomePageData {
  final int pageIndex;
  final List<AppModel> apps;

  const HomePageData({required this.pageIndex, required this.apps});
}

/// Dock栏数据
class DockData {
  final List<AppModel> apps;

  const DockData({required this.apps});
}
