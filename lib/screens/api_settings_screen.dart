import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/ios_wallpaper.dart';
import 'settings_screen.dart'; // For SettingsSection and SettingsTile
import 'chat_model_settings_screen.dart';
import 'image_model_settings_screen.dart';
import 'voice_model_settings_screen.dart';

class ApiSettingsScreen extends StatelessWidget {
  const ApiSettingsScreen({super.key});

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
              _buildHeader(context, isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    SettingsSection(
                      children: [
                        SettingsTile(
                          title: '聊天主模型',
                          subtitle: '管理对话模型预设',
                          icon: CupertinoIcons.chat_bubble_text_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChatModelSettingsScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '生图模型',
                          subtitle: '配置图像生成模型',
                          icon: CupertinoIcons.photo_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ImageModelSettingsScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          title: '语音模型',
                          subtitle: '配置语音合成模型',
                          icon: CupertinoIcons.mic_fill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const VoiceModelSettingsScreen(),
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
            'API 设置',
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
