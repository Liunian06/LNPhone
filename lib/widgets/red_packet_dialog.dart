import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';

class RedPacketDialog extends StatefulWidget {
  final ChatMessage message;
  final ContactRole role;
  final ContactMe me;
  final VoidCallback onOpen;

  const RedPacketDialog({
    super.key,
    required this.message,
    required this.role,
    required this.me,
    required this.onOpen,
  });

  @override
  State<RedPacketDialog> createState() => _RedPacketDialogState();
}

class _RedPacketDialogState extends State<RedPacketDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // 开红包按钮旋转动画
  late AnimationController _openController;
  late Animation<double> _rotationAnimation;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    // 初始化开红包3D翻转动画 (绕Y轴旋转两圈)
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 4 * math.pi).animate(
      CurvedAnimation(
        parent: _openController,
        curve: Curves.easeInOut,
      ),
    );

    _openController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onOpen();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _openController.dispose();
    super.dispose();
  }

  void _handleOpen() {
    if (_isOpening) return;
    setState(() {
      _isOpening = true;
    });
    _openController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final messageText = widget.message.metadata?['message'] ?? '恭喜发财，大吉大利';
    final senderName = widget.message.isMe ? widget.me.name : widget.role.name;
    final avatarPath =
        widget.message.isMe ? widget.me.avatarPath : widget.role.avatarPath;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: const Color(0xFFD95940), // 红包背景色
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: 300,
          height: 480,
          child: Stack(
            children: [
              // 上半部分圆弧背景
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 320,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE26048), // 稍浅一点的红色
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                      bottom: Radius.elliptical(300, 80),
                    ),
                  ),
                ),
              ),
              // 关闭按钮
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFFFFE0B2), size: 32),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      side:
                          const BorderSide(color: Color(0xFFFFE0B2), width: 1),
                    ),
                  ),
                ),
              ),
              // 内容
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // 头像
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.grey[300],
                      ),
                      child: avatarPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(avatarPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person,
                                      color: Colors.grey);
                                },
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // 发送者
                    Text(
                      '$senderName的红包',
                      style: const TextStyle(
                        color: Color(0xFFFFE0B2),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 祝福语
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        messageText,
                        style: const TextStyle(
                          color: Color(0xFFFFE0B2),
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    // 开红包按钮 - 3D硬币翻转效果
                    GestureDetector(
                      onTap: _handleOpen,
                      child: AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // 透视效果
                              ..rotateY(_rotationAnimation.value), // 绕Y轴3D旋转
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBC68E),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '開',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Serif',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
