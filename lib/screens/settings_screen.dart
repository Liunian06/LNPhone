import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import '../core/providers/system_state_provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/data/grid_default_apps.dart';
import '../core/services/api_log_service.dart';
import '../widgets/ios_wallpaper.dart';
import 'api_settings_screen.dart';
import 'prompt_settings_screen.dart';

/// 设置界面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    SettingsSection(
                      children: [
                        SettingsTile(
                          title: 'API 配置',
                          subtitle: '管理 LLM 接口与模型',
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

  Widget _buildHeader() {
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
                          title: '锁屏壁纸',
                          subtitle: '自定义锁屏背景图片',
                          icon: CupertinoIcons.lock_fill,
                          onTap: () =>
                              _showWallpaperSettings(isLockScreen: true),
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

  Widget _buildHeader() {
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '显示设置',
            style: TextStyle(
              color: Colors.white,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
                          title: '导出数据',
                          subtitle: '导出所有个性化设置',
                          icon: CupertinoIcons.square_arrow_up_fill,
                          onTap: _exportSettings,
                        ),
                        SettingsTile(
                          title: '导入数据',
                          subtitle: '从文件恢复设置',
                          icon: CupertinoIcons.square_arrow_down_fill,
                          onTap: _importSettings,
                        ),
                        SettingsTile(
                          title: '导出 API 日志',
                          subtitle: '导出 API 调用记录（JSONL 格式）',
                          icon: CupertinoIcons.doc_text_fill,
                          onTap: _exportApiLogs,
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

  Widget _buildHeader() {
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '数据管理',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() async {
    final provider = context.read<SystemStateProvider>();
    final size = await provider.calculateStorageUsage();
    final sizeInMB = (size / 1024 / 1024).toStringAsFixed(2);

    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('存储占用'),
        content: Text('当前应用占用空间：$sizeInMB MB\n\n包括自定义壁纸和应用图标'),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
      await File(zipPath).copy(filePath);

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
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

      // 如果导入成功，刷新 ChatProvider 的数据
      if (success) {
        try {
          final chatProvider = context.read<ChatProvider>();
          await chatProvider.reloadData();
          debugPrint('ChatProvider 数据已刷新');
        } catch (e) {
          debugPrint('刷新 ChatProvider 数据失败: $e');
        }
      }

      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(success ? '导入成功' : '导入失败'),
          content: Text(success ? '设置和数据已成功导入' : '文件格式不正确或数据损坏'),
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
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
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
            color: Colors.white.withValues(alpha: 0.1),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4),
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHandle(),
              _buildHeader(context),
              Expanded(child: _buildWallpaperGrid(context)),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.isLockScreen ? '选择锁屏壁纸' : '选择桌面壁纸',
            style: const TextStyle(
              color: Colors.white,
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
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_wallpaper.jpg';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  Expanded(child: _buildAppList(context)),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
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

  Widget _buildHeader(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '自定义图标',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(BuildContext context) {
    final apps = GridDefaultApps.appRegistry.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return _buildAppItem(context, apps[index]);
      },
    );
  }

  Widget _buildAppItem(BuildContext context, app) {
    final provider = context.watch<SystemStateProvider>();
    final hasCustomIcon = provider.getCustomAppIcon(app.id) != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.4),
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
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_icon_$appId.jpg';
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
