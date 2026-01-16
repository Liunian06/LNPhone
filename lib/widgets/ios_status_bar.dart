import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/constants/ios_constants.dart';

/// iOS风格状态栏 - 精确模仿iOS 17状态栏
class IOSStatusBar extends StatefulWidget {
  final bool isDark;
  final bool showDynamicIsland;

  const IOSStatusBar({
    super.key,
    this.isDark = false,
    this.showDynamicIsland = false,
  });

  @override
  State<IOSStatusBar> createState() => _IOSStatusBarState();
}

class _IOSStatusBarState extends State<IOSStatusBar> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime() {
    final hour = _currentTime.hour;
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.black : Colors.white;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Container(
      height: topPadding + IOSConstants.statusBarHeight,
      padding: EdgeInsets.only(top: topPadding),
      child: Stack(
        children: [
          // 左侧时间
          Positioned(
            left: 28,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                _formatTime(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // 中间灵动岛 (仅在支持的设备显示)
          if (widget.showDynamicIsland)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(child: _DynamicIsland()),
            ),

          // 右侧状态图标
          Positioned(
            right: 28,
            top: 0,
            bottom: 0,
            child: Center(child: _StatusIcons(textColor: textColor)),
          ),
        ],
      ),
    );
  }
}

/// 灵动岛组件（已禁用）
class _DynamicIsland extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 灵动岛已移除，返回空组件
    return const SizedBox.shrink();
  }
}

/// 状态图标组件 - 信号、WiFi、电池
class _StatusIcons extends StatelessWidget {
  final Color textColor;

  const _StatusIcons({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 信号强度
        _SignalStrength(color: textColor),
        const SizedBox(width: 6),
        // WiFi
        _WifiIcon(color: textColor),
        const SizedBox(width: 6),
        // 电池
        _BatteryIndicator(color: textColor),
      ],
    );
  }
}

/// 信号强度图标
class _SignalStrength extends StatelessWidget {
  final Color color;

  const _SignalStrength({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 12,
      child: CustomPaint(painter: _SignalPainter(color: color, strength: 4)),
    );
  }
}

class _SignalPainter extends CustomPainter {
  final Color color;
  final int strength; // 1-4

  _SignalPainter({required this.color, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 5;
    final gap = size.width / 10;

    for (int i = 0; i < 4; i++) {
      final barHeight = size.height * (0.3 + 0.175 * i);
      final x = i * (barWidth + gap);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(1),
      );

      if (i < strength) {
        canvas.drawRRect(rect, paint);
      } else {
        canvas.drawRRect(rect, paint..color = color.withOpacity(0.3));
        paint.color = color;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// WiFi图标
class _WifiIcon extends StatelessWidget {
  final Color color;

  const _WifiIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(CupertinoIcons.wifi, size: 16, color: color);
  }
}

/// 电池指示器
class _BatteryIndicator extends StatelessWidget {
  final Color color;

  const _BatteryIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 13,
      child: CustomPaint(painter: _BatteryPainter(color: color, level: 0.85)),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final Color color;
  final double level; // 0.0 - 1.0

  _BatteryPainter({required this.color, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyWidth = size.width - 4;
    final bodyHeight = size.height;

    // 电池外框
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyWidth, bodyHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, outlinePaint);

    // 电池头
    final capPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyWidth + 1, bodyHeight * 0.25, 2.5, bodyHeight * 0.5),
      const Radius.circular(1),
    );
    canvas.drawRRect(capRect, capPaint);

    // 电池电量
    final fillPaint = Paint()
      ..color = level > 0.2 ? color : const Color(0xFFFF3B30)
      ..style = PaintingStyle.fill;

    final fillWidth = (bodyWidth - 4) * level;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, fillWidth, bodyHeight - 4),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 简化版状态栏 (没有灵动岛的旧设备)
class IOSStatusBarSimple extends StatefulWidget {
  final bool isDark;

  const IOSStatusBarSimple({super.key, this.isDark = false});

  @override
  State<IOSStatusBarSimple> createState() => _IOSStatusBarSimpleState();
}

class _IOSStatusBarSimpleState extends State<IOSStatusBarSimple> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime() {
    final hour = _currentTime.hour;
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.black : Colors.white;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Container(
      height: topPadding + 20,
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧运营商和信号
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  _SignalStrength(color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    '中国移动',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 中间时间
          Text(
            _formatTime(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          // 右侧状态
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _WifiIcon(color: textColor),
                  const SizedBox(width: 6),
                  _BatteryIndicator(color: textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
