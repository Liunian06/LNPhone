import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/constants/ios_constants.dart';
import '../core/models/app_model.dart';

/// iOS风格应用图标组件
class IOSAppIcon extends StatefulWidget {
  final AppModel app;
  final double size;
  final bool showLabel;
  final bool isEditing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final String? customIconPath;

  const IOSAppIcon({
    super.key,
    required this.app,
    this.size = 60,
    this.showLabel = true,
    this.isEditing = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.customIconPath,
  });

  @override
  State<IOSAppIcon> createState() => _IOSAppIconState();
}

class _IOSAppIconState extends State<IOSAppIcon>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _wobbleAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    if (widget.isEditing) {
      _startWobble();
    }
  }

  @override
  void didUpdateWidget(IOSAppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _startWobble();
    } else if (!widget.isEditing && oldWidget.isEditing) {
      _stopWobble();
    }
  }

  void _startWobble() {
    _wobbleController.repeat(reverse: true);
  }

  void _stopWobble() {
    _wobbleController.stop();
    _wobbleController.reset();
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _wobbleController,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.isEditing ? _wobbleAnimation.value : 0,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标容器
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 主图标
                AnimatedScale(
                  scale: _isPressed ? 0.9 : 1.0,
                  duration: IOSConstants.iconPressDuration,
                  curve: Curves.easeInOut,
                  child: _buildIconContainer(),
                ),
                // 徽章
                if (widget.app.badge > 0)
                  Positioned(top: -5, right: -5, child: _buildBadge()),
                // 删除按钮 (编辑模式)
                if (widget.isEditing && widget.app.isRemovable)
                  Positioned(top: -8, left: -8, child: _buildDeleteButton()),
              ],
            ),
            // 标签
            if (widget.showLabel) ...[const SizedBox(height: 6), _buildLabel()],
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    final borderRadius = widget.size * 0.225; // iOS标准圆角比例

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildIconContent(),
      ),
    );
  }

  Widget _buildIconContent() {
    // 优先使用自定义图标
    if (widget.customIconPath != null) {
      return _buildCustomImageIcon();
    }

    switch (widget.app.iconType) {
      case IconType.gradient:
        return _buildGradientIcon();
      case IconType.image:
        return _buildImageIcon();
      case IconType.custom:
        return _buildCustomIcon();
      case IconType.icon:
      default:
        return _buildSimpleIcon();
    }
  }

  // 自定义图片图标
  Widget _buildCustomImageIcon() {
    final file = File(widget.customIconPath!);
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // 如果加载失败，回退到默认图标
        return _buildGradientIcon();
      },
    );
  }

  Widget _buildGradientIcon() {
    final colors = widget.app.gradientColors ?? [Colors.grey, Colors.grey];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // 光泽效果
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.size * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // 图标
          Center(
            child: Icon(
              widget.app.icon,
              size: widget.size * 0.5,
              color: _getIconColor(colors.first),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconColor(Color backgroundColor) {
    // 根据背景色自动选择图标颜色
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _buildImageIcon() {
    if (widget.app.imagePath != null) {
      return Image.asset(widget.app.imagePath!, fit: BoxFit.cover);
    }
    return _buildSimpleIcon();
  }

  Widget _buildCustomIcon() {
    // 日历图标特殊处理
    if (widget.app.id == 'calendar') {
      return _buildCalendarIcon();
    }
    return _buildGradientIcon();
  }

  Widget _buildCalendarIcon() {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[now.weekday - 1];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 红色顶部
          Container(
            height: widget.size * 0.2,
            color: const Color(0xFFFF3B30),
            alignment: Alignment.center,
            child: Text(
              weekday,
              style: TextStyle(
                fontSize: widget.size * 0.11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          // 日期数字
          Expanded(
            child: Center(
              child: Text(
                '${now.day}',
                style: TextStyle(
                  fontSize: widget.size * 0.45,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleIcon() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          widget.app.icon ?? Icons.apps,
          size: widget.size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBadge() {
    final badgeText = widget.app.badge > 99 ? '99+' : '${widget.app.badge}';
    final width = badgeText.length > 2 ? 28.0 : 22.0;

    return Container(
      constraints: BoxConstraints(minWidth: width, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: IOSColors.badgeBackground,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: Text(badgeText, style: IOSTextStyles.badge)),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: widget.onDelete,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.remove, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildLabel() {
    return SizedBox(
      width: widget.size + 10,
      child: Text(
        widget.app.name,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: IOSTextStyles.appLabel.copyWith(
          fontSize: IOSConstants.appLabelSize,
        ),
      ),
    );
  }
}

/// 文件夹图标预览
class IOSFolderIcon extends StatelessWidget {
  final AppModel folder;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IOSFolderIcon({
    super.key,
    required this.folder,
    this.size = 60,
    this.showLabel = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = size * 0.225;
    final apps = folder.folderApps ?? [];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.white.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(size * 0.12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: size * 0.04,
                    crossAxisSpacing: size * 0.04,
                  ),
                  itemCount: apps.length.clamp(0, 9),
                  itemBuilder: (context, index) {
                    return _buildMiniIcon(apps[index], size * 0.2);
                  },
                ),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: size + 10,
              child: Text(
                folder.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: IOSTextStyles.appLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniIcon(AppModel app, double iconSize) {
    final colors = app.gradientColors ?? [Colors.grey, Colors.grey];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(iconSize * 0.225),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }
}
