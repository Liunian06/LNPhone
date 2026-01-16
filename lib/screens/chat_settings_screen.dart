import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';

class ChatSettingsScreen extends StatelessWidget {
  final String chatId;

  const ChatSettingsScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '聊天设置',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final chat = chatProvider.getChat(chatId);

          if (chat == null) {
            return const Center(child: Text('聊天不存在'));
          }

          return ListView(
            children: [
              const SizedBox(height: 10),
              // 扩展聊天设置
              Container(
                color: Colors.white,
                child: SwitchListTile(
                  title: const Text(
                    '启用扩展聊天',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  subtitle: const Text(
                    '开启后将显示角色的动作和想法',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  value: chat.enableExtendedChat,
                  activeColor: const Color(0xFF07C160),
                  onChanged: (value) async {
                    await chatProvider.updateChatSettings(
                      chatId,
                      enableExtendedChat: value,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // 说明文字
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '关闭扩展聊天后，AI 回复中的动作和想法将不会显示，只显示对话内容。',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
