import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/moments_model.dart';
import '../core/providers/moments_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/utils/time_formatter.dart';

/// 朋友圈动态项
class MomentsPostItem extends StatefulWidget {
  final MomentsPost post;

  const MomentsPostItem({super.key, required this.post});

  @override
  State<MomentsPostItem> createState() => _MomentsPostItemState();
}

class _MomentsPostItemState extends State<MomentsPostItem> {
  bool _showFullContent = false;
  final TextEditingController _commentController = TextEditingController();
  MomentsUser? _replyToUser;
  OverlayEntry? _menuOverlay;
  final GlobalKey _moreButtonKey = GlobalKey();

  @override
  void dispose() {
    _removeMenuOverlay();
    _commentController.dispose();
    super.dispose();
  }

  void _removeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      color: containerBgColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          _buildAvatar(),
          const SizedBox(width: 12),
          // 内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名（当前用户显示最新昵称）
                Builder(
                  builder: (context) {
                    final momentsProvider = context.watch<MomentsProvider>();
                    final currentUser = momentsProvider.currentUser;
                    final isCurrentUser = widget.post.user.id == currentUser.id;
                    // 如果是当前用户发的帖子，使用最新昵称；否则使用帖子中保存的名字
                    final displayName = isCurrentUser
                        ? currentUser.name
                        : widget.post.user.name;
                    return Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF7AA3E5)
                            : const Color(0xFF576B95),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                // 文字内容
                if (widget.post.content != null) _buildContent(isDark),
                // 图片/视频
                if (widget.post.mediaItems.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildMediaGrid(),
                ],
                const SizedBox(height: 8),
                // 时间、位置和操作按钮
                _buildTimeLocationAndAction(isDark),
                const SizedBox(height: 8),
                // 点赞和评论区域
                if (widget.post.likes.isNotEmpty ||
                    widget.post.comments.isNotEmpty)
                  _buildInteractionArea(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    final momentsProvider = context.watch<MomentsProvider>();
    final contactProvider = context.watch<ContactProvider>();
    final currentUser = momentsProvider.currentUser;

    // 判断是否是当前用户发的帖子
    final isCurrentUser = widget.post.user.id == currentUser.id;

    String avatarUrl;
    if (isCurrentUser) {
      // 当前用户发的帖子，使用最新头像
      avatarUrl = currentUser.avatarUrl;
    } else {
      // 角色发的帖子，从 ContactProvider 获取角色的最新头像
      final role = contactProvider.roles.firstWhere(
        (r) => r.id == widget.post.user.id,
        orElse: () => contactProvider.roles.isNotEmpty
            ? contactProvider.roles.first
            : throw StateError('No roles found'),
      );
      // 如果能找到角色，使用角色的最新头像；否则使用帖子中保存的头像
      avatarUrl = role.avatarPath ?? widget.post.user.avatarUrl;
    }

    return GestureDetector(
      onTap: () {
        // TODO: 跳转到个人主页
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildAvatarImage(avatarUrl),
        ),
      ),
    );
  }

  /// 构建头像图片（支持本地和网络图片）
  Widget _buildAvatarImage(String avatarUrl) {
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person, size: 24),
          );
        },
      );
    } else {
      return Image.file(
        File(avatarUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person, size: 24),
          );
        },
      );
    }
  }

  /// 构建文字内容
  Widget _buildContent(bool isDark) {
    final content = widget.post.content!;
    final shouldTruncate = content.length > 100 && !_showFullContent;
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final linkColor =
        isDark ? const Color(0xFF7AA3E5) : const Color(0xFF576B95);

    return GestureDetector(
      onTap: () {
        if (content.length > 100) {
          setState(() {
            _showFullContent = !_showFullContent;
          });
        }
      },
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  shouldTruncate ? '${content.substring(0, 100)}...' : content,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.4,
              ),
            ),
            if (shouldTruncate)
              TextSpan(
                text: ' 全文',
                style: TextStyle(fontSize: 16, color: linkColor),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建媒体网格
  Widget _buildMediaGrid() {
    final itemCount = widget.post.mediaItems.length;

    // 单张图片/视频
    if (itemCount == 1) {
      return _buildSingleMedia(widget.post.mediaItems[0]);
    }

    // 多张图片/视频
    final columns = itemCount == 4 ? 2 : 3;
    final rows = (itemCount / columns).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: itemCount > 9 ? 9 : itemCount,
      itemBuilder: (context, index) {
        return _buildGridMedia(widget.post.mediaItems[index]);
      },
    );
  }

  /// 构建单张媒体
  Widget _buildSingleMedia(MediaItem item) {
    return GestureDetector(
      onTap: () {
        // TODO: 查看大图/播放视频
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildImage(
                item.type == MediaType.video && item.thumbnailUrl != null
                    ? item.thumbnailUrl!
                    : item.url,
                BoxFit.cover,
              ),
            ),
            if (item.type == MediaType.video)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建网格媒体
  Widget _buildGridMedia(MediaItem item) {
    return GestureDetector(
      onTap: () {
        // TODO: 查看大图/播放视频
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildImage(
              item.type == MediaType.video && item.thumbnailUrl != null
                  ? item.thumbnailUrl!
                  : item.url,
              BoxFit.cover,
            ),
          ),
          if (item.type == MediaType.video)
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 32,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建时间、位置和操作按钮
  Widget _buildTimeLocationAndAction(bool isDark) {
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Row(
      children: [
        Text(
          TimeFormatter.formatMomentsTime(widget.post.createdAt),
          style: TextStyle(fontSize: 14, color: secondaryColor),
        ),
        if (widget.post.location != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.location_on, size: 14, color: secondaryColor),
          const SizedBox(width: 2),
          Text(
            widget.post.location!,
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),
        ],
        const Spacer(),
        // 更多按钮
        _buildMoreButton(isDark),
      ],
    );
  }

  /// 构建更多按钮
  Widget _buildMoreButton(bool isDark) {
    final bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF7F7F7);
    final iconColor =
        isDark ? const Color(0xFF7AA3E5) : const Color(0xFF576B95);

    return GestureDetector(
      key: _moreButtonKey,
      onTap: () {
        if (_menuOverlay != null) {
          _removeMenuOverlay();
        } else {
          _showMenuOverlay();
        }
      },
      child: Container(
        height: 24,
        width: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.more_horiz, size: 18, color: iconColor),
      ),
    );
  }

  /// 显示悬浮菜单
  void _showMenuOverlay() {
    final RenderBox? renderBox =
        _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    // 菜单宽度
    const menuWidth = 200.0;

    // 计算菜单位置：在按钮左侧显示
    double left = buttonPosition.dx - menuWidth - 8;
    if (left < 8) {
      left = 8;
    }

    // 菜单顶部与按钮对齐
    final top = buttonPosition.dy - 20;

    _menuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 透明遮罩层，点击关闭菜单
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeMenuOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 菜单
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _buildInteractionPanel(),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_menuOverlay!);
  }

  /// 构建交互面板（点赞、评论、编辑、删除）
  Widget _buildInteractionPanel() {
    final momentsProvider = context.read<MomentsProvider>();
    final isLiked = momentsProvider.isLiked(widget.post.id);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF4C4C4C),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 第一行：点赞和评论
          Row(
            children: [
              // 点赞按钮
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _removeMenuOverlay();
                    momentsProvider.toggleLike(widget.post.id);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLiked ? '取消' : '赞',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 分隔线
              Container(width: 1, height: 20, color: Colors.black26),
              // 评论按钮
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _removeMenuOverlay();
                    setState(() {
                      _replyToUser = null;
                    });
                    _showCommentInput();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '评论',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 第二行：编辑和删除（所有帖子都显示）
          Container(height: 1, color: Colors.black26),
          Row(
            children: [
              // 编辑按钮
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _removeMenuOverlay();
                    _showEditPostDialog();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '编辑',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 分隔线
              Container(width: 1, height: 20, color: Colors.black26),
              // 删除按钮
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _removeMenuOverlay();
                    _showDeleteConfirmDialog();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '删除',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示编辑帖子对话框
  void _showEditPostDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: widget.post.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '编辑朋友圈',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: '编辑文案内容...',
            hintStyle:
                TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.blue[300]! : Colors.blue,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newContent = controller.text.trim();
              context
                  .read<MomentsProvider>()
                  .updatePostContent(widget.post.id, newContent);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '删除朋友圈',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          '确定要删除这条朋友圈吗？删除后无法恢复。',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<MomentsProvider>().deletePost(widget.post.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 构建互动区域（点赞和评论）
  Widget _buildInteractionArea(bool isDark) {
    final bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F7F7);
    final dividerColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 点赞列表
          if (widget.post.likes.isNotEmpty) _buildLikesList(isDark),
          // 分隔线
          if (widget.post.likes.isNotEmpty && widget.post.comments.isNotEmpty)
            Container(
              height: 1,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: dividerColor,
            ),
          // 评论列表
          if (widget.post.comments.isNotEmpty) _buildCommentsList(isDark),
        ],
      ),
    );
  }

  /// 构建点赞列表
  Widget _buildLikesList(bool isDark) {
    final linkColor =
        isDark ? const Color(0xFF7AA3E5) : const Color(0xFF576B95);
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            Icons.favorite_border,
            size: 14,
            color: linkColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: widget.post.likes.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                return TextSpan(
                  children: [
                    if (index > 0)
                      TextSpan(
                        text: ', ',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    TextSpan(
                      text: user.name,
                      style: TextStyle(
                        color: linkColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建评论列表
  Widget _buildCommentsList(bool isDark) {
    final linkColor =
        isDark ? const Color(0xFF7AA3E5) : const Color(0xFF576B95);
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.post.comments.map((comment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GestureDetector(
            onTap: () {
              // 回复评论
              setState(() {
                _replyToUser = comment.user;
              });
              _showCommentInput();
            },
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: comment.user.name,
                    style: TextStyle(
                      color: linkColor,
                      fontSize: 14,
                    ),
                  ),
                  if (comment.replyTo != null) ...[
                    TextSpan(
                      text: ' 回复 ',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    TextSpan(
                      text: comment.replyTo!.name,
                      style: TextStyle(
                        color: linkColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  TextSpan(
                    text: ': ${comment.content}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 显示评论输入框
  void _showCommentInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF3A3A3C) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: sheetBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyToUser != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '回复 ${_replyToUser!.name}',
                            style: TextStyle(
                              fontSize: 14,
                              color: hintColor,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyToUser = null;
                              });
                            },
                            child:
                                Icon(Icons.close, size: 18, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          autofocus: true,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: '发表评论...',
                            hintStyle: TextStyle(color: hintColor),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.blue[300]! : Colors.blue,
                              ),
                            ),
                            fillColor: inputBgColor,
                            filled: true,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final content = _commentController.text.trim();
                          if (content.isNotEmpty) {
                            context.read<MomentsProvider>().addComment(
                                  widget.post.id,
                                  content,
                                  replyTo: _replyToUser,
                                );
                            _commentController.clear();
                            setState(() {
                              _replyToUser = null;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('发送'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建图片（支持本地和网络图片）
  Widget _buildImage(String url, BoxFit fit) {
    // 判断是本地文件还是网络图片
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 50),
          );
        },
      );
    } else {
      return Image.file(
        File(url),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 50),
          );
        },
      );
    }
  }
}
