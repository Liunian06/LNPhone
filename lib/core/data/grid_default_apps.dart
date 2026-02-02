import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/app_model.dart';

/// 网格默认应用数据
class GridDefaultApps {
  /// 所有应用注册表
  static Map<String, AppModel> get appRegistry => {
        // 聊天应用 - 左上角第一位
        'ai_chat': const AppModel(
          id: 'ai_chat',
          name: '聊天',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.chat_bubble_2_fill,
          gradientColors: [Color(0xFF00C7BE), Color(0xFF30D158)],
          isRemovable: false,
        ),

        // 新增应用
        'memories': const AppModel(
          id: 'memories',
          name: '记忆',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.lightbulb,
          gradientColors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
        ),
        'stickers': const AppModel(
          id: 'stickers',
          name: '表情库',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.smiley_fill,
          gradientColors: [Color(0xFFF6D365), Color(0xFFFDA085)],
        ),
        'world_info': const AppModel(
          id: 'world_info',
          name: '世界书',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.book_fill,
          gradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        ),
        'text_preset': const AppModel(
          id: 'text_preset',
          name: '预设',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.doc_text_fill,
          gradientColors: [Color(0xFFFF512F), Color(0xFFDD2476)],
        ),
        // 系统应用 (保留需要的)
        'settings': const AppModel(
          id: 'settings',
          name: '设置',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.gear_solid,
          gradientColors: [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
          isRemovable: false,
        ),
        'album': const AppModel(
          id: 'album',
          name: '相册',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.photo_on_rectangle,
          gradientColors: [Color(0xFF5AC8FA), Color(0xFF5856D6)],
        ),
        'scenario': const AppModel(
          id: 'scenario',
          name: '奔现',
          type: AppType.system,
          iconType: IconType.gradient,
          icon: CupertinoIcons.heart_circle_fill,
          gradientColors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
        ),
      };

  /// 默认第一页网格布局 (4x7=28个位置)
  /// null表示空位
  static List<String?> get defaultPage1Grid => [
        // 第1行
        'memories', 'stickers', 'album', 'world_info',
        // 第2行
        'text_preset', 'scenario', null, null,
        // 第3-6行都是空的
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
        // 第7行 - 原dock应用
        'ai_chat', null, null, 'settings',
      ];

  /// 默认第二页网格布局
  static List<String?> get defaultPage2Grid => [
        // 全空
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
        null, null, null, null,
      ];
}
