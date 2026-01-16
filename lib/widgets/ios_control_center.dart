import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// iOS风格控制中心
class IOSControlCenter extends StatefulWidget {
  final VoidCallback? onClose;

  const IOSControlCenter({super.key, this.onClose});

  @override
  State<IOSControlCenter> createState() => _IOSControlCenterState();
}

class _IOSControlCenterState extends State<IOSControlCenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // 控制状态
  bool _isAirplaneMode = false;
  bool _isCellularEnabled = true;
  bool _isWifiEnabled = true;
  bool _isBluetoothEnabled = true;
  bool _isAirDropEnabled = false;
  bool _isHotspotEnabled = false;
  bool _isRotationLocked = false;
  bool _isFocusEnabled = false;
  bool _isMirroringEnabled = false;
  double _brightness = 0.7;
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
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
      onTap: _close,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.5),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {}, // 阻止点击穿透
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.topRight,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 顶部主控制区
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 连接控制组
              Expanded(child: _buildConnectionGroup()),
              const SizedBox(width: 12),
              // 右侧列：音乐+专注
              Column(
                children: [
                  _buildMusicWidget(),
                  const SizedBox(height: 12),
                  _buildFocusRotationRow(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 亮度和音量
          Row(
            children: [
              Expanded(child: _buildBrightnessSlider()),
              const SizedBox(width: 12),
              Expanded(child: _buildVolumeSlider()),
            ],
          ),
          const SizedBox(height: 12),

          // 底部快捷按钮
          _buildBottomShortcuts(),
        ],
      ),
    );
  }

  Widget _buildConnectionGroup() {
    return _ControlCenterCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  icon: CupertinoIcons.airplane,
                  label: '飞行模式',
                  isActive: _isAirplaneMode,
                  activeColor: const Color(0xFFFF9500),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isAirplaneMode = !_isAirplaneMode);
                  },
                ),
              ),
              Expanded(
                child: _ControlButton(
                  icon: CupertinoIcons.antenna_radiowaves_left_right,
                  label: '蜂窝数据',
                  isActive: _isCellularEnabled,
                  activeColor: const Color(0xFF34C759),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isCellularEnabled = !_isCellularEnabled);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  icon: CupertinoIcons.wifi,
                  label: 'Wi-Fi',
                  isActive: _isWifiEnabled,
                  activeColor: const Color(0xFF007AFF),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isWifiEnabled = !_isWifiEnabled);
                  },
                ),
              ),
              Expanded(
                child: _ControlButton(
                  icon: Icons.bluetooth,
                  label: '蓝牙',
                  isActive: _isBluetoothEnabled,
                  activeColor: const Color(0xFF007AFF),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isBluetoothEnabled = !_isBluetoothEnabled);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  icon: CupertinoIcons.share,
                  label: 'AirDrop',
                  isActive: _isAirDropEnabled,
                  activeColor: const Color(0xFF007AFF),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isAirDropEnabled = !_isAirDropEnabled);
                  },
                ),
              ),
              Expanded(
                child: _ControlButton(
                  icon: CupertinoIcons.personalhotspot,
                  label: '个人热点',
                  isActive: _isHotspotEnabled,
                  activeColor: const Color(0xFF34C759),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isHotspotEnabled = !_isHotspotEnabled);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusicWidget() {
    return _ControlCenterCard(
      width: 170,
      height: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA233B), Color(0xFFFC5C65)],
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '未在播放',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '音乐',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // 播放进度
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // 播放控制
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.backward_fill),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.play_fill),
                color: Colors.white,
                iconSize: 28,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.forward_fill),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusRotationRow() {
    return Row(
      children: [
        _ControlCenterCard(
          width: 79,
          height: 79,
          child: _SmallControlButton(
            icon: CupertinoIcons.moon_fill,
            label: '专注',
            isActive: _isFocusEnabled,
            activeColor: const Color(0xFF5856D6),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isFocusEnabled = !_isFocusEnabled);
            },
          ),
        ),
        const SizedBox(width: 12),
        _ControlCenterCard(
          width: 79,
          height: 79,
          child: _SmallControlButton(
            icon: CupertinoIcons.lock_rotation,
            label: '旋转锁定',
            isActive: _isRotationLocked,
            activeColor: const Color(0xFFFF3B30),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isRotationLocked = !_isRotationLocked);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrightnessSlider() {
    return _ControlCenterCard(
      height: 160,
      child: _VerticalSlider(
        value: _brightness,
        icon: CupertinoIcons.sun_max_fill,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() => _brightness = value);
        },
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return _ControlCenterCard(
      height: 160,
      child: _VerticalSlider(
        value: _volume,
        icon: CupertinoIcons.speaker_2_fill,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() => _volume = value);
        },
      ),
    );
  }

  Widget _buildBottomShortcuts() {
    return Row(
      children: [
        _ControlCenterCard(
          width: 79,
          height: 79,
          child: _SmallControlButton(
            icon: CupertinoIcons.bolt_fill,
            label: '手电筒',
            isActive: false,
            activeColor: const Color(0xFF007AFF),
            onTap: () => HapticFeedback.heavyImpact(),
          ),
        ),
        const SizedBox(width: 12),
        _ControlCenterCard(
          width: 79,
          height: 79,
          child: _SmallControlButton(
            icon: CupertinoIcons.timer,
            label: '计时器',
            isActive: false,
            activeColor: const Color(0xFFFF9500),
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ),
        const SizedBox(width: 12),
        _ControlCenterCard(
          width: 79,
          height: 79,
          child: _SmallControlButton(
            icon: CupertinoIcons.camera_fill,
            label: '相机',
            isActive: false,
            activeColor: const Color(0xFF8E8E93),
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ),
        const SizedBox(width: 12),
        _ControlCenterCard(
          width: 79,
          height: 79,
          child: _SmallControlButton(
            icon: CupertinoIcons.qrcode_viewfinder,
            label: '扫描',
            isActive: false,
            activeColor: const Color(0xFF8E8E93),
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ),
      ],
    );
  }
}

/// 控制中心卡片容器
class _ControlCenterCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const _ControlCenterCard({required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 控制按钮
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 小型控制按钮
class _SmallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _SmallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 垂直滑块
class _VerticalSlider extends StatelessWidget {
  final double value;
  final IconData icon;
  final ValueChanged<double>? onChanged;

  const _VerticalSlider({
    required this.value,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            final newValue =
                1 - (details.localPosition.dy / constraints.maxHeight);
            onChanged?.call(newValue.clamp(0.0, 1.0));
          },
          child: Stack(
            children: [
              // 背景
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // 填充
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: constraints.maxHeight * value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // 图标
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Icon(
                  icon,
                  color: value > 0.15 ? Colors.black54 : Colors.white54,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 显示控制中心的辅助方法
void showIOSControlCenter(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return IOSControlCenter(onClose: () => Navigator.of(context).pop());
      },
    ),
  );
}
