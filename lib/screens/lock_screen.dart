import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/providers/system_state_provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/models/contact_model.dart';
import '../core/utils/time_formatter.dart';
import '../widgets/ios_time_widget.dart';
import '../widgets/ios_wallpaper.dart';
import 'home_screen.dart';

/// iOS风格锁屏界面
class LockScreen extends StatefulWidget {
  final VoidCallback? onUnlock;

  const LockScreen({super.key, this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  double _dragDistance = 0;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isUnlocking) return;

    setState(() {
      _dragDistance += details.delta.dy;
      if (_dragDistance > 0) _dragDistance = 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isUnlocking) return;

    final screenHeight = MediaQuery.of(context).size.height;

    if (_dragDistance < -screenHeight * 0.3 ||
        details.velocity.pixelsPerSecond.dy < -500) {
      _unlock();
    } else {
      setState(() {
        _dragDistance = 0;
      });
    }
  }

  void _unlock() {
    HapticFeedback.mediumImpact();
    setState(() => _isUnlocking = true);

    _slideController.forward().then((_) {
      if (widget.onUnlock != null) {
        widget.onUnlock!();
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const HomeScreen();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final progress = (_dragDistance / -screenHeight).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              // 背景 - 使用 provider 中的锁屏壁纸设置
              Positioned.fill(
                child: Consumer<SystemStateProvider>(
                  builder: (context, provider, _) {
                    // 使用有效壁纸路径 (包含随机风景逻辑)
                    final wallpaperPath =
                        provider.effectiveLockScreenWallpaperPath;
                    if (wallpaperPath != null) {
                      return Image.file(
                        File(wallpaperPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 加载失败时回退到预设壁纸
                          return _buildFallbackWallpaper(provider);
                        },
                      );
                    }

                    // 如果没有有效路径，使用预设壁纸
                    return _buildFallbackWallpaper(provider);
                  },
                ),
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    // 时间组件
                    const IOSTimeWidget(showDate: true, showSeconds: false),

                    const Spacer(),

                    // 通知区域 (模拟)
                    _buildNotificationArea(),

                    const Spacer(),

                    // 底部操作区
                    _buildBottomActions(),

                    // 滑动解锁提示
                    _buildUnlockHint(progress),

                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 30,
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

  Widget _buildNotificationArea() {
    return Consumer2<ChatProvider, ContactProvider>(
      builder: (context, chatProvider, contactProvider, child) {
        // 获取所有会话
        final sessions = chatProvider.chats;

        // 筛选出有未读消息的会话
        final activeSessions = sessions.where((session) {
          if (session.messages.isEmpty) return false;
          // 检查是否有未读消息
          return session.messages.any((m) => !m.isRead && !m.isMe);
        }).toList();

        // 按时间倒序
        activeSessions.sort((a, b) {
          final timeA = a.messages.last.timestamp;
          final timeB = b.messages.last.timestamp;
          return timeB.compareTo(timeA);
        });

        // 取前 3 条
        final displaySessions = activeSessions.take(3).toList();

        if (displaySessions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: displaySessions.map((session) {
              // 获取最新的未读消息
              final lastUnreadMsg = session.messages.lastWhere(
                (m) => !m.isRead && !m.isMe,
                orElse: () => session.messages.last,
              );

              final role = contactProvider.roles.firstWhere(
                (r) => r.id == session.roleId,
                orElse: () =>
                    ContactRole(id: 'unknown', name: '未知用户', description: ''),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IOSLockScreenNotification(
                  appName: '微信',
                  appIcon: CupertinoIcons.chat_bubble_2_fill,
                  title: role.name,
                  message: lastUnreadMsg.displayText,
                  time: TimeFormatter.formatMomentsTime(
                    DateTime.fromMillisecondsSinceEpoch(
                      lastUnreadMsg.timestamp,
                    ),
                  ),
                  iconColor: const Color(0xFF07C160), // 微信绿
                  onTap: () {
                    // 标记该会话为已读
                    chatProvider.markSessionAsRead(session.id);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 手电筒
          _buildQuickAction(
            icon: CupertinoIcons.bolt_fill,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          // 相机
          _buildQuickAction(
            icon: CupertinoIcons.camera_fill,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockHint(double progress) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: 1 - progress,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 5,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const Text(
            '向上滑动解锁',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建备用壁纸（当每日壁纸和自定义壁纸都加载失败时使用）
  Widget _buildFallbackWallpaper(SystemStateProvider provider) {
    final index = provider.lockScreenWallpaperIndex
        .clamp(0, WallpaperStyle.values.length - 1);
    return IOSWallpaper(
      style: WallpaperStyle.values[index],
      enableParallax: false,
      child: const SizedBox.expand(),
    );
  }
}
