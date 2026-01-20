import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/ios_constants.dart';
import '../core/data/grid_default_apps.dart';
import '../core/models/app_model.dart';
import '../core/providers/system_state_provider.dart';
import '../widgets/ios_app_grid.dart';
import '../widgets/ios_wallpaper.dart';
import '../widgets/ios_control_center.dart';
import '../widgets/ios_notification_center.dart';
import '../widgets/ios_draggable_grid.dart';
import 'settings_screen.dart';
import 'wechat_main_screen.dart';
import 'world_info_list_screen.dart';
import 'text_preset_list_screen.dart';
import 'memory_app_screen.dart';

/// iOS风格主屏幕
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isEditing = false;

  // 网格数据
  late List<List<String?>> _gridPages;
  late Map<String, AppModel> _appRegistry;

  // 手势相关
  double _dragStartY = 0;
  double _dragStartX = 0;
  bool _isDraggingVertical = false;
  bool _isShowingControlCenter = false;
  bool _isShowingNotificationCenter = false;

  // 应用启动动画
  late AnimationController _launchController;
  late Animation<double> _launchScaleAnimation;
  late Animation<double> _launchFadeAnimation;
  String? _launchingAppId;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentPage = 0;
    _appRegistry = GridDefaultApps.appRegistry;
    _gridPages = [List.from(GridDefaultApps.defaultPage1Grid)];

    _launchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _launchScaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(parent: _launchController, curve: Curves.easeInOut),
    );
    _launchFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _launchController, curve: Curves.easeIn));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _launchController.dispose();
    super.dispose();
  }

  void _onAppTap(String appId) {
    print('点击了应用: $appId'); // 调试信息

    if (_isEditing) {
      setState(() => _isEditing = false);
      return;
    }

    // 如果点击的是设置应用，打开设置界面
    if (appId == 'settings') {
      print('正在打开设置界面'); // 调试信息
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      return;
    }

    // 如果点击的是聊天应用，打开微信主界面（包含4个底栏标签）
    if (appId == 'ai_chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WeChatMainScreen()),
      );
      return;
    }

    // 世界书应用
    if (appId == 'world_info') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WorldInfoListScreen()),
      );
      return;
    }

    // 预设应用
    if (appId == 'text_preset') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TextPresetListScreen()),
      );
      return;
    }

    // 记忆库应用
    if (appId == 'memories') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MemoryAppScreen()),
      );
      return;
    }

    // contacts 和 moments 已整合到微信主界面中，不再需要单独入口

    _launchApp(appId);
  }

  void _checkAndAddNewApps(SystemStateProvider provider) {
    final existingApps = <String>{};
    for (final page in _gridPages) {
      for (final appId in page) {
        if (appId != null) {
          existingApps.add(appId);
        }
      }
    }

    // 只需要检查我们需要显示的应用
    // 过滤掉不需要显示在桌面的应用（如果有的话，目前 appRegistry 里的应该都是要显示的）
    final allApps = _appRegistry.keys.toList();
    final missingApps =
        allApps.where((id) => !existingApps.contains(id)).toList();

    if (missingApps.isEmpty) return;

    bool hasChanges = false;
    int missingAppIndex = 0;

    // 尝试填入现有页面的空位
    for (int i = 0; i < _gridPages.length; i++) {
      if (missingAppIndex >= missingApps.length) break;

      for (int j = 0; j < _gridPages[i].length; j++) {
        if (missingAppIndex >= missingApps.length) break;

        if (_gridPages[i][j] == null) {
          _gridPages[i][j] = missingApps[missingAppIndex];
          missingAppIndex++;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setGridPages(_gridPages);
      });
    }
  }

  void _launchApp(String appId) {
    final app = _appRegistry[appId];
    if (app == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _launchingAppId = appId);

    _launchController.forward().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('启动 ${app.name}'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        _launchController.reset();
        setState(() => _launchingAppId = null);
      });
    });
  }

  void _onAppLongPress(String appId) {
    HapticFeedback.heavyImpact();
    setState(() => _isEditing = true);
  }

  void _onAppDelete(String appId) {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var i = 0; i < _gridPages.length; i++) {
        final index = _gridPages[i].indexOf(appId);
        if (index != -1) {
          _gridPages[i][index] = null;
          break;
        }
      }
    });
  }

  void _onGridChanged(int pageIndex, List<String?> newGrid) {
    setState(() {
      _gridPages[pageIndex] = newGrid;
    });
    // 保存到 Provider 以持久化
    context.read<SystemStateProvider>().updateGridPage(pageIndex, newGrid);
  }

  void _exitEditMode() {
    setState(() => _isEditing = false);
  }

  void _handlePanStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _dragStartX = details.globalPosition.dx;
    _isDraggingVertical = false;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final deltaY = details.globalPosition.dy - _dragStartY;
    final deltaX = (details.globalPosition.dx - _dragStartX).abs();

    if (!_isDraggingVertical && deltaY.abs() > 20 && deltaY.abs() > deltaX) {
      _isDraggingVertical = true;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDraggingVertical) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_dragStartX > screenWidth * 0.5 &&
        _dragStartY < 100 &&
        velocity > 300) {
      _showControlCenter();
    } else if (_dragStartX <= screenWidth * 0.5 &&
        _dragStartY < 100 &&
        velocity > 300) {
      _showNotificationCenter();
    }

    _isDraggingVertical = false;
  }

  void _showControlCenter() {
    if (_isShowingControlCenter) return;
    setState(() => _isShowingControlCenter = true);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Control Center',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return IOSControlCenter(
          onClose: () {
            Navigator.of(context).pop();
            setState(() => _isShowingControlCenter = false);
          },
        );
      },
    ).then((_) {
      setState(() => _isShowingControlCenter = false);
    });
  }

  void _showNotificationCenter() {
    if (_isShowingNotificationCenter) return;
    setState(() => _isShowingNotificationCenter = true);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification Center',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return IOSNotificationCenter(
          onClose: () {
            Navigator.of(context).pop();
            setState(() => _isShowingNotificationCenter = false);
          },
        );
      },
    ).then((_) {
      setState(() => _isShowingNotificationCenter = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SystemStateProvider>();

    // 初始化网格数据
    if (!_isInitialized && provider.isLoaded) {
      _isInitialized = true;
      if (provider.gridPages.isNotEmpty) {
        _gridPages =
            provider.gridPages.map((page) => List<String?>.from(page)).toList();
        _checkAndAddNewApps(provider);
      } else {
        // 保存默认布局到 Provider
        // 使用 addPostFrameCallback 避免在 build 期间触发 notifyListeners
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.setGridPages(_gridPages);
        });
      }
    }

    return GestureDetector(
      onTap: _isEditing ? _exitEditMode : null,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: IOSWallpaper(
          style: WallpaperStyle.values[provider.currentWallpaperIndex
              .clamp(0, WallpaperStyle.values.length - 1)],
          customImagePath: provider.effectiveWallpaperPath,
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // 应用网格区域
                    Expanded(child: _buildAppPages()),

                    // 页面指示器
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IOSPageIndicator(
                        pageCount: 1,
                        currentPage: 0,
                        showSearchDot: false,
                      ),
                    ),
                  ],
                ),
              ),

              // 编辑模式覆盖层
              if (_isEditing) _buildEditModeOverlay(),

              // 应用启动动画
              if (_launchingAppId != null) _buildLaunchAnimation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppPages() {
    return PageView.builder(
      controller: _pageController,
      itemCount: 1, // 只保留第一页
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemBuilder: (context, pageIndex) {
        // 应用网格页面
        if (pageIndex == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IOSDraggableGrid(
              gridApps: _gridPages[0], // 只显示第一页
              appRegistry: _appRegistry,
              dockAppIds: const [],
              isEditing: _isEditing,
              onAppTap: _onAppTap,
              onAppLongPress: _onAppLongPress,
              onAppDelete: _onAppDelete,
              onGridChanged: (newGrid) => _onGridChanged(0, newGrid),
              onEnterEditMode: () {
                setState(() => _isEditing = true);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        const SizedBox(height: 60),
        IOSSearchBar(placeholder: '搜索', onTap: () {}),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Siri 建议',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              _buildSuggestionGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionGrid() {
    // 获取前8个有效应用
    final suggestions = _gridPages[0]
        .where((id) => id != null)
        .take(8)
        .map((id) => _appRegistry[id!])
        .where((app) => app != null)
        .cast<AppModel>()
        .toList();

    return Wrap(
      spacing: 16,
      runSpacing: 20,
      children: suggestions.map((app) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 72) / 4,
          child: GestureDetector(
            onTap: () => _onAppTap(app.id),
            child: Column(
              children: [
                Container(
                  width: IOSConstants.appIconSize,
                  height: IOSConstants.appIconSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      IOSConstants.appIconSize * 0.225,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: app.gradientColors ?? [Colors.grey, Colors.grey],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    app.icon,
                    size: IOSConstants.appIconSize * 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  app.name,
                  style: IOSTextStyles.appLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditModeOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 20,
      child: GestureDetector(
        onTap: _exitEditMode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '完成',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaunchAnimation() {
    final app = _appRegistry[_launchingAppId];
    if (app == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _launchController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: _launchFadeAnimation.value),
              child: Center(
                child: Transform.scale(
                  scale: _launchScaleAnimation.value,
                  child: Container(
                    width: IOSConstants.appIconSize,
                    height: IOSConstants.appIconSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        IOSConstants.appIconSize * 0.225,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            app.gradientColors ?? [Colors.grey, Colors.grey],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
