import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';
import 'package:path/path.dart' as path;
import '../core/providers/system_state_provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/data/grid_default_apps.dart';
import '../core/utils/storage_utils.dart';
import '../core/services/api_log_service.dart';
import '../core/services/app_log_service.dart';
import '../core/services/json_export_service.dart';
import '../core/database/database.dart';
import '../widgets/ios_wallpaper.dart';
import 'api_settings_screen.dart';
import 'prompt_settings_screen.dart';
import 'lock_screen_style_screen.dart';
import 'desktop_style_screen.dart';
import 'regex_settings_screen.dart';

/// 设置界面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    SettingsSection(
                      children: [
                        SettingsTile(
                          title: 'API 设置',
                          subtitle: '管理聊天与生图模型',
                          icon: CupertinoIcons.settings,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApiSettingsScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '提示词与上下文管理',
                          subtitle: '管理系统提示词与上下文设置',
                          icon: CupertinoIcons.bubble_left_bubble_right_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PromptSettingsScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '正则设置',
                          subtitle: '管理响应后处理规则',
                          icon: CupertinoIcons.wand_stars,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegexSettingsScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '显示设置',
                          subtitle: '壁纸、图标',
                          icon: CupertinoIcons.paintbrush_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DisplaySettingsScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '数据管理',
                          subtitle: '存储、备份与恢复',
                          icon: CupertinoIcons.folder_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DataManagementScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '设置',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    SettingsSection(
                      children: [
                        SettingsTile(
                          title: '桌面壁纸',
                          subtitle: '自定义主屏幕背景图片',
                          icon: CupertinoIcons.photo_fill,
                          onTap: () =>
                              _showWallpaperSettings(isLockScreen: false),
                        ),
                        SettingsTile(
                          title: '桌面样式',
                          subtitle: '自定义字体颜色与阴影',
                          icon: CupertinoIcons.paintbrush,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DesktopStyleScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '锁屏壁纸',
                          subtitle: '自定义锁屏背景图片',
                          icon: CupertinoIcons.lock_fill,
                          onTap: () =>
                              _showWallpaperSettings(isLockScreen: true),
                        ),
                        SettingsTile(
                          title: '锁屏时间样式',
                          subtitle: '自定义时间颜色',
                          icon: CupertinoIcons.time,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LockScreenStyleScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '应用图标',
                          subtitle: '自定义应用图标样式',
                          icon: CupertinoIcons.app_fill,
                          onTap: _showIconSettings,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '显示设置',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showWallpaperSettings({required bool isLockScreen}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _WallpaperSettingsSheet(isLockScreen: isLockScreen),
    );
  }

  void _showIconSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _IconSettingsScreen()),
    );
  }
}

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    SettingsSection(
                      children: [
                        SettingsTile(
                          title: '存储空间',
                          subtitle: '查看应用占用空间',
                          icon: CupertinoIcons.chart_pie_fill,
                          onTap: _showStorageInfo,
                        ),
                        SettingsTile(
                          title: '导出数据 (ZIP)',
                          subtitle: '备份所有设置和资源',
                          icon: CupertinoIcons.square_arrow_up_fill,
                          onTap: _exportSettings,
                        ),
                        SettingsTile(
                          title: '导出明文数据 (JSON)',
                          subtitle: '导出可读的文本数据',
                          icon: CupertinoIcons.doc_text,
                          onTap: _exportToJson,
                          iconGradient: const [
                            Color(0xFFFDC830),
                            Color(0xFFF37335)
                          ],
                        ),
                        SettingsTile(
                          title: '导入数据',
                          subtitle: '从文件恢复设置',
                          icon: CupertinoIcons.square_arrow_down_fill,
                          onTap: _importSettings,
                        ),
                        SettingsTile(
                          title: '尝试恢复旧版数据',
                          subtitle: '如果升级后数据丢失，请尝试此选项',
                          icon: CupertinoIcons.arrow_2_circlepath,
                          onTap: _tryRestoreLegacyData,
                        ),
                        SettingsTile(
                          title: '管理导出文件',
                          subtitle: '查看并清理已导出的备份与日志',
                          icon: CupertinoIcons.doc_on_doc_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ExportManagementScreen(),
                            ),
                          ),
                          iconGradient: const [
                            Color(0xFF4facfe),
                            Color(0xFF00f2fe)
                          ],
                        ),
                        SettingsTile(
                          title: '导出 API 日志',
                          subtitle: '导出 API 调用记录（JSONL 格式）',
                          icon: CupertinoIcons.doc_text_fill,
                          onTap: _exportApiLogs,
                        ),
                        SettingsTile(
                          title: '导出软件日志',
                          subtitle: '导出用户操作和后台活动日志（用于问题排查）',
                          icon: CupertinoIcons.doc_plaintext,
                          onTap: _exportAppLogs,
                          iconGradient: const [
                            Color(0xFF00B4DB),
                            Color(0xFF0083B0)
                          ],
                        ),
                        SettingsTile(
                          title: '清空 API 日志',
                          subtitle: '删除所有 API 调用记录',
                          icon: CupertinoIcons.trash_fill,
                          onTap: _clearApiLogs,
                          iconGradient: const [
                            Color(0xFFFF6B6B),
                            Color(0xFFEE5A6F)
                          ],
                        ),
                        SettingsTile(
                          title: '清空软件日志',
                          subtitle: '删除所有软件操作日志',
                          icon: CupertinoIcons.trash,
                          onTap: _clearAppLogs,
                          iconGradient: const [
                            Color(0xFFFF6B6B),
                            Color(0xFFEE5A6F)
                          ],
                        ),
                        SettingsTile(
                          title: '日志保留天数',
                          subtitle:
                              '当前保留 ${context.watch<SystemStateProvider>().logKeepDays} 天',
                          icon: CupertinoIcons.calendar,
                          onTap: _showLogKeepDaysPicker,
                          iconGradient: const [
                            Color(0xFF6A11CB),
                            Color(0xFF2575FC)
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '数据管理',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StorageStatisticsScreen(),
      ),
    );
  }

  void _exportToJson() async {
    try {
      final jsonService = JsonExportService();
      final summary = await jsonService.getExportSummary();

      if (!mounted) return;

      // 准备摘要信息
      final chatCount =
          (summary['chats'] as Map<String, dynamic>)['sessionCount'];
      final msgCount =
          (summary['chats'] as Map<String, dynamic>)['messageCount'];
      final contactCount =
          (summary['contacts'] as Map<String, dynamic>)['roleCount'] +
              (summary['contacts'] as Map<String, dynamic>)['meCount'];

      // 确认导出
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出明文数据'),
          content: Text(
              '即将导出以下数据为 JSON 格式：\n\n• $contactCount 个联系人\n• $chatCount 个会话 ($msgCount 条消息)\n• 朋友圈、钱包、预设等数据\n\n导出的文件可供开发者分析或数据迁移，图片已以 Base64 编码存储。'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: const Text('导出'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // 执行导出
      final filePath = await jsonService.exportToJson();

      if (!mounted) return;

      // 显示选择导出方式
      final action = await showCupertinoModalPopup<int>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('导出成功'),
          message: const Text('选择导出方式'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('系统分享'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('保存到文件'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ),
      );

      if (action == null) return;

      if (action == 0) {
        // 系统分享
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'LNPhone JSON 数据导出',
          text: '这是 LNPhone 的明文数据导出文件',
        );
      } else {
        // 保存到文件
        final params = SaveFileDialogParams(sourceFilePath: filePath);
        final savedPath = await FlutterFileDialog.saveFile(params: params);

        if (savedPath != null && mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('保存成功'),
              content: const Text('文件已保存'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _exportSettings() async {
    try {
      // 显示选择菜单
      final action = await showCupertinoModalPopup<int>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('导出数据'),
          message: const Text('选择导出方式'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('系统分享'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('保存到文件'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ),
      );

      if (action == null) return;

      final provider = context.read<SystemStateProvider>();
      // 使用 ZIP 打包导出
      final zipPath = await provider.exportSettingsToZip();

      // 生成文件名：LNPhone-Backup-YYYY-MM-DD-HH-mm-SS.zip
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd-HH-mm-ss');
      final fileName = 'LNPhone-Backup-${formatter.format(now)}.zip';

      // 重命名文件
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final intermediateFile = File(zipPath);
      await intermediateFile.copy(filePath);

      // 删除中间临时文件
      if (await intermediateFile.exists()) {
        await intermediateFile.delete();
      }

      if (!mounted) return;

      if (action == 0) {
        // 系统分享
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'LNPhone 备份',
          text: '这是我的 LNPhone 备份文件',
        );
      } else {
        // 保存到文件 (使用 flutter_file_dialog)
        final params = SaveFileDialogParams(sourceFilePath: filePath);
        final savedPath = await FlutterFileDialog.saveFile(params: params);

        if (savedPath != null && mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('导出成功'),
              content: const Text('文件已保存'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _importSettings() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['json', 'zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path!;
      final extension = filePath.split('.').last.toLowerCase();

      if (!mounted) return;

      final provider = context.read<SystemStateProvider>();
      bool success = false;

      if (extension == 'zip') {
        success = await provider.importSettingsFromZip(filePath);
      } else {
        final file = File(filePath);
        final jsonString = await file.readAsString();
        success = await provider.importSettings(jsonString);
      }

      if (!mounted) return;

      if (success) {
        // 导入成功后，提示用户应用将重启以加载新数据
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('导入成功'),
            content: const Text('数据已成功导入，应用将重启以加载新数据。'),
            actions: [
              CupertinoDialogAction(
                child: const Text('重启应用'),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // 重启应用以完全重新加载数据库
                  Restart.restartApp();
                },
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('导入失败'),
            content: const Text('文件格式不正确或数据损坏'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导入失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _tryRestoreLegacyData() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('恢复旧版数据'),
        content:
            const Text('此操作将尝试从旧版本的存储中查找并恢复联系人数据。\n\n仅当您升级应用后发现角色或人设丢失时使用。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text('尝试恢复'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // 强制执行迁移逻辑
      final provider = context.read<ContactProvider>();
      await provider.forceRestoreFromLegacy();

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('恢复完成'),
            content: const Text('已尝试恢复数据。如果数据仍然缺失，可能已被系统清除。'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('恢复失败'),
            content: Text('错误：$e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _exportApiLogs() async {
    try {
      // 先获取日志信息
      final logCount = await ApiLogService.getLogCount();
      final logSize = await ApiLogService.getLogFileSize();

      if (logCount == 0) {
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('无日志记录'),
            content: const Text('当前没有 API 调用日志可以导出'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      // 显示日志信息
      final sizeInKB = (logSize / 1024).toStringAsFixed(2);
      final confirmExport = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出 API 日志'),
          content: Text('共有 $logCount 条日志记录\n文件大小: $sizeInKB KB\n\n确定要导出吗？'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: const Text('导出'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmExport != true) return;

      // 导出日志
      final exportPath = await ApiLogService.exportLogs();

      if (!mounted) return;

      // 显示选择导出方式
      final action = await showCupertinoModalPopup<int>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('导出 API 日志'),
          message: const Text('选择导出方式'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('系统分享'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('保存到文件'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ),
      );

      if (action == null || !mounted) return;

      if (action == 0) {
        // 系统分享
        await Share.shareXFiles(
          [XFile(exportPath)],
          subject: 'API 调用日志',
          text: '这是 API 调用日志文件（JSONL 格式）',
        );
      } else {
        // 保存到文件
        final params = SaveFileDialogParams(sourceFilePath: exportPath);
        final savedPath = await FlutterFileDialog.saveFile(params: params);

        if (savedPath != null && mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('导出成功'),
              content: const Text('API 日志已保存'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _clearApiLogs() async {
    try {
      // 先获取日志信息
      final logCount = await ApiLogService.getLogCount();

      if (logCount == 0) {
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('无日志记录'),
            content: const Text('当前没有 API 调用日志'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      // 确认删除
      final confirmClear = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('清空 API 日志'),
          content: Text('确定要删除所有 $logCount 条日志记录吗？\n此操作不可撤销。'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('删除'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmClear != true) return;

      // 清空日志
      await ApiLogService.clearLogs();

      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('清空成功'),
          content: const Text('所有 API 日志已删除'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('清空失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _exportAppLogs() async {
    try {
      // 先获取日志信息
      final logCount = await AppLogService.getLogCount();
      final logSize = await AppLogService.getLogFileSize();

      if (logCount == 0) {
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('无日志记录'),
            content: const Text('当前没有软件操作日志可以导出'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      // 显示日志信息
      final sizeInKB = (logSize / 1024).toStringAsFixed(2);
      final confirmExport = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出软件日志'),
          content: Text(
              '共有 $logCount 条日志记录\n文件大小: $sizeInKB KB\n\n此日志包含用户操作、后台服务活动、API 调用等详细信息，可用于问题排查。\n\n确定要导出吗？'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: const Text('导出'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmExport != true) return;

      // 导出日志
      final exportPath = await AppLogService.exportLogs();

      if (!mounted) return;

      // 显示选择导出方式
      final action = await showCupertinoModalPopup<int>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('导出软件日志'),
          message: const Text('选择导出方式'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('系统分享'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('保存到文件'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ),
      );

      if (action == null || !mounted) return;

      if (action == 0) {
        // 系统分享
        await Share.shareXFiles(
          [XFile(exportPath)],
          subject: '软件操作日志',
          text: '这是软件操作日志文件，包含用户操作、后台服务活动和 API 调用等详细信息',
        );
      } else {
        // 保存到文件
        final params = SaveFileDialogParams(sourceFilePath: exportPath);
        final savedPath = await FlutterFileDialog.saveFile(params: params);

        if (savedPath != null && mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('导出成功'),
              content: const Text('软件日志已保存'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('导出失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _clearAppLogs() async {
    try {
      // 先获取日志信息
      final logCount = await AppLogService.getLogCount();

      if (logCount == 0) {
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('无日志记录'),
            content: const Text('当前没有软件操作日志'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      // 确认删除
      final confirmClear = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('清空软件日志'),
          content: Text('确定要删除所有 $logCount 条日志记录吗？\n此操作不可撤销。'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('删除'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmClear != true) return;

      // 清空日志
      await AppLogService.clearLogs();

      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('清空成功'),
          content: const Text('所有软件日志已删除'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('清空失败'),
          content: Text('错误：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _showLogKeepDaysPicker() {
    final provider = context.read<SystemStateProvider>();
    final options = [1, 3, 7, 14, 30];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('日志保留天数'),
        message: const Text('过期的日志文件将被自动删除以节省空间'),
        actions: options.map((days) {
          return CupertinoActionSheetAction(
            onPressed: () {
              provider.setLogKeepDays(days);
              Navigator.pop(context);
            },
            child: Text('$days 天'),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: textColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final List<Color>? iconGradient;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconGradient ??
                        [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: textColor.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 壁纸设置面板
class _WallpaperSettingsSheet extends StatefulWidget {
  final bool isLockScreen;

  const _WallpaperSettingsSheet({this.isLockScreen = false});

  @override
  State<_WallpaperSettingsSheet> createState() =>
      _WallpaperSettingsSheetState();
}

class _WallpaperSettingsSheetState extends State<_WallpaperSettingsSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHandle(isDark),
              _buildHeader(context, isDark),
              Expanded(child: _buildWallpaperGrid(context)),
            ],
          ),
          if (_isLoading)
            Container(
              color: isDark ? Colors.black54 : Colors.white54,
              child: const Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.isLockScreen ? '选择锁屏壁纸' : '选择桌面壁纸',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : () => _pickCustomWallpaper(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.photo, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '自定义',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColorPicker(BuildContext context) {
    final provider = context.watch<SystemStateProvider>();
    final colors = [
      0xFFFFFFFF, // 白色
      0xFF000000, // 黑色
      0xFFFF3B30, // 红色
      0xFFFF9500, // 橙色
      0xFFFFCC00, // 黄色
      0xFF34C759, // 绿色
      0xFF007AFF, // 蓝色
      0xFF5856D6, // 紫色
      0xFFAF52DE, // 粉色
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = Color(colors[index]);
          final isSelected = provider.lockScreenTimeColor == colors[index];

          return GestureDetector(
            onTap: () => provider.setLockScreenTimeColor(colors[index]),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      CupertinoIcons.checkmark,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallpaperGrid(BuildContext context) {
    final provider = context.watch<SystemStateProvider>();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.6,
      ),
      itemCount: 7, // 增加一个随机风景选项
      itemBuilder: (context, index) {
        if (index == 6) {
          return _buildRandomLandscapeOption(context, provider);
        }
        return _buildWallpaperOption(context, index, provider);
      },
    );
  }

  Widget _buildRandomLandscapeOption(
    BuildContext context,
    SystemStateProvider provider,
  ) {
    final isSelected = widget.isLockScreen
        ? (provider.lockScreenWallpaperIndex == 6 &&
            provider.customLockScreenWallpaperPath == null)
        : (provider.currentWallpaperIndex == 6 &&
            provider.customWallpaperPath == null);

    return GestureDetector(
      onTap: () {
        if (widget.isLockScreen) {
          provider.setRandomLandscapeLockScreenWallpaper();
        } else {
          provider.setRandomLandscapeWallpaper();
        }
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '随机风景',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperOption(
    BuildContext context,
    int index,
    SystemStateProvider provider,
  ) {
    final isSelected = widget.isLockScreen
        ? (provider.lockScreenWallpaperIndex == index &&
            provider.customLockScreenWallpaperPath == null)
        : (provider.currentWallpaperIndex == index &&
            provider.customWallpaperPath == null);

    return GestureDetector(
      onTap: () {
        if (widget.isLockScreen) {
          provider.setLockScreenWallpaper(index);
        } else {
          provider.setWallpaper(index);
        }
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPreviewWallpaper(index),
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewWallpaper(int index) {
    final styles = [
      WallpaperStyle.gradient1,
      WallpaperStyle.gradient2,
      WallpaperStyle.gradient3,
      WallpaperStyle.dark,
      WallpaperStyle.aurora,
      WallpaperStyle.mesh,
    ];

    return IOSWallpaper(
      style: styles[index],
      enableParallax: false,
      child: const SizedBox.expand(),
    );
  }

  Future<void> _pickCustomWallpaper(BuildContext context) async {
    try {
      setState(() => _isLoading = true);

      // 使用 image_picker 自带的压缩功能
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // 限制最大宽度
        maxHeight: 2560, // 限制最大高度
        imageQuality: 85, // 压缩质量
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 检查文件大小（20MB限制）
      final file = File(image.path);
      final fileSize = await file.length();
      const maxSize = 20 * 1024 * 1024; // 20MB

      if (fileSize > maxSize) {
        setState(() => _isLoading = false);
        if (!context.mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('文件过大'),
            content: Text(
              '图片大小为 ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB，\n超过了 20MB 的限制，请选择较小的图片。',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      // 复制图片到应用目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${StorageUtils.getUniqueTimestamp()}_wallpaper.jpg';
      final savedPath = '${directory.path}/$fileName';
      await file.copy(savedPath);

      if (!context.mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final provider = context.read<SystemStateProvider>();
      if (widget.isLockScreen) {
        provider.setCustomLockScreenWallpaper(savedPath);
      } else {
        provider.setCustomWallpaper(savedPath);
      }

      setState(() => _isLoading = false);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('选择壁纸失败: $e');
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('选择失败'),
            content: Text('无法选择图片: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// 图标设置界面
class _IconSettingsScreen extends StatefulWidget {
  const _IconSettingsScreen();

  @override
  State<_IconSettingsScreen> createState() => _IconSettingsScreenState();
}

class _IconSettingsScreenState extends State<_IconSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(child: _buildAppList(context, isDark)),
                ],
              ),
              if (_isLoading)
                Container(
                  color: isDark ? Colors.black54 : Colors.white54,
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '自定义图标',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(BuildContext context, bool isDark) {
    final apps = GridDefaultApps.appRegistry.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return _buildAppItem(context, apps[index], isDark);
      },
    );
  }

  Widget _buildAppItem(BuildContext context, app, bool isDark) {
    final provider = context.watch<SystemStateProvider>();
    final hasCustomIcon = provider.getCustomAppIcon(app.id) != null;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showIconOptions(context, app.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13.5),
                    gradient: LinearGradient(
                      colors: app.gradientColors ?? [Colors.grey, Colors.grey],
                    ),
                  ),
                  child: Icon(app.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCustomIcon ? '已自定义' : '使用默认图标',
                        style: TextStyle(
                          color: hasCustomIcon
                              ? const Color(0xFF007AFF)
                              : textColor.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: textColor.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIconOptions(BuildContext context, String appId) {
    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => CupertinoActionSheet(
        title: const Text('自定义图标'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _pickIconImage(context, appId);
            },
            child: const Text('选择图片'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SystemStateProvider>().removeCustomAppIcon(appId);
            },
            isDestructiveAction: true,
            child: const Text('恢复默认'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _pickIconImage(BuildContext context, String appId) async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      // 使用 image_picker 自带的压缩功能，限制尺寸
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // 图标不需要太大
        maxHeight: 512,
        imageQuality: 80, // 压缩质量
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 检查文件大小（20MB限制）
      final file = File(image.path);
      final fileSize = await file.length();
      const maxSize = 20 * 1024 * 1024; // 20MB

      if (fileSize > maxSize) {
        setState(() => _isLoading = false);
        if (!context.mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('文件过大'),
            content: Text(
              '图片大小为 ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB，\n超过了 20MB 的限制，请选择较小的图片。',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
        return;
      }

      // 复制图片到应用目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${StorageUtils.getUniqueTimestamp()}_icon_$appId.jpg';
      final savedPath = '${directory.path}/$fileName';
      await file.copy(savedPath);

      if (context.mounted) {
        context.read<SystemStateProvider>().setCustomAppIcon(appId, savedPath);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('选择图标失败: $e');
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('选择失败'),
            content: Text('无法选择图片: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// 导出文件管理界面
class ExportManagementScreen extends StatefulWidget {
  const ExportManagementScreen({super.key});

  @override
  State<ExportManagementScreen> createState() => _ExportManagementScreenState();
}

class _ExportManagementScreenState extends State<ExportManagementScreen> {
  List<File> _exportFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExportFiles();
  }

  Future<void> _loadExportFiles() async {
    setState(() => _isLoading = true);
    try {
      final List<File> files = [];
      final tempDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();

      // 扫描目录
      await _scanDirectory(tempDir, files);
      await _scanDirectory(appDir, files);

      // 按时间排序（最新的在前）
      files.sort((a, b) {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      });

      setState(() {
        _exportFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载导出文件失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanDirectory(Directory dir, List<File> results) async {
    if (!await dir.exists()) return;

    final List<FileSystemEntity> entities = dir.listSync();
    for (var entity in entities) {
      if (entity is File) {
        final name = path.basename(entity.path);
        // 匹配导出文件模式
        if (name.startsWith('api_logs_export_') ||
            name.startsWith('app_logs_') ||
            name.startsWith('emojis_export_') ||
            name.startsWith('backup_') ||
            name.startsWith('LNPhone-Backup-') ||
            name.startsWith('LNPhone-Export-')) {
          results.add(entity);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _exportFiles.isEmpty
                        ? _buildEmptyState(textColor)
                        : _buildFileList(isDark, textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '管理导出文件',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_exportFiles.isNotEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('清空全部',
                  style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: _clearAllFiles,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无导出文件',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(bool isDark, Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _exportFiles.length,
      itemBuilder: (context, index) {
        final file = _exportFiles[index];
        final fileName = path.basename(file.path);
        final fileSize = (file.lengthSync() / 1024 / 1024).toStringAsFixed(2);
        final modifiedTime =
            DateFormat('yyyy-MM-dd HH:mm').format(file.lastModifiedSync());

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getFileColor(fileName).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(fileName),
                color: _getFileColor(fileName),
              ),
            ),
            title: Text(
              fileName,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$fileSize MB • $modifiedTime',
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.6), fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.share, size: 20),
                  onPressed: () => _shareFile(file),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.trash,
                      color: CupertinoColors.destructiveRed, size: 20),
                  onPressed: () => _deleteFile(file),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.contains('log')) return CupertinoIcons.doc_text_fill;
    if (fileName.contains('emoji')) return CupertinoIcons.smiley_fill;
    return CupertinoIcons.archivebox_fill;
  }

  Color _getFileColor(String fileName) {
    if (fileName.contains('log')) return CupertinoColors.systemOrange;
    if (fileName.contains('emoji')) return CupertinoColors.systemPink;
    return CupertinoColors.systemBlue;
  }

  void _shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  void _deleteFile(File file) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文件 ${path.basename(file.path)} 吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await file.delete();
      _loadExportFiles();
    }
  }

  void _clearAllFiles() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('清空全部'),
        content: const Text('确定要删除所有已导出的文件吗？此操作不可撤销。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('全部删除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var file in _exportFiles) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('删除文件失败: ${file.path}, $e');
        }
      }
      _loadExportFiles();
    }
  }
}

class StorageStatisticsScreen extends StatefulWidget {
  const StorageStatisticsScreen({super.key});

  @override
  State<StorageStatisticsScreen> createState() =>
      _StorageStatisticsScreenState();
}

class _StorageStatisticsScreenState extends State<StorageStatisticsScreen> {
  bool _isLoading = true;
  int _totalSize = 0;

  // 统计数据
  int _chatImageCount = 0;
  int _chatImageSize = 0;

  int _momentCount = 0;
  int _momentMediaCount = 0;
  int _momentMediaSize = 0;

  int _contactAvatarCount = 0;
  int _contactAvatarSize = 0;
  int _contactRefCount = 0;
  int _contactRefSize = 0;

  int _wallpaperCount = 0;
  int _wallpaperSize = 0;
  int _iconCount = 0;
  int _iconSize = 0;

  int _logSize = 0;
  int _dbSize = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final db = AppDatabase();
      final appDir = await getApplicationDocumentsDirectory();

      // 1. 聊天统计
      final sessions = await db.getAllSessions();
      for (final session in sessions) {
        // 聊天背景图
        if (session.backgroundImage != null &&
            session.backgroundImage!.isNotEmpty) {
          final file = File(session.backgroundImage!);
          if (await file.exists()) {
            _wallpaperSize += await file.length();
            _wallpaperCount++;
          }
        }
      }

      // 统计所有图片消息
      final imageMessages = await db.getAllImageMessages();
      _chatImageCount = imageMessages.length;
      for (final msg in imageMessages) {
        if (msg.content.isNotEmpty) {
          final file = File(msg.content);
          if (await file.exists()) {
            _chatImageSize += await file.length();
          } else {
            // 尝试相对路径
            final absPath = '${appDir.path}/${msg.content}';
            final absFile = File(absPath);
            if (await absFile.exists()) {
              _chatImageSize += await absFile.length();
            }
          }
        }
      }

      // 2. 朋友圈统计
      final moments = await db.getAllMoments(limit: 10000); // 获取所有动态
      _momentCount = moments.length;
      for (final post in moments) {
        for (final media in post.mediaItems) {
          _momentMediaCount++;
          if (media.url.isNotEmpty) {
            final file = File(media.url);
            if (await file.exists()) {
              _momentMediaSize += await file.length();
            } else {
              final absPath = '${appDir.path}/${media.url}';
              final absFile = File(absPath);
              if (await absFile.exists()) {
                _momentMediaSize += await absFile.length();
              }
            }
          }
          if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty) {
            final file = File(media.thumbnailUrl!);
            if (await file.exists()) {
              _momentMediaSize += await file.length();
            }
          }
        }
      }

      // 3. 联系人统计
      final roles = await db.getAllContactRoles();
      for (final role in roles) {
        if (role.avatarPath != null && role.avatarPath!.isNotEmpty) {
          final file = File(role.avatarPath!);
          if (await file.exists()) {
            _contactAvatarSize += await file.length();
            _contactAvatarCount++;
          }
        }
        for (final ref in role.referenceImages) {
          if (ref.isNotEmpty) {
            final file = File(ref);
            if (await file.exists()) {
              _contactRefSize += await file.length();
              _contactRefCount++;
            }
          }
        }
      }

      final mes = await db.getAllContactMes();
      for (final me in mes) {
        if (me.avatarPath != null && me.avatarPath!.isNotEmpty) {
          final file = File(me.avatarPath!);
          if (await file.exists()) {
            _contactAvatarSize += await file.length();
            _contactAvatarCount++;
          }
        }
        for (final ref in me.referenceImages) {
          if (ref.isNotEmpty) {
            final file = File(ref);
            if (await file.exists()) {
              _contactRefSize += await file.length();
              _contactRefCount++;
            }
          }
        }
      }

      // 4. 系统设置统计
      final systemProvider = context.read<SystemStateProvider>();
      if (systemProvider.customWallpaperPath != null) {
        final file = File(systemProvider.customWallpaperPath!);
        if (await file.exists()) {
          _wallpaperSize += await file.length();
          _wallpaperCount++;
        }
      }
      if (systemProvider.customLockScreenWallpaperPath != null) {
        final file = File(systemProvider.customLockScreenWallpaperPath!);
        if (await file.exists()) {
          _wallpaperSize += await file.length();
          _wallpaperCount++;
        }
      }

      _iconCount = systemProvider.customAppIcons.length;
      for (final iconPath in systemProvider.customAppIcons.values) {
        final file = File(iconPath);
        if (await file.exists()) {
          _iconSize += await file.length();
        }
      }

      // 5. 日志统计
      _logSize += await ApiLogService.getLogFileSize();
      _logSize += await AppLogService.getLogFileSize();

      // 6. 数据库文件大小
      final dbFile = File('${appDir.path}/db.sqlite');
      if (await dbFile.exists()) {
        _dbSize += await dbFile.length();
      }
      final dbWalFile = File('${appDir.path}/db.sqlite-wal');
      if (await dbWalFile.exists()) {
        _dbSize += await dbWalFile.length();
      }
      final dbShmFile = File('${appDir.path}/db.sqlite-shm');
      if (await dbShmFile.exists()) {
        _dbSize += await dbShmFile.length();
      }

      // 计算总大小
      _totalSize = _chatImageSize +
          _momentMediaSize +
          _contactAvatarSize +
          _contactRefSize +
          _wallpaperSize +
          _iconSize +
          _logSize +
          _dbSize;
    } catch (e) {
      debugPrint('统计存储空间失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          CupertinoIcons.back,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '存储空间统计',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildTotalCard(isDark, textColor),
                          const SizedBox(height: 20),
                          SettingsSection(
                            title: '详细分布',
                            children: [
                              _buildStatItem(
                                '聊天图片',
                                '$_chatImageCount 张图片',
                                _chatImageSize,
                                CupertinoIcons.photo,
                                Colors.blue,
                              ),
                              _buildStatItem(
                                '朋友圈媒体',
                                '$_momentMediaCount 个文件 (共 $_momentCount 条动态)',
                                _momentMediaSize,
                                CupertinoIcons.circle_grid_3x3_fill,
                                Colors.purple,
                              ),
                              _buildStatItem(
                                '联系人数据',
                                '$_contactAvatarCount 个头像, $_contactRefCount 张参考图',
                                _contactAvatarSize + _contactRefSize,
                                CupertinoIcons.person_2_fill,
                                Colors.orange,
                              ),
                              _buildStatItem(
                                '个性化设置',
                                '$_wallpaperCount 张壁纸, $_iconCount 个图标',
                                _wallpaperSize + _iconSize,
                                CupertinoIcons.paintbrush_fill,
                                Colors.pink,
                              ),
                              _buildStatItem(
                                '日志文件',
                                'API日志 & 应用日志',
                                _logSize,
                                CupertinoIcons.doc_text_fill,
                                Colors.brown,
                              ),
                              _buildStatItem(
                                '数据库',
                                '本地数据库文件',
                                _dbSize,
                                CupertinoIcons.layers_fill,
                                Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '总占用空间',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatSize(_totalSize),
            style: TextStyle(
              color: textColor,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String subtitle,
    int size,
    IconData icon,
    Color iconColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatSize(size),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
