import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/app_model.dart';

/// 默认iOS系统应用数据
class DefaultApps {
  /// Dock栏默认应用
  static List<AppModel> get dockApps => [
        const AppModel(
          id: 'ai_chat',
          name: '聊天',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.chat_bubble_2_fill,
          gradientColors: [Color(0xFF00C7BE), Color(0xFF30D158)],
        ),
        const AppModel(
          id: 'contacts',
          name: '联系人',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.person_crop_circle_fill,
          gradientColors: [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
        ),
        const AppModel(
          id: 'wallet',
          name: '钱包',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.creditcard_fill,
          gradientColors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
        ),
        const AppModel(
          id: 'settings',
          name: '设置',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.gear_solid,
          gradientColors: [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
          isRemovable: false,
        ),
      ];

  /// 第一页应用
  static List<AppModel> get page1Apps => [
        const AppModel(
          id: 'moments',
          name: '朋友圈',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.camera_circle_fill,
          gradientColors: [Color(0xFF30CFD0), Color(0xFF330867)],
        ),
        const AppModel(
          id: 'memories',
          name: '记忆',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.lightbulb,
          gradientColors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
        ),
        const AppModel(
          id: 'stickers',
          name: '表情库',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.smiley_fill,
          gradientColors: [Color(0xFFF6D365), Color(0xFFFDA085)],
        ),
      ];

  /// 第二页应用
  static List<AppModel> get page2Apps => [];

  /// 获取所有页面的应用
  static List<List<AppModel>> get allPages => [page1Apps, page2Apps];
}
