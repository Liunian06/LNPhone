import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/providers/api_settings_provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/storage_utils.dart';
import 'scenario_screen.dart';

/// 奔现聊天选择界面 - 选择已有的聊天会话来发起奔现
class ScenarioChatSelectorScreen extends StatelessWidget {
  const ScenarioChatSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: context.primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '选择聊天发起奔现',
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer2<ChatProvider, ContactProvider>(
        builder: (context, chatProvider, contactProvider, child) {
          if (chatProvider.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: context.secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无聊天记录',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请先创建聊天会话',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return _buildChatItem(
                context,
                chat,
                contactProvider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    ChatSession chat,
    ContactProvider contactProvider,
  ) {
    final role = contactProvider.roles.firstWhere(
      (r) => r.id == chat.roleId,
      orElse: () => ContactRole(
        id: 'unknown',
        name: '未知用户',
        description: '',
        avatarPath: null,
      ),
    );

    final me = contactProvider.meList.firstWhere(
      (m) => m.id == chat.meId,
      orElse: () => ContactMe(
        id: 'unknown',
        name: '未知',
        info: '',
        avatarPath: null,
      ),
    );

    return Container(
      color: context.surfaceColor,
      child: InkWell(
        onTap: () => _startScenario(context, chat, role, me),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 头像
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      context.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: role.avatarPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: FutureBuilder<String>(
                          future: StorageUtils.ensureFileExists(
                              role.avatarPath!,
                              backupData: role.avatarData),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final file = File(snapshot.data!);
                            if (!file.existsSync()) {
                              return Icon(Icons.person,
                                  color: context.secondaryTextColor);
                            }
                            return Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person,
                                    color: context.secondaryTextColor);
                              },
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          role.name.isNotEmpty
                              ? role.name.substring(0, 1)
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            role.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: context.isDarkMode
                              ? const Color(0xFFFF9966)
                              : const Color(0xFFFF5E62),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessagePreview.isEmpty
                          ? '开始奔现...'
                          : chat.lastMessagePreview,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 开始奔现
  void _startScenario(
    BuildContext context,
    ChatSession chat,
    ContactRole role,
    ContactMe me,
  ) async {
    // 获取 API 设置
    final apiProvider =
        Provider.of<ApiSettingsProvider>(context, listen: false);
    final apiPreset = apiProvider.activePreset;

    if (apiPreset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 API 设置')),
      );
      return;
    }

    // 获取会话的生图 API 预设
    final imageApiPresetId = chat.imageApiPresetId;

    // 显示场景输入对话框
    final initialScene = await _showSceneInputDialog(context, role.name);
    if (initialScene == null || initialScene.isEmpty) {
      return;
    }

    // 跳转到奔现界面
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScenarioScreen(
            role: role,
            me: me,
            apiPreset: apiPreset,
            imageApiPresetId: imageApiPresetId,
            imageStylePresetId: null, // 可以根据需要扩展
            initialScene: initialScene,
          ),
        ),
      );
    }
  }

  /// 显示场景输入对话框
  Future<String?> _showSceneInputDialog(
    BuildContext context,
    String roleName,
  ) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('发起奔现 - $roleName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请描述初始场景：',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '例如：在咖啡厅见面，阳光透过窗户洒进来...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              '提示：描述地点、时间、天气等场景要素',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }
}
