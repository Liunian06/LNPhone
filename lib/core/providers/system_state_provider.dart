import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../services/zip_backup_service.dart';
import '../models/app_model.dart';
import '../data/default_apps.dart';

/// 系统状态Provider
class SystemStateProvider extends ChangeNotifier {
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

  SystemStateProvider() {
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
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存桌面壁纸
      await prefs.setInt('wallpaper_index', _currentWallpaperIndex);
      if (_customWallpaperPath != null) {
        await prefs.setString('custom_wallpaper_path', _customWallpaperPath!);
      } else {
        await prefs.remove('custom_wallpaper_path');
      }

      // 保存锁屏壁纸
      await prefs.setInt(
        'lockscreen_wallpaper_index',
        _lockScreenWallpaperIndex,
      );
      if (_customLockScreenWallpaperPath != null) {
        await prefs.setString(
          'custom_lockscreen_wallpaper_path',
          _customLockScreenWallpaperPath!,
        );
      } else {
        await prefs.remove('custom_lockscreen_wallpaper_path');
      }

      // 保存自定义图标
      await prefs.setString('custom_app_icons', jsonEncode(_customAppIcons));

      // 保存网格布局
      if (_gridPages.isNotEmpty) {
        await prefs.setString('grid_pages', jsonEncode(_gridPages));
      }

      // 保存系统设置
      await prefs.setDouble('brightness', _brightness);
      await prefs.setDouble('volume', _volume);
      await prefs.setBool('airplane_mode', _isAirplaneMode);
      await prefs.setBool('wifi_enabled', _isWifiEnabled);
      await prefs.setBool('bluetooth_enabled', _isBluetoothEnabled);
      await prefs.setBool('cellular_enabled', _isCellularEnabled);
      await prefs.setBool('rotation_locked', _isRotationLocked);
      await prefs.setBool('focus_mode', _isFocusMode);
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  // 持久化存储 - 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载桌面壁纸
      _currentWallpaperIndex = prefs.getInt('wallpaper_index') ?? 0;
      // 确保索引在有效范围内（0-6），移除任何强制修正逻辑
      _currentWallpaperIndex = _currentWallpaperIndex.clamp(0, 6);
      _customWallpaperPath = prefs.getString('custom_wallpaper_path');

      // 加载锁屏壁纸
      _lockScreenWallpaperIndex =
          prefs.getInt('lockscreen_wallpaper_index') ?? 0;
      // 确保索引在有效范围内（0-6）
      _lockScreenWallpaperIndex = _lockScreenWallpaperIndex.clamp(0, 6);
      _customLockScreenWallpaperPath = prefs.getString(
        'custom_lockscreen_wallpaper_path',
      );

      // 加载自定义图标
      final iconsJson = prefs.getString('custom_app_icons');
      if (iconsJson != null) {
        _customAppIcons = Map<String, String>.from(jsonDecode(iconsJson));
      }

      // 加载网格布局
      final gridJson = prefs.getString('grid_pages');
      if (gridJson != null) {
        final decoded = jsonDecode(gridJson) as List;
        _gridPages = decoded.map((page) {
          return (page as List).map((item) => item as String?).toList();
        }).toList();
      }

      // 加载系统设置
      _brightness = prefs.getDouble('brightness') ?? 0.7;
      _volume = prefs.getDouble('volume') ?? 0.5;
      _isAirplaneMode = prefs.getBool('airplane_mode') ?? false;
      _isWifiEnabled = prefs.getBool('wifi_enabled') ?? true;
      _isBluetoothEnabled = prefs.getBool('bluetooth_enabled') ?? true;
      _isCellularEnabled = prefs.getBool('cellular_enabled') ?? true;
      _isRotationLocked = prefs.getBool('rotation_locked') ?? false;
      _isFocusMode = prefs.getBool('focus_mode') ?? false;

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
      _isLoaded = true;
      notifyListeners();
    }
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
    // 聊天背景图路径存储在数据库中，我们需要扫描 Documents 目录下的 chat_bg_* 文件
    final docDir = await getApplicationDocumentsDirectory();
    final docDirList = await docDir.list().toList();
    for (final entity in docDirList) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        if (fileName.startsWith('chat_bg_')) {
          files[fileName] = entity.path;
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
      // 如果 db.sqlite 存在，它应该已经被覆盖了（或者我们需要手动移动它）
      // ZipBackupService 的 restoreBackup 方法会将所有文件解压到 Documents 目录
      // 所以 db.sqlite 应该已经就位了。
      // 但是，我们需要重启数据库连接或者应用才能生效。
      // 目前我们假设用户重启应用后生效，或者我们可以在这里触发数据库重连（比较复杂）。
      // 简单起见，提示用户重启。

      // 导入桌面壁纸设置
      if (settings['homeWallpaper'] != null) {
        final wallpaper = settings['homeWallpaper'] as Map<String, dynamic>;
        _currentWallpaperIndex = wallpaper['index'] ?? 0;

        final customPathInZip = wallpaper['customPath'] as String?;
        if (customPathInZip != null) {
          if (restoredImages.containsKey(customPathInZip)) {
            _customWallpaperPath = restoredImages[customPathInZip];
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
        if (customPathInZip != null &&
            restoredImages.containsKey(customPathInZip)) {
          _customLockScreenWallpaperPath = restoredImages[customPathInZip];
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
      debugPrint('Import settings from zip failed: $e');
      return false;
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
  Future<void> _loadWallpaperSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载壁纸池路径列表
      final poolJson = prefs.getString('wallpaper_pool');
      if (poolJson != null) {
        final decoded = jsonDecode(poolJson) as List;
        _wallpaperPool = decoded.map((e) => e as String).toList();
      }

      // 加载当前壁纸索引
      _currentWallpaperPoolIndex =
          prefs.getInt('current_wallpaper_pool_index') ?? 0;

      // 加载上次更新日期
      _lastWallpaperUpdateDate = prefs.getString('last_wallpaper_update_date');

      debugPrint(
          '壁纸设置加载完成: 池大小=${_wallpaperPool.length}, 当前索引=$_currentWallpaperPoolIndex, 上次更新=$_lastWallpaperUpdateDate');
    } catch (e) {
      debugPrint('加载壁纸设置失败: $e');
    }
  }

  /// 保存壁纸相关设置
  Future<void> _saveWallpaperSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存壁纸池
      await prefs.setString('wallpaper_pool', jsonEncode(_wallpaperPool));

      // 保存当前索引
      await prefs.setInt(
          'current_wallpaper_pool_index', _currentWallpaperPoolIndex);

      // 保存上次更新日期
      if (_lastWallpaperUpdateDate != null) {
        await prefs.setString(
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
