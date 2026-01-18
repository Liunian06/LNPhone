import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/providers/api_settings_provider.dart';
import '../core/providers/prompt_settings_provider.dart';
import '../core/providers/moments_provider.dart';
import '../core/services/llm_service.dart';
import '../core/services/notification_service.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/models/moments_model.dart';
import '../widgets/message_bubbles.dart';
import '../widgets/chat_context_menu.dart';
import 'chat_settings_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIds = {};
  bool _showAttachmentOptions = false; // 控制是否显示附件选项
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // 进入聊天界面时，标记所有消息为已读
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.markSessionAsRead(widget.chatId);
      _scrollToBottom();

      // 初始化消息数量，避免首次build触发不必要的滚动
      final chat = chatProvider.getChat(widget.chatId);
      if (chat != null) {
        _lastMessageCount = chat.messages.length;
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ContactProvider>(
      builder: (context, chatProvider, contactProvider, child) {
        final chat = chatProvider.getChat(widget.chatId);

        if (chat == null) {
          return const Scaffold(body: Center(child: Text('聊天不存在')));
        }

        // 监听消息数量变化，自动滚动到底部
        if (chat.messages.length > _lastMessageCount) {
          _lastMessageCount = chat.messages.length;
          // 使用 addPostFrameCallback 确保在列表构建完成后滚动
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        } else if (chat.messages.length < _lastMessageCount) {
          // 消息减少（如删除），只更新计数，不滚动
          _lastMessageCount = chat.messages.length;
        }

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
          orElse: () =>
              ContactMe(id: 'unknown', name: '我', info: '', avatarPath: null),
        );

        // 获取背景图
        final backgroundImage = chat.backgroundImage;

        return GestureDetector(
          onTap: () {
            _removeOverlay();
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: const Color(0xFFEDEDED),
            appBar: AppBar(
              backgroundColor: backgroundImage != null
                  ? Colors.transparent
                  : const Color(0xFFEDEDED),
              elevation: 0,
              leading: _isMultiSelectMode
                  ? TextButton(
                      onPressed: () {
                        setState(() {
                          _isMultiSelectMode = false;
                          _selectedMessageIds.clear();
                        });
                      },
                      child: const Text(
                        '取消',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
              title: Selector<ChatProvider, (bool, String?)>(
                selector: (context, provider) => (
                  provider.isTyping(widget.chatId),
                  provider.getCurrentState(widget.chatId),
                ),
                builder: (context, data, child) {
                  final isTyping = data.$1;
                  final currentState = data.$2;
                  return Column(
                    children: [
                      Text(
                        isTyping ? '正在输入中…' : role.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (currentState != null && currentState.isNotEmpty)
                        Text(
                          currentState,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  );
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatSettingsScreen(chatId: widget.chatId),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Container(
              decoration: backgroundImage != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(backgroundImage)),
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      cacheExtent: 500,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final messageIndex = chat.messages.length - 1 - index;
                        return MessageItem(
                          key: ValueKey(chat.messages[messageIndex].id),
                          message: chat.messages[messageIndex],
                          role: role,
                          me: me,
                          isMultiSelectMode: _isMultiSelectMode,
                          isSelected: _selectedMessageIds
                              .contains(chat.messages[messageIndex].id),
                          onTap: () {
                            if (_isMultiSelectMode) {
                              setState(() {
                                if (_selectedMessageIds
                                    .contains(chat.messages[messageIndex].id)) {
                                  _selectedMessageIds
                                      .remove(chat.messages[messageIndex].id);
                                } else {
                                  _selectedMessageIds
                                      .add(chat.messages[messageIndex].id);
                                }
                              });
                            } else {
                              // 非多选模式下，点击空白处收起键盘和菜单
                              _removeOverlay();
                              FocusScope.of(context).unfocus();
                            }
                          },
                          onLongPress: (details) {
                            if (!_isMultiSelectMode) {
                              _showContextMenu(context, details.globalPosition,
                                  chat.messages[messageIndex]);
                            }
                          },
                          onSelectionChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMessageIds
                                    .add(chat.messages[messageIndex].id);
                              } else {
                                _selectedMessageIds
                                    .remove(chat.messages[messageIndex].id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  if (_isMultiSelectMode)
                    _buildMultiSelectBottomBar(chatProvider)
                  else
                    _buildInputArea(chatProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // _buildMessageItem, _buildMessageBubble, _buildAvatar methods removed and refactored into MessageItem class

  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Color(0xFFDCDCDC), width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 输入框区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 8),
                        ),
                        onSubmitted: (value) => _sendMessage(chatProvider),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: Colors.black87,
                    ),
                    onPressed: () {
                      // TODO: Show emoji picker
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _showAttachmentOptions
                          ? Icons.keyboard
                          : Icons.add_circle_outline,
                      color: Colors.black87,
                    ),
                    onPressed: () {
                      setState(() {
                        _showAttachmentOptions = !_showAttachmentOptions;
                      });
                    },
                  ),
                ],
              ),
            ),
            // 附件选项区域（可选显示，放在输入框下方）
            if (_showAttachmentOptions) _buildAttachmentOptionsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOptionsPanel() {
    return SizedBox(
      height: 180,
      child: PageView(
        children: [
          // 第一页 - 8个按钮
          _buildPage1(),
          // 第二页 - 4个按钮
          _buildPage2(),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              icon: Icons.photo_library,
              label: '相册',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 打开相册选择图片
              },
            ),
            _buildAttachmentOption(
              icon: Icons.camera_alt,
              label: '拍摄',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 打开相机拍照
              },
            ),
            _buildAttachmentOption(
              icon: Icons.video_call,
              label: '视频通话',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 发起视频通话
              },
            ),
            _buildAttachmentOption(
              icon: Icons.location_on,
              label: '位置',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 选择位置
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              icon: Icons.card_giftcard,
              label: '红包',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 发红包
              },
            ),
            _buildAttachmentOption(
              icon: Icons.redeem,
              label: '礼物',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 发送礼物
              },
            ),
            _buildAttachmentOption(
              icon: Icons.payments,
              label: '转账',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 转账
              },
            ),
            _buildAttachmentOption(
              icon: Icons.mic,
              label: '语音输入',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 语音输入
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              icon: Icons.star,
              label: '收藏',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 打开收藏
              },
            ),
            _buildAttachmentOption(
              icon: Icons.person,
              label: '个人名片',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 分享个人名片
              },
            ),
            _buildAttachmentOption(
              icon: Icons.folder,
              label: '文件',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 选择文件
              },
            ),
            _buildAttachmentOption(
              icon: Icons.music_note,
              label: '音乐',
              onTap: () {
                setState(() => _showAttachmentOptions = false);
                // TODO: 分享音乐
              },
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage(ChatProvider chatProvider) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 预先获取所有需要的上下文数据，防止 await 期间 context 失效导致无法触发 AI 回复
    final apiProvider = context.read<ApiSettingsProvider>();
    final promptProvider = context.read<PromptSettingsProvider>();
    final contactProvider = context.read<ContactProvider>();
    final momentsProvider = context.read<MomentsProvider>();
    final chatId = widget.chatId;

    // 1. 发送用户消息
    await chatProvider.addMessage(chatId, text, MessageType.words, true);

    // 标记会话为已读
    await chatProvider.markSessionAsRead(chatId);

    _textController.clear();

    // 滚动到底部 (UI 操作，需要 mounted)
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom();
      });
    }

    // 2. 准备 AI 回复所需的参数
    final chat = chatProvider.getChat(chatId);
    if (chat == null) return;

    // 等待 API 设置初始化完成
    if (!apiProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final activePreset = apiProvider.activePreset;
    if (activePreset == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法找到可用的 API 预设，请在设置中配置 API'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

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
      orElse: () =>
          ContactMe(id: 'unknown', name: '我', info: '', avatarPath: null),
    );

    // 3. 调用 Provider 生成回复 (不 await，让其在后台运行)
    chatProvider.generateAiResponse(
      chatId: chatId,
      apiPreset: activePreset,
      promptConfig: promptProvider.config,
      role: role,
      me: me,
      onAddMoment: (content, user) {
        momentsProvider.addMomentFromChat(content, user);
      },
      onError: (error) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('生成回复失败'),
              content: SingleChildScrollView(
                child: Text(error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      },
      enableExtendedChat: chat.enableExtendedChat,
      delayedReplySeconds: promptProvider.delayedReplySeconds,
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    ChatMessage message,
  ) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final size = MediaQuery.of(context).size;

    // 计算菜单位置
    double left = position.dx;
    double top = position.dy;

    // 确保菜单不超出屏幕边界
    if (left + 280 > size.width) {
      left = size.width - 290;
    }
    if (left < 10) {
      left = 10;
    }

    // 优先显示在上方，如果上方空间不足则显示在下方
    if (top - 100 < 0) {
      top = top + 20;
    } else {
      top = top - 100;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: left,
            top: top,
            child: ChatContextMenu(
              onCopy: () {
                _removeOverlay();
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
              },
              onEdit: () {
                _removeOverlay();
                _showEditDialog(message);
              },
              onDelete: () {
                _removeOverlay();
                _deleteMessage(message.id);
              },
              onBacktrack: () {
                _removeOverlay();
                _showBacktrackDialog(message);
              },
              onMultiSelect: () {
                _removeOverlay();
                setState(() {
                  _isMultiSelectMode = true;
                  _selectedMessageIds.add(message.id);
                });
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _showEditDialog(ChatMessage message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().updateMessage(
                    message.id,
                    controller.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) {
    context.read<ChatProvider>().deleteMessage(messageId);
  }

  void _showBacktrackDialog(ChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final dontShowAgain = prefs.getBool('backtrack_dont_show_again') ?? false;

    if (dontShowAgain) {
      _performBacktrack(message);
      return;
    }

    bool isChecked = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('确认回溯？'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('回溯将删除该消息之后的所有消息，并重新生成回复。此操作不可撤销。'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          isChecked = value ?? false;
                        });
                      },
                    ),
                    const Text('下次不再提示'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (isChecked) {
                    await prefs.setBool('backtrack_dont_show_again', true);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    _performBacktrack(message);
                  }
                },
                child: const Text('确认回溯', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _performBacktrack(ChatMessage message) async {
    // 预先获取所有需要的上下文数据
    final chatProvider = context.read<ChatProvider>();
    final apiProvider = context.read<ApiSettingsProvider>();
    final promptProvider = context.read<PromptSettingsProvider>();
    final contactProvider = context.read<ContactProvider>();
    final momentsProvider = context.read<MomentsProvider>();
    final chatId = widget.chatId;

    await chatProvider.backtrack(chatId, message.timestamp);

    // 重新生成回复
    final chat = chatProvider.getChat(chatId);
    if (chat == null) return;

    final activePreset = apiProvider.activePreset;
    if (activePreset == null) return;

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
      orElse: () =>
          ContactMe(id: 'unknown', name: '我', info: '', avatarPath: null),
    );

    chatProvider.generateAiResponse(
      chatId: chatId,
      apiPreset: activePreset,
      promptConfig: promptProvider.config,
      role: role,
      me: me,
      onAddMoment: (content, user) {
        momentsProvider.addMomentFromChat(content, user);
      },
      onError: (error) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('生成回复失败'),
              content: SingleChildScrollView(
                child: Text(error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      },
      enableExtendedChat: chat.enableExtendedChat,
      delayedReplySeconds: 0, // 回溯后通常立即回复
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 26, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectBottomBar(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Color(0xFFDCDCDC), width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('已选择 ${_selectedMessageIds.length} 条消息'),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _selectedMessageIds.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('删除消息'),
                          content: Text(
                            '确定要删除选中的 ${_selectedMessageIds.length} 条消息吗？',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                chatProvider.deleteMessages(
                                  _selectedMessageIds.toList(),
                                );
                                setState(() {
                                  _isMultiSelectMode = false;
                                  _selectedMessageIds.clear();
                                });
                                Navigator.pop(context);
                              },
                              child: const Text(
                                '删除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final ChatMessage message;
  final ContactRole role;
  final ContactMe me;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(LongPressStartDetails) onLongPress;
  final Function(bool?) onSelectionChanged;

  const MessageItem({
    super.key,
    required this.message,
    required this.role,
    required this.me,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 跳过不显示的消息类型
    if (message.type == MessageType.memory ||
        message.type == MessageType.diary ||
        message.type == MessageType.moment ||
        message.type == MessageType.state) {
      return const SizedBox.shrink();
    }

    // 跳过内容为空的文本消息
    if ((message.type == MessageType.words ||
            message.type == MessageType.thought ||
            message.type == MessageType.action) &&
        message.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // 最大宽度 = 屏幕宽度 - 左右padding(24) - 两侧头像位置(40+8+40+8)
    final maxBubbleWidth = screenWidth - 120;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Row(
          children: [
            if (isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  shape: const CircleBorder(),
                ),
              ),
            Expanded(
              child: Row(
                mainAxisAlignment: message.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isMe) ...[
                    _buildAvatar(role.avatarPath, false),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onLongPressStart: onLongPress,
                    child: _buildMessageBubble(message, maxBubbleWidth),
                  ),
                  if (message.isMe) ...[
                    const SizedBox(width: 8),
                    _buildAvatar(me.avatarPath, true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? path, bool isMe) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isMe ? Colors.orange[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: path != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    color: isMe ? Colors.orange : Colors.grey,
                  );
                },
              ),
            )
          : Icon(Icons.person, color: isMe ? Colors.orange : Colors.grey),
    );
  }

  /// 根据消息类型构建对应的气泡
  Widget _buildMessageBubble(ChatMessage message, double maxBubbleWidth) {
    switch (message.type) {
      // 基础文本类型
      case MessageType.words:
      case MessageType.action:
      case MessageType.thought:
        return _ChatBubble(
          content: message.content,
          isMe: message.isMe,
          maxWidth: maxBubbleWidth,
          messageType: message.type,
        );

      // 多媒体类型
      case MessageType.emoji:
        return EmojiBubble(message: message, maxWidth: maxBubbleWidth);

      case MessageType.image:
        return Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              color: Colors.grey[300],
              height: 150,
              width: 100,
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        );

      case MessageType.location:
        return LocationBubble(message: message, maxWidth: maxBubbleWidth);

      // 资金往来类型
      case MessageType.redpacket:
        return RedpacketBubble(message: message, maxWidth: maxBubbleWidth);

      case MessageType.transfer:
        return TransferBubble(message: message, maxWidth: maxBubbleWidth);

      // 分享类型
      case MessageType.product:
        return ProductBubble(message: message, maxWidth: maxBubbleWidth);

      case MessageType.link:
        return LinkBubble(message: message, maxWidth: maxBubbleWidth);

      case MessageType.note:
        return NoteBubble(message: message, maxWidth: maxBubbleWidth);

      case MessageType.anniversary:
        return AnniversaryBubble(message: message, maxWidth: maxBubbleWidth);

      // 不应该显示的类型（已在外部过滤）
      case MessageType.memory:
      case MessageType.diary:
      case MessageType.moment:
      case MessageType.state:
        return const SizedBox.shrink();
    }
  }
}

// 自定义气泡Widget，带三角形指针
class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final double maxWidth;
  final MessageType messageType;

  const _ChatBubble({
    required this.content,
    required this.isMe,
    required this.maxWidth,
    required this.messageType,
  });

  @override
  Widget build(BuildContext context) {
    // 根据消息类型确定文字样式和气泡颜色
    TextStyle textStyle;
    Color bubbleColor;

    switch (messageType) {
      case MessageType.words:
        textStyle = const TextStyle(fontSize: 16, color: Colors.black);
        bubbleColor = isMe ? const Color(0xFF95EC69) : Colors.white;
        break;
      case MessageType.action:
        textStyle = const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontStyle: FontStyle.italic,
        );
        bubbleColor = isMe
            ? const Color(0xFF95EC69).withOpacity(0.8)
            : Colors.white.withOpacity(0.8);
        break;
      case MessageType.thought:
        textStyle = const TextStyle(fontSize: 15, color: Colors.grey);
        bubbleColor = isMe
            ? const Color(0xFF95EC69).withOpacity(0.6)
            : Colors.grey.withOpacity(0.1);
        break;
      default:
        textStyle = const TextStyle(fontSize: 16, color: Colors.black);
        bubbleColor = isMe ? const Color(0xFF95EC69) : Colors.white;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Stack(
        children: [
          // 三角形指针
          Positioned(
            top: 12,
            left: isMe ? null : 0,
            right: isMe ? 0 : null,
            child: CustomPaint(
              painter: _BubbleTrianglePainter(isMe: isMe, color: bubbleColor),
              size: const Size(6, 10),
            ),
          ),
          // 消息气泡
          Container(
            margin: EdgeInsets.only(left: isMe ? 0 : 6, right: isMe ? 6 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(content, style: textStyle),
          ),
        ],
      ),
    );
  }
}

// 绘制三角形指针
class _BubbleTrianglePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  _BubbleTrianglePainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      // 右侧三角形 (指向右边)
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      // 左侧三角形 (指向左边)
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
