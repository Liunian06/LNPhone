import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import '../core/models/emoji_model.dart';
import '../core/providers/emoji_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/models/contact_model.dart';
import '../core/providers/api_settings_provider.dart';
import '../core/services/llm_service.dart';
import '../core/models/api_preset.dart';
import '../core/database/database.dart';
import 'package:flutter/services.dart' show rootBundle;

class EmojiManagementScreen extends StatefulWidget {
  const EmojiManagementScreen({super.key});

  @override
  State<EmojiManagementScreen> createState() => _EmojiManagementScreenState();
}

class _EmojiManagementScreenState extends State<EmojiManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedEmojiIds = {};
  bool _isSelectionMode = false;
  String? _selectedRoleId; // 当前选中的角色ID（用于角色表情Tab）

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 默认加载全局表情
      context.read<EmojiProvider>().loadEmojis(null);
      // 加载角色列表
      context.read<ContactProvider>().loadContacts();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isSelectionMode = false;
        _selectedEmojiIds.clear();
      });
      _refreshEmojis();
    }
  }

  void _refreshEmojis() {
    final provider = context.read<EmojiProvider>();
    if (_tabController.index == 0) {
      // 全局表情
      provider.loadEmojis(null);
    } else {
      // 角色表情
      if (_selectedRoleId != null) {
        provider.loadEmojis(_selectedRoleId);
      } else {
        // 如果没有选中角色，尝试选中第一个
        final contacts = context.read<ContactProvider>().roles;
        if (contacts.isNotEmpty) {
          setState(() {
            _selectedRoleId = contacts.first.id;
          });
          provider.loadEmojis(_selectedRoleId);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<EmojiProvider>();
    final contactProvider = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('表情库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全局表情'),
            Tab(text: '角色表情'),
          ],
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '批量删除',
              onPressed: _selectedEmojiIds.isEmpty ? null : _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: '批量复制',
              onPressed: _selectedEmojiIds.isEmpty ? null : _copySelected,
            ),
            IconButton(
              icon: Icon(
                  _tabController.index == 0 ? Icons.move_down : Icons.move_up),
              tooltip: _tabController.index == 0 ? '移动到角色库' : '移动到全局库',
              onPressed: _selectedEmojiIds.isEmpty ? null : _moveSelected,
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: '批量重新打标',
              onPressed: _selectedEmojiIds.isEmpty ? null : _batchReTagEmojis,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedEmojiIds.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: '新建分组',
              onPressed: _addEmojiGroup,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              onSelected: (value) {
                if (value == 'single') {
                  _addEmoji();
                } else if (value == 'batch') {
                  _batchImportEmojis();
                } else if (value == 'pure_batch') {
                  _pureBatchImportEmojis();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'single',
                  child: Text('添加单个表情'),
                ),
                const PopupMenuItem<String>(
                  value: 'batch',
                  child: Text('批量导入 (AI打标)'),
                ),
                const PopupMenuItem<String>(
                  value: 'pure_batch',
                  child: Text('纯批量导入 (无打标)'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 全局表情 Tab
          _buildGroupedEmojiList(
              provider.globalEmojis, provider.emojiGroups, null, isDark),

          // 角色表情 Tab
          Column(
            children: [
              // 角色选择器
              if (contactProvider.roles.isNotEmpty)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: contactProvider.roles.length,
                    itemBuilder: (context, index) {
                      final role = contactProvider.roles[index];
                      final isSelected = role.id == _selectedRoleId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(role.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedRoleId = role.id;
                                _isSelectionMode = false;
                                _selectedEmojiIds.clear();
                              });
                              provider.loadEmojis(role.id);
                            }
                          },
                          avatar: (role.avatarPath != null &&
                                  role.avatarPath!.isNotEmpty)
                              ? CircleAvatar(
                                  backgroundImage:
                                      FileImage(File(role.avatarPath!)),
                                  radius: 10,
                                )
                              : const CircleAvatar(
                                  radius: 10,
                                  child: Icon(Icons.person, size: 12),
                                ),
                        ),
                      );
                    },
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('暂无角色，请先创建角色'),
                ),

              // 表情网格
              Expanded(
                child: _selectedRoleId != null
                    ? _buildGroupedEmojiList(provider.roleEmojis,
                        provider.emojiGroups, _selectedRoleId, isDark)
                    : const Center(child: Text('请选择一个角色')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedEmojiList(List<EmojiModel> emojis,
      List<EmojiGroupEntity> groups, String? roleId, bool isDark) {
    final type = _tabController.index == 0 ? EmojiType.global : EmojiType.role;
    final currentGroups =
        groups.where((g) => g.type == type && g.roleId == roleId).toList();

    // 未分组的表情
    final ungroupedEmojis = emojis.where((e) => e.groupId == null).toList();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (ungroupedEmojis.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text('未分组',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildEmojiGrid(ungroupedEmojis, isDark),
        ],
        for (final group in currentGroups) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () => _deleteGroup(group),
                ),
              ],
            ),
          ),
          _buildEmojiGrid(
              emojis.where((e) => e.groupId == group.id).toList(), isDark),
        ],
        if (emojis.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Icon(Icons.emoji_emotions_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _tabController.index == 0 ? '全局表情库为空' : '该角色暂无专属表情',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmojiGrid(List<EmojiModel> emojis, bool isDark) {
    if (emojis.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final isSelected = _selectedEmojiIds.contains(emoji.id);

        return GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedEmojiIds.add(emoji.id);
            });
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedEmojiIds.remove(emoji.id);
                  if (_selectedEmojiIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedEmojiIds.add(emoji.id);
                }
              });
            } else {
              _editEmoji(emoji);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.file(
                      File(emoji.localPath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    emoji.meaning,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addEmoji() async {
    if (_tabController.index == 1 && _selectedRoleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择一个角色')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && mounted) {
      for (final file in result.files) {
        if (file.path == null) continue;

        final meaningResult =
            await _showMeaningDialog(context, imagePath: file.path);
        if (meaningResult == null) continue;

        if (mounted) {
          final isGlobal = _tabController.index == 0;
          final roleId = isGlobal ? null : _selectedRoleId;

          if (!isGlobal && roleId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('添加失败：未选择角色')),
            );
            continue;
          }

          await context.read<EmojiProvider>().addEmoji(
                filePath: file.path!,
                meaning: meaningResult['meaning']!,
                type: isGlobal ? EmojiType.global : EmojiType.role,
                roleId: roleId,
              );
        }
      }
    }
  }

  Future<void> _editEmoji(EmojiModel emoji) async {
    final result = await _showMeaningDialog(
      context,
      defaultMeaning: emoji.meaning,
      defaultRawContent: emoji.rawContent,
      imagePath: emoji.localPath,
    );

    if (result != null && mounted) {
      await context.read<EmojiProvider>().updateEmojiContent(
            id: emoji.id,
            meaning: result['meaning']!,
            rawContent: result['rawContent'],
          );
    }
  }

  Future<Map<String, String?>?> _showMeaningDialog(BuildContext context,
      {String? defaultMeaning,
      String? defaultRawContent,
      String? imagePath}) async {
    final meaningController = TextEditingController(text: defaultMeaning);
    final rawContentController = TextEditingController(text: defaultRawContent);

    return showDialog<Map<String, String?>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑表情内容'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.file(
                    File(imagePath),
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              TextField(
                controller: meaningController,
                decoration: const InputDecoration(
                  labelText: '简短含义 (simple_content)',
                  hintText: '例如：开心、伤心',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rawContentController,
                decoration: const InputDecoration(
                  labelText: '详细描述 (raw_content)',
                  hintText: '详细描述画面内容...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'meaning': meaningController.text.trim(),
              'rawContent': rawContentController.text.trim().isEmpty
                  ? null
                  : rawContentController.text.trim(),
            }),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedEmojiIds.length} 个表情吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<EmojiProvider>()
          .deleteEmojis(_selectedEmojiIds.toList());
      setState(() {
        _selectedEmojiIds.clear();
        _isSelectionMode = false;
      });
      _refreshEmojis();
    }
  }

  Future<void> _copySelected() async {
    final isGlobal = _tabController.index == 0;
    final provider = context.read<EmojiProvider>();

    // 1. 选择目标库和分组
    final result = await _showTargetSelectionDialog(
      context,
      title: '复制到...',
      isGlobalSource: isGlobal,
    );

    if (result == null) return;

    final targetType = result['type'] as EmojiType;
    final targetRoleId = result['roleId'] as String?;
    final targetGroupId = result['groupId'] as String?;

    if (mounted) {
      final emojis = isGlobal ? provider.globalEmojis : provider.roleEmojis;
      final selectedEmojis =
          emojis.where((e) => _selectedEmojiIds.contains(e.id)).toList();

      await provider.copyEmojis(
        emojis: selectedEmojis,
        targetType: targetType,
        targetRoleId: targetRoleId,
        targetGroupId: targetGroupId,
      );

      setState(() {
        _selectedEmojiIds.clear();
        _isSelectionMode = false;
      });

      _refreshEmojis();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制')),
        );
      }
    }
  }

  Future<void> _moveSelected() async {
    final isGlobal = _tabController.index == 0;
    final provider = context.read<EmojiProvider>();

    // 1. 选择目标库和分组
    final result = await _showTargetSelectionDialog(
      context,
      title: '移动到...',
      isGlobalSource: isGlobal,
    );

    if (result == null) return;

    final targetType = result['type'] as EmojiType;
    final targetRoleId = result['roleId'] as String?;
    final targetGroupId = result['groupId'] as String?;

    if (mounted) {
      final emojis = isGlobal ? provider.globalEmojis : provider.roleEmojis;
      final selectedEmojis =
          emojis.where((e) => _selectedEmojiIds.contains(e.id)).toList();

      await provider.moveEmojis(
        emojis: selectedEmojis,
        targetType: targetType,
        targetRoleId: targetRoleId,
        targetGroupId: targetGroupId,
      );

      setState(() {
        _selectedEmojiIds.clear();
        _isSelectionMode = false;
      });

      _refreshEmojis();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移动')),
        );
      }
    }
  }

  /// 弹出对话框选择目标库和分组
  Future<Map<String, dynamic>?> _showTargetSelectionDialog(BuildContext context,
      {required String title, required bool isGlobalSource}) async {
    final contactProvider = context.read<ContactProvider>();
    final emojiProvider = context.read<EmojiProvider>();
    final currentType = isGlobalSource ? EmojiType.global : EmojiType.role;
    final currentRoleId = isGlobalSource ? null : _selectedRoleId;

    // 获取当前库下的所有分组
    final currentGroups = emojiProvider.emojiGroups
        .where((g) => g.type == currentType && g.roleId == currentRoleId)
        .toList();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // --- 第一部分：当前库的分组 ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text('移动到当前库的分组',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.grey),
                title: const Text('未分组'),
                onTap: () => Navigator.pop(context, {
                  'type': currentType,
                  'roleId': currentRoleId,
                  'groupId': null,
                }),
              ),
              for (final group in currentGroups)
                ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(group.name),
                  onTap: () => Navigator.pop(context, {
                    'type': currentType,
                    'roleId': currentRoleId,
                    'groupId': group.id,
                  }),
                ),

              const Divider(),

              // --- 第二部分：其他库 ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text('移动到其他库',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ),

              // 如果当前不是全局库，显示全局库选项
              if (!isGlobalSource)
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('全局表情库'),
                  onTap: () async {
                    final groupId = await _showGroupSelectionDialog(
                        context, EmojiType.global, null);
                    if (context.mounted) {
                      Navigator.pop(context, {
                        'type': EmojiType.global,
                        'roleId': null,
                        'groupId': groupId,
                      });
                    }
                  },
                ),

              // 显示所有角色库（排除当前角色）
              for (final role in contactProvider.roles)
                if (role.id != currentRoleId)
                  ListTile(
                    leading: (role.avatarPath != null &&
                            role.avatarPath!.isNotEmpty)
                        ? CircleAvatar(
                            backgroundImage: FileImage(File(role.avatarPath!)),
                            radius: 14,
                          )
                        : const CircleAvatar(
                            radius: 14, child: Icon(Icons.person, size: 16)),
                    title: Text(role.name),
                    onTap: () async {
                      final groupId = await _showGroupSelectionDialog(
                          context, EmojiType.role, role.id);
                      if (context.mounted) {
                        Navigator.pop(context, {
                          'type': EmojiType.role,
                          'roleId': role.id,
                          'groupId': groupId,
                        });
                      }
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹出对话框选择分组
  Future<String?> _showGroupSelectionDialog(
      BuildContext context, EmojiType type, String? roleId) async {
    final provider = context.read<EmojiProvider>();
    final groups = provider.emojiGroups
        .where((g) => g.type == type && g.roleId == roleId)
        .toList();

    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择目标分组'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('未分组'),
                onTap: () => Navigator.pop(context, null),
              ),
              for (final group in groups)
                ListTile(
                  title: Text(group.name),
                  onTap: () => Navigator.pop(context, group.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _batchImportEmojis() async {
    if (_tabController.index == 1 && _selectedRoleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择一个角色')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;
    final apiProvider = context.read<ApiSettingsProvider>();

    // 强制刷新 API 列表，确保读取到数据库中的最新数据
    await apiProvider.reload();
    final updatedPresets = apiProvider.presets;

    if (updatedPresets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在设置中配置 API 预设')),
        );
      }
      return;
    }

    ApiPreset? selectedPreset;
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择多模态 API'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: updatedPresets.length,
              itemBuilder: (context, index) {
                final preset = updatedPresets[index];
                return ListTile(
                  title: Text(preset.name),
                  subtitle: Text(preset.model),
                  onTap: () {
                    selectedPreset = preset;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    if (selectedPreset == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始批量导入，AI 正在打标...')),
    );

    final promptTemplate =
        await rootBundle.loadString('assets/prompts/emoji_tagging_prompt.txt');

    if (mounted) {
      await context.read<EmojiProvider>().batchImportEmojis(
            filePaths: result.files.map((f) => f.path!).toList(),
            type: _tabController.index == 0 ? EmojiType.global : EmojiType.role,
            roleId: _tabController.index == 1 ? _selectedRoleId : null,
            onTagging: (path) async {
              return await LlmService.analyzeImage(
                apiPreset: selectedPreset!,
                imagePath: path,
                systemPrompt: promptTemplate,
              );
            },
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('批量导入完成')),
      );
    }
  }

  Future<void> _batchReTagEmojis() async {
    if (_selectedEmojiIds.isEmpty) return;

    final apiProvider = context.read<ApiSettingsProvider>();
    await apiProvider.reload();
    final updatedPresets = apiProvider.presets;

    if (updatedPresets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在设置中配置 API 预设')),
        );
      }
      return;
    }

    ApiPreset? selectedPreset;
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择多模态 API 进行重新打标'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: updatedPresets.length,
              itemBuilder: (context, index) {
                final preset = updatedPresets[index];
                return ListTile(
                  title: Text(preset.name),
                  subtitle: Text(preset.model),
                  onTap: () {
                    selectedPreset = preset;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    if (selectedPreset == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始批量重新打标...')),
    );

    final provider = context.read<EmojiProvider>();
    final currentEmojis =
        _tabController.index == 0 ? provider.globalEmojis : provider.roleEmojis;
    final selectedEmojis =
        currentEmojis.where((e) => _selectedEmojiIds.contains(e.id)).toList();

    final promptTemplate =
        await rootBundle.loadString('assets/prompts/emoji_tagging_prompt.txt');

    await provider.batchReTagEmojis(
      emojis: selectedEmojis,
      onTagging: (path) async {
        return await LlmService.analyzeImage(
          apiPreset: selectedPreset!,
          imagePath: path,
          systemPrompt: promptTemplate,
        );
      },
    );

    setState(() {
      _selectedEmojiIds.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('批量重新打标完成')),
      );
    }
  }

  Future<void> _pureBatchImportEmojis() async {
    if (_tabController.index == 1 && _selectedRoleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择一个角色')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在批量导入表情包...')),
    );

    await context.read<EmojiProvider>().pureBatchImportEmojis(
          filePaths: result.files.map((f) => f.path!).toList(),
          type: _tabController.index == 0 ? EmojiType.global : EmojiType.role,
          roleId: _tabController.index == 1 ? _selectedRoleId : null,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('批量导入完成')),
      );
    }
  }

  Future<void> _addEmojiGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建分组'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入分组名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('确定')),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      await context.read<EmojiProvider>().addEmojiGroup(
            name: name,
            type: _tabController.index == 0 ? EmojiType.global : EmojiType.role,
            roleId: _tabController.index == 1 ? _selectedRoleId : null,
          );
    }
  }

  Future<void> _deleteGroup(EmojiGroupEntity group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除分组 "${group.name}" 吗？其中的表情将变为未分组状态。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<EmojiProvider>()
          .deleteEmojiGroup(group.id, _selectedRoleId);
    }
  }
}
