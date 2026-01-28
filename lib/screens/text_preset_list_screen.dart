import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/prompt_settings_provider.dart';
import '../core/models/text_preset_model.dart';
import '../widgets/ios_wallpaper.dart';

/// 预设列表页面 - ChatProvider 重构版
class TextPresetListScreen extends StatefulWidget {
  const TextPresetListScreen({super.key});

  @override
  State<TextPresetListScreen> createState() => _TextPresetListScreenState();
}

class _TextPresetListScreenState extends State<TextPresetListScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  TextPresetType _currentType = TextPresetType.chat;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentType.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _handleBatchDelete(ChatProvider provider) async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 个预设吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTextPresets(_selectedIds.toList());
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark ? Colors.black : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              _buildTypeSelector(isDark),
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    if (!provider.isLoaded) {
                      return Center(
                        child: CupertinoActivityIndicator(
                            color: isDark ? Colors.white : Colors.grey),
                      );
                    }

                    return PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentType = TextPresetType.values[index];
                          _isSelectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                      children: [
                        _buildPresetList(provider, TextPresetType.chat, isDark),
                        _buildPresetList(
                            provider, TextPresetType.image, isDark),
                      ],
                    );
                  },
                ),
              ),
              if (_isSelectionMode) _buildBatchActionBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildHeaderButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.pop(context),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '预设',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildHeaderButton(
            icon: _isSelectionMode
                ? CupertinoIcons.xmark
                : CupertinoIcons.list_bullet,
            onTap: _toggleSelectionMode,
            isDark: isDark,
            active: _isSelectionMode,
          ),
          const SizedBox(width: 12),
          _buildHeaderButton(
            icon: CupertinoIcons.add,
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) =>
                    TextPresetEditScreen(initialType: _currentType),
              ),
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF007AFF)
              : (isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color:
                active ? Colors.white : (isDark ? Colors.white : Colors.black),
            size: 24),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = 0;
            if (_pageController.hasClients) {
              page = _pageController.page ??
                  _pageController.initialPage.toDouble();
            } else {
              page = _currentType.index.toDouble();
            }

            return Stack(
              children: [
                // 滑动背景指示器 - 带有拉伸效果
                Builder(builder: (context) {
                  final double totalWidth =
                      MediaQuery.of(context).size.width - 32;
                  final double itemWidth = totalWidth / 2;
                  // 计算拉伸：在中间位置时指示器变长
                  final double stretchFactor =
                      (0.5 - (page - 0.5).abs()).clamp(0.0, 0.5) * 0.4;
                  final double indicatorWidth =
                      itemWidth * (1.0 + stretchFactor);
                  // 偏移量调整，使其在滑动时看起来有拉力
                  final double leftOffset =
                      (totalWidth / 2) * page - (itemWidth * stretchFactor / 2);

                  return Positioned(
                    left: leftOffset,
                    width: indicatorWidth,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeItem(
                          '聊天预设', TextPresetType.chat, isDark, page),
                    ),
                    Expanded(
                      child: _buildTypeItem(
                          '生图预设', TextPresetType.image, isDark, page),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeItem(
      String label, TextPresetType type, bool isDark, double currentPage) {
    final index = type.index;
    // 计算当前项的激活程度 (0.0 到 1.0)
    final double activeFactor =
        (1.0 - (currentPage - index).abs()).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
        );
      },
      child: Center(
        child: Transform.scale(
          scale: 1.0 + (0.1 * activeFactor), // 激活时轻微放大
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.lerp(
                isDark ? Colors.white70 : Colors.black54,
                Colors.white,
                activeFactor,
              ),
              fontSize: 14,
              fontWeight:
                  activeFactor > 0.5 ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionBar(bool isDark) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '已选择 ${_selectedIds.length} 项',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: CupertinoColors.destructiveRed,
            borderRadius: BorderRadius.circular(20),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _handleBatchDelete(provider),
            child: const Text('批量删除',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList(
      ChatProvider provider, TextPresetType type, bool isDark) {
    final list = provider.textPresets.where((p) => p.type == type).toList();

    // 排序逻辑：自定义在前（按更新时间倒序），内置在后
    list.sort((a, b) {
      if (a.isBuiltIn != b.isBuiltIn) {
        return a.isBuiltIn ? 1 : -1; // 自定义在前，内置在后
      }
      // 同类型的按更新时间倒序
      return b.updatedAt.compareTo(a.updatedAt);
    });

    if (list.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Consumer<PromptSettingsProvider>(
      builder: (context, promptProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final preset = list[index];
            final isGlobalDefault = type == TextPresetType.image &&
                promptProvider.activeImagePresetId == preset.id;
            return _buildListItem(
                context, preset, provider, isDark, isGlobalDefault);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text_fill,
            size: 80,
            color: textColor.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            '点击右上角按钮新建预设',
            style: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, TextPreset preset,
      ChatProvider provider, bool isDark,
      [bool isGlobalDefault = false]) {
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor = isGlobalDefault
        ? const Color(0xFF007AFF).withOpacity(0.5)
        : (isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1));
    final isSelected = _selectedIds.contains(preset.id);

    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF007AFF)
              : (isGlobalDefault ? const Color(0xFF007AFF) : borderColor),
          width: (isSelected || isGlobalDefault) ? 2 : 1,
        ),
        boxShadow: isGlobalDefault
            ? [
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : textColor.withOpacity(0.3),
                size: 24,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_plaintext,
                        color: Color(0xFFFF512F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            preset.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isGlobalDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      const Color(0xFF007AFF).withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: const Text(
                                '默认',
                                style: TextStyle(
                                  color: Color(0xFF007AFF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  preset.isBuiltIn ? '' : preset.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                    fontStyle:
                        preset.isBuiltIn ? FontStyle.italic : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _isSelectionMode
          ? GestureDetector(
              onTap: () => _toggleSelection(preset.id),
              child: content,
            )
          : Dismissible(
              key: Key('text_preset_${preset.id}'),
              direction: preset.isBuiltIn
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (preset.isBuiltIn) return false;
                return await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除"${preset.name}"吗？'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('取消'),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('删除'),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => provider.deleteTextPreset(preset.id),
              child: GestureDetector(
                onLongPress: preset.type == TextPresetType.image
                    ? () {
                        final promptProvider =
                            context.read<PromptSettingsProvider>();
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            title: Text('预设: ${preset.name}'),
                            actions: [
                              if (promptProvider.activeImagePresetId !=
                                  preset.id)
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    promptProvider
                                        .updateActiveImagePreset(preset.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已设为全局默认生图预设'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Text('设为全局默认'),
                                ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                          ),
                        );
                      }
                    : null,
                onTap: () {
                  if (preset.isBuiltIn) {
                    // 内置预设不可编辑
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('提示'),
                        content: const Text('内置预设不可编辑'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('确定'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) =>
                          TextPresetEditScreen(preset: preset),
                    ),
                  );
                },
                child: content,
              ),
            ),
    );
  }
}

/// 预设编辑页面
class TextPresetEditScreen extends StatefulWidget {
  final TextPreset? preset;
  final TextPresetType initialType;
  const TextPresetEditScreen(
      {super.key, this.preset, this.initialType = TextPresetType.chat});

  @override
  State<TextPresetEditScreen> createState() => _TextPresetEditScreenState();
}

class _TextPresetEditScreenState extends State<TextPresetEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late TextPresetType _type;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _contentController =
        TextEditingController(text: widget.preset?.content ?? '');
    _type = widget.preset?.type ?? widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(ChatProvider provider) async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final preset = TextPreset(
      id: widget.preset?.id ?? now.toString(),
      name: name,
      content: content,
      type: _type,
      isBuiltIn: false,
      createdAt: widget.preset?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await provider.addTextPreset(preset);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(ChatProvider provider) async {
    if (widget.preset == null) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${widget.preset!.name}"吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTextPreset(widget.preset!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark ? Colors.black : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, provider, isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildInputLabel('分类', isDark),
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 24),
                    _buildInputLabel('名称', isDark),
                    _buildTextField(
                      controller: _nameController,
                      placeholder: '输入预设名称...',
                      maxLines: 1,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    _buildInputLabel('内容', isDark),
                    _buildTextField(
                      controller: _contentController,
                      placeholder: '输入预设详细内容 (纯文本)...',
                      maxLines: 15,
                      height: 400,
                      isDark: isDark,
                    ),
                    if (widget.preset != null) ...[
                      const SizedBox(height: 40),
                      CupertinoButton(
                        color: CupertinoColors.destructiveRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => _handleDelete(provider),
                        child: const Text(
                          '删除预设',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // 滑动背景指示器
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: _type == TextPresetType.chat
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildTypeItem('聊天预设', TextPresetType.chat, isDark),
              ),
              Expanded(
                child: _buildTypeItem('生图预设', TextPresetType.image, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem(String label, TextPresetType type, bool isDark) {
    final isSelected = _type == type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _type = type;
        });
      },
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isSelected ? 1.1 : 1.0,
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ChatProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.back, color: textColor, size: 24),
            ),
          ),
          Text(
            widget.preset == null ? '新建预设' : '编辑预设',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => _handleSave(provider),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isSaving
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Icon(CupertinoIcons.check_mark,
                      color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withOpacity(0.5),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    double? height,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: TextStyle(color: textColor.withOpacity(0.2)),
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: null,
        maxLines: maxLines,
        cursorColor: const Color(0xFF007AFF),
      ),
    );
  }
}
