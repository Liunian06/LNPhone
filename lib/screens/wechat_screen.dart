import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/database/database.dart';
import '../core/models/world_info_model.dart';
import '../core/models/text_preset_model.dart';
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
            // Avatar with unread badge
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                                return const Icon(Icons.person,
                                    color: Colors.grey);
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
                  // Unread badge
                  if (chat.unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: chat.unreadCount > 9 ? 4 : 0,
                          vertical: 0,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F3F),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
  int _step = 0; // 0: Select Role, 1: Select Me, 2: Select World Info & Presets
  ContactRole? _selectedRole;
  ContactMe? _selectedMe;
  List<String> _selectedWorldInfos = [];
  List<String> _selectedTextPresets = [];
  bool _isCreating = false;

  // Data for step 2
  List<WorldInfo> _worldInfos = [];
  List<TextPreset> _textPresets = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    setState(() => _isLoadingData = true);
    try {
      await Future.wait([
        provider.refreshWorldInfos(),
        provider.refreshTextPresets(),
      ]);
      if (mounted) {
        setState(() {
          _worldInfos = provider.worldInfos;
          _textPresets = provider.textPresets;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading extra data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);

    String title = '';
    if (_step == 0)
      title = '选择聊天对象 (角色)';
    else if (_step == 1)
      title = '选择你的身份 (用户)';
    else
      title = '选择世界书与预设 (可选)';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_step == 2)
                TextButton(
                  onPressed: _createChat,
                  child: const Text('完成'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(contactProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ContactProvider provider) {
    if (_step == 0) return _buildRoleList(provider);
    if (_step == 1) return _buildMeList(provider);
    return _buildConfigList();
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
          onTap: () {
            setState(() {
              _selectedMe = me;
              _step = 2;
            });
          },
        );
      },
    );
  }

  Widget _buildConfigList() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        if (_worldInfos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '世界书 (多选)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ..._worldInfos.map((info) {
            final isSelected = _selectedWorldInfos.contains(info.id);
            return CheckboxListTile(
              title: Text(info.name),
              subtitle: Text(
                info.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedWorldInfos.add(info.id);
                  } else {
                    _selectedWorldInfos.remove(info.id);
                  }
                });
              },
            );
          }),
        ],
        if (_textPresets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '预设 (多选)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ..._textPresets.map((preset) {
            final isSelected = _selectedTextPresets.contains(preset.id);
            return CheckboxListTile(
              title: Text(preset.name),
              subtitle: Text(
                preset.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedTextPresets.add(preset.id);
                  } else {
                    _selectedTextPresets.remove(preset.id);
                  }
                });
              },
            );
          }),
        ],
        if (_worldInfos.isEmpty && _textPresets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('暂无世界书或预设可选')),
          ),
      ],
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
          worldInfoIds: _selectedWorldInfos,
          textPresetIds: _selectedTextPresets,
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
