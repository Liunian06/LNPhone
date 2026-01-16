import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/ios_constants.dart';
import '../core/models/app_model.dart';
import 'ios_app_icon.dart';

/// 可拖拽的iOS风格Dock栏
class IOSDraggableDock extends StatefulWidget {
  final List<String> dockAppIds; // 最多4个应用ID
  final Map<String, AppModel> appRegistry;
  final bool isEditing;
  final Function(String appId)? onAppTap;
  final Function(String appId)? onAppLongPress;
  final Function(String appId)? onAppDelete;
  final Function(List<String> newDockApps)? onDockChanged;
  final Function(String appId)? onAppRemovedFromDock; // 应用被拖出dock时回调
  final Function(String appId)? onAppAddedToDock; // 应用从网格拖入dock时回调
  final VoidCallback? onEnterEditMode;

  const IOSDraggableDock({
    super.key,
    required this.dockAppIds,
    required this.appRegistry,
    this.isEditing = false,
    this.onAppTap,
    this.onAppLongPress,
    this.onAppDelete,
    this.onDockChanged,
    this.onAppRemovedFromDock,
    this.onAppAddedToDock,
    this.onEnterEditMode,
  });

  @override
  State<IOSDraggableDock> createState() => _IOSDraggableDockState();
}

class _IOSDraggableDockState extends State<IOSDraggableDock> {
  late List<String> _currentDockApps;
  int? _dragFromIndex;
  bool _isDraggingOut = false;
  String? _draggingAppId;

  static const int maxDockApps = 4;

  @override
  void initState() {
    super.initState();
    _currentDockApps = List.from(widget.dockAppIds);
  }

  @override
  void didUpdateWidget(IOSDraggableDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在不处于拖拽状态时才同步外部数据
    // 避免在拖拽过程中被外部更新覆盖本地状态
    if (_draggingAppId == null && oldWidget.dockAppIds != widget.dockAppIds) {
      _currentDockApps = List.from(widget.dockAppIds);
    }
  }

  void _onDragStarted(int index, String appId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragFromIndex = index;
      _draggingAppId = appId;
    });
  }

  void _onDragEnd(DraggableDetails details) {
    final wasDraggingOut = _isDraggingOut;
    final draggedAppId = _draggingAppId;

    // 先重置拖拽状态
    setState(() {
      _draggingAppId = null;
      _dragFromIndex = null;
      _isDraggingOut = false;
    });

    // 如果拖拽出去了dock区域，移除应用
    if (wasDraggingOut && draggedAppId != null) {
      final newDock = List<String>.from(_currentDockApps);
      newDock.remove(draggedAppId);

      setState(() {
        _currentDockApps = newDock;
      });

      widget.onDockChanged?.call(newDock);
      widget.onAppRemovedFromDock?.call(draggedAppId);
    }
  }

  void _onDragAccept(int toIndex, String appId) {
    if (_dragFromIndex == null || _dragFromIndex == toIndex) return;

    HapticFeedback.lightImpact();

    final newDock = List<String>.from(_currentDockApps);
    // 在dock内交换位置
    final temp = newDock[toIndex];
    newDock[toIndex] = newDock[_dragFromIndex!];
    newDock[_dragFromIndex!] = temp;

    setState(() {
      _currentDockApps = newDock;
      _dragFromIndex = null;
    });

    widget.onDockChanged?.call(newDock);
  }

  // 接收从外部拖入的应用
  void _onExternalAppDrop(String appId) {
    if (_currentDockApps.length >= maxDockApps) {
      // dock已满，不接受
      HapticFeedback.heavyImpact();
      return;
    }

    if (_currentDockApps.contains(appId)) {
      // 已经在dock中
      return;
    }

    HapticFeedback.mediumImpact();

    final newDock = List<String>.from(_currentDockApps);
    newDock.add(appId);

    setState(() {
      _currentDockApps = newDock;
    });

    widget.onDockChanged?.call(newDock);
    // 通知home_screen从网格中移除该应用
    widget.onAppAddedToDock?.call(appId);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + IOSConstants.dockMarginBottom,
      ),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          // 只接受不在dock中的应用，且dock未满
          final appId = details.data;
          return !_currentDockApps.contains(appId) &&
              _currentDockApps.length < maxDockApps;
        },
        onAcceptWithDetails: (details) {
          _onExternalAppDrop(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: IOSConstants.dockBlurSigma,
                sigmaY: IOSConstants.dockBlurSigma,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: IOSConstants.dockHeight,
                decoration: BoxDecoration(
                  color: isHovering
                      ? IOSColors.dockBackground.withValues(alpha: 0.4)
                      : IOSColors.dockBackground,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: isHovering
                        ? Colors.white.withValues(alpha: 0.5)
                        : IOSColors.dockBorder,
                    width: isHovering ? 2 : 0.5,
                  ),
                ),
                child: _buildDockContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDockContent() {
    final appCount = _currentDockApps.length;

    if (appCount == 0) {
      return const Center(
        child: Text(
          '拖入应用',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    // 使用Row布局，根据应用数量进行等距排列
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final iconSize = IOSConstants.appIconSize;

        // 计算每个应用的位置
        List<double> positions = _calculatePositions(
          appCount,
          availableWidth,
          iconSize,
        );

        return Stack(
          children: List.generate(_currentDockApps.length, (index) {
            final appId = _currentDockApps[index];
            final app = widget.appRegistry[appId];
            if (app == null) return const SizedBox.shrink();

            // 如果正在被拖拽，显示占位
            final isDragging = _draggingAppId == appId;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: positions[index] - iconSize / 2,
              top: (IOSConstants.dockHeight - iconSize) / 2,
              width: iconSize,
              height: iconSize,
              child: isDragging && widget.isEditing
                  ? _buildPlaceholder(iconSize)
                  : _buildDockItem(index, appId, app, iconSize),
            );
          }),
        );
      },
    );
  }

  List<double> _calculatePositions(
    int count,
    double availableWidth,
    double iconSize,
  ) {
    List<double> positions = [];

    if (count == 1) {
      // 1个应用：居中
      positions.add(availableWidth / 2);
    } else if (count == 2) {
      // 2个应用：左右各一
      final spacing = availableWidth / 3;
      positions.add(spacing);
      positions.add(spacing * 2);
    } else if (count == 3) {
      // 3个应用：左中右等距
      final spacing = availableWidth / 4;
      positions.add(spacing);
      positions.add(spacing * 2);
      positions.add(spacing * 3);
    } else {
      // 4个应用：均匀分布
      final spacing = availableWidth / 5;
      for (int i = 0; i < count; i++) {
        positions.add(spacing * (i + 1));
      }
    }

    return positions;
  }

  Widget _buildPlaceholder(double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(iconSize * 0.225),
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }

  Widget _buildDockItem(
    int index,
    String appId,
    AppModel app,
    double iconSize,
  ) {
    if (widget.isEditing) {
      return DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          // 只接受来自dock内部的拖拽
          return _currentDockApps.contains(details.data) &&
              details.data != appId;
        },
        onAcceptWithDetails: (details) {
          final fromIndex = _currentDockApps.indexOf(details.data);
          if (fromIndex != -1 && fromIndex != index) {
            _dragFromIndex = fromIndex;
            _onDragAccept(index, details.data);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Draggable<String>(
            data: appId,
            onDragStarted: () => _onDragStarted(index, appId),
            onDragEnd: _onDragEnd,
            onDragUpdate: (details) {
              // 检测是否拖出dock区域
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final dockHeight = IOSConstants.dockHeight;
                // 如果拖拽位置超出dock区域较远，标记为拖出
                if (localPosition.dy < -50 ||
                    localPosition.dy > dockHeight + 50) {
                  if (!_isDraggingOut) {
                    setState(() => _isDraggingOut = true);
                    HapticFeedback.lightImpact();
                  }
                } else {
                  if (_isDraggingOut) {
                    setState(() => _isDraggingOut = false);
                  }
                }
              }
            },
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.1,
                child: _buildAppIconWidget(app, iconSize),
              ),
            ),
            childWhenDragging: _buildPlaceholder(iconSize),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconSize * 0.225),
                border: isHovering
                    ? Border.all(color: Colors.white38, width: 2)
                    : null,
              ),
              child: IOSAppIcon(
                app: app,
                size: iconSize,
                showLabel: false,
                isEditing: true,
                onDelete: app.isRemovable ? () => _removeApp(appId) : null,
              ),
            ),
          );
        },
      );
    }

    // 普通模式
    return GestureDetector(
      onTap: () => widget.onAppTap?.call(appId),
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onEnterEditMode?.call();
      },
      child: IOSAppIcon(
        app: app,
        size: iconSize,
        showLabel: false,
        isEditing: false,
      ),
    );
  }

  void _removeApp(String appId) {
    HapticFeedback.mediumImpact();
    final newDock = List<String>.from(_currentDockApps);
    newDock.remove(appId);

    setState(() {
      _currentDockApps = newDock;
    });

    widget.onDockChanged?.call(newDock);
    widget.onAppDelete?.call(appId);
  }

  Widget _buildAppIconWidget(AppModel app, double iconSize) {
    final borderRadius = iconSize * 0.225;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: app.gradientColors ?? [Colors.grey, Colors.grey],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: iconSize * 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(app.icon, size: iconSize * 0.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
