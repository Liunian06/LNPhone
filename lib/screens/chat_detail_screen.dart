import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/database/database.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/providers/api_settings_provider.dart';
import '../core/providers/prompt_settings_provider.dart';
import '../core/providers/moments_provider.dart';
import '../core/providers/memory_provider.dart';
import '../core/services/llm_service.dart';
import '../core/services/notification_service.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/models/moments_model.dart';
import '../core/theme/app_theme.dart';
import '../widgets/message_bubbles.dart';
import '../widgets/chat_context_menu.dart';
import '../widgets/red_packet_dialog.dart';
import 'chat_settings_screen.dart';
import 'red_packet_result_screen.dart';
import 'transfer_receive_screen.dart';
import 'transfer_result_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIds = {};
  bool _showAttachmentOptions = false; // 控制是否显示附件选项
  int _lastMessageCount = 0;
  ChatMessage? _replyingMessage; // 当前正在引用的消息

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
    _focusNode.dispose();
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
            backgroundColor: context.chatBackground,
            appBar: AppBar(
              backgroundColor: backgroundImage != null
                  ? Colors.transparent
                  : context.appBarBackground,
              elevation: 0,
              leading: _isMultiSelectMode
                  ? TextButton(
                      onPressed: () {
                        setState(() {
                          _isMultiSelectMode = false;
                          _selectedMessageIds.clear();
                        });
                      },
                      child: Text(
                        '取消',
                        style: TextStyle(
                            color: context.primaryTextColor, fontSize: 16),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: context.primaryTextColor,
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
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (currentState != null && currentState.isNotEmpty)
                        Text(
                          currentState,
                          style: TextStyle(
                            color: context.secondaryTextColor,
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
                  icon: Icon(Icons.more_horiz, color: context.primaryTextColor),
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
                        final currentMessage = chat.messages[messageIndex];

                        // 判断是否需要显示时间戳
                        // 由于是reverse列表，index=0是最新消息，我们需要检查下一条消息（更早的消息）
                        bool showTimestamp = false;
                        if (messageIndex == 0) {
                          // 第一条消息（最早的消息）总是显示时间戳
                          showTimestamp = true;
                        } else {
                          final previousMessage =
                              chat.messages[messageIndex - 1];
                          final currentTime =
                              DateTime.fromMillisecondsSinceEpoch(
                                  currentMessage.timestamp);
                          final previousTime =
                              DateTime.fromMillisecondsSinceEpoch(
                                  previousMessage.timestamp);
                          final timeDiff = currentTime.difference(previousTime);
                          // 如果与上一条消息间隔超过5分钟，显示时间戳
                          if (timeDiff.inMinutes.abs() >= 5) {
                            showTimestamp = true;
                          }
                        }

                        return Column(
                          children: [
                            // 时间戳气泡（显示在消息上方，但由于reverse，需要放在消息下方）
                            if (showTimestamp)
                              _TimestampBubble(
                                  timestamp: currentMessage.timestamp),
                            MessageItem(
                              key: ValueKey(currentMessage.id),
                              message: currentMessage,
                              role: role,
                              me: me,
                              isMultiSelectMode: _isMultiSelectMode,
                              isSelected: _selectedMessageIds
                                  .contains(currentMessage.id),
                              onTap: () {
                                if (_isMultiSelectMode) {
                                  setState(() {
                                    if (_selectedMessageIds
                                        .contains(currentMessage.id)) {
                                      _selectedMessageIds
                                          .remove(currentMessage.id);
                                    } else {
                                      _selectedMessageIds
                                          .add(currentMessage.id);
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
                                  _showContextMenu(context,
                                      details.globalPosition, currentMessage);
                                }
                              },
                              onSelectionChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedMessageIds.add(currentMessage.id);
                                  } else {
                                    _selectedMessageIds
                                        .remove(currentMessage.id);
                                  }
                                });
                              },
                              onBubbleTap: (msg, r, m) {
                                if (msg.type == MessageType.redpacket) {
                                  _handleRedPacketTap(context, msg, r, m);
                                } else if (msg.type == MessageType.transfer) {
                                  _handleTransferTap(context, msg, r, m);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_isMultiSelectMode)
                    _buildMultiSelectBottomBar(chatProvider)
                  else
                    _buildInputArea(chatProvider, role, me),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleRedPacketTap(BuildContext context, ChatMessage message,
      ContactRole role, ContactMe me) {
    final status = message.metadata?['status'] ?? 'unclaimed';

    if (status == 'opened') {
      // 已领取，直接跳转结果页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RedPacketResultScreen(
            message: message,
            role: role,
            me: me,
          ),
        ),
      );
    } else {
      // 未领取，显示开红包弹窗
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => RedPacketDialog(
          message: message,
          role: role,
          me: me,
          onOpen: () {
            // 更新消息状态为已领取
            final chatProvider = context.read<ChatProvider>();
            final newMetadata =
                Map<String, dynamic>.from(message.metadata ?? {});
            newMetadata['status'] = 'opened';

            chatProvider.updateMessageMetadata(message.id, newMetadata);

            Navigator.pop(context); // 关闭弹窗
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RedPacketResultScreen(
                  message: message,
                  role: role,
                  me: me,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _handleTransferTap(BuildContext context, ChatMessage message,
      ContactRole role, ContactMe me) {
    final status = message.metadata?['status'] ?? 'pending';

    if (status == 'accepted') {
      // 已收款，跳转结果页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferResultScreen(message: message),
        ),
      );
    } else {
      // 待收款，跳转收款页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferReceiveScreen(
            message: message,
            role: role,
            me: me,
            onAccept: (receiveContext) {
              // 更新消息状态为已收款
              final chatProvider = receiveContext.read<ChatProvider>();
              final newMetadata =
                  Map<String, dynamic>.from(message.metadata ?? {});
              newMetadata['status'] = 'accepted';
              chatProvider.updateMessageMetadata(message.id, newMetadata);

              // 跳转结果页
              Navigator.pushReplacement(
                receiveContext,
                MaterialPageRoute(
                  builder: (context) => TransferResultScreen(message: message),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  // _buildMessageItem, _buildMessageBubble, _buildAvatar methods removed and refactored into MessageItem class

  Widget _buildInputArea(
      ChatProvider chatProvider, ContactRole role, ContactMe me) {
    return Container(
      decoration: BoxDecoration(
        color: context.inputBackground,
        border:
            Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
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
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: context.isDarkMode
                              ? const Color(0xFF48484A)
                              : Colors.transparent,
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: TextStyle(color: context.primaryTextColor),
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          filled: false,
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          _sendMessage(chatProvider);
                          // 发送后重新请求焦点，保持输入法不关闭
                          _focusNode.requestFocus();
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: context.primaryTextColor,
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
                      color: context.primaryTextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showAttachmentOptions = !_showAttachmentOptions;
                      });
                    },
                  ),
                  if (chatProvider
                          .getChat(widget.chatId)
                          ?.enableIndependentSendButton ??
                      false) ...[
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, child) {
                        final isEmpty = value.text.trim().isEmpty;
                        return GestureDetector(
                          onTap: () {
                            if (isEmpty) {
                              // 续写 - 强制立即回复
                              _sendMessage(chatProvider,
                                  isContinue: true, forceImmediate: true);
                            } else {
                              // 发送 - 仍然使用延迟回复（因为用户可能还有下一条消息）
                              _sendMessage(chatProvider, forceImmediate: false);
                            }
                          },
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF07C160),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEmpty ? '续写' : '发送',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            // 引用预览区域
            if (_replyingMessage != null)
              Builder(
                builder: (context) {
                  // 从最新的消息列表中获取被引用消息
                  // 避免因 Consumer2 重建导致 _replyingMessage 指向过时对象
                  final chat = chatProvider.getChat(widget.chatId);
                  final freshMessage = chat?.messages.firstWhere(
                    (m) => m.id == _replyingMessage!.id,
                    orElse: () => _replyingMessage!,
                  );

                  final targetMessage = freshMessage ?? _replyingMessage!;
                  final senderName = _resolveSenderName(
                    isMe: targetMessage.isMe,
                    sender: targetMessage.sender,
                    me: me,
                    role: role,
                  );

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: context.surfaceColor.withOpacity(0.5),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          color: context.primaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '回复 $senderName',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _replyingMessage!.displayText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 18, color: context.secondaryTextColor),
                          onPressed: () {
                            setState(() {
                              _replyingMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
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

  void _sendMessage(ChatProvider chatProvider,
      {bool isContinue = false, bool forceImmediate = false}) async {
    final text = _textController.text.trim();
    if (text.isEmpty && !isContinue) return;

    // 预先获取所有需要的上下文数据，防止 await 期间 context 失效导致无法触发 AI 回复
    final apiProvider = context.read<ApiSettingsProvider>();
    final promptProvider = context.read<PromptSettingsProvider>();
    final contactProvider = context.read<ContactProvider>();
    final momentsProvider = context.read<MomentsProvider>();
    final memoryProvider = context.read<MemoryProvider>();
    final chatId = widget.chatId;

    // 提前获取用户人设信息（用于发送消息和引用）
    final currentChat = chatProvider.getChat(chatId);
    final currentMe = contactProvider.meList.firstWhere(
      (m) => m.id == currentChat?.meId,
      orElse: () =>
          ContactMe(id: 'unknown', name: '我', info: '', avatarPath: null),
    );
    final currentRole = contactProvider.roles.firstWhere(
      (r) => r.id == currentChat?.roleId,
      orElse: () => ContactRole(
        id: 'unknown',
        name: '未知用户',
        description: '',
        avatarPath: null,
      ),
    );

    // 1. 发送用户消息
    if (text.isNotEmpty) {
      Map<String, dynamic>? metadata;
      if (_replyingMessage != null) {
        final quotedSenderName = _resolveSenderName(
          isMe: _replyingMessage!.isMe,
          sender: _replyingMessage!.sender,
          me: currentMe,
          role: currentRole,
        );

        metadata = {
          'quote': {
            'id': _replyingMessage!.id,
            'content': _replyingMessage!.content,
            'sender': quotedSenderName, // 使用 sender 字段存储发送者名称
            'isMe': _replyingMessage!.isMe, // 保持兼容性
          }
        };
      }

      await chatProvider.addMessage(
        chatId,
        text,
        MessageType.words,
        true,
        metadata: metadata,
        sender: currentMe.name, // 用户消息使用用户人设名
      );

      // 标记会话为已读
      await chatProvider.markSessionAsRead(chatId);

      _textController.clear();
      setState(() {
        _replyingMessage = null; // 清除引用状态
      });

      // 滚动到底部 (UI 操作，需要 mounted)
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });
      }
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
      delayedReplySeconds:
          forceImmediate ? 0 : promptProvider.delayedReplySeconds,
      roleMemories: memoryProvider
          .getMemoriesForRole(role.id)
          .map((m) => m.content)
          .toList(),
      onAddMemory: (content, categoryStr) {
        memoryProvider.addMemoryFromAiResponse(
          roleId: role.id,
          content: content,
          sourceSessionId: chatId,
          categoryStr: categoryStr,
        );
      },
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
              onReply: () {
                _removeOverlay();
                setState(() {
                  _replyingMessage = message;
                });
                // 聚焦输入框
                _focusNode.requestFocus();
                // 延迟一下再聚焦，确保UI更新
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _focusNode.requestFocus();
                  }
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

  /// 显示回溯确认对话框
  /// 注意：所有设置现在从数据库读取，SharedPreferences 已被弃用
  void _showBacktrackDialog(ChatMessage message) async {
    final db = AppDatabase();
    final dontShowAgain =
        await db.getSettingBool('backtrack_dont_show_again') ?? false;

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
                    final db = AppDatabase();
                    await db.setSettingBool('backtrack_dont_show_again', true);
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
    final memoryProvider = context.read<MemoryProvider>();
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
      roleMemories: memoryProvider
          .getMemoriesForRole(role.id)
          .map((m) => m.content)
          .toList(),
      onAddMemory: (content, categoryStr) {
        memoryProvider.addMemoryFromAiResponse(
          roleId: role.id,
          content: content,
          sourceSessionId: chatId,
          categoryStr: categoryStr,
        );
      },
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
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 26, color: context.primaryTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: context.primaryTextColor),
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
      decoration: BoxDecoration(
        color: context.inputBackground,
        border:
            Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '已选择 ${_selectedMessageIds.length} 条消息',
              style: TextStyle(color: context.primaryTextColor),
            ),
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
  final Function(ChatMessage, ContactRole, ContactMe)? onBubbleTap;

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
    this.onBubbleTap,
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

  void _handleRedPacketTap(BuildContext context, ChatMessage message,
      ContactRole role, ContactMe me) {
    final status = message.metadata?['status'] ?? 'unclaimed';

    if (status == 'opened') {
      // 已领取，直接跳转结果页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RedPacketResultScreen(
            message: message,
            role: role,
            me: me,
          ),
        ),
      );
    } else {
      // 未领取，显示开红包弹窗
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => RedPacketDialog(
          message: message,
          role: role,
          me: me,
          onOpen: () {
            // 更新消息状态为已领取
            final chatProvider = context.read<ChatProvider>();
            final newMetadata =
                Map<String, dynamic>.from(message.metadata ?? {});
            newMetadata['status'] = 'opened';

            // 模拟更新数据库
            // 注意：这里应该调用 updateMessageMetadata，但目前只有 updateMessageContent
            // 我们暂时通过 updateMessageContent 触发刷新，实际应该扩展 Provider
            // 为了演示效果，我们假设 updateMessage 支持 metadata 更新
            // 由于 ChatProvider 没有直接更新 metadata 的方法，我们需要扩展它
            // 这里暂时用一个变通方法：重新插入一条同样 ID 的消息（会覆盖吗？Drift 的 insertOrReplace）
            // 或者我们添加一个 updateMessageMetadata 方法到 ChatProvider

            // 既然不能直接修改 metadata，我们先在内存中修改，然后跳转
            // 实际项目中需要在 ChatProvider 添加 updateMessageMetadata 方法

            // 临时方案：调用 updateMessageContent 触发刷新，虽然内容没变
            // 更好的方案是请求添加 updateMessageMetadata

            // 假设我们已经有了 updateMessageMetadata
            chatProvider.updateMessageMetadata(message.id, newMetadata);

            Navigator.pop(context); // 关闭弹窗
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RedPacketResultScreen(
                  message: message,
                  role: role,
                  me: me,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _handleTransferTap(BuildContext context, ChatMessage message,
      ContactRole role, ContactMe me) {
    final status = message.metadata?['status'] ?? 'pending';

    if (status == 'accepted') {
      // 已收款，跳转结果页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferResultScreen(message: message),
        ),
      );
    } else {
      // 待收款，跳转收款页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferReceiveScreen(
            message: message,
            role: role,
            me: me,
            onAccept: (receiveContext) {
              // 更新消息状态为已收款
              final chatProvider = receiveContext.read<ChatProvider>();
              final newMetadata =
                  Map<String, dynamic>.from(message.metadata ?? {});
              newMetadata['status'] = 'accepted';
              chatProvider.updateMessageMetadata(message.id, newMetadata);

              // 跳转结果页
              Navigator.pushReplacement(
                receiveContext,
                MaterialPageRoute(
                  builder: (context) => TransferResultScreen(message: message),
                ),
              );
            },
          ),
        ),
      );
    }
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
    Widget bubbleContent;
    switch (message.type) {
      // 基础文本类型
      case MessageType.words:
      case MessageType.action:
      case MessageType.thought:
        bubbleContent = _ChatBubble(
          content: message.content,
          isMe: message.isMe,
          maxWidth: maxBubbleWidth,
          messageType: message.type,
        );
        break;

      // 多媒体类型
      case MessageType.emoji:
        bubbleContent = EmojiBubble(message: message, maxWidth: maxBubbleWidth);
        break;

      case MessageType.image:
        bubbleContent = Container(
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
        break;

      case MessageType.location:
        bubbleContent =
            LocationBubble(message: message, maxWidth: maxBubbleWidth);
        break;

      // 资金往来类型
      case MessageType.redpacket:
        bubbleContent = GestureDetector(
          onTap: () {
            if (isMultiSelectMode) {
              onTap();
              return;
            }
            onBubbleTap?.call(message, role, me);
          },
          child: RedpacketBubble(message: message, maxWidth: maxBubbleWidth),
        );
        break;

      case MessageType.transfer:
        bubbleContent = GestureDetector(
          onTap: () {
            if (isMultiSelectMode) {
              onTap();
              return;
            }
            onBubbleTap?.call(message, role, me);
          },
          child: TransferBubble(message: message, maxWidth: maxBubbleWidth),
        );
        break;

      // 分享类型
      case MessageType.product:
        bubbleContent =
            ProductBubble(message: message, maxWidth: maxBubbleWidth);
        break;

      case MessageType.link:
        bubbleContent = LinkBubble(message: message, maxWidth: maxBubbleWidth);
        break;

      case MessageType.note:
        bubbleContent = NoteBubble(message: message, maxWidth: maxBubbleWidth);
        break;

      case MessageType.anniversary:
        bubbleContent =
            AnniversaryBubble(message: message, maxWidth: maxBubbleWidth);
        break;

      // 不应该显示的类型（已在外部过滤）
      case MessageType.memory:
      case MessageType.diary:
      case MessageType.moment:
      case MessageType.state:
        return const SizedBox.shrink();
    }

    // 检查是否有引用消息
    if (message.metadata != null && message.metadata!.containsKey('quote')) {
      try {
        final quote = message.metadata!['quote'] as Map<String, dynamic>;
        final quoteContent = quote['content'] as String;

        // 解析引用数据
        final bool isQuoteMe = quote['isMe'] == true;
        final String? quoteSender = quote['sender'] as String?;
        // 兼容旧数据 'name'
        final String? legacyName = quote['name'] as String?;

        // 如果有 legacyName 且没有 sender，暂时用 legacyName 作为 sender 传入
        // 但 _resolveSenderName 会优先处理 isMe
        final String quoteName = _resolveSenderName(
          isMe: isQuoteMe,
          sender: quoteSender ?? legacyName,
          me: me,
          role: role,
        );

        return Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 实际消息气泡
            bubbleContent,
            // 引用内容气泡
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$quoteName: ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: quoteContent,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      } catch (e) {
        // 忽略引用解析错误
      }
    }

    return bubbleContent;
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
    // 根据消息类型和主题模式确定文字样式和气泡颜色
    TextStyle textStyle;
    Color bubbleColor;

    // 使用主题扩展方法获取气泡颜色
    final myBubble = context.myMessageBubbleColor;
    final otherBubble = context.otherMessageBubbleColor;
    final myTextColor = context.myMessageTextColor;
    final otherTextColor = context.otherMessageTextColor;

    switch (messageType) {
      case MessageType.words:
        textStyle =
            TextStyle(fontSize: 16, color: isMe ? myTextColor : otherTextColor);
        bubbleColor = isMe ? myBubble : otherBubble;
        break;
      case MessageType.action:
        textStyle = TextStyle(
          fontSize: 15,
          color: (isMe ? myTextColor : otherTextColor).withOpacity(0.87),
          fontStyle: FontStyle.italic,
        );
        bubbleColor = (isMe ? myBubble : otherBubble).withOpacity(0.8);
        break;
      case MessageType.thought:
        textStyle = TextStyle(fontSize: 15, color: context.secondaryTextColor);
        bubbleColor = (isMe ? myBubble : otherBubble).withOpacity(0.6);
        break;
      default:
        textStyle =
            TextStyle(fontSize: 16, color: isMe ? myTextColor : otherTextColor);
        bubbleColor = isMe ? myBubble : otherBubble;
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

/// 时间戳气泡Widget
class _TimestampBubble extends StatelessWidget {
  final int timestamp;

  const _TimestampBubble({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String timeText;

    if (messageDate == today) {
      // 今天：显示 HH:mm
      timeText =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // 昨天
      timeText =
          '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 2))) {
      // 前天
      timeText =
          '前天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 更早的日期：显示 MM月dd日
      timeText =
          '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: context.secondaryTextColor,
          ),
        ),
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

/// 统一解析发送者名称的逻辑
///
/// 逻辑优先级：
/// 1. 如果 [isMe] 为 true，强制返回 [me.name]（当前用户名称）。
///    这确保了即使历史数据中 sender 字段存储了错误的名字，
///    只要消息是用户发的，就显示当前正确的用户名称。
/// 2. 如果 [sender] 存在且不为空，返回 [sender]。
/// 3. 否则返回 [role.name]（当前角色名称）。
String _resolveSenderName({
  required bool isMe,
  required String? sender,
  required ContactMe me,
  required ContactRole role,
}) {
  if (isMe) {
    return me.name;
  }
  if (sender != null && sender.isNotEmpty) {
    return sender;
  }
  return role.name;
}
