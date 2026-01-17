import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import 'chat_detail_screen.dart';

class WeChatScreen extends StatefulWidget {
  const WeChatScreen({super.key});

  @override
  State<WeChatScreen> createState() => _WeChatScreenState();
}

class _WeChatScreenState extends State<WeChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED), // WeChat background grey
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        automaticallyImplyLeading: false, // 移除返回按钮
        title: const Text(
          '聊天',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: _showCreateChatDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<ChatProvider, ContactProvider>(
        builder: (context, chatProvider, contactProvider, child) {
          if (chatProvider.chats.isEmpty) {
            return const Center(
              child: Text(
                '暂无聊天\n点击右上角 + 号创建',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return _buildChatItem(context, chat, contactProvider);
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

    return Container(
      color: Colors.white, // Chat item background
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatId: chat.id),
            ),
          );
        },
        onLongPressStart: (LongPressStartDetails details) {
          _showChatOptionsMenu(context, chat, role, details.globalPosition);
        },
        child: Row(
          children: [
            // Avatar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: role.avatarPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(role.avatarPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, color: Colors.grey);
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
            ),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEDEDED), width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            role.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(chat.lastUpdated),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessagePreview,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _showChatOptionsMenu(
    BuildContext context,
    ChatSession chat,
    ContactRole role,
    Offset position,
  ) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 100, // 以长按位置为中心，向左偏移
        position.dy, // 长按位置的Y坐标
        position.dx + 100, // 向右偏移
        0,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          enabled: false,
          child: Text(
            role.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(
                chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 20,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              Text(
                chat.isPinned ? '取消置顶' : '置顶该聊天',
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
          onTap: () async {
            // 延迟执行，避免菜单关闭后立即执行导致context问题
            Future.delayed(Duration.zero, () async {
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              await chatProvider.togglePinChat(chat.id);
            });
          },
        ),
        PopupMenuItem<void>(
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('删除该聊天', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              _showDeleteConfirmDialog(context, chat, role);
            });
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    ChatSession chat,
    ContactRole role,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除聊天'),
        content: Text('确定要删除与"${role.name}"的聊天记录吗？\n删除后将无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              await chatProvider.deleteChat(chat.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('聊天已删除')),
                );
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CreateChatSheet(),
    );
  }
}

class CreateChatSheet extends StatefulWidget {
  const CreateChatSheet({super.key});

  @override
  State<CreateChatSheet> createState() => _CreateChatSheetState();
}

class _CreateChatSheetState extends State<CreateChatSheet> {
  int _step = 0; // 0: Select Role, 1: Select Me
  ContactRole? _selectedRole;
  ContactMe? _selectedMe;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _step == 0 ? '选择聊天对象 (角色)' : '选择你的身份 (用户)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _step == 0
                ? _buildRoleList(contactProvider)
                : _buildMeList(contactProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleList(ContactProvider provider) {
    if (provider.roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无角色，请先去通讯录添加'),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.roles.length,
      itemBuilder: (context, index) {
        final role = provider.roles[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: role.avatarPath != null
                ? FileImage(File(role.avatarPath!))
                : null,
            child: role.avatarPath == null ? Text(role.name[0]) : null,
          ),
          title: Text(role.name),
          subtitle: Text(
            role.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            setState(() {
              _selectedRole = role;
              _step = 1;
            });
          },
        );
      },
    );
  }

  Widget _buildMeList(ContactProvider provider) {
    if (provider.meList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无用户身份，请先去通讯录添加'),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.meList.length,
      itemBuilder: (context, index) {
        final me = provider.meList[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                me.avatarPath != null ? FileImage(File(me.avatarPath!)) : null,
            child: me.avatarPath == null ? Text(me.name[0]) : null,
          ),
          title: Text(me.name),
          subtitle: Text(
            me.info,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          enabled: !_isCreating,
          onTap: () async {
            setState(() {
              _selectedMe = me;
            });
            await _createChat();
          },
        );
      },
    );
  }

  Future<void> _createChat() async {
    if (_isCreating) return;
    if (_selectedRole != null && _selectedMe != null) {
      setState(() {
        _isCreating = true;
      });

      try {
        final navigator = Navigator.of(context);
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final chatId = await chatProvider.createChat(
          _selectedRole!.id,
          _selectedMe!.id,
        );

        if (mounted) {
          navigator.pop(); // Close sheet
          navigator.push(
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatId: chatId),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error creating chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('创建聊天失败: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }
}
