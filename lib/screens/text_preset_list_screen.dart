import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/models/text_preset_model.dart';
import '../widgets/ios_wallpaper.dart';

/// 预设列表页面 - ChatProvider 重构版
class TextPresetListScreen extends StatelessWidget {
  const TextPresetListScreen({super.key});

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

                    final list = provider.textPresets;
                    if (list.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final preset = list[index];
                        return _buildListItem(
                            context, preset, provider, isDark);
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.pop(context),
            isDark: isDark,
          ),
          Text(
            '预设',
            style: TextStyle(
              color: textColor,
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
                  builder: (context) => const TextPresetEditScreen()),
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon,
      required VoidCallback onTap,
      required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child:
            Icon(icon, color: isDark ? Colors.white : Colors.black, size: 24),
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
      ChatProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('text_preset_${preset.id}'),
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
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => TextPresetEditScreen(preset: preset),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_plaintext,
                        color: Color(0xFFFF512F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preset.name,
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
                  preset.content,
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
        ),
      ),
    );
  }
}

/// 预设编辑页面
class TextPresetEditScreen extends StatefulWidget {
  final TextPreset? preset;
  const TextPresetEditScreen({super.key, this.preset});

  @override
  State<TextPresetEditScreen> createState() => _TextPresetEditScreenState();
}

class _TextPresetEditScreenState extends State<TextPresetEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _contentController =
        TextEditingController(text: widget.preset?.content ?? '');
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
