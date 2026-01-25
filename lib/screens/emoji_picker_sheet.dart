import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/emoji_model.dart';
import '../core/providers/emoji_provider.dart';

class EmojiPickerSheet extends StatefulWidget {
  final String roleId;
  final Function(EmojiModel) onEmojiSelected;

  const EmojiPickerSheet({
    super.key,
    required this.roleId,
    required this.onEmojiSelected,
  });

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet> {
  List<EmojiModel> _availableEmojis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmojis();
  }

  Future<void> _loadEmojis() async {
    final provider = context.read<EmojiProvider>();
    final emojis = await provider.getAvailableEmojisForRole(widget.roleId);
    if (mounted) {
      setState(() {
        _availableEmojis = emojis;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<EmojiProvider>();
    final groups = provider.emojiGroups.where((g) {
      if (g.type == EmojiType.global) return true;
      return g.roleId == widget.roleId;
    }).toList();

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableEmojis.isEmpty
                    ? const Center(child: Text('暂无可用表情'))
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          // 未分组
                          _buildGroupSection(
                              '常用',
                              _availableEmojis
                                  .where((e) => e.groupId == null)
                                  .toList(),
                              isDark),
                          // 各个分组
                          for (final group in groups)
                            _buildGroupSection(
                                group.name,
                                _availableEmojis
                                    .where((e) => e.groupId == group.id)
                                    .toList(),
                                isDark),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
      String title, List<EmojiModel> emojis, bool isDark) {
    if (emojis.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) {
            final emoji = emojis[index];
            return GestureDetector(
              onTap: () => widget.onEmojiSelected(emoji),
              child: Tooltip(
                message: emoji.meaning,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.file(
                    File(emoji.localPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
