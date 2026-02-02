import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_model.dart';
import '../models/api_preset.dart';
import '../models/contact_model.dart';
import '../models/prompt_config.dart';
import '../services/llm_service.dart';
import '../services/scene_cache_service.dart';
import '../services/image_generation_service.dart';
import '../database/database.dart';
import '../utils/storage_utils.dart';

/// 沉浸模式状态
class ScenarioState {
  final String? currentSceneImage; // 当前场景背景图路径
  final String? currentLocation; // 当前位置
  final String? currentTime; // 当前时间段
  final String? currentWeather; // 当前天气
  final String? characterState; // 角色当前状态
  final List<Map<String, dynamic>>? currentOptions; // 当前可选选项
  final bool isGenerating; // 是否正在生成
  final bool isGeneratingScene; // 是否正在生成场景图

  const ScenarioState({
    this.currentSceneImage,
    this.currentLocation,
    this.currentTime,
    this.currentWeather,
    this.characterState,
    this.currentOptions,
    this.isGenerating = false,
    this.isGeneratingScene = false,
  });

  ScenarioState copyWith({
    String? currentSceneImage,
    String? currentLocation,
    String? currentTime,
    String? currentWeather,
    String? characterState,
    List<Map<String, dynamic>>? currentOptions,
    bool? isGenerating,
    bool? isGeneratingScene,
  }) {
    return ScenarioState(
      currentSceneImage: currentSceneImage ?? this.currentSceneImage,
      currentLocation: currentLocation ?? this.currentLocation,
      currentTime: currentTime ?? this.currentTime,
      currentWeather: currentWeather ?? this.currentWeather,
      characterState: characterState ?? this.characterState,
      currentOptions: currentOptions ?? this.currentOptions,
      isGenerating: isGenerating ?? this.isGenerating,
      isGeneratingScene: isGeneratingScene ?? this.isGeneratingScene,
    );
  }
}

/// 沉浸模式 Provider
class ScenarioProvider extends ChangeNotifier {
  final String sessionId;
  final ContactRole role;
  final ContactMe me;
  final ApiPreset apiPreset;
  final String? imageApiPresetId;
  final String? imageStylePresetId;

  ScenarioState _state = const ScenarioState();
  ScenarioState get state => _state;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  final AppDatabase _db = AppDatabase();
  final SceneCacheService _sceneCache = SceneCacheService();

  String? _scenarioPrompt;
  String? _lastSceneDescription; // 记录最后的场景描述用于重新生成

  ScenarioProvider({
    required this.sessionId,
    required this.role,
    required this.me,
    required this.apiPreset,
    this.imageApiPresetId,
    this.imageStylePresetId,
  }) {
    _init();
  }

  Future<void> _init() async {
    await _sceneCache.init();
    await _loadScenarioPrompt();
    // 设置图片生成服务的上下文（角色和用户信息）
    ImageGenerationService().setCurrentContext(role, me);
    debugPrint('[ScenarioProvider] 初始化完成，角色: ${role.name}');
  }

  Future<void> _loadScenarioPrompt() async {
    try {
      _scenarioPrompt =
          await rootBundle.loadString('assets/prompts/scenario_prompt.txt');
      debugPrint('[ScenarioProvider] 沉浸模式 Prompt 加载成功');
    } catch (e) {
      debugPrint('[ScenarioProvider] 加载沉浸模式 Prompt 失败: $e');
    }
  }

  /// 开始场景
  Future<void> startScenario(String initialScene) async {
    _state = _state.copyWith(isGenerating: true);
    _lastSceneDescription = initialScene; // 记录初始场景描述
    notifyListeners();

    try {
      // 发送初始场景描述给 AI
      final userMessage = ChatMessage(
        id: 'user_${StorageUtils.getUniqueTimestamp()}',
        isMe: true,
        type: MessageType.words,
        content: '{"type": "system", "content": "开始场景：$initialScene"}',
        timestamp: StorageUtils.getUniqueTimestamp(),
      );

      _messages.add(userMessage);
      notifyListeners();

      await _generateAiResponse();
    } finally {
      _state = _state.copyWith(isGenerating: false);
      notifyListeners();
    }
  }

  /// 用户发送消息或选择选项
  Future<void> sendMessage(String content) async {
    if (content.isEmpty) return;

    _state = _state.copyWith(isGenerating: true);
    notifyListeners();

    try {
      // 添加用户消息
      final userMessage = ChatMessage(
        id: 'user_${StorageUtils.getUniqueTimestamp()}',
        isMe: true,
        type: MessageType.words,
        content: '{"type": "word", "content": "$content"}',
        timestamp: StorageUtils.getUniqueTimestamp(),
      );

      _messages.add(userMessage);
      notifyListeners();

      await _generateAiResponse();
    } finally {
      _state = _state.copyWith(isGenerating: false);
      notifyListeners();
    }
  }

  /// 用户选择选项
  Future<void> selectOption(Map<String, dynamic> option) async {
    final text = option['text'] as String? ?? '';
    await sendMessage(text);
  }

  /// 生成 AI 回复
  Future<void> _generateAiResponse() async {
    if (_scenarioPrompt == null) {
      debugPrint('[ScenarioProvider] 沉浸模式 Prompt 未加载');
      return;
    }

    try {
      final promptConfig = PromptConfig(
        roleplayPrompt: _scenarioPrompt!,
        contextLength: 30,
      );

      final aiMessages = await LlmService.generateResponse(
        apiPreset: apiPreset,
        promptConfig: promptConfig,
        history: _messages,
        role: role,
        me: me,
        messageIdPrefix: 'ai_${StorageUtils.getUniqueTimestamp()}',
        enableTextToImage: true, // 沉浸模式启用生图
      );

      // 处理 AI 回复
      for (final message in aiMessages) {
        await _processMessage(message);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[ScenarioProvider] 生成 AI 回复失败: $e');
    }
  }

  /// 处理 AI 消息
  Future<void> _processMessage(ChatMessage message) async {
    switch (message.type) {
      case MessageType.scene:
        await _handleSceneMessage(message);
        break;

      case MessageType.state:
        _state = _state.copyWith(characterState: message.content);
        break;

      case MessageType.options:
        final options = message.metadata?['options'] as List<dynamic>?;
        if (options != null) {
          _state = _state.copyWith(
            currentOptions:
                options.map((o) => Map<String, dynamic>.from(o)).toList(),
          );
        }
        break;

      case MessageType.narration:
      case MessageType.words:
      case MessageType.action:
      case MessageType.thought:
        _messages.add(message);
        break;

      default:
        // 其他类型消息也添加到列表
        _messages.add(message);
        break;
    }
  }

  /// 处理场景消息
  Future<void> _handleSceneMessage(ChatMessage message) async {
    final metadata = message.metadata ?? {};
    final generate = metadata['generate'] as bool? ?? true;
    final location = metadata['location'] as String? ?? '';
    final time = metadata['time'] as String? ?? '';
    final weather = metadata['weather'] as String? ?? '';

    debugPrint('[ScenarioProvider] 处理场景消息:');
    debugPrint('  - generate: $generate');
    debugPrint('  - location: $location');
    debugPrint('  - time: $time');
    debugPrint('  - weather: $weather');
    debugPrint(
        '  - content: ${message.content.substring(0, message.content.length > 100 ? 100 : message.content.length)}...');
    debugPrint('  - imageApiPresetId: $imageApiPresetId');
    debugPrint('  - imageStylePresetId: $imageStylePresetId');

    // 更新状态
    _state = _state.copyWith(
      currentLocation: location,
      currentTime: time,
      currentWeather: weather,
    );

    // 记录最后的场景描述用于重新生成
    _lastSceneDescription =
        message.metadata?['original_prompt'] ?? message.content;

    // 如果需要生成新场景图
    if (generate) {
      debugPrint('[ScenarioProvider] 开始生成场景图...');
      _state = _state.copyWith(isGeneratingScene: true);
      notifyListeners();

      try {
        final imagePath = await _sceneCache.generateAndCache(
          sessionId: sessionId,
          description: message.content,
          location: location,
          time: time,
          weather: weather,
          imageApiPresetId: imageApiPresetId,
          imageStylePresetId: imageStylePresetId,
        );

        debugPrint('[ScenarioProvider] 场景图生成结果: $imagePath');

        if (imagePath != null) {
          _state = _state.copyWith(currentSceneImage: imagePath);
          debugPrint('[ScenarioProvider] 场景背景图已更新');
        } else {
          debugPrint('[ScenarioProvider] 场景图生成失败，imagePath 为 null');
        }
      } catch (e) {
        debugPrint('[ScenarioProvider] 场景图生成异常: $e');
      } finally {
        _state = _state.copyWith(isGeneratingScene: false);
        notifyListeners();
      }
    } else {
      debugPrint('[ScenarioProvider] 尝试从缓存获取场景图...');
      // 尝试从缓存中查找
      final cached = _sceneCache.findMatch(
        sessionId: sessionId,
        location: location,
        time: time,
        weather: weather,
      );

      if (cached != null) {
        _state = _state.copyWith(currentSceneImage: cached.imagePath);
        debugPrint('[ScenarioProvider] 使用缓存的场景图: ${cached.imagePath}');
      } else {
        debugPrint('[ScenarioProvider] 未找到匹配的缓存场景图');
      }
    }
  }

  /// 重新生成当前背景图
  Future<void> regenerateBackground() async {
    if (_lastSceneDescription == null && _state.currentLocation == null) {
      debugPrint('[ScenarioProvider] 没有可用的场景信息来重新生成背景');
      return;
    }

    _state = _state.copyWith(isGeneratingScene: true);
    notifyListeners();

    try {
      // 强制生成新图，不使用缓存
      final imagePath = await _sceneCache.generateAndCache(
        sessionId: sessionId,
        description: _lastSceneDescription ?? '当前场景',
        location: _state.currentLocation ?? '',
        time: _state.currentTime ?? '',
        weather: _state.currentWeather ?? '',
        imageApiPresetId: imageApiPresetId,
        imageStylePresetId: imageStylePresetId,
        force: true, // 关键：强制重新生成
      );

      if (imagePath != null) {
        _state = _state.copyWith(currentSceneImage: imagePath);
      }
    } catch (e) {
      debugPrint('[ScenarioProvider] 重新生成背景异常: $e');
    } finally {
      _state = _state.copyWith(isGeneratingScene: false);
      notifyListeners();
    }
  }

  /// 清除当前场景
  void clearScenario() {
    _messages.clear();
    _state = const ScenarioState();
    notifyListeners();
  }

  /// 获取显示用的消息（过滤掉不需要显示的类型）
  List<ChatMessage> get displayMessages {
    return _messages.where((m) {
      // 只显示对话、旁白、动作、想法
      return m.type == MessageType.words ||
          m.type == MessageType.narration ||
          m.type == MessageType.action ||
          m.type == MessageType.thought;
    }).toList();
  }
}
