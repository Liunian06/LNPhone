import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/emoji_model.dart';
import '../core/models/contact_model.dart';
import '../core/providers/emoji_provider.dart';
import '../core/providers/contact_provider.dart';

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
  int _currentGroupIndex = 0; // 0 为“角色专属/常用”

  @override
  void initState() {
    super.initState();
    // 确保进入时触发一次加载，以防 Provider 缓存为空
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmojiProvider>().loadEmojis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<EmojiProvider>();
    // 监听表情变化，确保偷图后能及时刷新
    final allEmojis = provider.allEmojis;
    final isLoading = provider.isLoading;
    final contactProvider = context.watch<ContactProvider>();
    final role = contactProvider.roles.firstWhere(
      (r) => r.id == widget.roleId,
      orElse: () => ContactRole(
        id: widget.roleId,
        name: '未知角色',
        description: '',
        avatarPath: null,
      ),
    );

    // 1. 未分组表情（全局池中没有 groupId 的）
    final ungroupedEmojis = allEmojis
        .where((e) => e.type == EmojiType.global && e.groupId == null)
        .toList();

    // 2. 角色“偷图”（通过 ID 关联的表情）
    // 逻辑：在角色的订阅列表中，且不在已订阅的分组内（或者是单独偷来的）
    final stolenEmojis = allEmojis.where((e) {
      return role.subscribedEmojiIds.contains(e.id) &&
          (e.groupId == null || !role.subscribedGroupIds.contains(e.groupId));
    }).toList();

    // 3. 获取所有全局分组
    final allGlobalGroups =
        provider.emojiGroups.where((g) => g.type == EmojiType.global).toList();

    // 4. 排序分组：已订阅在前，未订阅在后
    final subscribedGroups = allGlobalGroups
        .where((g) => role.subscribedGroupIds.contains(g.id))
        .toList();
    final unsubscribedGroups = allGlobalGroups
        .where((g) => !role.subscribedGroupIds.contains(g.id))
        .toList();

    final displayGroups = [...subscribedGroups, ...unsubscribedGroups];

    return Container(
      height: 350,
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          // 顶部滑动切换区域
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allEmojis.isEmpty
                    ? const Center(child: Text('暂无可用表情，请先在表情库导入'))
                    : IndexedStack(
                        index: _currentGroupIndex.clamp(
                            0, displayGroups.length + 1),
                        children: [
                          // 1. 未分组
                          _buildEmojiGrid(ungroupedEmojis, isDark),
                          // 2. 偷图分组
                          _buildEmojiGrid(stolenEmojis, isDark),
                          // 3. 各个全局分组
                          for (final group in displayGroups)
                            _buildEmojiGrid(
                                allEmojis
                                    .where((e) => e.groupId == group.id)
                                    .toList(),
                                isDark),
                        ],
                      ),
          ),

          // 底部导航栏（类似微信/截图中的样式）
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[300]!)),
              color: isDark ? Colors.black26 : Colors.grey[50],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayGroups.length + 2,
              itemBuilder: (context, index) {
                final isSelected = _currentGroupIndex == index;
                String? iconPath;
                IconData? iconData;
                String label = '';

                if (index == 0) {
                  iconData = Icons.apps_rounded;
                  label = '未分组';
                  // 尝试取未分组第一个表情作为图标
                  final firstEmoji = ungroupedEmojis.firstOrNull;
                  if (firstEmoji != null) {
                    iconPath = firstEmoji.localPath;
                  }
                } else if (index == 1) {
                  iconData = Icons.auto_awesome_motion_outlined;
                  label = '偷图';
                  // 尝试取偷图第一个表情作为图标
                  final firstEmoji = stolenEmojis.firstOrNull;
                  if (firstEmoji != null) {
                    iconPath = firstEmoji.localPath;
                  }
                } else {
                  final group = displayGroups[index - 2];
                  label = group.name;
                  // 尝试取该组第一个表情作为图标
                  final firstEmoji =
                      allEmojis.where((e) => e.groupId == group.id).firstOrNull;
                  if (firstEmoji != null) {
                    iconPath = firstEmoji.localPath;
                  } else {
                    iconData = Icons.grid_view_rounded;
                  }
                }

                return GestureDetector(
                  onTap: () => setState(() => _currentGroupIndex = index),
                  child: Container(
                    width: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white10 : Colors.white)
                          : Colors.transparent,
                    ),
                    child: iconPath != null
                        ? Image.file(File(iconPath),
                            width: 24, height: 24, fit: BoxFit.contain)
                        : Icon(iconData,
                            size: 24,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(List<EmojiModel> emojis, bool isDark) {
    if (emojis.isEmpty) {
      return const Center(
          child: Text('该分组暂无表情', style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
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
