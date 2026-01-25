import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/models/api_preset.dart';
import '../core/providers/api_settings_provider.dart';
import '../widgets/ios_wallpaper.dart';
import 'settings_screen.dart'; // For SettingsSection and SettingsTile

class ImageModelSettingsScreen extends StatelessWidget {
  const ImageModelSettingsScreen({super.key});

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
                        if (provider.imagePresets.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                '暂无生图预设，请点击右上角添加',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                        else
                          SettingsSection(
                            title: '生图预设列表',
                            children: provider.imagePresets.map((preset) {
                              final isActive =
                                  provider.activeImagePresetId == preset.id;
                              return SettingsTile(
                                title: preset.name,
                                subtitle:
                                    '${_getProviderName(preset.provider)} - ${preset.model}',
                                icon: isActive
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.circle,
                                iconColor:
                                    isActive ? Colors.green : Colors.grey,
                                iconGradient: isActive
                                    ? [Colors.green, Colors.greenAccent]
                                    : [Colors.grey, Colors.blueGrey],
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
                '生图模型',
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
                  builder: (context) => const ImagePresetEditScreen(),
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
              provider.setActiveImagePreset(preset.id);
            },
            child: const Text('设为当前使用'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePresetEditScreen(preset: preset),
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  String _getProviderName(ApiProvider provider) {
    switch (provider) {
      case ApiProvider.volcengine:
        return '火山引擎';
      case ApiProvider.gemini:
        return 'Gemini';
      case ApiProvider.openaicompatible:
        return 'OpenAI Compatible';
      default:
        return 'Unknown';
    }
  }
}

class ImagePresetEditScreen extends StatefulWidget {
  final ApiPreset? preset;

  const ImagePresetEditScreen({super.key, this.preset});

  @override
  State<ImagePresetEditScreen> createState() => _ImagePresetEditScreenState();
}

class _ImagePresetEditScreenState extends State<ImagePresetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late ApiProvider _provider;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late String _model;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _nameController = TextEditingController(text: preset?.name ?? 'New Preset');
    _provider = preset?.provider ?? ApiProvider.volcengine;
    _baseUrlController = TextEditingController(text: preset?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: preset?.apiKey ?? '');
    _model = preset?.model ?? '';
    _modelController = TextEditingController(text: _model);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
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
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'API 配置',
                        isDark: isDark,
                        children: [
                          _buildProviderSelector(isDark),
                          Container(
                            height: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          _buildTextField(
                            label: 'Base URL (可选)',
                            controller: _baseUrlController,
                            placeholder: _getPlaceholderBaseUrl(),
                            isDark: isDark,
                          ),
                          Container(
                            height: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
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
                        title: '模型设置',
                        isDark: isDark,
                        children: [
                          _buildTextField(
                            label: '模型名称',
                            controller: _modelController,
                            placeholder: _getDefaultModel(),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton(
                        color: buttonBgColor,
                        onPressed: _testImageGeneration,
                        child: Text(
                          '测试生图',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
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
            widget.preset == null ? '添加生图预设' : '编辑生图预设',
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

  Widget _buildProviderSelector(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '供应商',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          GestureDetector(
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => CupertinoActionSheet(
                  title: const Text('选择供应商'),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () {
                        _updateProvider(ApiProvider.volcengine);
                        Navigator.pop(context);
                      },
                      child: const Text('火山引擎'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        _updateProvider(ApiProvider.gemini);
                        Navigator.pop(context);
                      },
                      child: const Text('Gemini'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        _updateProvider(ApiProvider.openaicompatible);
                        Navigator.pop(context);
                      },
                      child: const Text('OpenAI Compatible'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  _getProviderName(_provider),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_up_chevron_down,
                  color: textColor.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateProvider(ApiProvider value) {
    setState(() {
      _provider = value;
    });
  }

  String _getProviderName(ApiProvider provider) {
    switch (provider) {
      case ApiProvider.volcengine:
        return '火山引擎';
      case ApiProvider.gemini:
        return 'Gemini';
      case ApiProvider.openaicompatible:
        return 'OpenAI Compatible';
      default:
        return 'Unknown';
    }
  }

  String _getDefaultModel() {
    switch (_provider) {
      case ApiProvider.volcengine:
        return 'doubao-seedream-4-5-251128';
      case ApiProvider.gemini:
        return 'gemini-3-pro-image-preview';
      case ApiProvider.openaicompatible:
        return 'dall-e-3';
      default:
        return '';
    }
  }

  String _getPlaceholderBaseUrl() {
    switch (_provider) {
      case ApiProvider.volcengine:
        return 'https://ark.cn-beijing.volces.com/api/v3';
      case ApiProvider.gemini:
        return 'https://generativelanguage.googleapis.com';
      case ApiProvider.openaicompatible:
        return 'https://api.openai.com/v1';
      default:
        return 'https://api.example.com';
    }
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? placeholder,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
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
            style: TextStyle(color: textColor),
            placeholderStyle: TextStyle(color: placeholderColor),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _testImageGeneration() async {
    if (_apiKeyController.text.isEmpty) {
      _showError('请先输入 API Key');
      return;
    }
    final model = _modelController.text.isEmpty
        ? _getDefaultModel()
        : _modelController.text;

    final provider = context.read<ApiSettingsProvider>();
    final tempPreset = ApiPreset(
      id: 'temp',
      name: 'temp',
      type: ApiPresetType.image,
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: model,
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
            Text('正在生成图片...'),
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
      final imageBytes = await provider.testImageGeneration(
        tempPreset,
        'A cute cat running on the grass',
      );

      if (context.mounted && !isCancelled) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          Navigator.pop(context); // Dismiss loading
          _showImageResult(imageBytes);
        }
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

  void _showImageResult(Uint8List imageBytes) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('生成成功'),
        content: Column(
          children: [
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
    final model = _modelController.text.isEmpty
        ? _getDefaultModel()
        : _modelController.text;

    final provider = context.read<ApiSettingsProvider>();
    final newPreset = ApiPreset(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: ApiPresetType.image, // Explicitly set type to image
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: model,
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
