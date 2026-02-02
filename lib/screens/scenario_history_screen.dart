import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/providers/api_settings_provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/models/api_preset.dart';
import '../core/models/text_preset_model.dart';
import '../core/theme/app_theme.dart';
import 'scenario_screen.dart';
import '../core/utils/time_formatter.dart';
import 'dart:io';

/// 奔现历史记录界面
class ScenarioHistoryScreen extends StatelessWidget {
  const ScenarioHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('奔现记录'),
        centerTitle: true,
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: context.primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: TextStyle(
          color: context.primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: context.chatBackground,
      body: Consumer2<ChatProvider, ContactProvider>(
        builder: (context, chatProvider, contactProvider, child) {
          // 过滤出包含奔现消息的会话
          final scenarioSessions = chatProvider.chats.where((session) {
            return session.messages.any((m) =>
                m.type == MessageType.scene ||
                m.type == MessageType.narration ||
                m.type == MessageType.options);
          }).toList();

          if (scenarioSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '暂无奔现记录',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: scenarioSessions.length,
            itemBuilder: (context, index) {
              final session = scenarioSessions[index];
              final role = contactProvider.roles.firstWhere(
                (r) => r.id == session.roleId,
                orElse: () =>
                    ContactRole(id: 'unknown', name: '未知角色', description: ''),
              );

              // 查找最后一条奔现相关的消息作为预览
              final lastScenarioMsg = session.messages.lastWhere(
                (m) =>
                    m.type == MessageType.scene ||
                    m.type == MessageType.narration,
                orElse: () => session.messages.last,
              );

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _buildAvatar(role),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        TimeFormatter.formatRelative(session.lastUpdated),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      lastScenarioMsg.displayText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ),
                  onTap: () =>
                      _enterScenario(context, session, role, contactProvider),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatar(ContactRole role) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: role.avatarPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(role.avatarPath!), fit: BoxFit.cover),
            )
          : const Icon(Icons.person, color: Colors.grey),
    );
  }

  void _enterScenario(BuildContext context, ChatSession session,
      ContactRole role, ContactProvider contactProvider) {
    final apiProvider = context.read<ApiSettingsProvider>();
    final chatProvider = context.read<ChatProvider>();

    final me = contactProvider.meList.firstWhere(
      (m) => m.id == session.meId,
      orElse: () => ContactMe(id: 'unknown', name: '我', info: ''),
    );

    // 获取 API 预设
    ApiPreset? activePreset;
    if (session.apiPresetId != null && session.apiPresetId!.isNotEmpty) {
      try {
        activePreset =
            apiProvider.presets.firstWhere((p) => p.id == session.apiPresetId);
      } catch (_) {}
    }
    activePreset ??= apiProvider.activePreset;

    if (activePreset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 API 预设')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScenarioScreen(
          role: role,
          me: me,
          apiPreset: activePreset!,
          imageApiPresetId: session.imageApiPresetId,
          imageStylePresetId: session.textPresetIds.cast<String?>().firstWhere(
                (id) => chatProvider.textPresets
                    .any((p) => p.id == id && p.type == TextPresetType.image),
                orElse: () => null,
              ),
        ),
      ),
    );
  }
}
