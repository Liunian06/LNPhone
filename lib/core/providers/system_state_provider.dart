import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../services/zip_backup_service.dart';
import '../models/app_model.dart';
import '../models/contact_model.dart';
import '../data/default_apps.dart';
import '../database/database.dart';
import '../models/api_preset.dart';
import '../models/moments_model.dart';
import '../models/chat_model.dart';

/// 系统状态Provider
/// 注意：所有设置现在存储在数据库中
/// SharedPreferences 已被弃用，仅用于兼容迁移
class SystemStateProvider extends ChangeNotifier {
  final AppDatabase _db;
  // 主屏幕应用
  List<List<AppModel>> _homePages = [];
  List<AppModel> _dockApps = [];

  // 网格布局数据 (持久化)
  List<List<String?>> _gridPages = [];

  // 运行中的应用
  final List<String> _runningAppIds = [];

  // 系统状态
  bool _isAirplaneMode = false;
  bool _isWifiEnabled = true;
  bool _isBluetoothEnabled = true;
  bool _isCellularEnabled = true;
  bool _isRotationLocked = false;
  bool _isFocusMode = false;
  double _brightness = 0.7;
  double _volume = 0.5;

  // 桌面壁纸
  int _currentWallpaperIndex = 0;
  String? _customWallpaperPath;

  // 锁屏壁纸
  int _lockScreenWallpaperIndex = 0;
  String? _customLockScreenWallpaperPath;

  // 自定义应用图标 (appId -> 图片路径)
  Map<String, String> _customAppIcons = {};

  // 编辑模式
  bool _isEditingHome = false;

  // 数据加载状态
  bool _isLoaded = false;

  // 壁纸池管理
  List<String> _wallpaperPool = []; // 预下载的壁纸路径列表
  int _currentWallpaperPoolIndex = 0; // 当前使用的壁纸在池中的索引
  String? _lastWallpaperUpdateDate; // 上次更新壁纸的日期 (格式: yyyy-MM-dd)
  bool _isDownloadingWallpapers = false; // 是否正在下载壁纸

  SystemStateProvider(this._db) {
    _loadDefaultData();
    _init();
  }

  Future<void> _init() async {
    // 严格按顺序初始化，确保设置先加载
    await _loadSettings();
    await _initializeWallpaperSystem();
  }

  void _loadDefaultData() {
    _homePages = List.from(DefaultApps.allPages);
    _dockApps = List.from(DefaultApps.dockApps);
  }

  // Getters
  List<List<AppModel>> get homePages => _homePages;
  List<AppModel> get dockApps => _dockApps;
  List<String> get runningAppIds => _runningAppIds;
  List<List<String?>> get gridPages => _gridPages;

  bool get isAirplaneMode => _isAirplaneMode;
  bool get isWifiEnabled => _isWifiEnabled;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isCellularEnabled => _isCellularEnabled;
  bool get isRotationLocked => _isRotationLocked;
  bool get isFocusMode => _isFocusMode;
  double get brightness => _brightness;
  double get volume => _volume;

  int get currentWallpaperIndex => _currentWallpaperIndex;
  String? get customWallpaperPath => _customWallpaperPath;
  int get lockScreenWallpaperIndex => _lockScreenWallpaperIndex;
  String? get customLockScreenWallpaperPath => _customLockScreenWallpaperPath;
  Map<String, String> get customAppIcons => _customAppIcons;
  bool get isEditingHome => _isEditingHome;
  bool get isLoaded => _isLoaded;

  // 壁纸池相关的getters
  List<String> get wallpaperPool => _wallpaperPool;
  int get currentWallpaperPoolIndex => _currentWallpaperPoolIndex;
  String? get lastWallpaperUpdateDate => _lastWallpaperUpdateDate;
  bool get isDownloadingWallpapers => _isDownloadingWallpapers;

  // 获取当前桌面壁纸路径 (仅在选中随机风景时使用壁纸池)
  String? get effectiveWallpaperPath {
    if (_currentWallpaperIndex == 6) {
      if (_wallpaperPool.isNotEmpty &&
          _currentWallpaperPoolIndex < _wallpaperPool.length) {
        return _wallpaperPool[_currentWallpaperPoolIndex];
      }
    }
    return _customWallpaperPath;
  }

  // 获取当前锁屏壁纸路径 (仅在选中随机风景时使用壁纸池)
  String? get effectiveLockScreenWallpaperPath {
    if (_lockScreenWallpaperIndex == 6) {
      if (_wallpaperPool.isNotEmpty &&
          _currentWallpaperPoolIndex < _wallpaperPool.length) {
        return _wallpaperPool[_currentWallpaperPoolIndex];
      }
    }
    return _customLockScreenWallpaperPath;
  }

  // 系统控制方法
  void toggleAirplaneMode() {
    _isAirplaneMode = !_isAirplaneMode;
    if (_isAirplaneMode) {
      _isWifiEnabled = false;
      _isBluetoothEnabled = false;
      _isCellularEnabled = false;
    }
    notifyListeners();
  }

  void toggleWifi() {
    _isWifiEnabled = !_isWifiEnabled;
    notifyListeners();
  }

  void toggleBluetooth() {
    _isBluetoothEnabled = !_isBluetoothEnabled;
    notifyListeners();
  }

  void toggleCellular() {
    _isCellularEnabled = !_isCellularEnabled;
    notifyListeners();
  }

  void toggleRotationLock() {
    _isRotationLocked = !_isRotationLocked;
    notifyListeners();
  }

  void toggleFocusMode() {
    _isFocusMode = !_isFocusMode;
    notifyListeners();
  }

  void setBrightness(double value) {
    _brightness = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  // 桌面壁纸切换
  void setWallpaper(int index) {
    _currentWallpaperIndex = index;
    // 切换到预设壁纸时，不一定要清除自定义壁纸路径，但为了逻辑清晰，我们保持清除
    _customWallpaperPath = null;
    _saveSettings();
    notifyListeners();
  }

  // 设置随机风景壁纸
  void setRandomLandscapeWallpaper() {
    _currentWallpaperIndex = 6; // 使用索引 6 对应 WallpaperStyle.randomLandscape
    _customWallpaperPath = null;
    _saveSettings();
    notifyListeners();
  }

  void nextWallpaper() {
    _currentWallpaperIndex = (_currentWallpaperIndex + 1) % 7;
    _customWallpaperPath = null;
    _saveSettings();
    notifyListeners();
  }

  // 设置自定义桌面壁纸
  void setCustomWallpaper(String path) {
    _customWallpaperPath = path;
    _currentWallpaperIndex = 0; // 设置自定义壁纸时，将索引重置为 0，避免处于随机风景模式
    _saveSettings();
    notifyListeners();
  }

  // 锁屏壁纸切换
  void setLockScreenWallpaper(int index) {
    _lockScreenWallpaperIndex = index;
    _customLockScreenWallpaperPath = null;
    _saveSettings();
    notifyListeners();
  }

  // 设置随机风景锁屏壁纸
  void setRandomLandscapeLockScreenWallpaper() {
    _lockScreenWallpaperIndex = 6; // 使用索引 6 对应 WallpaperStyle.randomLandscape
    _customLockScreenWallpaperPath = null;
    _saveSettings();
    notifyListeners();
  }

  // 设置自定义锁屏壁纸
  void setCustomLockScreenWallpaper(String path) {
    _customLockScreenWallpaperPath = path;
    _lockScreenWallpaperIndex = 0; // 设置自定义壁纸时，将索引重置为 0
    _saveSettings();
    notifyListeners();
  }

  // 设置自定义应用图标
  void setCustomAppIcon(String appId, String imagePath) {
    _customAppIcons[appId] = imagePath;
    _saveSettings();
    notifyListeners();
  }

  // 移除自定义应用图标
  void removeCustomAppIcon(String appId) {
    _customAppIcons.remove(appId);
    _saveSettings();
    notifyListeners();
  }

  // 获取应用的自定义图标路径
  String? getCustomAppIcon(String appId) {
    return _customAppIcons[appId];
  }

  // 网格布局管理
  void setGridPages(List<List<String?>> pages) {
    _gridPages = pages.map((page) => List<String?>.from(page)).toList();
    _saveSettings();
    notifyListeners();
  }

  void updateGridPage(int pageIndex, List<String?> newGrid) {
    while (_gridPages.length <= pageIndex) {
      _gridPages.add(List.filled(28, null));
    }
    _gridPages[pageIndex] = List<String?>.from(newGrid);
    _saveSettings();
    notifyListeners();
  }

  // 主屏幕编辑
  void toggleEditMode() {
    _isEditingHome = !_isEditingHome;
    notifyListeners();
  }

  void exitEditMode() {
    _isEditingHome = false;
    notifyListeners();
  }

  // 应用管理
  void launchApp(String appId) {
    if (!_runningAppIds.contains(appId)) {
      _runningAppIds.add(appId);
      notifyListeners();
    }
  }

  void closeApp(String appId) {
    _runningAppIds.remove(appId);
    notifyListeners();
  }

  void closeAllApps() {
    _runningAppIds.clear();
    notifyListeners();
  }

  // 从主屏幕删除应用
  void removeAppFromHome(String appId) {
    for (var page in _homePages) {
      page.removeWhere((app) => app.id == appId);
    }
    // 移除空页面
    _homePages.removeWhere((page) => page.isEmpty);
    notifyListeners();
  }

  // 移动应用
  void moveApp(String appId, int fromPage, int toPage, int toIndex) {
    AppModel? app;

    // 找到应用
    for (var page in _homePages) {
      final index = page.indexWhere((a) => a.id == appId);
      if (index != -1) {
        app = page.removeAt(index);
        break;
      }
    }

    if (app != null) {
      // 确保目标页面存在
      while (_homePages.length <= toPage) {
        _homePages.add([]);
      }

      // 插入到新位置
      if (toIndex >= _homePages[toPage].length) {
        _homePages[toPage].add(app);
      } else {
        _homePages[toPage].insert(toIndex, app);
      }

      // 移除空页面
      _homePages.removeWhere((page) => page.isEmpty);

      notifyListeners();
    }
  }

  // 获取所有应用（用于搜索）
  List<AppModel> get allApps {
    final apps = <AppModel>[];
    for (var page in _homePages) {
      apps.addAll(page);
    }
    apps.addAll(_dockApps);
    return apps;
  }

  // 搜索应用
  List<AppModel> searchApps(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return allApps.where((app) {
      return app.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // 计算存储占用空间
  Future<int> calculateStorageUsage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      int totalSize = 0;

      // 递归计算目录下所有文件大小
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // 持久化存储 - 保存设置
  // 注意：所有设置现在存储在数据库中，SharedPreferences 已被弃用
  Future<void> _saveSettings() async {
    try {
      // 保存桌面壁纸
      await _db.setSettingInt('wallpaper_index', _currentWallpaperIndex);
      if (_customWallpaperPath != null) {
        await _db.setSetting('custom_wallpaper_path', _customWallpaperPath!);
      } else {
        await _db.deleteSetting('custom_wallpaper_path');
      }

      // 保存锁屏壁纸
      await _db.setSettingInt(
        'lockscreen_wallpaper_index',
        _lockScreenWallpaperIndex,
      );
      if (_customLockScreenWallpaperPath != null) {
        await _db.setSetting(
          'custom_lockscreen_wallpaper_path',
          _customLockScreenWallpaperPath!,
        );
      } else {
        await _db.deleteSetting('custom_lockscreen_wallpaper_path');
      }

      // 保存自定义图标
      await _db.setSetting('custom_app_icons', jsonEncode(_customAppIcons));

      // 保存网格布局
      if (_gridPages.isNotEmpty) {
        await _db.setSetting('grid_pages', jsonEncode(_gridPages));
      }

      // 保存系统设置
      await _db.setSettingDouble('brightness', _brightness);
      await _db.setSettingDouble('volume', _volume);
      await _db.setSettingBool('airplane_mode', _isAirplaneMode);
      await _db.setSettingBool('wifi_enabled', _isWifiEnabled);
      await _db.setSettingBool('bluetooth_enabled', _isBluetoothEnabled);
      await _db.setSettingBool('cellular_enabled', _isCellularEnabled);
      await _db.setSettingBool('rotation_locked', _isRotationLocked);
      await _db.setSettingBool('focus_mode', _isFocusMode);
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  // 持久化存储 - 加载设置
  // 注意：先检查数据库，如果没有则从 SharedPreferences 迁移
  Future<void> _loadSettings() async {
    try {
      // [已弃用] SharedPreferences 仅用于兼容迁移
      final prefs = await SharedPreferences.getInstance();

      // 检查是否需要迁移（如果数据库中没有 wallpaper_index，则尝试迁移）
      final needsMigration = !(await _db.hasSetting('wallpaper_index'));

      if (needsMigration) {
        debugPrint('[SystemState] 开始从 SharedPreferences 迁移数据到数据库...');
        await _migrateFromSharedPreferences(prefs);
      }

      // 从数据库加载设置
      await _loadFromDatabase();

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 从 SharedPreferences 迁移数据到数据库
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migrateFromSharedPreferences(SharedPreferences prefs) async {
    try {
      // 迁移桌面壁纸
      final wallpaperIndex = prefs.getInt('wallpaper_index') ?? 0;
      await _db.setSettingInt('wallpaper_index', wallpaperIndex.clamp(0, 6));

      final customWallpaperPath = prefs.getString('custom_wallpaper_path');
      if (customWallpaperPath != null) {
        await _db.setSetting('custom_wallpaper_path', customWallpaperPath);
      }

      // 迁移锁屏壁纸
      final lockScreenIndex = prefs.getInt('lockscreen_wallpaper_index') ?? 0;
      await _db.setSettingInt(
          'lockscreen_wallpaper_index', lockScreenIndex.clamp(0, 6));

      final customLockPath =
          prefs.getString('custom_lockscreen_wallpaper_path');
      if (customLockPath != null) {
        await _db.setSetting(
            'custom_lockscreen_wallpaper_path', customLockPath);
      }

      // 迁移自定义图标
      final iconsJson = prefs.getString('custom_app_icons');
      if (iconsJson != null) {
        await _db.setSetting('custom_app_icons', iconsJson);
      }

      // 迁移网格布局
      final gridJson = prefs.getString('grid_pages');
      if (gridJson != null) {
        await _db.setSetting('grid_pages', gridJson);
      }

      // 迁移系统设置
      await _db.setSettingDouble(
          'brightness', prefs.getDouble('brightness') ?? 0.7);
      await _db.setSettingDouble('volume', prefs.getDouble('volume') ?? 0.5);
      await _db.setSettingBool(
          'airplane_mode', prefs.getBool('airplane_mode') ?? false);
      await _db.setSettingBool(
          'wifi_enabled', prefs.getBool('wifi_enabled') ?? true);
      await _db.setSettingBool(
          'bluetooth_enabled', prefs.getBool('bluetooth_enabled') ?? true);
      await _db.setSettingBool(
          'cellular_enabled', prefs.getBool('cellular_enabled') ?? true);
      await _db.setSettingBool(
          'rotation_locked', prefs.getBool('rotation_locked') ?? false);
      await _db.setSettingBool(
          'focus_mode', prefs.getBool('focus_mode') ?? false);

      debugPrint('[SystemState] 数据迁移完成');
    } catch (e) {
      debugPrint('[SystemState] 数据迁移失败: $e');
    }
  }

  /// 从数据库加载设置
  Future<void> _loadFromDatabase() async {
    // 加载桌面壁纸
    _currentWallpaperIndex = await _db.getSettingInt('wallpaper_index') ?? 0;
    _currentWallpaperIndex = _currentWallpaperIndex.clamp(0, 6);
    _customWallpaperPath = await _db.getSetting('custom_wallpaper_path');

    // 加载锁屏壁纸
    _lockScreenWallpaperIndex =
        await _db.getSettingInt('lockscreen_wallpaper_index') ?? 0;
    _lockScreenWallpaperIndex = _lockScreenWallpaperIndex.clamp(0, 6);
    _customLockScreenWallpaperPath =
        await _db.getSetting('custom_lockscreen_wallpaper_path');

    // 加载自定义图标
    final iconsJson = await _db.getSetting('custom_app_icons');
    if (iconsJson != null) {
      _customAppIcons = Map<String, String>.from(jsonDecode(iconsJson));
    }

    // 加载网格布局
    final gridJson = await _db.getSetting('grid_pages');
    if (gridJson != null) {
      final decoded = jsonDecode(gridJson) as List;
      _gridPages = decoded.map((page) {
        return (page as List).map((item) => item as String?).toList();
      }).toList();
    }

    // 加载系统设置
    _brightness = await _db.getSettingDouble('brightness') ?? 0.7;
    _volume = await _db.getSettingDouble('volume') ?? 0.5;
    _isAirplaneMode = await _db.getSettingBool('airplane_mode') ?? false;
    _isWifiEnabled = await _db.getSettingBool('wifi_enabled') ?? true;
    _isBluetoothEnabled = await _db.getSettingBool('bluetooth_enabled') ?? true;
    _isCellularEnabled = await _db.getSettingBool('cellular_enabled') ?? true;
    _isRotationLocked = await _db.getSettingBool('rotation_locked') ?? false;
    _isFocusMode = await _db.getSettingBool('focus_mode') ?? false;
  }

  // 辅助方法：读取文件为Base64
  Future<String?> _fileToBase64(String? path) async {
    if (path == null) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error reading file to base64: $e');
    }
    return null;
  }

  // 辅助方法：保存Base64到文件
  Future<String?> _base64ToFile(String? base64String, String fileName) async {
    if (base64String == null) return null;
    try {
      final bytes = base64Decode(base64String);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving base64 to file: $e');
      return null;
    }
  }

  // 导出设置
  Future<String> exportSettings() async {
    // 导出自定义图标数据
    final customIconsData = <String, String>{};
    for (final entry in _customAppIcons.entries) {
      final base64Data = await _fileToBase64(entry.value);
      if (base64Data != null) {
        customIconsData[entry.key] = base64Data;
      }
    }

    final settings = {
      'homeWallpaper': {
        'index': _currentWallpaperIndex,
        'customPath': _customWallpaperPath,
        'data': await _fileToBase64(_customWallpaperPath),
      },
      'lockScreenWallpaper': {
        'index': _lockScreenWallpaperIndex,
        'customPath': _customLockScreenWallpaperPath,
        'data': await _fileToBase64(_customLockScreenWallpaperPath),
      },
      'customIcons': _customAppIcons,
      'customIconsData': customIconsData,
      'gridLayout': _gridPages,
      'system': {
        'brightness': _brightness,
        'volume': _volume,
        'isAirplaneMode': _isAirplaneMode,
        'isWifiEnabled': _isWifiEnabled,
        'isBluetoothEnabled': _isBluetoothEnabled,
        'isCellularEnabled': _isCellularEnabled,
        'isRotationLocked': _isRotationLocked,
        'isFocusMode': _isFocusMode,
      },
    };

    return jsonEncode(settings);
  }

  // 导出设置到ZIP
  Future<String> exportSettingsToZip() async {
    final files = <String, String>{}; // zipFileName -> localPath
    final db = _db;

    // 确保所有数据都已迁移到数据库（兼容旧版本数据）
    await _ensureDataMigratedToDatabase(db);

    // 1. 收集自定义图标
    for (final entry in _customAppIcons.entries) {
      final localPath = entry.value;
      final ext = path.extension(localPath);
      final zipFileName = 'icon_${entry.key}$ext';
      files[zipFileName] = localPath;
    }

    // 2. 收集壁纸
    if (_customWallpaperPath != null) {
      final ext = path.extension(_customWallpaperPath!);
      final zipFileName = 'wallpaper_home$ext';
      files[zipFileName] = _customWallpaperPath!;
    }

    if (_customLockScreenWallpaperPath != null) {
      final ext = path.extension(_customLockScreenWallpaperPath!);
      final zipFileName = 'wallpaper_lock$ext';
      files[zipFileName] = _customLockScreenWallpaperPath!;
    }

    // 2.5 收集聊天背景图文件
    // 聊天背景图路径存储在数据库中，需要从会话中读取
    final sessions = await db.getAllSessions();
    for (final session in sessions) {
      if (session.backgroundImage != null &&
          session.backgroundImage!.isNotEmpty &&
          !session.backgroundImage!.startsWith('http')) {
        final bgFile = File(session.backgroundImage!);
        if (await bgFile.exists()) {
          final ext = path.extension(session.backgroundImage!);
          // 使用 session.id 作为唯一标识
          final zipFileName = 'chat_bg_${session.id}$ext';
          files[zipFileName] = session.backgroundImage!;
        }
      }
    }

    // 2.6 收集角色人设头像
    final roles = await db.getAllContactRoles();
    for (final role in roles) {
      if (role.avatarPath != null && role.avatarPath!.isNotEmpty) {
        final avatarFile = File(role.avatarPath!);
        if (await avatarFile.exists()) {
          final ext = path.extension(role.avatarPath!);
          final zipFileName = 'role_avatar_${role.id}$ext';
          files[zipFileName] = role.avatarPath!;
        }
      }
    }

    // 2.7 收集用户人设头像
    final meList = await db.getAllContactMes();
    for (final me in meList) {
      if (me.avatarPath != null && me.avatarPath!.isNotEmpty) {
        final avatarFile = File(me.avatarPath!);
        if (await avatarFile.exists()) {
          final ext = path.extension(me.avatarPath!);
          final zipFileName = 'me_avatar_${me.id}$ext';
          files[zipFileName] = me.avatarPath!;
        }
      }
    }

    // 2.8 收集朋友圈用户设置中的头像和封面
    final momentsSettings = await db.getMomentsUserSettings();
    if (momentsSettings != null) {
      // 收集朋友圈头像
      if (momentsSettings.avatarUrl != null &&
          momentsSettings.avatarUrl!.isNotEmpty &&
          !momentsSettings.avatarUrl!.startsWith('http')) {
        final avatarFile = File(momentsSettings.avatarUrl!);
        if (await avatarFile.exists()) {
          final ext = path.extension(momentsSettings.avatarUrl!);
          final zipFileName = 'moments_avatar$ext';
          files[zipFileName] = momentsSettings.avatarUrl!;
        }
      }
      // 收集朋友圈封面
      if (momentsSettings.coverImageUrl != null &&
          momentsSettings.coverImageUrl!.isNotEmpty &&
          !momentsSettings.coverImageUrl!.startsWith('http')) {
        final coverFile = File(momentsSettings.coverImageUrl!);
        if (await coverFile.exists()) {
          final ext = path.extension(momentsSettings.coverImageUrl!);
          final zipFileName = 'moments_cover$ext';
          files[zipFileName] = momentsSettings.coverImageUrl!;
        }
      }
    }

    // 2.9 收集朋友圈动态中的图片
    final momentsPosts = await db.getAllMoments();
    for (final post in momentsPosts) {
      // 收集动态媒体图片
      for (int i = 0; i < post.mediaItems.length; i++) {
        final mediaItem = post.mediaItems[i];
        if (mediaItem.url.isNotEmpty && !mediaItem.url.startsWith('http')) {
          final mediaFile = File(mediaItem.url);
          if (await mediaFile.exists()) {
            final ext = path.extension(mediaItem.url);
            final zipFileName = 'moment_media_${post.id}_$i$ext';
            files[zipFileName] = mediaItem.url;
          }
        }
        // 收集视频缩略图
        if (mediaItem.thumbnailUrl != null &&
            mediaItem.thumbnailUrl!.isNotEmpty &&
            !mediaItem.thumbnailUrl!.startsWith('http')) {
          final thumbFile = File(mediaItem.thumbnailUrl!);
          if (await thumbFile.exists()) {
            final ext = path.extension(mediaItem.thumbnailUrl!);
            final zipFileName = 'moment_thumb_${post.id}_$i$ext';
            files[zipFileName] = mediaItem.thumbnailUrl!;
          }
        }
      }

      // 收集动态发布者头像
      if (post.user.avatarUrl.isNotEmpty &&
          !post.user.avatarUrl.startsWith('http')) {
        final avatarFile = File(post.user.avatarUrl);
        if (await avatarFile.exists()) {
          final ext = path.extension(post.user.avatarUrl);
          final zipFileName = 'moment_user_avatar_${post.id}$ext';
          files[zipFileName] = post.user.avatarUrl;
        }
      }

      // 收集评论者头像
      for (int i = 0; i < post.comments.length; i++) {
        final comment = post.comments[i];
        if (comment.user.avatarUrl.isNotEmpty &&
            !comment.user.avatarUrl.startsWith('http')) {
          final avatarFile = File(comment.user.avatarUrl);
          if (await avatarFile.exists()) {
            final ext = path.extension(comment.user.avatarUrl);
            final zipFileName =
                'moment_comment_avatar_${post.id}_${comment.id}$ext';
            files[zipFileName] = comment.user.avatarUrl;
          }
        }
        // 收集被回复者头像
        if (comment.replyTo != null &&
            comment.replyTo!.avatarUrl.isNotEmpty &&
            !comment.replyTo!.avatarUrl.startsWith('http')) {
          final replyAvatarFile = File(comment.replyTo!.avatarUrl);
          if (await replyAvatarFile.exists()) {
            final ext = path.extension(comment.replyTo!.avatarUrl);
            final zipFileName =
                'moment_reply_avatar_${post.id}_${comment.id}$ext';
            files[zipFileName] = comment.replyTo!.avatarUrl;
          }
        }
      }

      // 收集点赞用户头像
      for (int i = 0; i < post.likes.length; i++) {
        final likeUser = post.likes[i];
        if (likeUser.avatarUrl.isNotEmpty &&
            !likeUser.avatarUrl.startsWith('http')) {
          final avatarFile = File(likeUser.avatarUrl);
          if (await avatarFile.exists()) {
            final ext = path.extension(likeUser.avatarUrl);
            final zipFileName = 'moment_like_avatar_${post.id}_$i$ext';
            files[zipFileName] = likeUser.avatarUrl;
          }
        }
      }
    }

    // 3. 构建设置数据 (不包含Base64)
    final settings = {
      'homeWallpaper': {
        'index': _currentWallpaperIndex,
        'customPath': _customWallpaperPath != null
            ? 'wallpaper_home${path.extension(_customWallpaperPath!)}'
            : null,
      },
      'lockScreenWallpaper': {
        'index': _lockScreenWallpaperIndex,
        'customPath': _customLockScreenWallpaperPath != null
            ? 'wallpaper_lock${path.extension(_customLockScreenWallpaperPath!)}'
            : null,
      },
      'customIcons': _customAppIcons.map(
        (key, value) => MapEntry(key, 'icon_$key${path.extension(value)}'),
      ),
      'gridLayout': _gridPages,
      'system': {
        'brightness': _brightness,
        'volume': _volume,
        'isAirplaneMode': _isAirplaneMode,
        'isWifiEnabled': _isWifiEnabled,
        'isBluetoothEnabled': _isBluetoothEnabled,
        'isCellularEnabled': _isCellularEnabled,
        'isRotationLocked': _isRotationLocked,
        'isFocusMode': _isFocusMode,
      },
    };

    // 4. 添加数据库文件
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(path.join(dbFolder.path, 'db.sqlite'));
    if (await dbFile.exists()) {
      files['db.sqlite'] = dbFile.path;
    }
    // 尝试备份 WAL 和 SHM 文件 (如果存在)
    final dbWalFile = File(path.join(dbFolder.path, 'db.sqlite-wal'));
    if (await dbWalFile.exists()) {
      files['db.sqlite-wal'] = dbWalFile.path;
    }
    final dbShmFile = File(path.join(dbFolder.path, 'db.sqlite-shm'));
    if (await dbShmFile.exists()) {
      files['db.sqlite-shm'] = dbShmFile.path;
    }

    final zipService = ZipBackupService();
    return await zipService.createBackup(settings: settings, files: files);
  }

  // 导入设置
  Future<bool> importSettings(String jsonString) async {
    try {
      final settings = jsonDecode(jsonString) as Map<String, dynamic>;

      // 导入桌面壁纸设置
      if (settings['homeWallpaper'] != null) {
        final wallpaper = settings['homeWallpaper'] as Map<String, dynamic>;
        _currentWallpaperIndex = wallpaper['index'] ?? 0;

        // 优先尝试从Base64数据恢复文件
        final base64Data = wallpaper['data'] as String?;
        if (base64Data != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _customWallpaperPath = await _base64ToFile(
            base64Data,
            'wallpaper_$timestamp.jpg',
          );
        } else {
          _customWallpaperPath = wallpaper['customPath'];
        }
      }

      // 导入锁屏壁纸设置
      if (settings['lockScreenWallpaper'] != null) {
        final wallpaper =
            settings['lockScreenWallpaper'] as Map<String, dynamic>;
        _lockScreenWallpaperIndex = wallpaper['index'] ?? 0;

        // 优先尝试从Base64数据恢复文件
        final base64Data = wallpaper['data'] as String?;
        if (base64Data != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _customLockScreenWallpaperPath = await _base64ToFile(
            base64Data,
            'lockscreen_$timestamp.jpg',
          );
        } else {
          _customLockScreenWallpaperPath = wallpaper['customPath'];
        }
      }

      // 导入自定义图标
      if (settings['customIcons'] != null) {
        _customAppIcons = Map<String, String>.from(
          settings['customIcons'] as Map,
        );

        // 如果有Base64数据，恢复图标文件
        if (settings['customIconsData'] != null) {
          final iconsData = Map<String, String>.from(
            settings['customIconsData'] as Map,
          );

          for (final entry in iconsData.entries) {
            final appId = entry.key;
            final base64Data = entry.value;
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final newPath = await _base64ToFile(
              base64Data,
              'icon_${appId}_$timestamp.png',
            );

            if (newPath != null) {
              _customAppIcons[appId] = newPath;
            }
          }
        }
      }

      // 导入网格布局
      if (settings['gridLayout'] != null) {
        final decoded = settings['gridLayout'] as List;
        _gridPages = decoded.map((page) {
          return (page as List).map((item) => item as String?).toList();
        }).toList();
      }

      // 导入系统设置
      if (settings['system'] != null) {
        final system = settings['system'] as Map<String, dynamic>;
        _brightness = system['brightness'] ?? 0.7;
        _volume = system['volume'] ?? 0.5;
        _isAirplaneMode = system['isAirplaneMode'] ?? false;
        _isWifiEnabled = system['isWifiEnabled'] ?? true;
        _isBluetoothEnabled = system['isBluetoothEnabled'] ?? true;
        _isCellularEnabled = system['isCellularEnabled'] ?? true;
        _isRotationLocked = system['isRotationLocked'] ?? false;
        _isFocusMode = system['isFocusMode'] ?? false;
      }

      await _saveSettings();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import settings failed: $e');
      return false;
    }
  }

  // 从ZIP导入设置
  Future<bool> importSettingsFromZip(String zipPath) async {
    try {
      final zipService = ZipBackupService();
      final result = await zipService.restoreBackup(zipPath);

      final settings = result;
      final restoredImages =
          settings['_restoredImages'] as Map<String, String>? ?? {};

      // 恢复数据库文件
      // ZipBackupService 已经将文件解压到了 Documents 目录
      // 数据库文件已经就位，现在需要重新连接数据库以使用新文件

      // 重新连接数据库，这会关闭旧连接并打开新文件，同时触发必要的迁移
      // 注意：reconnect 后 _db 仍指向旧实例，必须使用返回的新实例
      AppDatabase? newDb;
      try {
        newDb = await AppDatabase.reconnect();
        debugPrint('数据库重连成功，导入的数据已生效');
      } catch (e) {
        debugPrint('数据库重连失败: $e');
        // 即使重连失败，我们仍然继续处理其他设置
        // 用户可能需要重启应用才能看到数据库变化
      }

      // 更新数据库中的头像路径（因为文件被恢复到新位置）
      if (newDb != null) {
        await _updateAvatarPathsAfterImport(newDb, restoredImages);
      }

      // 导入桌面壁纸设置
      if (settings['homeWallpaper'] != null) {
        final wallpaper = settings['homeWallpaper'] as Map<String, dynamic>;
        _currentWallpaperIndex = wallpaper['index'] ?? 0;

        final customPathInZip = wallpaper['customPath'] as String?;
        if (customPathInZip != null) {
          // 尝试多种 key 格式来查找恢复的文件
          if (restoredImages.containsKey(customPathInZip)) {
            _customWallpaperPath = restoredImages[customPathInZip];
          } else if (restoredImages.containsKey('images/$customPathInZip')) {
            _customWallpaperPath = restoredImages['images/$customPathInZip'];
          } else {
            debugPrint('警告：无法找到壁纸文件 $customPathInZip');
            _customWallpaperPath = null;
          }
        } else {
          _customWallpaperPath = null;
        }
      }

      // 导入锁屏壁纸设置
      if (settings['lockScreenWallpaper'] != null) {
        final wallpaper =
            settings['lockScreenWallpaper'] as Map<String, dynamic>;
        _lockScreenWallpaperIndex = wallpaper['index'] ?? 0;

        final customPathInZip = wallpaper['customPath'] as String?;
        if (customPathInZip != null) {
          if (restoredImages.containsKey(customPathInZip)) {
            _customLockScreenWallpaperPath = restoredImages[customPathInZip];
          } else if (restoredImages.containsKey('images/$customPathInZip')) {
            _customLockScreenWallpaperPath =
                restoredImages['images/$customPathInZip'];
          } else {
            debugPrint('警告：无法找到锁屏壁纸文件 $customPathInZip');
            _customLockScreenWallpaperPath = null;
          }
        } else {
          _customLockScreenWallpaperPath = null;
        }
      }

      // 导入自定义图标
      if (settings['customIcons'] != null) {
        final iconsMap = settings['customIcons'] as Map<String, dynamic>;
        _customAppIcons.clear();

        for (final entry in iconsMap.entries) {
          final appId = entry.key;
          final pathInZip = entry.value as String;

          if (restoredImages.containsKey(pathInZip)) {
            _customAppIcons[appId] = restoredImages[pathInZip]!;
          } else if (restoredImages.containsKey('images/$pathInZip')) {
            _customAppIcons[appId] = restoredImages['images/$pathInZip']!;
          } else {
            debugPrint('警告：无法找到图标文件 $pathInZip (appId: $appId)');
          }
        }
      }

      // 导入网格布局
      if (settings['gridLayout'] != null) {
        final decoded = settings['gridLayout'] as List;
        _gridPages = decoded.map((page) {
          return (page as List).map((item) => item as String?).toList();
        }).toList();
      }

      // 导入系统设置
      if (settings['system'] != null) {
        final system = settings['system'] as Map<String, dynamic>;
        _brightness = system['brightness'] ?? 0.7;
        _volume = system['volume'] ?? 0.5;
        _isAirplaneMode = system['isAirplaneMode'] ?? false;
        _isWifiEnabled = system['isWifiEnabled'] ?? true;
        _isBluetoothEnabled = system['isBluetoothEnabled'] ?? true;
        _isCellularEnabled = system['isCellularEnabled'] ?? true;
        _isRotationLocked = system['isRotationLocked'] ?? false;
        _isFocusMode = system['isFocusMode'] ?? false;
      }

      // 重要：使用新的数据库实例保存设置
      // _db 在 reconnect 后已经失效，必须使用新实例
      if (newDb != null) {
        await _saveSettingsToDb(newDb);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import settings from zip failed: $e');
      return false;
    }
  }

  /// 使用指定的数据库实例保存设置（用于导入后保存到新数据库）
  Future<void> _saveSettingsToDb(AppDatabase db) async {
    try {
      // 保存桌面壁纸
      await db.setSettingInt('wallpaper_index', _currentWallpaperIndex);
      if (_customWallpaperPath != null) {
        await db.setSetting('custom_wallpaper_path', _customWallpaperPath!);
      } else {
        await db.deleteSetting('custom_wallpaper_path');
      }

      // 保存锁屏壁纸
      await db.setSettingInt(
        'lockscreen_wallpaper_index',
        _lockScreenWallpaperIndex,
      );
      if (_customLockScreenWallpaperPath != null) {
        await db.setSetting(
          'custom_lockscreen_wallpaper_path',
          _customLockScreenWallpaperPath!,
        );
      } else {
        await db.deleteSetting('custom_lockscreen_wallpaper_path');
      }

      // 保存自定义图标
      await db.setSetting('custom_app_icons', jsonEncode(_customAppIcons));

      // 保存网格布局
      if (_gridPages.isNotEmpty) {
        await db.setSetting('grid_pages', jsonEncode(_gridPages));
      }

      // 保存系统设置
      await db.setSettingDouble('brightness', _brightness);
      await db.setSettingDouble('volume', _volume);
      await db.setSettingBool('airplane_mode', _isAirplaneMode);
      await db.setSettingBool('wifi_enabled', _isWifiEnabled);
      await db.setSettingBool('bluetooth_enabled', _isBluetoothEnabled);
      await db.setSettingBool('cellular_enabled', _isCellularEnabled);
      await db.setSettingBool('rotation_locked', _isRotationLocked);
      await db.setSettingBool('focus_mode', _isFocusMode);

      debugPrint('设置已成功保存到新数据库');
    } catch (e) {
      debugPrint('保存设置到新数据库失败: $e');
    }
  }

  /// 确保所有旧数据都已迁移到数据库（导出前调用）
  Future<void> _ensureDataMigratedToDatabase(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 迁移角色人设数据
    final rolesJson = prefs.getString('contact_roles');
    if (rolesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rolesJson);
        final roles =
            decoded.map((item) => ContactRole.fromJson(item)).toList();

        for (final role in roles) {
          await db.insertContactRole(role);
        }

        // 迁移成功后清除旧数据
        await prefs.remove('contact_roles');
        debugPrint('[导出] 已迁移 ${roles.length} 个角色人设到数据库');
      } catch (e) {
        debugPrint('[导出] 迁移角色人设失败: $e');
      }
    }

    // 2. 迁移用户人设数据
    final meListJson = prefs.getString('contact_me_list');
    if (meListJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(meListJson);
        final meList = decoded.map((item) => ContactMe.fromJson(item)).toList();

        for (final me in meList) {
          await db.insertContactMe(me);
        }

        // 迁移成功后清除旧数据
        await prefs.remove('contact_me_list');
        debugPrint('[导出] 已迁移 ${meList.length} 个用户人设到数据库');
      } catch (e) {
        debugPrint('[导出] 迁移用户人设失败: $e');
      }
    }

    // 3. 迁移 API 预设数据
    final presetsJson = prefs.getStringList('api_presets');
    if (presetsJson != null && presetsJson.isNotEmpty) {
      try {
        final presets = presetsJson
            .map((json) => ApiPreset.fromJson(jsonDecode(json)))
            .toList();

        for (final preset in presets) {
          await db.insertApiPreset(preset);
        }

        // 迁移成功后清除旧数据
        await prefs.remove('api_presets');
        debugPrint('[导出] 已迁移 ${presets.length} 个 API 预设到数据库');
      } catch (e) {
        debugPrint('[导出] 迁移 API 预设失败: $e');
      }
    }

    // 4. 迁移朋友圈用户设置
    final momentsUserJson = prefs.getString('moments_current_user');
    if (momentsUserJson != null) {
      try {
        final userData = jsonDecode(momentsUserJson) as Map<String, dynamic>;
        await db.saveMomentsUserSettings(
          name: userData['name'] ?? '我',
          avatarUrl: userData['avatarUrl'],
          coverImageUrl: userData['coverImageUrl'],
          signature: userData['signature'],
        );

        // 迁移成功后清除旧数据
        await prefs.remove('moments_current_user');
        debugPrint('[导出] 已迁移朋友圈用户设置到数据库');
      } catch (e) {
        debugPrint('[导出] 迁移朋友圈用户设置失败: $e');
      }
    }
  }

  /// 导入后更新数据库中的图片路径（头像、背景图、朋友圈图片等）
  Future<void> _updateAvatarPathsAfterImport(
    AppDatabase db,
    Map<String, String> restoredImages,
  ) async {
    try {
      // 1. 更新角色头像路径
      final roles = await db.getAllContactRoles();
      for (final role in roles) {
        String? newAvatarPath;
        for (final entry in restoredImages.entries) {
          if (entry.key.contains('role_avatar_${role.id}') ||
              entry.value.contains('role_avatar_${role.id}')) {
            newAvatarPath = entry.value;
            break;
          }
        }

        if (newAvatarPath != null && newAvatarPath != role.avatarPath) {
          final updatedRole = ContactRole(
            id: role.id,
            name: role.name,
            avatarPath: newAvatarPath,
            description: role.description,
          );
          await db.insertContactRole(updatedRole);
          debugPrint('已更新角色 ${role.name} 的头像路径');
        }
      }

      // 2. 更新用户头像路径
      final meList = await db.getAllContactMes();
      for (final me in meList) {
        String? newAvatarPath;
        for (final entry in restoredImages.entries) {
          if (entry.key.contains('me_avatar_${me.id}') ||
              entry.value.contains('me_avatar_${me.id}')) {
            newAvatarPath = entry.value;
            break;
          }
        }

        if (newAvatarPath != null && newAvatarPath != me.avatarPath) {
          final updatedMe = ContactMe(
            id: me.id,
            name: me.name,
            avatarPath: newAvatarPath,
            info: me.info,
          );
          await db.insertContactMe(updatedMe);
          debugPrint('已更新用户 ${me.name} 的头像路径');
        }
      }

      // 3. 更新朋友圈头像和封面路径
      final momentsSettings = await db.getMomentsUserSettings();
      if (momentsSettings != null) {
        String? newAvatarUrl;
        String? newCoverUrl;

        for (final entry in restoredImages.entries) {
          if (entry.key.contains('moments_avatar') ||
              entry.value.contains('moments_avatar')) {
            newAvatarUrl = entry.value;
            break;
          }
        }

        for (final entry in restoredImages.entries) {
          if (entry.key.contains('moments_cover') ||
              entry.value.contains('moments_cover')) {
            newCoverUrl = entry.value;
            break;
          }
        }

        if (newAvatarUrl != null || newCoverUrl != null) {
          await db.saveMomentsUserSettings(
            name: momentsSettings.name,
            avatarUrl: newAvatarUrl ?? momentsSettings.avatarUrl,
            coverImageUrl: newCoverUrl ?? momentsSettings.coverImageUrl,
            signature: momentsSettings.signature,
          );
          debugPrint('已更新朋友圈用户的头像/封面路径');
        }
      }

      // 4. 更新聊天背景图路径
      final sessions = await db.getAllSessions();
      for (final session in sessions) {
        if (session.backgroundImage != null &&
            session.backgroundImage!.isNotEmpty) {
          String? newBgPath;
          for (final entry in restoredImages.entries) {
            if (entry.key.contains('chat_bg_${session.id}') ||
                entry.value.contains('chat_bg_${session.id}')) {
              newBgPath = entry.value;
              break;
            }
          }

          if (newBgPath != null && newBgPath != session.backgroundImage) {
            await db.updateSessionBackgroundImage(session.id, newBgPath);
            debugPrint('已更新会话 ${session.id} 的背景图路径');
          }
        }
      }

      // 5. 更新朋友圈动态中的图片路径
      final moments = await db.getAllMoments();
      for (final post in moments) {
        bool needsUpdate = false;

        // 5.1 更新媒体项路径
        final updatedMediaItems = <MediaItem>[];
        for (int i = 0; i < post.mediaItems.length; i++) {
          final item = post.mediaItems[i];
          String newUrl = item.url;
          String? newThumbUrl = item.thumbnailUrl;

          // 查找媒体文件
          for (final entry in restoredImages.entries) {
            if (entry.key.contains('moment_media_${post.id}_$i') ||
                entry.value.contains('moment_media_${post.id}_$i')) {
              newUrl = entry.value;
              needsUpdate = true;
              break;
            }
          }

          // 查找缩略图
          if (item.thumbnailUrl != null) {
            for (final entry in restoredImages.entries) {
              if (entry.key.contains('moment_thumb_${post.id}_$i') ||
                  entry.value.contains('moment_thumb_${post.id}_$i')) {
                newThumbUrl = entry.value;
                needsUpdate = true;
                break;
              }
            }
          }

          updatedMediaItems.add(MediaItem(
            url: newUrl,
            type: item.type,
            thumbnailUrl: newThumbUrl,
          ));
        }

        // 5.2 更新发布者头像
        String newUserAvatarUrl = post.user.avatarUrl;
        for (final entry in restoredImages.entries) {
          if (entry.key.contains('moment_user_avatar_${post.id}') ||
              entry.value.contains('moment_user_avatar_${post.id}')) {
            newUserAvatarUrl = entry.value;
            needsUpdate = true;
            break;
          }
        }
        final updatedUser = post.user.copyWith(avatarUrl: newUserAvatarUrl);

        // 5.3 更新评论者头像
        final updatedComments = <MomentsComment>[];
        for (int i = 0; i < post.comments.length; i++) {
          final comment = post.comments[i];

          // 评论者头像
          String newCommentAvatarUrl = comment.user.avatarUrl;
          for (final entry in restoredImages.entries) {
            if (entry.key.contains(
                    'moment_comment_avatar_${post.id}_${comment.id}') ||
                entry.value.contains(
                    'moment_comment_avatar_${post.id}_${comment.id}')) {
              newCommentAvatarUrl = entry.value;
              needsUpdate = true;
              break;
            }
          }

          // 被回复者头像
          MomentsUser? updatedReplyTo = comment.replyTo;
          if (comment.replyTo != null) {
            String newReplyAvatarUrl = comment.replyTo!.avatarUrl;
            for (final entry in restoredImages.entries) {
              if (entry.key.contains(
                      'moment_reply_avatar_${post.id}_${comment.id}') ||
                  entry.value.contains(
                      'moment_reply_avatar_${post.id}_${comment.id}')) {
                newReplyAvatarUrl = entry.value;
                needsUpdate = true;
                break;
              }
            }
            updatedReplyTo =
                comment.replyTo!.copyWith(avatarUrl: newReplyAvatarUrl);
          }

          updatedComments.add(MomentsComment(
            id: comment.id,
            user: comment.user.copyWith(avatarUrl: newCommentAvatarUrl),
            content: comment.content,
            createdAt: comment.createdAt,
            replyTo: updatedReplyTo,
          ));
        }

        // 5.4 更新点赞用户头像
        final updatedLikes = <MomentsUser>[];
        for (int i = 0; i < post.likes.length; i++) {
          final likeUser = post.likes[i];
          String newLikeAvatarUrl = likeUser.avatarUrl;
          for (final entry in restoredImages.entries) {
            if (entry.key.contains('moment_like_avatar_${post.id}_$i') ||
                entry.value.contains('moment_like_avatar_${post.id}_$i')) {
              newLikeAvatarUrl = entry.value;
              needsUpdate = true;
              break;
            }
          }
          updatedLikes.add(likeUser.copyWith(avatarUrl: newLikeAvatarUrl));
        }

        // 如果有更新，保存到数据库
        if (needsUpdate) {
          final updatedPost = MomentsPost(
            id: post.id,
            user: updatedUser,
            content: post.content,
            mediaItems: updatedMediaItems,
            createdAt: post.createdAt,
            likes: updatedLikes,
            comments: updatedComments,
            location: post.location,
          );
          await db.insertMoment(updatedPost);
          debugPrint('已更新朋友圈动态 ${post.id} 的图片路径');
        }
      }

      debugPrint('所有图片路径更新完成');
    } catch (e) {
      debugPrint('更新图片路径失败: $e');
    }
  }

  // 重置到默认状态
  void reset() {
    _loadDefaultData();
    _runningAppIds.clear();
    _isAirplaneMode = false;
    _isWifiEnabled = true;
    _isBluetoothEnabled = true;
    _isCellularEnabled = true;
    _isRotationLocked = false;
    _isFocusMode = false;
    _brightness = 0.7;
    _volume = 0.5;
    _currentWallpaperIndex = 0;
    _customWallpaperPath = null;
    _lockScreenWallpaperIndex = 0;
    _customLockScreenWallpaperPath = null;
    _customAppIcons.clear();
    _gridPages.clear();
    _isEditingHome = false;
    _saveSettings();
    notifyListeners();
  }

  // ==================== 壁纸管理系统 ====================

  /// 初始化壁纸系统
  Future<void> _initializeWallpaperSystem() async {
    await _loadWallpaperSettings();
    await _updateDailyWallpaper();
  }

  /// 加载壁纸相关设置
  /// 注意：所有设置现在存储在数据库中，SharedPreferences 已被弃用
  Future<void> _loadWallpaperSettings() async {
    try {
      // [已弃用] SharedPreferences 仅用于兼容迁移
      final prefs = await SharedPreferences.getInstance();

      // 检查是否需要迁移壁纸池设置
      final needsMigration = !(await _db.hasSetting('wallpaper_pool'));

      if (needsMigration) {
        // 从 SharedPreferences 迁移壁纸池设置
        final poolJson = prefs.getString('wallpaper_pool');
        if (poolJson != null) {
          await _db.setSetting('wallpaper_pool', poolJson);
        }

        final poolIndex = prefs.getInt('current_wallpaper_pool_index');
        if (poolIndex != null) {
          await _db.setSettingInt('current_wallpaper_pool_index', poolIndex);
        }

        final lastUpdate = prefs.getString('last_wallpaper_update_date');
        if (lastUpdate != null) {
          await _db.setSetting('last_wallpaper_update_date', lastUpdate);
        }
      }

      // 从数据库加载壁纸池设置
      final poolJson = await _db.getSetting('wallpaper_pool');
      if (poolJson != null) {
        final decoded = jsonDecode(poolJson) as List;
        _wallpaperPool = decoded.map((e) => e as String).toList();
      }

      _currentWallpaperPoolIndex =
          await _db.getSettingInt('current_wallpaper_pool_index') ?? 0;

      _lastWallpaperUpdateDate =
          await _db.getSetting('last_wallpaper_update_date');

      debugPrint(
          '壁纸设置加载完成: 池大小=${_wallpaperPool.length}, 当前索引=$_currentWallpaperPoolIndex, 上次更新=$_lastWallpaperUpdateDate');
    } catch (e) {
      debugPrint('加载壁纸设置失败: $e');
    }
  }

  /// 保存壁纸相关设置
  /// 注意：所有设置现在存储在数据库中
  Future<void> _saveWallpaperSettings() async {
    try {
      // 保存壁纸池
      await _db.setSetting('wallpaper_pool', jsonEncode(_wallpaperPool));

      // 保存当前索引
      await _db.setSettingInt(
          'current_wallpaper_pool_index', _currentWallpaperPoolIndex);

      // 保存上次更新日期
      if (_lastWallpaperUpdateDate != null) {
        await _db.setSetting(
            'last_wallpaper_update_date', _lastWallpaperUpdateDate!);
      }

      debugPrint('壁纸设置保存成功');
    } catch (e) {
      debugPrint('保存壁纸设置失败: $e');
    }
  }

  /// 检查并更新每日壁纸
  Future<void> _updateDailyWallpaper() async {
    try {
      final today = _getTodayDateString();

      // 如果是同一天，不需要更新
      if (_lastWallpaperUpdateDate == today && _wallpaperPool.isNotEmpty) {
        debugPrint('今日壁纸已设置，保持不变');
        return;
      }

      // 日期变化了，需要异步下载新壁纸
      debugPrint('检测到日期变化（从 $_lastWallpaperUpdateDate 到 $today），准备异步下载新壁纸...');

      // 先更新日期，防止重复触发下载
      _lastWallpaperUpdateDate = today;
      await _saveWallpaperSettings();

      // 异步下载新壁纸（不阻塞UI）
      _downloadDailyWallpaperAsync();
    } catch (e) {
      debugPrint('更新每日壁纸失败: $e');
    }
  }

  /// 异步下载每日壁纸（不阻塞UI）
  void _downloadDailyWallpaperAsync() {
    // 使用异步方式下载，不等待完成
    Future(() async {
      if (_isDownloadingWallpapers) {
        debugPrint('壁纸正在下载中，跳过');
        return;
      }

      _isDownloadingWallpapers = true;
      notifyListeners();

      try {
        final directory = await getApplicationDocumentsDirectory();
        final wallpaperDir =
            Directory(path.join(directory.path, 'daily_wallpapers'));

        // 确保目录存在
        if (!await wallpaperDir.exists()) {
          await wallpaperDir.create(recursive: true);
        }

        // 使用当天日期作为种子，确保每天的壁纸不同但同一天总是相同
        final today = DateTime.now();
        final seed = today.year * 10000 + today.month * 100 + today.day;
        final url = 'https://picsum.photos/1080/1920?random=$seed';

        debugPrint('开始下载今日壁纸: $url');

        final response = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 30),
            );

        if (response.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'wallpaper_$timestamp.jpg';
          final filePath = path.join(wallpaperDir.path, fileName);
          final file = File(filePath);

          await file.writeAsBytes(response.bodyBytes);

          // 删除旧壁纸
          if (_wallpaperPool.isNotEmpty) {
            for (final oldPath in _wallpaperPool) {
              try {
                final oldFile = File(oldPath);
                if (await oldFile.exists()) {
                  await oldFile.delete();
                  debugPrint('已删除旧壁纸: $oldPath');
                }
              } catch (e) {
                debugPrint('删除旧壁纸失败: $e');
              }
            }
          }

          // 更新壁纸池
          _wallpaperPool.clear();
          _wallpaperPool.add(filePath);
          _currentWallpaperPoolIndex = 0;

          await _saveWallpaperSettings();
          notifyListeners();

          debugPrint('今日壁纸下载成功: $fileName');
        } else {
          debugPrint('下载失败，状态码: ${response.statusCode}，将继续使用旧壁纸');
        }
      } catch (e) {
        debugPrint('下载壁纸失败: $e，将继续使用旧壁纸');
      } finally {
        _isDownloadingWallpapers = false;
        notifyListeners();
      }
    });
  }

  /// 下载壁纸到壁纸池（手动调用时使用）
  Future<void> _checkAndDownloadWallpapers() async {
    if (_isDownloadingWallpapers) {
      debugPrint('壁纸正在下载中，跳过');
      return;
    }

    _isDownloadingWallpapers = true;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final wallpaperDir =
          Directory(path.join(directory.path, 'daily_wallpapers'));

      // 确保目录存在
      if (!await wallpaperDir.exists()) {
        await wallpaperDir.create(recursive: true);
      }

      // 使用当天日期作为种子
      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final url = 'https://picsum.photos/1080/1920?random=$seed';

      debugPrint('开始下载壁纸: $url');

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'wallpaper_$timestamp.jpg';
        final filePath = path.join(wallpaperDir.path, fileName);
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        // 删除旧壁纸
        if (_wallpaperPool.isNotEmpty) {
          for (final oldPath in _wallpaperPool) {
            try {
              final oldFile = File(oldPath);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
            } catch (e) {
              debugPrint('删除旧壁纸失败: $e');
            }
          }
        }

        _wallpaperPool.clear();
        _wallpaperPool.add(filePath);
        _currentWallpaperPoolIndex = 0;

        debugPrint('壁纸下载成功: $fileName');
      } else {
        debugPrint('下载失败，状态码: ${response.statusCode}');
      }

      // 保存更新后的壁纸池
      await _saveWallpaperSettings();
      debugPrint('壁纸池更新完成，当前池大小: ${_wallpaperPool.length}');
    } catch (e) {
      debugPrint('下载壁纸失败: $e');
    } finally {
      _isDownloadingWallpapers = false;
      notifyListeners();
    }
  }

  /// 手动刷新壁纸（供用户主动调用）
  Future<void> refreshDailyWallpaper() async {
    await _updateDailyWallpaper();
  }

  /// 手动触发下载壁纸（供设置界面使用）
  Future<void> downloadWallpapers() async {
    await _checkAndDownloadWallpapers();
  }

  /// 清理壁纸池
  Future<void> clearWallpaperPool() async {
    try {
      // 删除所有壁纸文件
      for (final wallpaperPath in _wallpaperPool) {
        try {
          final file = File(wallpaperPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('删除壁纸文件失败: $e');
        }
      }

      // 清空壁纸池
      _wallpaperPool.clear();
      _currentWallpaperPoolIndex = 0;
      _lastWallpaperUpdateDate = null;

      await _saveWallpaperSettings();
      notifyListeners();

      debugPrint('壁纸池已清空');
    } catch (e) {
      debugPrint('清理壁纸池失败: $e');
    }
  }

  /// 获取今天的日期字符串 (yyyy-MM-dd)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
