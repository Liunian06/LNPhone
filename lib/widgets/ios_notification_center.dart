import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'ios_time_widget.dart';

/// iOS风格通知中心
class IOSNotificationCenter extends StatefulWidget {
  final VoidCallback? onClose;

  const IOSNotificationCenter({super.key, this.onClose});

  @override
  State<IOSNotificationCenter> createState() => _IOSNotificationCenterState();
}

class _IOSNotificationCenterState extends State<IOSNotificationCenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < -200) {
          _close();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                // 背景模糊
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: _fadeAnimation.value * 0.3,
                      ),
                    ),
                  ),
                ),
                // 内容
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 时间日期
          const IOSTimeWidget(showDate: true, showSeconds: false),
          const SizedBox(height: 30),

          // 通知列表
          Expanded(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildNotificationGroup(
                      title: '今天',
                      notifications: [
                        _NotificationData(
                          appName: 'AI 助手',
                          appIcon: CupertinoIcons.sparkles,
                          iconColor: const Color(0xFF5856D6),
                          title: '智能提醒',
                          message: '您今天有3个待办事项需要处理',
                          time: '10分钟前',
                        ),
                        _NotificationData(
                          appName: '信息',
                          appIcon: CupertinoIcons.chat_bubble_fill,
                          iconColor: const Color(0xFF34C759),
                          title: '新消息',
                          message: '您有2条未读消息',
                          time: '30分钟前',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationGroup(
                      title: '昨天',
                      notifications: [
                        _NotificationData(
                          appName: '邮件',
                          appIcon: CupertinoIcons.mail_solid,
                          iconColor: const Color(0xFF007AFF),
                          title: '系统通知',
                          message: '欢迎使用 LnPhone AI Native 系统',
                          time: '昨天',
                        ),
                        _NotificationData(
                          appName: '日历',
                          appIcon: CupertinoIcons.calendar,
                          iconColor: const Color(0xFFFF3B30),
                          title: '日程提醒',
                          message: '明天有重要会议',
                          time: '昨天',
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroup({
    required String title,
    required List<_NotificationData> notifications,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...notifications.map((notification) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NotificationCard(data: notification),
          );
        }),
      ],
    );
  }
}

class _NotificationData {
  final String appName;
  final IconData appIcon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;

  _NotificationData({
    required this.appName,
    required this.appIcon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationData data;

  const _NotificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 应用图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data.iconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.appIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.appName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          data.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}

/// 显示通知中心的辅助方法
void showIOSNotificationCenter(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return IOSNotificationCenter(
          onClose: () => Navigator.of(context).pop(),
        );
      },
    ),
  );
}
