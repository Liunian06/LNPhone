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
    // [已弃用] SharedPreferences 仅用于兼容迁移
    final prefs = await SharedPreferences.getInstance();

    // 检查是否需要迁移（如果数据库中没有 roleplay_prompt，则尝试迁移）
    final needsMigration = !(await _db.hasSetting('roleplay_prompt'));

    if (needsMigration) {
      debugPrint('[PromptSettings] 开始从 SharedPreferences 迁移数据到数据库...');
      await _migrateFromSharedPreferences(prefs);
    }

    // 从数据库加载设置
    await _loadFromDatabase();
  }

  /// 从 SharedPreferences 迁移数据到数据库
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migrateFromSharedPreferences(SharedPreferences prefs) async {
    try {
      // 迁移 roleplay_prompt
      String? roleplayPrompt = prefs.getString('roleplay_prompt');
      if (roleplayPrompt == null) {
        try {
          roleplayPrompt = await rootBundle.loadString(
            'assets/prompts/roleplay_prompt.txt',
          );
        } catch (e) {
          debugPrint('Error loading roleplay_prompt: $e');
          roleplayPrompt = '你是一个AI助手，正在进行角色扮演任务。请完全沉浸在设定的角色中，不要暴露你是AI的身份。';
        }
      }
      await _db.setSetting('roleplay_prompt', roleplayPrompt);

      // 迁移 reality_prompt
      String? realityPrompt = prefs.getString('reality_prompt');
      if (realityPrompt == null) {
        try {
          realityPrompt = await rootBundle.loadString(
            'assets/prompts/reality_prompt.txt',
          );
        } catch (e) {
          debugPrint('Error loading reality_prompt: $e');
          realityPrompt = '当前时间：{time}。当前日期：{date}。';
        }
      }
      await _db.setSetting('reality_prompt', realityPrompt);

      // 迁移其他布尔和整数设置
      final enableRealityPrompt =
          prefs.getBool('enable_reality_prompt') ?? _enableRealityPrompt;
      await _db.setSettingBool('enable_reality_prompt', enableRealityPrompt);

      final contextLength = prefs.getInt('context_length') ?? _contextLength;
      await _db.setSettingInt('context_length', contextLength);

      final delayedReplySeconds =
          prefs.getInt('delayed_reply_seconds') ?? _delayedReplySeconds;
      await _db.setSettingInt('delayed_reply_seconds', delayedReplySeconds);

      final enableBackgroundActiveReply =
          prefs.getBool('enable_background_active_reply') ??
              _enableBackgroundActiveReply;
      await _db.setSettingBool(
          'enable_background_active_reply', enableBackgroundActiveReply);

      final backgroundActiveReplyInterval =
          prefs.getInt('background_active_reply_interval') ??
              _backgroundActiveReplyInterval;
      await _db.setSettingInt(
          'background_active_reply_interval', backgroundActiveReplyInterval);

      debugPrint('[PromptSettings] 数据迁移完成');
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
