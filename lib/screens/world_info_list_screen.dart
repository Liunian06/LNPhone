import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/models/world_info_model.dart';
import '../widgets/ios_wallpaper.dart';

/// 世界书列表页面 - ChatProvider 重构版
class WorldInfoListScreen extends StatelessWidget {
  const WorldInfoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    if (!provider.isLoaded) {
                      return const Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      );
                    }

                    final list = provider.worldInfos;
                    if (list.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final info = list[index];
                        return _buildListItem(context, info, provider);
                      },
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.pop(context),
          ),
          const Text(
            '世界书',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          _buildHeaderButton(
            icon: CupertinoIcons.add,
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => const WorldInfoEditScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.book_fill,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            '点击右上角按钮新建世界书',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, WorldInfo info, ChatProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
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
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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

    final now = DateTime.now().millisecondsSinceEpoch;
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, provider),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildInputLabel('名称'),
                    _buildTextField(
                      controller: _nameController,
                      placeholder: '输入世界书名称...',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 24),
                    _buildInputLabel('内容'),
                    _buildTextField(
                      controller: _contentController,
                      placeholder: '输入世界书详细内容 (纯文本)...',
                      maxLines: 15,
                      height: 400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatProvider provider) {
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
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.back,
                  color: Colors.white, size: 24),
            ),
          ),
          Text(
            widget.info == null ? '新建世界书' : '编辑世界书',
            style: const TextStyle(
              color: Colors.white,
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
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
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
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: null,
        maxLines: maxLines,
        cursorColor: const Color(0xFF007AFF),
      ),
    );
  }
}
