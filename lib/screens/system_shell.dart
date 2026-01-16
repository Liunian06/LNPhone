import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'lock_screen.dart';

class SystemShell extends StatefulWidget {
  const SystemShell({super.key});

  @override
  State<SystemShell> createState() => _SystemShellState();
}

class _SystemShellState extends State<SystemShell> {
  // 默认为锁定状态
  bool _isLocked = true;

  void _handleUnlock() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主屏幕始终在底层被渲染
        const HomeScreen(),

        // 锁屏界面覆盖在上层
        // 使用AnimatedSwitcher或直接通过LockScreen内部的动画控制显示
        if (_isLocked)
          Positioned.fill(child: LockScreen(onUnlock: _handleUnlock)),
      ],
    );
  }
}
