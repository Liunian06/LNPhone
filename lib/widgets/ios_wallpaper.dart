import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// iOS风格动态壁纸
class IOSWallpaper extends StatefulWidget {
  final Widget child;
  final WallpaperStyle style;
  final bool enableParallax;
  final String? customImagePath;

  const IOSWallpaper({
    super.key,
    required this.child,
    this.style = WallpaperStyle.gradient1,
    this.enableParallax = true,
    this.customImagePath,
  });

  @override
  State<IOSWallpaper> createState() => _IOSWallpaperState();
}

class _IOSWallpaperState extends State<IOSWallpaper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _parallaxOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // 壁纸背景 - 固定，不可拖动
            _buildWallpaper(),
            // 内容
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildWallpaper() {
    // 如果有自定义壁纸，优先使用
    if (widget.customImagePath != null) {
      return _buildCustomWallpaper();
    }

    switch (widget.style) {
      case WallpaperStyle.gradient1:
        return _buildGradient1();
      case WallpaperStyle.gradient2:
        return _buildGradient2();
      case WallpaperStyle.gradient3:
        return _buildGradient3();
      case WallpaperStyle.dark:
        return _buildDarkWallpaper();
      case WallpaperStyle.aurora:
        return _buildAuroraWallpaper();
      case WallpaperStyle.mesh:
        return _buildMeshGradient();
    }
  }

  // 自定义图片壁纸
  Widget _buildCustomWallpaper() {
    final file = File(widget.customImagePath!);
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // 如果加载失败，返回默认壁纸
        return _buildGradient1();
      },
    );
  }

  // iOS 17 经典深蓝紫色渐变
  Widget _buildGradient1() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
            Color(0xFF533483),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 添加一些光斑效果
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366f1).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8b5cf6).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 橙红暖色渐变
  Widget _buildGradient2() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFfb923c),
            Color(0xFFf97316),
            Color(0xFFea580c),
            Color(0xFFdc2626),
            Color(0xFF991b1b),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }

  // 青绿色海洋渐变
  Widget _buildGradient3() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0d9488),
            Color(0xFF0891b2),
            Color(0xFF0284c7),
            Color(0xFF1d4ed8),
          ],
        ),
      ),
    );
  }

  // 深色壁纸
  Widget _buildDarkWallpaper() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1c1c1e), Color(0xFF000000)],
        ),
      ),
    );
  }

  // 极光效果
  Widget _buildAuroraWallpaper() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF0a0a1a)),
        CustomPaint(painter: _AuroraPainter(animation: _controller)),
      ],
    );
  }

  // 网格渐变
  Widget _buildMeshGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 100,
            left: 50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFfb923c).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 30,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22d3ee).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 极光绘制器
class _AuroraPainter extends CustomPainter {
  final Animation<double> animation;

  _AuroraPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final time = animation.value * 2 * math.pi;

    // 绘制多个极光波浪
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final color = [
        const Color(0xFF22d3ee),
        const Color(0xFF34d399),
        const Color(0xFF6366f1),
      ][i];

      path.moveTo(0, size.height * 0.5);

      for (double x = 0; x <= size.width; x += 10) {
        final y =
            size.height * 0.4 +
            math.sin(x * 0.01 + time + i * 2) * 100 +
            math.sin(x * 0.02 - time * 0.5) * 50;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.color = color.withOpacity(0.15);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 壁纸样式枚举
enum WallpaperStyle {
  gradient1, // 深蓝紫色
  gradient2, // 橙红暖色
  gradient3, // 青绿海洋
  dark, // 深色
  aurora, // 极光
  mesh, // 网格渐变
}
