import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/ios_constants.dart';

/// iOS风格大时间组件 - 锁屏界面使用
class IOSTimeWidget extends StatefulWidget {
  final bool showDate;
  final bool showSeconds;
  final Color? textColor;

  const IOSTimeWidget({
    super.key,
    this.showDate = true,
    this.showSeconds = false,
    this.textColor,
  });

  @override
  State<IOSTimeWidget> createState() => _IOSTimeWidgetState();
}

class _IOSTimeWidgetState extends State<IOSTimeWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final duration = widget.showSeconds
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
    _timer = Timer.periodic(duration, (timer) {
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
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    if (widget.showSeconds) {
      final second = _currentTime.second.toString().padLeft(2, '0');
      return '$hour:$minute:$second';
    }
    return '$hour:$minute';
  }

  String _formatDate() {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[_currentTime.weekday - 1];
    final month = _currentTime.month;
    final day = _currentTime.day;
    return '$month月$day日 $weekday';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? IOSColors.timeText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 日期
        if (widget.showDate)
          Text(
            _formatDate(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        if (widget.showDate) const SizedBox(height: 8),
        // 时间
        Text(
          _formatTime(),
          style: TextStyle(
            fontSize: 86,
            fontWeight: FontWeight.w200,
            color: textColor,
            letterSpacing: -3,
            height: 1.0,
            fontFamily: '.SF Pro Display',
          ),
        ),
      ],
    );
  }
}

/// 主屏幕小型时间组件
class IOSSmallTimeWidget extends StatefulWidget {
  final Color? textColor;

  const IOSSmallTimeWidget({super.key, this.textColor});

  @override
  State<IOSSmallTimeWidget> createState() => _IOSSmallTimeWidgetState();
}

class _IOSSmallTimeWidgetState extends State<IOSSmallTimeWidget> {
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

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? Colors.white;
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');

    return Text(
      '$hour:$minute',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

/// 锁屏界面通知提示
class IOSLockScreenNotification extends StatelessWidget {
  final String appName;
  final IconData appIcon;
  final String title;
  final String message;
  final String time;
  final Color iconColor;
  final VoidCallback? onTap;

  const IOSLockScreenNotification({
    super.key,
    required this.appName,
    required this.appIcon,
    required this.title,
    required this.message,
    required this.time,
    this.iconColor = Colors.blue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用图标
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(appIcon, color: Colors.white, size: 24),
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
                        appName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
