import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/models/world_info_model.dart';
import '../widgets/ios_wallpaper.dart';
import '../core/utils/storage_utils.dart';

/// 世界书列表页面 - ChatProvider 重构版
class WorldInfoListScreen extends StatefulWidget {
  const WorldInfoListScreen({super.key});

  @override
  State<WorldInfoListScreen> createState() => _WorldInfoListScreenState();
}

class _WorldInfoListScreenState extends State<WorldInfoListScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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
        content: Text('确定要删除选中的 ${_selectedIds.length} 个世界书吗？'),
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
      await provider.deleteWorldInfos(_selectedIds.toList());
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
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    if (!provider.isLoaded) {
                      return Center(
                        child: CupertinoActivityIndicator(
                            color: isDark ? Colors.white : Colors.grey),
                      );
                    }

                    final list = provider.worldInfos;
                    if (list.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final info = list[index];
                        return _buildListItem(context, info, provider, isDark);
                      },
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
              '世界书',
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
                  builder: (context) => const WorldInfoEditScreen()),
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

  Widget _buildEmptyState(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.book_fill,
            size: 80,
            color: textColor.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            '点击右上角按钮新建世界书',
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

  Widget _buildListItem(BuildContext context, WorldInfo info,
      ChatProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1);
    final isSelected = _selectedIds.contains(info.id);

    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF007AFF) : borderColor,
          width: isSelected ? 2 : 1,
        ),
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
                    const Icon(CupertinoIcons.doc_text,
                        color: Color(0xFF8E2DE2), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  info.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
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
              onTap: () => _toggleSelection(info.id),
              child: content,
            )
          : Dismissible(
              key: Key('world_info_${info.id}'),
              direction: DismissDirection.endToStart,
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
                return await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除"${info.name}"吗？'),
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
              onDismissed: (_) => provider.deleteWorldInfo(info.id),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => WorldInfoEditScreen(info: info),
                  ),
                ),
                child: content,
              ),
            ),
    );
  }
}

/// 世界书编辑页面
class WorldInfoEditScreen extends StatefulWidget {
  final WorldInfo? info;
  const WorldInfoEditScreen({super.key, this.info});

  @override
  State<WorldInfoEditScreen> createState() => _WorldInfoEditScreenState();
}

class _WorldInfoEditScreenState extends State<WorldInfoEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.info?.name ?? '');
    _contentController =
        TextEditingController(text: widget.info?.content ?? '');
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

    final now = StorageUtils.getUniqueTimestamp();
    final info = WorldInfo(
      id: widget.info?.id ?? now.toString(),
      name: name,
      content: content,
      createdAt: widget.info?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await provider.addWorldInfo(info);
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
    if (widget.info == null) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${widget.info!.name}"吗？'),
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
      await provider.deleteWorldInfo(widget.info!.id);
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
                    _buildInputLabel('名称', isDark),
                    _buildTextField(
                      controller: _nameController,
                      placeholder: '输入世界书名称...',
                      maxLines: 1,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    _buildInputLabel('内容', isDark),
                    _buildTextField(
                      controller: _contentController,
                      placeholder: '输入世界书详细内容 (纯文本)...',
                      maxLines: 15,
                      height: 400,
                      isDark: isDark,
                    ),
                    if (widget.info != null) ...[
                      const SizedBox(height: 40),
                      CupertinoButton(
                        color: CupertinoColors.destructiveRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => _handleDelete(provider),
                        child: const Text(
                          '删除世界书',
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
            widget.info == null ? '新建世界书' : '编辑世界书',
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
