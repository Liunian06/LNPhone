import 'package:flutter/material.dart';
import '../core/constants/ios_constants.dart';
import '../core/models/app_model.dart';
import 'ios_app_icon.dart';

/// iOS风格应用网格布局
class IOSAppGrid extends StatelessWidget {
  final List<AppModel> apps;
  final bool isEditing;
  final Function(AppModel)? onAppTap;
  final Function(AppModel)? onAppLongPress;
  final Function(AppModel)? onAppDelete;
  final EdgeInsets? padding;

  const IOSAppGrid({
    super.key,
    required this.apps,
    this.isEditing = false,
    this.onAppTap,
    this.onAppLongPress,
    this.onAppDelete,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: IOSConstants.gridPaddingHorizontal,
          vertical: IOSConstants.gridPaddingTop,
        );

    // 计算每个单元格的宽度
    final availableWidth = screenWidth - gridPadding.horizontal;
    final itemWidth = availableWidth / IOSConstants.gridColumns;
    final itemHeight = IOSConstants.appIconSize + 30; // 图标高度 + 标签 + 间距

    return Padding(
      padding: gridPadding,
      child: Wrap(
        spacing: 0,
        runSpacing: 20,
        children: apps.map((app) {
          return SizedBox(
            width: itemWidth,
            height: itemHeight,
            child: Center(
              child: app.type == AppType.folder
                  ? IOSFolderIcon(
                      folder: app,
                      size: IOSConstants.appIconSize,
                      showLabel: true,
                      onTap: () => onAppTap?.call(app),
                      onLongPress: () => onAppLongPress?.call(app),
                    )
                  : IOSAppIcon(
                      app: app,
                      size: IOSConstants.appIconSize,
                      showLabel: true,
                      isEditing: isEditing,
                      onTap: () => onAppTap?.call(app),
                      onLongPress: () => onAppLongPress?.call(app),
                      onDelete: () => onAppDelete?.call(app),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 带页面滑动的应用网格
class IOSPagedAppGrid extends StatefulWidget {
  final List<List<AppModel>> pages;
  final bool isEditing;
  final Function(AppModel)? onAppTap;
  final Function(AppModel)? onAppLongPress;
  final Function(AppModel)? onAppDelete;
  final ValueChanged<int>? onPageChanged;

  const IOSPagedAppGrid({
    super.key,
    required this.pages,
    this.isEditing = false,
    this.onAppTap,
    this.onAppLongPress,
    this.onAppDelete,
    this.onPageChanged,
  });

  @override
  State<IOSPagedAppGrid> createState() => _IOSPagedAppGridState();
}

class _IOSPagedAppGridState extends State<IOSPagedAppGrid> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.pages.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        widget.onPageChanged?.call(index);
      },
      itemBuilder: (context, pageIndex) {
        return IOSAppGrid(
          apps: widget.pages[pageIndex],
          isEditing: widget.isEditing,
          onAppTap: widget.onAppTap,
          onAppLongPress: widget.onAppLongPress,
          onAppDelete: widget.onAppDelete,
        );
      },
    );
  }
}

/// 页面指示器
class IOSPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final bool showSearchDot;

  const IOSPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.showSearchDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalDots = pageCount + (showSearchDot ? 1 : 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isSearch = showSearchDot && index == 0;
        final isActive = showSearchDot
            ? index == currentPage + 1
            : index == currentPage;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: IOSConstants.pageIndicatorSpacing / 2,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSearch
                ? IOSConstants.pageIndicatorSize * 0.8
                : IOSConstants.pageIndicatorSize,
            height: IOSConstants.pageIndicatorSize,
            decoration: BoxDecoration(
              color: isActive
                  ? IOSColors.pageIndicatorActive
                  : IOSColors.pageIndicatorInactive,
              shape: isSearch ? BoxShape.circle : BoxShape.circle,
            ),
            child: isSearch && !isActive
                ? Icon(
                    Icons.search,
                    size: IOSConstants.pageIndicatorSize * 0.7,
                    color: IOSColors.pageIndicatorInactive,
                  )
                : null,
          ),
        );
      }),
    );
  }
}

/// 搜索栏
class IOSSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String placeholder;

  const IOSSearchBar({super.key, this.onTap, this.placeholder = '搜索'});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: IOSColors.searchBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 18, color: IOSColors.searchIcon),
            const SizedBox(width: 6),
            Text(placeholder, style: IOSTextStyles.searchPlaceholder),
          ],
        ),
      ),
    );
  }
}
