import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/app_model.dart';

/// iOS风格多任务切换器
class IOSAppSwitcher extends StatefulWidget {
  final List<AppSnapshot> runningApps;
  final VoidCallback? onClose;
  final Function(AppSnapshot)? onAppSelected;
  final Function(AppSnapshot)? onAppClosed;

  const IOSAppSwitcher({
    super.key,
    required this.runningApps,
    this.onClose,
    this.onAppSelected,
    this.onAppClosed,
  });

  @override
  State<IOSAppSwitcher> createState() => _IOSAppSwitcherState();
}

class _IOSAppSwitcherState extends State<IOSAppSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _pageController = PageController(viewportFraction: 0.75, initialPage: 0);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  void _selectApp(AppSnapshot app) {
    HapticFeedback.mediumImpact();
    widget.onAppSelected?.call(app);
  }

  void _closeApp(AppSnapshot app) {
    HapticFeedback.mediumImpact();
    widget.onAppClosed?.call(app);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: 0.5 * _controller.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // 应用卡片
                    Expanded(child: _buildAppCards()),
                    // 底部指示器
                    _buildBottomIndicator(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppCards() {
    if (widget.runningApps.isEmpty) {
      return Center(
        child: Text(
          '没有运行中的应用',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 18,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.runningApps.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemBuilder: (context, index) {
        final app = widget.runningApps[index];
        return _AppCard(
          app: app,
          isActive: index == _currentPage,
          onTap: () => _selectApp(app),
          onSwipeUp: () => _closeApp(app),
        );
      },
    );
  }

  Widget _buildBottomIndicator() {
    return Container(
      width: 134,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

/// 应用快照数据
class AppSnapshot {
  final String id;
  final String name;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Widget? preview;

  const AppSnapshot({
    required this.id,
    required this.name,
    this.icon,
    this.gradientColors,
    this.preview,
  });

  factory AppSnapshot.fromAppModel(AppModel app) {
    return AppSnapshot(
      id: app.id,
      name: app.name,
      icon: app.icon,
      gradientColors: app.gradientColors,
    );
  }
}

/// 应用卡片
class _AppCard extends StatefulWidget {
  final AppSnapshot app;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeUp;

  const _AppCard({
    required this.app,
    required this.isActive,
    this.onTap,
    this.onSwipeUp,
  });

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  double _dragOffset = 0;
  bool _isDragging = false;

  void _handleVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset > 0) _dragOffset = 0;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    if (_dragOffset < -150 || details.velocity.pixelsPerSecond.dy < -500) {
      widget.onSwipeUp?.call();
    }

    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.isActive ? 1.0 : 0.9;
    final opacity = 1.0 + (_dragOffset / 300).clamp(-0.5, 0.0);

    return GestureDetector(
      onTap: widget.onTap,
      onVerticalDragStart: _handleVerticalDragStart,
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 100),
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                children: [
                  // 应用图标和名称
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors:
                                widget.app.gradientColors ??
                                [Colors.grey, Colors.grey],
                          ),
                        ),
                        child: Icon(
                          widget.app.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.app.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 应用预览
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: widget.app.preview ?? _buildPlaceholder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (widget.app.gradientColors?.first ?? Colors.grey).withValues(
              alpha: 0.3,
            ),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          widget.app.icon,
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// 显示多任务切换器
void showIOSAppSwitcher(
  BuildContext context, {
  required List<AppSnapshot> runningApps,
  Function(AppSnapshot)? onAppSelected,
  Function(AppSnapshot)? onAppClosed,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'App Switcher',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) {
      return IOSAppSwitcher(
        runningApps: runningApps,
        onClose: () => Navigator.of(context).pop(),
        onAppSelected: (app) {
          Navigator.of(context).pop();
          onAppSelected?.call(app);
        },
        onAppClosed: onAppClosed,
      );
    },
  );
}
