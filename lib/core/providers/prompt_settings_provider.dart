import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt_config.dart';

class PromptSettingsProvider extends ChangeNotifier {
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

  PromptSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('roleplay_prompt')) {
      _roleplayPrompt = prefs.getString('roleplay_prompt')!;
    } else {
      try {
        _roleplayPrompt = await rootBundle.loadString(
          'assets/prompts/roleplay_prompt.txt',
        );
      } catch (e) {
        debugPrint('Error loading roleplay_prompt: $e');
        _roleplayPrompt = '你是一个AI助手，正在进行角色扮演任务。请完全沉浸在设定的角色中，不要暴露你是AI的身份。';
      }
      // 确保默认值也被保存，以便后台服务读取
      await prefs.setString('roleplay_prompt', _roleplayPrompt);
    }

    if (prefs.containsKey('reality_prompt')) {
      _realityPrompt = prefs.getString('reality_prompt')!;
    } else {
      try {
        _realityPrompt = await rootBundle.loadString(
          'assets/prompts/reality_prompt.txt',
        );
      } catch (e) {
        debugPrint('Error loading reality_prompt: $e');
        _realityPrompt = '当前时间：{time}。当前日期：{date}。';
      }
      // 确保默认值也被保存
      await prefs.setString('reality_prompt', _realityPrompt);
    }

    // 确保后台回复相关的默认值也存在于 SharedPreferences 中
    if (!prefs.containsKey('enable_background_active_reply')) {
      await prefs.setBool(
          'enable_background_active_reply', _enableBackgroundActiveReply);
    }
    if (!prefs.containsKey('background_active_reply_interval')) {
      await prefs.setInt(
          'background_active_reply_interval', _backgroundActiveReplyInterval);
    }

    _enableRealityPrompt =
        prefs.getBool('enable_reality_prompt') ?? _enableRealityPrompt;
    _contextLength = prefs.getInt('context_length') ?? _contextLength;
    _delayedReplySeconds =
        prefs.getInt('delayed_reply_seconds') ?? _delayedReplySeconds;
    _enableBackgroundActiveReply =
        prefs.getBool('enable_background_active_reply') ??
            _enableBackgroundActiveReply;
    _backgroundActiveReplyInterval =
        prefs.getInt('background_active_reply_interval') ??
            _backgroundActiveReplyInterval;
    notifyListeners();
  }

  Future<void> updateRoleplayPrompt(String value) async {
    _roleplayPrompt = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roleplay_prompt', value);
    notifyListeners();
  }

  Future<void> updateRealityPrompt(String value) async {
    _realityPrompt = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reality_prompt', value);
    notifyListeners();
  }

  Future<void> toggleRealityPrompt(bool value) async {
    _enableRealityPrompt = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_reality_prompt', value);
    notifyListeners();
  }

  Future<void> updateContextLength(int value) async {
    _contextLength = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('context_length', value);
    notifyListeners();
  }

  Future<void> updateDelayedReplySeconds(int value) async {
    _delayedReplySeconds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('delayed_reply_seconds', value);
    notifyListeners();
  }

  Future<void> toggleBackgroundActiveReply(bool value) async {
    _enableBackgroundActiveReply = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_background_active_reply', value);
    notifyListeners();
  }

  Future<void> updateBackgroundActiveReplyInterval(int value) async {
    _backgroundActiveReplyInterval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('background_active_reply_interval', value);
    notifyListeners();
  }
}
