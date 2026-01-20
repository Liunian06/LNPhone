import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/models/api_preset.dart';
import '../core/providers/api_settings_provider.dart';
import '../widgets/ios_wallpaper.dart';
import 'settings_screen.dart'; // For SettingsSection and SettingsTile

class ApiSettingsScreen extends StatelessWidget {
  const ApiSettingsScreen({super.key});

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
                        if (provider.presets.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                '暂无 API 预设，请点击右上角添加',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                        else
                          SettingsSection(
                            title: 'API 预设列表',
                            children: provider.presets.map((preset) {
                              final isActive =
                                  provider.activePresetId == preset.id;
                              return SettingsTile(
                                title: preset.name,
                                subtitle:
                                    '${preset.provider.name.toUpperCase()} - ${preset.model}',
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
                'API 设置',
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
                  builder: (context) => const ApiPresetEditScreen(),
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
              provider.setActivePreset(preset.id);
            },
            child: const Text('设为当前使用'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApiPresetEditScreen(preset: preset),
                ),
              );
            },
            child: const Text('编辑'),
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

class ApiPresetEditScreen extends StatefulWidget {
  final ApiPreset? preset;

  const ApiPresetEditScreen({super.key, this.preset});

  @override
  State<ApiPresetEditScreen> createState() => _ApiPresetEditScreenState();
}

class _ApiPresetEditScreenState extends State<ApiPresetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late ApiProvider _provider;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _temperatureController;
  late TextEditingController _topPController;
  late String _model;
  late double _temperature;
  late double _topP;
  late bool _isStream;
  late bool _enableThinking;
  List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _nameController = TextEditingController(text: preset?.name ?? 'New Preset');
    _provider = preset?.provider ?? ApiProvider.openai;
    _baseUrlController = TextEditingController(text: preset?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: preset?.apiKey ?? '');
    _model = preset?.model ?? '';
    _modelController = TextEditingController(text: _model);
    _temperature = preset?.temperature ?? 0.7;
    _temperatureController = TextEditingController(
      text: _temperature.toString(),
    );
    _topP = preset?.topP ?? 0.9;
    _topPController = TextEditingController(text: _topP.toString());
    _isStream = preset?.isStream ?? true;
    _enableThinking = preset?.enableThinking ?? true;

    if (_model.isNotEmpty) {
      _availableModels = [_model];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
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
                            placeholder: _provider == ApiProvider.openai
                                ? 'https://api.openai.com/v1'
                                : 'https://generativelanguage.googleapis.com',
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
                        title: '模型选择',
                        isDark: isDark,
                        children: [_buildModelSelector(isDark)],
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: '参数设置',
                        isDark: isDark,
                        children: [
                          _buildSlider(
                            label: 'Temperature',
                            value: _temperature,
                            min: 0.0,
                            max: 2.0,
                            controller: _temperatureController,
                            onChanged: (v) => setState(() => _temperature = v),
                            isDark: isDark,
                          ),
                          _buildSlider(
                            label: 'Top P',
                            value: _topP,
                            min: 0.0,
                            max: 1.0,
                            controller: _topPController,
                            onChanged: (v) => setState(() => _topP = v),
                            isDark: isDark,
                          ),
                          _buildSwitch(
                            label: '流式输出 (Stream)',
                            value: _isStream,
                            onChanged: (v) => setState(() => _isStream = v),
                            isDark: isDark,
                          ),
                          _buildSwitch(
                            label: '启用推理 (Thinking)',
                            value: _enableThinking,
                            onChanged: (v) =>
                                setState(() => _enableThinking = v),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton(
                        color: buttonBgColor,
                        onPressed: _testConnection,
                        child: Text(
                          '测试连接',
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
            widget.preset == null ? '添加预设' : '编辑预设',
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

  Widget _buildProviderSelector(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '提供商',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          CupertinoSlidingSegmentedControl<ApiProvider>(
            groupValue: _provider,
            children: const {
              ApiProvider.openai: Text('OpenAI'),
              ApiProvider.gemini: Text('Gemini'),
            },
            onValueChanged: (value) {
              if (value != null) {
                setState(() {
                  _provider = value;
                  // Reset model when provider changes
                  _model = '';
                  _availableModels = [];
                });
              }
            },
            backgroundColor: bgColor,
            thumbColor: const Color(0xFF6366f1),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(bool isDark) {
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
                '模型',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('拉取列表'),
                onPressed: _fetchModels,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _modelController,
                  placeholder: '输入或选择模型 ID',
                  style: TextStyle(color: textColor),
                  placeholderStyle: TextStyle(color: placeholderColor),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onChanged: (value) {
                    _model = value;
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showModelPicker,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    color: textColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required TextEditingController controller,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              SizedBox(
                width: 60,
                child: CupertinoTextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: textColor),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onChanged: (text) {
                    final newValue = double.tryParse(text);
                    if (newValue != null &&
                        newValue >= min &&
                        newValue <= max) {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: value,
              min: min,
              max: max,
              onChanged: (newValue) {
                onChanged(newValue);
                controller.text = newValue.toStringAsFixed(2);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _fetchModels() async {
    if (_apiKeyController.text.isEmpty) {
      _showError('请先输入 API Key');
      return;
    }

    final provider = context.read<ApiSettingsProvider>();
    final tempPreset = ApiPreset(
      id: 'temp',
      name: 'temp',
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: '',
    );

    try {
      final models = await provider.fetchModels(tempPreset);
      models.sort();
      setState(() {
        _availableModels = models;
        if (models.isNotEmpty && _model.isEmpty) {
          _model = models.first;
        }
      });
      _showSuccess('成功获取 ${models.length} 个模型');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showModelPicker() {
    if (_availableModels.isEmpty) {
      _showError('请先拉取模型列表');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        color: bgColor,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _model = _availableModels[index];
                      _modelController.text = _model;
                    });
                  },
                  children: _availableModels
                      .map(
                        (m) => Center(
                          child: Text(
                            m,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty) {
      _showError('请先输入 API Key');
      return;
    }
    if (_modelController.text.isEmpty) {
      _showError('请先输入或选择模型');
      return;
    }

    final provider = context.read<ApiSettingsProvider>();
    final tempPreset = ApiPreset(
      id: 'temp',
      name: 'temp',
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
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
            Text('正在测试连接...'),
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
      await provider.testConnection(tempPreset);
      if (context.mounted && !isCancelled) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          Navigator.pop(context); // Dismiss loading
          _showSuccess('连接测试成功！');
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

  void _savePreset() {
    if (_nameController.text.isEmpty) {
      _showError('请输入预设名称');
      return;
    }
    if (_apiKeyController.text.isEmpty) {
      _showError('请输入 API Key');
      return;
    }
    if (_modelController.text.isEmpty) {
      _showError('请选择模型');
      return;
    }

    final provider = context.read<ApiSettingsProvider>();
    final newPreset = ApiPreset(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      provider: _provider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      temperature: _temperature,
      topP: _topP,
      isStream: _isStream,
      enableThinking: _enableThinking,
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

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('成功'),
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
