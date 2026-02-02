import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/database/database.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/utils/storage_utils.dart';
import '../core/theme/app_theme.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isSelectMode = false;
  final Set<ChatMessage> _selectedMessages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isSelectMode = false;
      _selectedMessages.clear();
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) _selectedMessages.clear();
    });
  }

  void _toggleMessageSelection(ChatMessage message) {
    setState(() {
      if (_selectedMessages.contains(message)) {
        _selectedMessages.remove(message);
      } else {
        _selectedMessages.add(message);
      }
    });
  }

  Future<void> _batchDownload() async {
    if (_selectedMessages.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    for (var msg in _selectedMessages) {
      try {
        final absPath = await StorageUtils.toAbsolutePath(msg.content);
        await Gal.putImage(absPath);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      Navigator.pop(context); // 关闭加载框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载完成: 成功 $successCount, 失败 $failCount')),
      );
      setState(() {
        _isSelectMode = false;
        _selectedMessages.clear();
      });
    }
  }

  void _batchDelete() {
    if (_selectedMessages.isEmpty) return;
    _showDeleteConfirm(context, _selectedMessages.toList());
  }

  void _showDeleteConfirm(BuildContext context, List<ChatMessage> messages) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${messages.length} 张照片吗？\n删除后聊天记录中的图片也将失效。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(messages);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(List<ChatMessage> messages) async {
    final chatProvider = context.read<ChatProvider>();

    for (var msg in messages) {
      // 1. 删除物理文件
      if (!msg.content.startsWith('http')) {
        await StorageUtils.deleteFile(msg.content);
      }
      // 2. 更新数据库消息内容
      await chatProvider.updateMessage(msg.id, '[图片已删除]');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已成功删除选中的照片')),
      );
      setState(() {
        _isSelectMode = false;
        _selectedMessages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        title: Text(
          _isSelectMode
              ? '已选择 ${_selectedMessages.length} 项'
              : (_currentIndex == 0 ? '所有照片' : '角色相册'),
          style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: _isSelectMode
            ? TextButton(
                onPressed: _toggleSelectMode,
                child: Text('取消',
                    style: TextStyle(color: context.primaryTextColor)),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: context.primaryTextColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (!_isSelectMode && _currentIndex == 0)
            IconButton(
              icon: Icon(Icons.check_circle_outline,
                  color: context.primaryTextColor),
              onPressed: _toggleSelectMode,
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: _isSelectMode ? const NeverScrollableScrollPhysics() : null,
        children: [
          AllPhotosView(
            isSelectMode: _isSelectMode,
            selectedMessages: _selectedMessages,
            onToggleSelection: _toggleMessageSelection,
            onShowDeleteConfirm: (msgs) => _showDeleteConfirm(context, msgs),
          ),
          const RoleAlbumsView(),
        ],
      ),
      bottomNavigationBar: _isSelectMode
          ? _buildBatchActionBottomBar()
          : _buildNormalBottomBar(context),
    );
  }

  Widget _buildBatchActionBottomBar() {
    return Container(
      height: 60 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.appBarBackground,
        border:
            Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.download, '保存',
              _selectedMessages.isNotEmpty ? _batchDownload : null),
          _buildActionButton(Icons.delete_outline, '删除',
              _selectedMessages.isNotEmpty ? _batchDelete : null,
              color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap,
      {Color? color}) {
    final finalColor =
        onTap == null ? Colors.grey : (color ?? context.primaryTextColor);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: finalColor, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: finalColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNormalBottomBar(BuildContext context) {
    return SizedBox(
      height: 60,
      child: CupertinoTabBar(
        backgroundColor: context.appBarBackground,
        activeColor: const Color(0xFF07C160),
        inactiveColor: context.secondaryTextColor,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(CupertinoIcons.photo_fill),
            ),
            label: '所有照片',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(CupertinoIcons.person_2_square_stack_fill),
            ),
            label: '角色相册',
          ),
        ],
      ),
    );
  }
}

class AllPhotosView extends StatelessWidget {
  final bool isSelectMode;
  final Set<ChatMessage> selectedMessages;
  final Function(ChatMessage) onToggleSelection;
  final Function(List<ChatMessage>) onShowDeleteConfirm;

  const AllPhotosView({
    super.key,
    required this.isSelectMode,
    required this.selectedMessages,
    required this.onToggleSelection,
    required this.onShowDeleteConfirm,
  });

  String _getDateString(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '今天';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天';
    }
    if (date.year == now.year) {
      return '${date.month}月${date.day}日';
    }
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChatMessage>>(
      future: AppDatabase().getAllImageMessages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allImageMessages = snapshot.data!
            .where((m) => m.content.isNotEmpty && m.content != '[图片已删除]')
            .toList();
        allImageMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (allImageMessages.isEmpty) {
          return Center(
            child: Text('暂无照片',
                style: TextStyle(color: context.secondaryTextColor)),
          );
        }

        final Map<String, List<ChatMessage>> groupedMessages = {};
        final Map<String, Set<String>> groupedSources = {};

        for (var msg in allImageMessages) {
          final dateStr = _getDateString(msg.timestamp);
          if (!groupedMessages.containsKey(dateStr)) {
            groupedMessages[dateStr] = [];
            groupedSources[dateStr] = {};
          }
          groupedMessages[dateStr]!.add(msg);

          if (msg.sender != null && msg.sender!.isNotEmpty) {
            groupedSources[dateStr]!.add(msg.sender!);
          } else {
            groupedSources[dateStr]!.add(msg.isMe ? '我' : '系统');
          }
        }

        final groupKeys = groupedMessages.keys.toList();

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            for (var date in groupKeys) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (groupedSources[date]!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '|',
                          style: TextStyle(
                            color: context.secondaryTextColor.withOpacity(0.3),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            groupedSources[date]!.join(', '),
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final messages = groupedMessages[date]!;
                    final msg = messages[index];
                    return PhotoGridItem(
                      message: msg,
                      allMessages: allImageMessages,
                      isSelectMode: isSelectMode,
                      isSelected: selectedMessages.contains(msg),
                      onTap: () {
                        if (isSelectMode) {
                          onToggleSelection(msg);
                        }
                      },
                      onShowDeleteConfirm: (msgs) => onShowDeleteConfirm(msgs),
                    );
                  },
                  childCount: groupedMessages[date]!.length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}

class RoleAlbumsView extends StatelessWidget {
  const RoleAlbumsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, child) {
        return FutureBuilder<Map<String, List<ChatMessage>>>(
          future: _getRoleImageMap(contactProvider),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final roleImageMap = snapshot.data!;
            final rolesWithPhotos = contactProvider.roles
                .where((role) =>
                    roleImageMap.containsKey(role.id) &&
                    roleImageMap[role.id]!.isNotEmpty)
                .toList();

            if (rolesWithPhotos.isEmpty) {
              return Center(
                child: Text('暂无角色相册',
                    style: TextStyle(color: context.secondaryTextColor)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: rolesWithPhotos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final role = rolesWithPhotos[index];
                final roleImages = roleImageMap[role.id]!;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CupertinoListTile(
                    padding: const EdgeInsets.all(12),
                    leadingSize: 60,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: roleImages.isNotEmpty
                          ? FutureBuilder<String>(
                              future: StorageUtils.ensureFileExists(
                                  roleImages.first.content,
                                  backupData: roleImages.first.messageData),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final file = File(snapshot.data!);
                                if (!file.existsSync()) {
                                  return Container(color: context.dividerColor);
                                }
                                return Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                  cacheWidth: 120,
                                  cacheHeight: 120,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: context.dividerColor),
                                );
                              },
                            )
                          : Container(color: context.dividerColor),
                    ),
                    title: Text(role.name,
                        style: TextStyle(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text('${roleImages.length} 张照片',
                        style: TextStyle(color: context.secondaryTextColor)),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => RoleAlbumDetailScreen(
                            role: role,
                            messages: roleImages,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, List<ChatMessage>>> _getRoleImageMap(
      ContactProvider contactProvider) async {
    final db = AppDatabase();
    final allSessions = await db.getAllSessions();
    final Map<String, List<ChatMessage>> roleImageMap = {};

    for (var session in allSessions) {
      final roleId = session.roleId;
      final sessionImages = await db.getMessages(session.id);
      final imageMessages = sessionImages
          .where((m) => m.type == MessageType.image && m.content != '[图片已删除]')
          .toList();

      if (imageMessages.isNotEmpty) {
        if (!roleImageMap.containsKey(roleId)) {
          roleImageMap[roleId] = [];
        }
        roleImageMap[roleId]!.addAll(imageMessages);
      }
    }

    for (var roleId in roleImageMap.keys) {
      roleImageMap[roleId]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return roleImageMap;
  }
}

class RoleAlbumDetailScreen extends StatelessWidget {
  final ContactRole role;
  final List<ChatMessage> messages;

  const RoleAlbumDetailScreen({
    super.key,
    required this.role,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        title: Text(role.name,
            style: TextStyle(
                color: context.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: context.primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return PhotoGridItem(
            message: messages[index],
            allMessages: messages,
            isSelectMode: false,
            isSelected: false,
            onTap: () {},
            onShowDeleteConfirm: (msgs) {
              // 详情页暂不支持批量删除，仅支持长按删除
            },
          );
        },
      ),
    );
  }
}

class PhotoGridItem extends StatelessWidget {
  final ChatMessage message;
  final List<ChatMessage> allMessages;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(List<ChatMessage>) onShowDeleteConfirm;

  const PhotoGridItem({
    super.key,
    required this.message,
    required this.allMessages,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onShowDeleteConfirm,
  });

  void _showFullScreen(BuildContext context) {
    final initialIndex = allMessages.indexOf(message);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          imageMessages: allMessages,
          initialIndex: initialIndex,
          onDelete: (msg) => onShowDeleteConfirm([msg]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectMode ? onTap : () => _showFullScreen(context),
      onLongPress: isSelectMode ? null : () => _showLongPressMenu(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'album_${message.id}',
            child: _buildImage(message.content),
          ),
          if (isSelectMode)
            Positioned(
              right: 4,
              top: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF07C160) : Colors.white70,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String content) {
    if (content.startsWith('http')) {
      return Image.network(
        content,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      return FutureBuilder<String>(
        future: StorageUtils.ensureFileExists(content,
            backupData: message.messageData),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container(color: Colors.grey[200]);
          final file = File(snapshot.data!);
          if (!file.existsSync()) return _buildErrorPlaceholder();
          return Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorPlaceholder(),
          );
        },
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
    );
  }

  void _showLongPressMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final absPath =
                    await StorageUtils.toAbsolutePath(message.content);
                await Gal.putImage(absPath);
                _showToast(context, '保存成功', '照片已保存到相册');
              } catch (e) {
                _showToast(context, '保存失败', e.toString());
              }
            },
            child: const Text('保存到相册'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onShowDeleteConfirm([message]);
            },
            child: const Text('删除照片'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
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

class FullScreenPhotoViewer extends StatefulWidget {
  final List<ChatMessage> imageMessages;
  final int initialIndex;
  final Function(ChatMessage) onDelete;

  const FullScreenPhotoViewer({
    super.key,
    required this.imageMessages,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${_currentIndex + 1} / ${widget.imageMessages.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () => _showOptions(context),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        onLongPress: () => _showOptions(context),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageMessages.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final message = widget.imageMessages[index];
            return Hero(
              tag: 'album_${message.id}',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: FutureBuilder<String>(
                    future: StorageUtils.ensureFileExists(message.content,
                        backupData: message.messageData),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator(
                            color: Colors.white);
                      }
                      final file = File(snapshot.data!);
                      if (!file.existsSync()) return _buildErrorPlaceholder();
                      return Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildErrorPlaceholder(),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentPath = widget.imageMessages[_currentIndex].content;
                final absPath = await StorageUtils.toAbsolutePath(currentPath);
                await Gal.putImage(absPath);
                _showToast(context, '保存成功', '照片已保存到相册');
              } catch (e) {
                _showToast(context, '保存失败', e.toString());
              }
            },
            child: const Text('保存到相册'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(widget.imageMessages[_currentIndex]);
              Navigator.pop(context); // 删除后退出全屏
            },
            child: const Text('删除照片'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: Colors.white, size: 64),
          SizedBox(height: 16),
          Text('图片加载失败', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
