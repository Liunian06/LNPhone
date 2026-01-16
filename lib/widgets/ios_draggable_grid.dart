import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/ios_constants.dart';
import '../core/models/app_model.dart';
import '../core/providers/system_state_provider.dart';
import 'ios_app_icon.dart';

/// 可拖拽的4x7网格布局
class IOSDraggableGrid extends StatefulWidget {
  final List<String?> gridApps; // 28个位置，null表示空位
  final Map<String, AppModel> appRegistry; // 应用注册表
  final List<String> dockAppIds; // 保留用于兼容性，但不再使用
  final bool isEditing;
  final Function(String appId)? onAppTap;
  final Function(String appId)? onAppLongPress;
  final Function(String appId)? onAppDelete;
  final Function(List<String?> newGrid)? onGridChanged;
  final VoidCallback? onEnterEditMode;

  const IOSDraggableGrid({
    super.key,
    required this.gridApps,
    required this.appRegistry,
    this.dockAppIds = const [],
    this.isEditing = false,
    this.onAppTap,
    this.onAppLongPress,
    this.onAppDelete,
    this.onGridChanged,
    this.onEnterEditMode,
  });

  @override
  State<IOSDraggableGrid> createState() => _IOSDraggableGridState();
}

class _IOSDraggableGridState extends State<IOSDraggableGrid> {
  late List<String?> _currentGrid;
  int? _dragFromIndex;

  @override
  void initState() {
    super.initState();
    _currentGrid = List.from(widget.gridApps);
  }

  @override
  void didUpdateWidget(IOSDraggableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gridApps != widget.gridApps) {
      _currentGrid = List.from(widget.gridApps);
    }
  }

  void _onDragStarted(int index) {
    HapticFeedback.mediumImpact();
    _dragFromIndex = index;
  }

  void _onDragAccept(int toIndex, String? appId) {
    if (_dragFromIndex == null || _dragFromIndex == toIndex) return;

    HapticFeedback.lightImpact();

    final newGrid = List<String?>.from(_currentGrid);
    // 交换
    final temp = newGrid[toIndex];
    newGrid[toIndex] = newGrid[_dragFromIndex!];
    newGrid[_dragFromIndex!] = temp;

    setState(() {
      _currentGrid = newGrid;
      _dragFromIndex = null;
    });

    widget.onGridChanged?.call(newGrid);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    // 计算可用高度（移除dock后，整个屏幕用于网格）
    final availableHeight =
        screenHeight - safeTop - MediaQuery.of(context).padding.bottom - 60;

    // 计算单元格尺寸
    final cellWidth = (screenWidth - 40) / 4;
    final cellHeight = availableHeight / 7;

    // 图标尺寸，基于单元格大小
    final iconSize = (cellWidth * 0.7).clamp(50.0, 65.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: availableHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: cellWidth / cellHeight,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
          ),
          itemCount: 28,
          itemBuilder: (context, index) {
            return _buildGridCell(index, iconSize);
          },
        ),
      ),
    );
  }

  Widget _buildGridCell(int index, double iconSize) {
    final appId = _currentGrid[index];

    // 空位：可以接受拖放（仅来自网格内）
    if (appId == null) {
      return DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          final draggedAppId = details.data;
          // 只接受来自网格内的拖拽
          return _currentGrid.contains(draggedAppId);
        },
        onAcceptWithDetails: (details) {
          final draggedAppId = details.data;
          // 来自网格内
          _onDragAccept(index, draggedAppId);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13.5),
              border: isHovering
                  ? Border.all(color: Colors.white38, width: 2)
                  : null,
              color: isHovering ? Colors.white.withValues(alpha: 0.1) : null,
            ),
          );
        },
      );
    }

    final app = widget.appRegistry[appId];
    if (app == null) return const SizedBox.shrink();

    return Consumer<SystemStateProvider>(
      builder: (context, provider, _) {
        final customIconPath = provider.getCustomAppIcon(appId);

        // 编辑模式：可拖拽
        if (widget.isEditing) {
          return DragTarget<String>(
            onWillAcceptWithDetails: (details) {
              final draggedAppId = details.data;
              // 只接受来自网格内的拖拽（不同位置）
              return draggedAppId != appId &&
                  _currentGrid.contains(draggedAppId);
            },
            onAcceptWithDetails: (details) {
              final draggedAppId = details.data;
              _onDragAccept(index, draggedAppId);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              return Draggable<String>(
                data: appId,
                onDragStarted: () => _onDragStarted(index),
                onDragEnd: (details) {
                  setState(() {
                    _dragFromIndex = null;
                  });
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.1,
                    child: IOSAppIcon(
                      app: app,
                      size: iconSize,
                      showLabel: true,
                      isEditing: false,
                      customIconPath: customIconPath,
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13.5),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13.5),
                    border: isHovering
                        ? Border.all(color: Colors.white38, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: IOSAppIcon(
                      app: app,
                      size: iconSize,
                      showLabel: true,
                      isEditing: true,
                      onDelete: () => widget.onAppDelete?.call(appId),
                      customIconPath: customIconPath,
                    ),
                  ),
                ),
              );
            },
          );
        }

        // 普通模式
        return Center(
          child: IOSAppIcon(
            app: app,
            size: iconSize,
            showLabel: true,
            isEditing: false,
            onTap: () {
              print('IOSAppIcon: 点击了应用 $appId'); // 调试
              HapticFeedback.lightImpact();
              widget.onAppTap?.call(appId);
            },
            onLongPress: () {
              print('IOSAppIcon: 长按了应用 $appId'); // 调试
              HapticFeedback.heavyImpact();
              widget.onEnterEditMode?.call();
            },
            customIconPath: customIconPath,
          ),
        );
      },
    );
  }
}
