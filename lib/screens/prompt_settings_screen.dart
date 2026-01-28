import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../widgets/ios_wallpaper.dart';
import '../core/providers/prompt_settings_provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/models/text_preset_model.dart';

class PromptSettingsScreen extends StatefulWidget {
  const PromptSettingsScreen({super.key});

  @override
  State<PromptSettingsScreen> createState() => _PromptSettingsScreenState();
}

class _PromptSettingsScreenState extends State<PromptSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: Consumer<PromptSettingsProvider>(
                  builder: (context, provider, child) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 20),
                        _buildSectionTitle('系统提示词 (System Prompt)', isDark),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Roleplay Prompt版本：${_extractVersion(provider.roleplayPrompt)}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            onPressed: () =>
                                _showResetConfirmation(context, provider),
                            child: const Text(
                              '重置为默认提示词',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRealityPromptSection(provider, isDark),
                        const SizedBox(height: 30),
                        _buildSectionTitle('用户提示词 (User Prompt)', isDark),
                        const SizedBox(height: 10),
                        _ContextLengthSection(
                          value: provider.contextLength,
                          onChanged: provider.updateContextLength,
                        ),
                        const SizedBox(height: 16),
                        _buildDelayedReplySection(provider, isDark),
                        const SizedBox(height: 16),
                        _buildBackgroundActiveReplySection(provider, isDark),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractVersion(String content) {
    final RegExp regex = RegExp(r'\*\*Version\*\*: (.*)');
    final match = regex.firstMatch(content);
    if (match != null) {
      return match.group(1)?.trim() ?? '未知版本';
    }
    return '未知版本';
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '提示词与上下文',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(
      BuildContext context, PromptSettingsProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('重置提示词'),
        content: const Text('确定要将所有提示词重置为默认值吗？这将覆盖当前的修改。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('提示词已重置为默认值')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('重置失败: $e')),
                  );
                }
              }
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRealityPromptSection(
      PromptSettingsProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reality Prompt',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '注入真实时间与日期信息',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              CupertinoSwitch(
                value: provider.enableRealityPrompt,
                onChanged: provider.toggleRealityPrompt,
                activeColor: const Color(0xFF007AFF),
              ),
            ],
          ),
          if (provider.enableRealityPrompt) ...[
            const SizedBox(height: 12),
            _PromptInputField(
              title: '模板内容',
              subtitle: '使用 {time} 和 {date} 作为占位符',
              value: provider.realityPrompt,
              onChanged: provider.updateRealityPrompt,
              maxLines: 2,
              showHeader: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDelayedReplySection(
      PromptSettingsProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '延迟回复 (Delayed Reply)',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                provider.delayedReplySeconds == 0
                    ? '立即回复'
                    : '${provider.delayedReplySeconds} 秒',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            provider.delayedReplySeconds == 0
                ? '每发送一条消息后立即请求 AI 回复'
                : '在用户停止发送消息 ${provider.delayedReplySeconds} 秒后请求 AI 回复',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: provider.delayedReplySeconds.toDouble(),
              min: 0,
              max: 120,
              divisions: 24,
              activeColor: const Color(0xFF007AFF),
              onChanged: (value) {
                provider.updateDelayedReplySeconds(value.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundActiveReplySection(
      PromptSettingsProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '后台主动回复',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '应用在后台时主动发送消息',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              CupertinoSwitch(
                value: provider.enableBackgroundActiveReply,
                onChanged: provider.toggleBackgroundActiveReply,
                activeColor: const Color(0xFF007AFF),
              ),
            ],
          ),
          if (provider.enableBackgroundActiveReply) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '触发间隔',
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
                Text(
                  '${provider.backgroundActiveReplyInterval} 分钟',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '当应用在后台检测到超过此时间没有发送过消息，则所有角色都分别请求一次 API',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlider(
                value: provider.backgroundActiveReplyInterval.toDouble(),
                min: 1,
                max: 1440,
                divisions: 1439,
                activeColor: const Color(0xFF007AFF),
                onChanged: (value) {
                  provider.updateBackgroundActiveReplyInterval(value.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1分钟',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
                Text(
                  '24小时',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                onPressed: () {
                  FlutterBackgroundService().invoke('force_check');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已发送强制检查指令，请查看控制台日志'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  '立即测试后台触发',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextLengthSection extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ContextLengthSection({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ContextLengthSection> createState() => _ContextLengthSectionState();
}

class _ContextLengthSectionState extends State<_ContextLengthSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_ContextLengthSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final textValue = int.tryParse(_controller.text) ?? 0;
      if (widget.value != textValue) {
        _controller.text = widget.value.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final inputBgColor = isDark
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.grey.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '上下文长度 (Context Length)',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                width: 80,
                child: CupertinoTextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final newValue = int.tryParse(value);
                    if (newValue != null) {
                      widget.onChanged(newValue.clamp(0, 10000));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '包含用户与 AI 的最近聊天记录数量',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: ((widget.value / 100).round() * 100)
                  .clamp(0, 10000)
                  .toDouble(),
              min: 0,
              max: 10000,
              divisions: 100,
              activeColor: const Color(0xFF007AFF),
              onChanged: (value) {
                widget.onChanged(value.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptInputField extends StatefulWidget {
  final String title;
  final String subtitle;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool showHeader;
  final bool readOnly;

  const _PromptInputField({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.showHeader = true,
    this.readOnly = false,
  });

  @override
  State<_PromptInputField> createState() => _PromptInputFieldState();
}

class _PromptInputFieldState extends State<_PromptInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_PromptInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final inputBgColor = isDark
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.grey.withValues(alpha: 0.15);
    final placeholderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);

    return Container(
      padding: widget.showHeader ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: widget.showHeader
          ? BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Text(
              widget.title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],
          CupertinoTextField(
            controller: _controller,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            style: TextStyle(
              color: widget.readOnly
                  ? textColor.withValues(alpha: 0.5)
                  : textColor,
            ),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            placeholderStyle: TextStyle(color: placeholderColor),
          ),
        ],
      ),
    );
  }
}
