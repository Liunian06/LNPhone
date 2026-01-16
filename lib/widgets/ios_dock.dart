import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/ios_constants.dart';
import '../core/models/app_model.dart';
import 'ios_app_icon.dart';

/// iOS风格Dock栏
class IOSDock extends StatelessWidget {
  final List<AppModel> apps;
  final bool isEditing;
  final Function(AppModel)? onAppTap;
  final Function(AppModel)? onAppLongPress;
  final Function(AppModel)? onAppDelete;

  const IOSDock({
    super.key,
    required this.apps,
    this.isEditing = false,
    this.onAppTap,
    this.onAppLongPress,
    this.onAppDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + IOSConstants.dockMarginBottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: IOSConstants.dockBlurSigma,
            sigmaY: IOSConstants.dockBlurSigma,
          ),
          child: Container(
            height: IOSConstants.dockHeight,
            decoration: BoxDecoration(
              color: IOSColors.dockBackground,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: IOSColors.dockBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: apps.map((app) {
                return Expanded(
                  child: Center(
                    child: IOSAppIcon(
                      app: app,
                      size: IOSConstants.appIconSize,
                      showLabel: false,
                      isEditing: isEditing,
                      onTap: () => onAppTap?.call(app),
                      onLongPress: () => onAppLongPress?.call(app),
                      onDelete: () => onAppDelete?.call(app),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dock栏占位区域 (用于布局计算)
class DockPlaceholder extends StatelessWidget {
  const DockPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height:
          IOSConstants.dockHeight +
          bottomPadding +
          IOSConstants.dockMarginBottom +
          16,
    );
  }
}
