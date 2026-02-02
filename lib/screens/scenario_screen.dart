import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/scenario_provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/api_preset.dart';
import '../core/models/contact_model.dart';

/// 沉浸剧本模式界面 - 视觉小说风格
class ScenarioScreen extends StatefulWidget {
  final ContactRole role;
  final ContactMe me;
  final ApiPreset apiPreset;
  final String? imageApiPresetId;
  final String? imageStylePresetId;
  final String? initialScene;

  const ScenarioScreen({
    super.key,
    required this.role,
    required this.me,
    required this.apiPreset,
    this.imageApiPresetId,
    this.imageStylePresetId,
    this.initialScene,
  });

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen>
    with TickerProviderStateMixin {
  late ScenarioProvider _provider;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _provider = ScenarioProvider(
      sessionId: 'scenario_${DateTime.now().millisecondsSinceEpoch}',
      role: widget.role,
      me: widget.me,
      apiPreset: widget.apiPreset,
      imageApiPresetId: widget.imageApiPresetId,
      imageStylePresetId: widget.imageStylePresetId,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // 如果有初始场景，自动开始
    if (widget.initialScene != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.startScenario(widget.initialScene!);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    _provider.sendMessage(text);
  }

  void _selectOption(Map<String, dynamic> option) {
    _provider.selectOption(option);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ScenarioProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: Stack(
              children: [
                // 背景图层
                _buildBackground(provider),

                // 渐变遮罩（让文字更易读）
                _buildGradientOverlay(),

                // 主内容区
                SafeArea(
                  child: Column(
                    children: [
                      // 顶部状态栏
                      _buildTopBar(provider),

                      // 对话/旁白区域
                      Expanded(
                        child: _buildContentArea(provider),
                      ),

                      // 选项区域
                      if (provider.state.currentOptions != null &&
                          provider.state.currentOptions!.isNotEmpty)
                        _buildOptionsArea(provider),

                      // 输入区域
                      _buildInputArea(provider),
                    ],
                  ),
                ),

                // 加载指示器
                if (provider.state.isGenerating ||
                    provider.state.isGeneratingScene)
                  _buildLoadingOverlay(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 背景图层
  Widget _buildBackground(ScenarioProvider provider) {
    final imagePath = provider.state.currentSceneImage;

    if (imagePath == null) {
      // 默认渐变背景
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Image.file(
        File(imagePath),
        key: ValueKey(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) {
          return Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white54),
            ),
          );
        },
      ),
    );
  }

  /// 渐变遮罩
  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.2, 0.5, 1.0],
        ),
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildTopBar(ScenarioProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),

          // 场景信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  provider.state.currentLocation ?? '未知地点',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (provider.state.currentTime != null ||
                    provider.state.currentWeather != null)
                  Text(
                    [
                      provider.state.currentTime,
                      provider.state.currentWeather,
                    ].whereType<String>().join(' · '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // 菜单按钮
          IconButton(
            onPressed: () => _showMenu(context),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 对话/旁白内容区域
  Widget _buildContentArea(ScenarioProvider provider) {
    final messages = provider.displayMessages;

    if (messages.isEmpty) {
      return Center(
        child: Text(
          '输入场景描述开始...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  /// 构建消息项
  Widget _buildMessageItem(ChatMessage message) {
    switch (message.type) {
      case MessageType.narration:
        return _buildNarrationCard(message);
      case MessageType.words:
        return _buildDialogueBubble(message);
      case MessageType.action:
        return _buildActionText(message);
      case MessageType.thought:
        return _buildThoughtText(message);
      default:
        return _buildDialogueBubble(message);
    }
  }

  /// 旁白卡片（环境描写）
  Widget _buildNarrationCard(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        message.displayText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 15,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// 对话气泡
  Widget _buildDialogueBubble(ChatMessage message) {
    final isMe = message.isMe;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // 角色头像
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade400,
              child: Text(
                widget.role.name.isNotEmpty ? widget.role.name[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 气泡
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blue.shade600.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                message.displayText,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// 动作描述
  Widget _buildActionText(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '*${message.displayText}*',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.amber.shade200,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// 内心独白
  Widget _buildThoughtText(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '（${message.displayText}）',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.purple.shade200,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// 选项区域
  Widget _buildOptionsArea(ScenarioProvider provider) {
    final options = provider.state.currentOptions!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options.map((option) {
          final text = option['text'] as String? ?? '';
          final hint = option['hint'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () => _selectOption(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 输入区域
  Widget _buildInputArea(ScenarioProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '输入你的话语和动作...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: provider.state.isGenerating ? null : _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// 加载遮罩
  Widget _buildLoadingOverlay(ScenarioProvider provider) {
    String text = '思考中...';
    if (provider.state.isGeneratingScene) {
      text = '正在生成场景...';
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示菜单
  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title:
                    const Text('查看记录', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现查看记录功能
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white),
                title:
                    const Text('重新开始', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _provider.clearScenario();
                },
              ),
              ListTile(
                leading: const Icon(Icons.wallpaper, color: Colors.white),
                title:
                    const Text('重新生成背景', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _provider.regenerateBackground();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title:
                    const Text('更换背景', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现更换背景功能
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text('退出场景',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
