import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/providers/system_state_provider.dart';
import '../widgets/ios_wallpaper.dart';
import '../widgets/ios_app_icon.dart';
import '../core/models/app_model.dart';
import '../core/constants/ios_constants.dart';

class DesktopStyleScreen extends StatefulWidget {
  const DesktopStyleScreen({super.key});

  @override
  State<DesktopStyleScreen> createState() => _DesktopStyleScreenState();
}

class _DesktopStyleScreenState extends State<DesktopStyleScreen> {
  // 预设颜色
  final List<int> _presetColors = [
    0xFFFFFFFF, // 白色
    0xFF000000, // 黑色
    0xFFFF3B30, // 红色
    0xFFFF9500, // 橙色
    0xFFFFCC00, // 黄色
    0xFF34C759, // 绿色
    0xFF007AFF, // 蓝色
    0xFF5856D6, // 紫色
    0xFFAF52DE, // 粉色
    0xFF8E8E93, // 灰色
  ];

  bool _showCustomPicker = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 背景预览
          Positioned.fill(
            child: Consumer<SystemStateProvider>(
              builder: (context, provider, _) {
                final wallpaperPath = provider.effectiveWallpaperPath;
                if (wallpaperPath != null) {
                  return Image.file(
                    File(wallpaperPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackWallpaper(provider);
                    },
                  );
                }
                return _buildFallbackWallpaper(provider);
              },
            ),
          ),

          // 遮罩，让内容更清晰
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const Text(
                        '桌面样式',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 48), // 占位
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 图标预览
                Consumer<SystemStateProvider>(
                  builder: (context, provider, _) {
                    // 创建一个示例应用用于预览
                    final previewApp = AppModel(
                      id: 'preview',
                      name: '预览应用',
                      icon: CupertinoIcons.app_fill,
                      gradientColors: IOSColors.systemAppGradients[0],
                    );

                    return Center(
                      child: IOSAppIcon(
                        app: previewApp,
                        size: 60,
                        showLabel: true,
                        // 强制使用当前设置的样式
                        forceTextColor: Color(provider.desktopTextColor),
                        forceShowShadow: provider.showIconShadow,
                      ),
                    );
                  },
                ),

                const Spacer(),

                // 设置面板
                _buildSettingsPanel(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackWallpaper(SystemStateProvider provider) {
    final index = provider.currentWallpaperIndex
        .clamp(0, WallpaperStyle.values.length - 1);
    return IOSWallpaper(
      style: WallpaperStyle.values[index],
      enableParallax: false,
      child: const SizedBox.expand(),
    );
  }

  Widget _buildSettingsPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<SystemStateProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 阴影开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '图标阴影',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              CupertinoSwitch(
                value: provider.showIconShadow,
                onChanged: (value) => provider.setShowIconShadow(value),
                activeColor: const Color(0xFF007AFF),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 字体颜色选择
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '字体颜色',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCustomPicker = !_showCustomPicker;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _showCustomPicker ? '预设颜色' : '自定义',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showCustomPicker)
            _buildCustomColorPicker(context)
          else
            _buildPresetColorList(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPresetColorList(BuildContext context) {
    final provider = context.watch<SystemStateProvider>();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _presetColors.length,
        itemBuilder: (context, index) {
          final colorValue = _presetColors[index];
          final color = Color(colorValue);
          final isSelected = provider.desktopTextColor == colorValue;

          return GestureDetector(
            onTap: () => provider.setDesktopTextColor(colorValue),
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

  Widget _buildCustomColorPicker(BuildContext context) {
    final provider = context.watch<SystemStateProvider>();
    final currentColor = Color(provider.desktopTextColor);

    return Column(
      children: [
        _buildSlider(
          label: '红',
          value: currentColor.red.toDouble(),
          max: 255,
          color: Colors.red,
          onChanged: (value) {
            final newColor = currentColor.withRed(value.toInt());
            provider.setDesktopTextColor(newColor.value);
          },
        ),
        _buildSlider(
          label: '绿',
          value: currentColor.green.toDouble(),
          max: 255,
          color: Colors.green,
          onChanged: (value) {
            final newColor = currentColor.withGreen(value.toInt());
            provider.setDesktopTextColor(newColor.value);
          },
        ),
        _buildSlider(
          label: '蓝',
          value: currentColor.blue.toDouble(),
          max: 255,
          color: Colors.blue,
          onChanged: (value) {
            final newColor = currentColor.withBlue(value.toInt());
            provider.setDesktopTextColor(newColor.value);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('预览: '),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            const Spacer(),
            Text(
              '#${currentColor.value.toRadixString(16).toUpperCase().substring(2)}',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: CupertinoSlider(
            value: value,
            min: 0,
            max: max,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            value.toInt().toString(),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
