import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/theme/app_theme.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

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
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        title: Text(
          _currentIndex == 0 ? '所有照片' : '角色相册',
          style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: context.primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          AllPhotosView(),
          RoleAlbumsView(),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 60, // 增加底栏高度
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
      ),
    );
  }
}

class AllPhotosView extends StatelessWidget {
  const AllPhotosView({super.key});

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
    return Selector<ChatProvider, List<ChatMessage>>(
      selector: (_, provider) {
        final List<ChatMessage> allImages = [];
        for (var chat in provider.chats) {
          for (var m in chat.messages) {
            if (m.type == MessageType.image) {
              allImages.add(m);
            }
          }
        }
        return allImages..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      },
      builder: (context, allImageMessages, child) {
        if (allImageMessages.isEmpty) {
          return Center(
            child: Text('暂无照片',
                style: TextStyle(color: context.secondaryTextColor)),
          );
        }

        // 按日期分组并收集来源
        final Map<String, List<ChatMessage>> groupedMessages = {};
        final Map<String, Set<String>> groupedSources = {};

        for (var msg in allImageMessages) {
          final dateStr = _getDateString(msg.timestamp);
          if (!groupedMessages.containsKey(dateStr)) {
            groupedMessages[dateStr] = [];
            groupedSources[dateStr] = {};
          }
          groupedMessages[dateStr]!.add(msg);

          // 收集来源名称
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
                    return PhotoGridItem(
                      message: messages[index],
                      allMessages: allImageMessages,
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
    return Consumer2<ChatProvider, ContactProvider>(
      builder: (context, chatProvider, contactProvider, child) {
        final roles = contactProvider.roles;

        // 优化：预先建立 roleId 到 chat 的映射，避免在循环中多次查找
        final chatMap = {
          for (var chat in chatProvider.chats) chat.roleId: chat
        };

        final rolesWithPhotos = roles.where((role) {
          final chat = chatMap[role.id];
          if (chat == null) return false;
          return chat.messages.any((m) => m.type == MessageType.image);
        }).toList();

        if (rolesWithPhotos.isEmpty) {
          return Center(
            child: Text('暂无角色相册',
                style: TextStyle(color: context.secondaryTextColor)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: rolesWithPhotos.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 12), // 增加间隔
          itemBuilder: (context, index) {
            final role = rolesWithPhotos[index];
            final chat = chatMap[role.id]!;
            final roleImages = chat.messages
                .where((m) => m.type == MessageType.image)
                .toList();
            roleImages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
                      ? Image.file(
                          File(roleImages.first.content),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          cacheWidth: 120, // 优化：限制解码大小
                          cacheHeight: 120,
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
          );
        },
      ),
    );
  }
}

class PhotoGridItem extends StatelessWidget {
  final ChatMessage message;
  final List<ChatMessage> allMessages;

  const PhotoGridItem({
    super.key,
    required this.message,
    required this.allMessages,
  });

  void _showFullScreen(BuildContext context) {
    final initialIndex = allMessages.indexOf(message);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          imageMessages: allMessages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      onLongPress: () => _showSaveDialog(context),
      child: Hero(
        tag: 'album_${message.id}',
        child: Image.file(
          File(message.content),
          fit: BoxFit.cover,
          cacheWidth: 300, // 优化：网格缩略图限制解码大小，大幅减少内存占用
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Gal.putImage(message.content);
                if (context.mounted) {
                  _showToast(context, '保存成功', '照片已保存到相册');
                }
              } catch (e) {
                if (context.mounted) {
                  _showToast(context, '保存失败', e.toString());
                }
              }
            },
            child: const Text('保存到相册'),
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

  const FullScreenPhotoViewer({
    super.key,
    required this.imageMessages,
    required this.initialIndex,
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
                  child: Image.file(
                    File(message.content),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
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
                await Gal.putImage(currentPath);
                if (context.mounted) {
                  _showToast(context, '保存成功', '照片已保存到相册');
                }
              } catch (e) {
                if (context.mounted) {
                  _showToast(context, '保存失败', e.toString());
                }
              }
            },
            child: const Text('保存到相册'),
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
