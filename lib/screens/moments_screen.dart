import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/providers/moments_provider.dart';
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
  static const double _coverHeight = 300.0;
  static const double _collapsedHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Consumer<MomentsProvider>(
      builder: (context, momentsProvider, child) {
        final currentUser = momentsProvider.currentUser;
        final posts = momentsProvider.posts;

        // 计算透明度
        final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);
        final isCollapsed = opacity > 0.5;

        return GestureDetector(
          onTap: () {
            // 点击屏幕其他区域时关闭操作菜单
            momentsProvider.setActivePostId(null);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 顶部封面区域
              SliverAppBar(
                expandedHeight: _coverHeight,
                collapsedHeight: _collapsedHeight,
                toolbarHeight: 44.0, // 显式设置工具栏高度
                pinned: true,
                backgroundColor: appBarBgColor.withOpacity(opacity),
                automaticallyImplyLeading: false, // 移除返回按钮
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
                        child: SizedBox.expand(
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
                                  : Image.file(
                                      File(currentUser.coverImageUrl!),
                                      fit: BoxFit.cover,
                                    ))
                              : Container(color: Colors.grey[300]),
                        ),
                      ),
                      // 渐变遮罩
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
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
                      // 用户信息
                      Positioned(
                        bottom: 20,
                        right: 16,
                        child: Row(
                          children: [
                            Text(
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
                            const SizedBox(width: 12),
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
                                        .updateCurrentUserAvatar(image.path);
                                  }
                                }
                              },
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child:
                                      currentUser.avatarUrl.startsWith('http')
                                          ? Image.network(
                                              currentUser.avatarUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.person,
                                                  ),
                                                );
                                              },
                                            )
                                          : Image.file(
                                              File(currentUser.avatarUrl),
                                              fit: BoxFit.cover,
                                            ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 朋友圈动态列表
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= posts.length) return null;
                  return MomentsPostItem(post: posts[index]);
                }, childCount: posts.length),
              ),
            ],
          ),
        );
      },
    );
  }
}
