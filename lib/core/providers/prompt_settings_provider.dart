import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../models/prompt_config.dart';

/// Prompt设置提供者
/// 注意：所有设置现在存储在数据库中
/// SharedPreferences 已被弃用，仅用于兼容迁移
class PromptSettingsProvider extends ChangeNotifier {
  final AppDatabase _db;

  String _roleplayPrompt = '';
  String _realityPrompt = '';
  bool _enableRealityPrompt = true;
  int _contextLength = 10; // Number of messages
  int _delayedReplySeconds = 10; // 延迟回复时间（秒），0表示立即回复
  bool _enableBackgroundActiveReply = true; // 是否开启后台主动回复
  int _backgroundActiveReplyInterval = 60; // 后台主动回复间隔（分钟）

  String get roleplayPrompt => _roleplayPrompt;
  String get realityPrompt => _realityPrompt;
  bool get enableRealityPrompt => _enableRealityPrompt;
  int get contextLength => _contextLength;
  int get delayedReplySeconds => _delayedReplySeconds;
  bool get enableBackgroundActiveReply => _enableBackgroundActiveReply;
  int get backgroundActiveReplyInterval => _backgroundActiveReplyInterval;

  PromptConfig get config => PromptConfig(
        roleplayPrompt: _roleplayPrompt,
        realityPrompt: _realityPrompt,
        enableRealityPrompt: _enableRealityPrompt,
        contextLength: _contextLength,
      );

  PromptSettingsProvider(this._db) {
    _loadSettings();
  }

  /// 从数据库加载设置，并从 SharedPreferences 迁移旧数据
  Future<void> _loadSettings() async {
    // 无论数据库是否有数据，都尝试从 SharedPreferences 迁移
    // 这样可以确保从任何中间版本升级时都不会丢失数据
    await _migrateFromSharedPreferences();

    // 从数据库加载设置
    await _loadFromDatabase();
  }

  /// 从 SharedPreferences 迁移数据到数据库
  /// 使用增量更新策略：只添加数据库中不存在的设置，不覆盖已有数据
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasMigrated = false;

    try {
      // 迁移 roleplay_prompt（增量更新：只在数据库中没有时添加）
      final roleplayPromptFromPrefs = prefs.getString('roleplay_prompt');
      if (roleplayPromptFromPrefs != null) {
        if (!(await _db.hasSetting('roleplay_prompt'))) {
          await _db.setSetting('roleplay_prompt', roleplayPromptFromPrefs);
          debugPrint('[PromptSettings] 已增量添加 roleplay_prompt');
        }
        await prefs.remove('roleplay_prompt');
        hasMigrated = true;
      }

      // 迁移 reality_prompt（增量更新：只在数据库中没有时添加）
      final realityPromptFromPrefs = prefs.getString('reality_prompt');
      if (realityPromptFromPrefs != null) {
        if (!(await _db.hasSetting('reality_prompt'))) {
          await _db.setSetting('reality_prompt', realityPromptFromPrefs);
          debugPrint('[PromptSettings] 已增量添加 reality_prompt');
        }
        await prefs.remove('reality_prompt');
        hasMigrated = true;
      }

      // 迁移 enable_reality_prompt（增量更新）
      if (prefs.containsKey('enable_reality_prompt')) {
        final value = prefs.getBool('enable_reality_prompt');
        if (value != null && !(await _db.hasSetting('enable_reality_prompt'))) {
          await _db.setSettingBool('enable_reality_prompt', value);
        }
        await prefs.remove('enable_reality_prompt');
        hasMigrated = true;
      }

      // 迁移 context_length（增量更新）
      // 同时检查驼峰命名和蛇形命名（兼容旧版本）
      int? contextLengthValue;
      if (prefs.containsKey('contextLength')) {
        contextLengthValue = prefs.getInt('contextLength');
        await prefs.remove('contextLength');
        hasMigrated = true;
      }
      if (prefs.containsKey('context_length')) {
        contextLengthValue ??= prefs.getInt('context_length');
        await prefs.remove('context_length');
        hasMigrated = true;
      }
      if (contextLengthValue != null &&
          !(await _db.hasSetting('context_length'))) {
        await _db.setSettingInt('context_length', contextLengthValue);
        debugPrint(
            '[PromptSettings] 已增量添加 context_length: $contextLengthValue');
      }

      // 迁移 delayed_reply_seconds（增量更新）
      // 同时检查驼峰命名和蛇形命名（兼容旧版本）
      int? delayedReplyValue;
      if (prefs.containsKey('delayedReplySeconds')) {
        delayedReplyValue = prefs.getInt('delayedReplySeconds');
        await prefs.remove('delayedReplySeconds');
        hasMigrated = true;
      }
      if (prefs.containsKey('delayed_reply_seconds')) {
        delayedReplyValue ??= prefs.getInt('delayed_reply_seconds');
        await prefs.remove('delayed_reply_seconds');
        hasMigrated = true;
      }
      if (delayedReplyValue != null &&
          !(await _db.hasSetting('delayed_reply_seconds'))) {
        await _db.setSettingInt('delayed_reply_seconds', delayedReplyValue);
        debugPrint(
            '[PromptSettings] 已增量添加 delayed_reply_seconds: $delayedReplyValue');
      }

      // 迁移 enable_background_active_reply（增量更新）
      // 同时检查驼峰命名和蛇形命名（兼容旧版本）
      bool? enableBackgroundValue;
      if (prefs.containsKey('enableBackgroundActiveReply')) {
        enableBackgroundValue = prefs.getBool('enableBackgroundActiveReply');
        await prefs.remove('enableBackgroundActiveReply');
        hasMigrated = true;
      }
      if (prefs.containsKey('enable_background_active_reply')) {
        enableBackgroundValue ??=
            prefs.getBool('enable_background_active_reply');
        await prefs.remove('enable_background_active_reply');
        hasMigrated = true;
      }
      if (enableBackgroundValue != null &&
          !(await _db.hasSetting('enable_background_active_reply'))) {
        await _db.setSettingBool(
            'enable_background_active_reply', enableBackgroundValue);
        debugPrint(
            '[PromptSettings] 已增量添加 enable_background_active_reply: $enableBackgroundValue');
      }

      // 迁移 background_active_reply_interval（增量更新）
      // 同时检查驼峰命名和蛇形命名（兼容旧版本）
      int? backgroundIntervalValue;
      if (prefs.containsKey('backgroundActiveReplyInterval')) {
        backgroundIntervalValue = prefs.getInt('backgroundActiveReplyInterval');
        await prefs.remove('backgroundActiveReplyInterval');
        hasMigrated = true;
      }
      if (prefs.containsKey('background_active_reply_interval')) {
        backgroundIntervalValue ??=
            prefs.getInt('background_active_reply_interval');
        await prefs.remove('background_active_reply_interval');
        hasMigrated = true;
      }
      if (backgroundIntervalValue != null &&
          !(await _db.hasSetting('background_active_reply_interval'))) {
        await _db.setSettingInt(
            'background_active_reply_interval', backgroundIntervalValue);
        debugPrint(
            '[PromptSettings] 已增量添加 background_active_reply_interval: $backgroundIntervalValue');
      }

      if (hasMigrated) {
        debugPrint('[PromptSettings] 数据迁移完成');
      }
    } catch (e) {
      debugPrint('[PromptSettings] 数据迁移失败: $e');
    }
  }

  /// 从数据库加载设置
  Future<void> _loadFromDatabase() async {
    // 加载 roleplay_prompt
    String? roleplayPrompt = await _db.getSetting('roleplay_prompt');
    if (roleplayPrompt == null) {
      // 如果数据库中没有，加载默认值
      try {
        roleplayPrompt = await rootBundle.loadString(
          'assets/prompts/roleplay_prompt.txt',
        );
      } catch (e) {
        debugPrint('Error loading roleplay_prompt: $e');
        roleplayPrompt = '你是一个AI助手，正在进行角色扮演任务。请完全沉浸在设定的角色中，不要暴露你是AI的身份。';
      }
      await _db.setSetting('roleplay_prompt', roleplayPrompt);
    }
    _roleplayPrompt = roleplayPrompt;

    // 加载 reality_prompt
    String? realityPrompt = await _db.getSetting('reality_prompt');
    if (realityPrompt == null) {
      try {
        realityPrompt = await rootBundle.loadString(
          'assets/prompts/reality_prompt.txt',
        );
      } catch (e) {
        debugPrint('Error loading reality_prompt: $e');
        realityPrompt = '当前时间：{time}。当前日期：{date}。';
      }
      await _db.setSetting('reality_prompt', realityPrompt);
    }
    _realityPrompt = realityPrompt;

    // 加载其他设置
    _enableRealityPrompt = await _db.getSettingBool('enable_reality_prompt') ??
        _enableRealityPrompt;
    _contextLength =
        await _db.getSettingInt('context_length') ?? _contextLength;
    _delayedReplySeconds = await _db.getSettingInt('delayed_reply_seconds') ??
        _delayedReplySeconds;
    _enableBackgroundActiveReply =
        await _db.getSettingBool('enable_background_active_reply') ??
            _enableBackgroundActiveReply;
    _backgroundActiveReplyInterval =
        await _db.getSettingInt('background_active_reply_interval') ??
            _backgroundActiveReplyInterval;

    notifyListeners();
  }

  /// 更新角色扮演提示词
  Future<void> updateRoleplayPrompt(String value) async {
    _roleplayPrompt = value;
    await _db.setSetting('roleplay_prompt', value);
    notifyListeners();
  }

  /// 更新现实注入提示词
  Future<void> updateRealityPrompt(String value) async {
    _realityPrompt = value;
    await _db.setSetting('reality_prompt', value);
    notifyListeners();
  }

  /// 切换现实注入提示词开关
  Future<void> toggleRealityPrompt(bool value) async {
    _enableRealityPrompt = value;
    await _db.setSettingBool('enable_reality_prompt', value);
    notifyListeners();
  }

  /// 更新上下文长度
  Future<void> updateContextLength(int value) async {
    _contextLength = value;
    await _db.setSettingInt('context_length', value);
    notifyListeners();
  }

  /// 更新延迟回复秒数
  Future<void> updateDelayedReplySeconds(int value) async {
    _delayedReplySeconds = value;
    await _db.setSettingInt('delayed_reply_seconds', value);
    notifyListeners();
  }

  /// 切换后台主动回复开关
  Future<void> toggleBackgroundActiveReply(bool value) async {
    _enableBackgroundActiveReply = value;
    await _db.setSettingBool('enable_background_active_reply', value);
    notifyListeners();
  }

  /// 更新后台主动回复间隔
  Future<void> updateBackgroundActiveReplyInterval(int value) async {
    _backgroundActiveReplyInterval = value;
    await _db.setSettingInt('background_active_reply_interval', value);
    notifyListeners();
  }
}
