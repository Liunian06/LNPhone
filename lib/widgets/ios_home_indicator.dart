import 'package:flutter/material.dart';

/// iOS风格底部Home指示器
class IOSHomeIndicator extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final EdgeInsets margin;

  const IOSHomeIndicator({
    super.key,
    this.color = Colors.white,
    this.width = 134,
    this.height = 5,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// 带手势处理的Home指示器
class IOSHomeIndicatorGesture extends StatefulWidget {
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Color color;

  const IOSHomeIndicatorGesture({
    super.key,
    this.onSwipeUp,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.color = Colors.white,
  });

  @override
  State<IOSHomeIndicatorGesture> createState() =>
      _IOSHomeIndicatorGestureState();
}

class _IOSHomeIndicatorGestureState extends State<IOSHomeIndicatorGesture> {
  double _dragStartX = 0;
  double _dragStartY = 0;

  void _handlePanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final velocityY = details.velocity.pixelsPerSecond.dy;

    if (velocityY < -500) {
      // 向上滑动 - 返回主屏幕或显示多任务
      widget.onSwipeUp?.call();
    } else if (velocityX.abs() > 500) {
      if (velocityX < 0) {
        // 向左滑动 - 切换到下一个应用
        widget.onSwipeLeft?.call();
      } else {
        // 向右滑动 - 切换到上一个应用
        widget.onSwipeRight?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        child: IOSHomeIndicator(color: widget.color),
      ),
    );
  }
}
