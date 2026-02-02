import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/providers/moments_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/utils/storage_utils.dart';
import '../widgets/moments_post_item.dart';
import 'edit_moment_screen.dart';

/// 朋友圈主页
class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: const _MomentsBody(),
    );
  }
}

class _MomentsBody extends StatefulWidget {
  const _MomentsBody();

  @override
  State<_MomentsBody> createState() => _MomentsBodyState();
}

class _MomentsBodyState extends State<_MomentsBody> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  static const double _coverHeight = 300.0; // 封面图高度
  static const double _avatarSize = 70.0;
  static const double _avatarOnCoverHeight = 46.0; // 头像在封面上的高度（约2/3）
  static const double _avatarUnderCoverHeight = 24.0; // 头像在封面下的高度（约1/3）
  static const double _collapsedHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 进入朋友圈时强制刷新一次数据，确保 AI 的静默评论/点赞能立即显示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MomentsProvider>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    // 滚动到底部加载更多
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MomentsProvider>().loadMore();
    }
  }

  /// 显示编辑昵称对话框
  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '修改昵称',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: '请输入昵称',
            hintStyle:
                TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<MomentsProvider>().updateCurrentUserName(name);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑签名对话框
  void _showEditSignatureDialog(
      BuildContext context, String? currentSignature) {
    final controller = TextEditingController(text: currentSignature ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '修改签名',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: '请输入个性签名',
            hintStyle:
                TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final signature = controller.text.trim();
              context
                  .read<MomentsProvider>()
                  .updateCurrentUserSignature(signature);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;
    final containerBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Consumer<MomentsProvider>(
      builder: (context, momentsProvider, child) {
        final currentUser = momentsProvider.currentUser;
        final posts = momentsProvider.posts;

        // 计算透明度
        final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);
        final isCollapsed = opacity > 0.5;

        // 头像初始位置：封面底部减去头像上半部分
        // 封面展开时的总高度 = statusBarHeight + _coverHeight
        // 头像应该在封面底部，且有约2/3在封面上
        final avatarInitialTop =
            statusBarHeight + _coverHeight - _avatarOnCoverHeight;
        // 头像随滚动移动的位置
        final avatarTop = (avatarInitialTop - _scrollOffset).clamp(
          statusBarHeight + _collapsedHeight - 50.0, // 折叠后隐藏
          double.infinity,
        );
        // 头像透明度（滚动到一定程度后隐藏）
        final avatarOpacity =
            (1.0 - (_scrollOffset / (_coverHeight - _collapsedHeight - 50)))
                .clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () {
            // 点击屏幕其他区域时关闭操作菜单
            momentsProvider.setActivePostId(null);
          },
          child: Stack(
            children: [
              // 主滚动区域
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 顶部封面区域
                  SliverAppBar(
                    expandedHeight: _coverHeight,
                    collapsedHeight: _collapsedHeight,
                    toolbarHeight: 44.0,
                    pinned: true,
                    backgroundColor: appBarBgColor.withOpacity(opacity),
                    automaticallyImplyLeading: false,
                    title: isCollapsed
                        ? Text(
                            '朋友圈',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                    centerTitle: true,
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: isCollapsed ? titleColor : Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditMomentScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 封面图片
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                if (context.mounted) {
                                  context
                                      .read<MomentsProvider>()
                                      .updateCurrentUserCover(image.path);
                                }
                              }
                            },
                            child: currentUser.coverImageUrl != null
                                ? (currentUser.coverImageUrl!.startsWith('http')
                                    ? Image.network(
                                        currentUser.coverImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image,
                                              size: 50,
                                            ),
                                          );
                                        },
                                      )
                                    : FutureBuilder<String>(
                                        future: StorageUtils.ensureFileExists(
                                          currentUser.coverImageUrl!,
                                          backupData:
                                              currentUser.coverImageData,
                                        ),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox.shrink();
                                          }
                                          final file = File(snapshot.data!);
                                          if (!file.existsSync()) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 50,
                                              ),
                                            );
                                          }
                                          return Image.file(
                                            file,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 50,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ))
                                : Container(color: Colors.grey[300]),
                          ),
                          // 渐变遮罩
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 签名区域
                  SliverToBoxAdapter(
                    child: Container(
                      color: containerBgColor,
                      padding: EdgeInsets.only(
                        top: _avatarUnderCoverHeight + 16,
                        right: 16,
                        bottom: 12,
                        left: 16,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _showEditSignatureDialog(
                            context,
                            currentUser.signature,
                          ),
                          child: Text(
                            currentUser.signature ?? '点击添加签名',
                            style: TextStyle(
                              fontSize: 13,
                              color: currentUser.signature != null
                                  ? (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600])
                                  : (isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                              fontStyle: currentUser.signature == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 朋友圈动态列表
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < posts.length) {
                        return MomentsPostItem(post: posts[index]);
                      } else if (index == posts.length &&
                          momentsProvider.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                        childCount: posts.length +
                            (momentsProvider.isLoadingMore ? 1 : 0)),
                  ),
                ],
              ),
              // 悬浮头像（在最上层，不会被 SliverAppBar 遮挡）
              if (avatarOpacity > 0)
                Positioned(
                  top: avatarTop,
                  right: 16,
                  child: Opacity(
                    opacity: avatarOpacity,
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          if (context.mounted) {
                            context
                                .read<MomentsProvider>()
                                .updateCurrentUserAvatar(image.path);
                          }
                        }
                      },
                      child: Container(
                        width: _avatarSize,
                        height: _avatarSize,
                        decoration: BoxDecoration(
                          color: containerBgColor,
                          border: Border.all(
                            color: containerBgColor,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _buildAvatar(currentUser.avatarUrl),
                        ),
                      ),
                    ),
                  ),
                ),
              // 悬浮昵称（跟随头像移动）
              if (avatarOpacity > 0)
                Positioned(
                  top: avatarTop + 10, // 调整垂直位置以对齐头像（数值越小越靠上）
                  right: 16 + _avatarSize + 12,
                  child: Opacity(
                    opacity: avatarOpacity,
                    child: GestureDetector(
                      onTap: () =>
                          _showEditNameDialog(context, currentUser.name),
                      child: Text(
                        currentUser.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建头像
  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person),
          );
        },
      );
    } else {
      final momentsProvider = context.read<MomentsProvider>();
      final contactProvider = context.read<ContactProvider>();
      final currentUser = momentsProvider.currentUser;

      // 尝试获取备份数据
      Uint8List? backupData;
      if (avatarUrl == currentUser.avatarUrl) {
        backupData = currentUser.avatarData;
      } else {
        // 尝试从 ContactProvider 中查找匹配该路径的角色的备份数据
        final role = contactProvider.roles
            .where((r) => r.avatarPath == avatarUrl)
            .firstOrNull;
        backupData = role?.avatarData;
      }

      return FutureBuilder<String>(
        future:
            StorageUtils.ensureFileExists(avatarUrl, backupData: backupData),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final file = File(snapshot.data!);
          if (!file.existsSync()) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person),
            );
          }
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person),
              );
            },
          );
        },
      );
    }
  }
}
