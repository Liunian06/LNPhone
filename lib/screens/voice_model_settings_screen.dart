import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/models/api_preset.dart';
import '../core/providers/api_settings_provider.dart';
import '../core/utils/storage_utils.dart';
import '../widgets/ios_wallpaper.dart';
import 'settings_screen.dart'; // For SettingsSection and SettingsTile

class VoiceModelSettingsScreen extends StatelessWidget {
  const VoiceModelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: Consumer<ApiSettingsProvider>(
                  builder: (context, provider, child) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 20),
                        if (provider.voicePresets.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                '暂无语音模型预设，请点击右上角添加',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                        else
                          SettingsSection(
                            title: 'API 预设列表',
                            children: provider.voicePresets.map((preset) {
                              // 语音预设没有"当前激活"的概念，因为是在角色设置里选择
                              // 但为了保持一致性，我们还是可以显示一个选中状态，或者不显示
                              return SettingsTile(
                                title: preset.name,
                                subtitle:
                                    '${preset.provider.name.toUpperCase()} - ${preset.model}',
                                icon: CupertinoIcons.mic_fill,
                                iconColor: Colors.orange,
                                iconGradient: const [
                                  Colors.orange,
                                  Colors.deepOrange
                                ],
                                onTap: () {
                                  _showPresetOptions(context, preset, provider);
                                },
                              );
                            }).toList(),
                          ),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                '语音模型',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoicePresetEditScreen(),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresetOptions(
    BuildContext context,
    ApiPreset preset,
    ApiSettingsProvider provider,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(preset.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoicePresetEditScreen(preset: preset),
                ),
              );
            },
            child: const Text('编辑'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _copyPreset(context, provider, preset);
            },
            child: const Text('复制'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, provider, preset.id);
            },
            child: const Text('删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _copyPreset(
    BuildContext context,
    ApiSettingsProvider provider,
    ApiPreset preset,
  ) async {
    final newPreset = preset.copyWith(
      id: StorageUtils.getUniqueTimestamp().toString(),
      name: '${preset.name} copy',
    );

    try {
      await provider.addPreset(newPreset);
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('错误'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _confirmDelete(
    BuildContext context,
    ApiSettingsProvider provider,
    String id,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个预设吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.deletePreset(id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class VoicePresetEditScreen extends StatefulWidget {
  final ApiPreset? preset;

  const VoicePresetEditScreen({super.key, this.preset});

  @override
  State<VoicePresetEditScreen> createState() => _VoicePresetEditScreenState();
}

class _VoicePresetEditScreenState extends State<VoicePresetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late ApiProvider _provider;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _voiceIdController;
  late TextEditingController _audioChannelController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _nameController = TextEditingController(text: preset?.name ?? 'New Preset');
    _provider = preset?.provider ?? ApiProvider.minimax;
    _baseUrlController = TextEditingController(text: preset?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: preset?.apiKey ?? '');
    _modelController =
        TextEditingController(text: preset?.model ?? 'speech-2.8-hd');
    _voiceIdController =
        TextEditingController(text: preset?.voiceId ?? 'male-qn-qingse');
    _audioChannelController =
        TextEditingController(text: (preset?.audioChannel ?? 1).toString());

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _voiceIdController.dispose();
    _audioChannelController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 20),
                      _buildSection(
                        title: '基本信息',
                        isDark: isDark,
                        children: [
                          _buildTextField(
                            label: '预设名称',
                            controller: _nameController,
                            isDark: isDark,
                          ),
                          _buildProviderSelector(isDark),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'API 配置',
                        isDark: isDark,
                        children: [
                          _buildTextField(
                            label: 'Base URL',
                            controller: _baseUrlController,
                            placeholder: 'https://api.minimaxi.com/v1/t2a_v2',
                            isDark: isDark,
                          ),
                          _buildTextField(
                            label: 'API Key',
                            controller: _apiKeyController,
                            obscureText: false,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: '模型参数',
                        isDark: isDark,
                        children: [
                          _buildTextField(
                            label: '模型 (Model)',
                            controller: _modelController,
                            placeholder: 'speech-2.8-hd',
                            isDark: isDark,
                          ),
                          _buildVoiceIdSelector(isDark),
                          _buildTextField(
                            label: '声道 (Channel)',
                            controller: _audioChannelController,
                            placeholder: '1',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton(
                        color: buttonBgColor,
                        onPressed: _isPlaying ? _stopAudio : _testGeneration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPlaying
                                  ? CupertinoIcons.stop_fill
                                  : CupertinoIcons.play_fill,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPlaying ? '停止播放' : '测试语音生成',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        onPressed: _savePreset,
                        child: const Text('保存'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
            widget.preset == null ? '添加语音预设' : '编辑语音预设',
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final placeholderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor),
            placeholderStyle: TextStyle(color: placeholderColor),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '提供商',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          // 目前仅支持 Minimax，由于 CupertinoSlidingSegmentedControl 要求至少 2 个子项，
          // 这里直接显示文本或使用简单的装饰容器。
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Minimax',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchVoices() async {
    if (_apiKeyController.text.isEmpty) {
      _showError('请先输入 API Key');
      return;
    }

    final provider = context.read<ApiSettingsProvider>();
    final tempPreset = ApiPreset(
      id: 'temp',
      name: 'temp',
      type: ApiPresetType.voice,
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
    );

    try {
      final voices = await provider.fetchMinimaxVoices(tempPreset);
      if (mounted) {
        _showVoicePicker(voices);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showVoicePicker(List<Map<String, String>> voices) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 500,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '选择音色',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                        color: Colors.blue,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: voices.length,
                  itemBuilder: (context, index) {
                    final voice = voices[index];
                    final isSelected = voice['id'] == _voiceIdController.text;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _voiceIdController.text = voice['id']!;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          color: isSelected
                              ? (isDark
                                  ? Colors.white10
                                  : Colors.blue.withOpacity(0.1))
                              : Colors.transparent,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  voice['name']!,
                                  style: TextStyle(
                                    color: isSelected ? Colors.blue : textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    voice['category']!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (voice['desc']!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                voice['desc']!,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${voice['id']}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.3),
                                fontSize: 10,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildVoiceIdSelector(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final placeholderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice ID',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _fetchVoices,
                child: const Text('获取可用音色'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _voiceIdController,
            placeholder: '输入或选择 Voice ID',
            style: TextStyle(color: textColor),
            placeholderStyle: TextStyle(color: placeholderColor),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testGeneration() async {
    if (_apiKeyController.text.isEmpty) {
      _showError('请先输入 API Key');
      return;
    }

    final provider = context.read<ApiSettingsProvider>();
    final tempPreset = ApiPreset(
      id: 'temp',
      name: 'temp',
      type: ApiPresetType.voice,
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      voiceId: _voiceIdController.text,
      audioChannel: int.tryParse(_audioChannelController.text) ?? 1,
    );

    bool isCancelled = false;

    // Show loading
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 16),
            Text('正在生成语音...'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              isCancelled = true;
              Navigator.pop(dialogContext);
            },
            child: const Text('取消'),
          ),
        ],
      ),
    ).then((_) => isCancelled = true);

    try {
      final audioBytes = await provider.testVoiceGeneration(
          tempPreset, "今天是不是很开心呀(laughs)，当然了！");

      if (context.mounted && !isCancelled) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          Navigator.pop(context); // Dismiss loading
        }

        // Play audio
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/test_voice.mp3');
        await file.writeAsBytes(audioBytes);
        await _audioPlayer.play(DeviceFileSource(file.path));
      }
    } catch (e) {
      if (context.mounted && !isCancelled) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          Navigator.pop(context); // Dismiss loading
          _showError(e.toString());
        }
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  void _savePreset() {
    if (_nameController.text.isEmpty) {
      _showError('请输入预设名称');
      return;
    }
    if (_apiKeyController.text.isEmpty) {
      _showError('请输入 API Key');
      return;
    }

    final provider = context.read<ApiSettingsProvider>();
    final newPreset = ApiPreset(
      id: widget.preset?.id ?? StorageUtils.getUniqueTimestamp().toString(),
      name: _nameController.text,
      type: ApiPresetType.voice,
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      voiceId: _voiceIdController.text,
      audioChannel: int.tryParse(_audioChannelController.text) ?? 1,
    );

    try {
      if (widget.preset == null) {
        provider.addPreset(newPreset);
      } else {
        provider.updatePreset(newPreset);
      }
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
