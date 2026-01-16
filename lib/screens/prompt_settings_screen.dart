import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../widgets/ios_wallpaper.dart';
import '../core/providers/prompt_settings_provider.dart';

class PromptSettingsScreen extends StatefulWidget {
  const PromptSettingsScreen({super.key});

  @override
  State<PromptSettingsScreen> createState() => _PromptSettingsScreenState();
}

class _PromptSettingsScreenState extends State<PromptSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<PromptSettingsProvider>(
                  builder: (context, provider, child) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 20),
                        _buildSectionTitle('系统提示词 (System Prompt)'),
                        const SizedBox(height: 10),
                        _PromptInputField(
                          title: 'Roleplay Prompt',
                          subtitle: '引导 AI 进行角色扮演任务',
                          value: provider.roleplayPrompt,
                          onChanged: provider.updateRoleplayPrompt,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        _PromptInputField(
                          title: 'Presetting Prompt',
                          subtitle: '引导 AI 输出特定的文风',
                          value: provider.presettingPrompt,
                          onChanged: provider.updatePresettingPrompt,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        _buildRealityPromptSection(provider),

                        const SizedBox(height: 30),
                        _buildSectionTitle('用户提示词 (User Prompt)'),
                        const SizedBox(height: 10),
                        _buildContextLengthSection(provider),
                        const SizedBox(height: 16),
                        _buildDelayedReplySection(provider),
                        const SizedBox(height: 16),
                        _buildBackgroundActiveReplySection(provider),

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

  Widget _buildHeader() {
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '提示词与上下文',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRealityPromptSection(PromptSettingsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
                  const Text(
                    'Reality Prompt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '注入真实时间与日期信息',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildContextLengthSection(PromptSettingsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '上下文长度 (Context Length)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${provider.contextLength} 条',
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
            '包含用户与 AI 的最近聊天记录数量',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: provider.contextLength.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: const Color(0xFF007AFF),
              onChanged: (value) {
                provider.updateContextLength(value.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayedReplySection(PromptSettingsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '延迟回复 (Delayed Reply)',
                style: TextStyle(
                  color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildBackgroundActiveReplySection(PromptSettingsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
                  const Text(
                    '后台主动回复',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '应用在后台时主动发送消息',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
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
                const Text(
                  '触发间隔',
                  style: TextStyle(color: Colors.white, fontSize: 14),
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
                color: Colors.white.withValues(alpha: 0.6),
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
                Text(
                  '24小时',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
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

  const _PromptInputField({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.showHeader = true,
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
    return Container(
      padding: widget.showHeader ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: widget.showHeader
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],
          CupertinoTextField(
            controller: _controller,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            placeholderStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
