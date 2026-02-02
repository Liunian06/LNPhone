import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moments_model.dart';
import '../database/database.dart';
import '../utils/storage_utils.dart';

/// 朋友圈数据提供者
class MomentsProvider extends ChangeNotifier {
  late final AppDatabase _database;

  // 当前用户
  MomentsUser _currentUser = MomentsUser(
    id: 'current_user',
    name: '我',
    avatarUrl: 'https://picsum.photos/200/200?random=1',
    coverImageUrl: 'https://picsum.photos/800/400?random=cover',
  );

  // 朋友圈动态列表
  List<MomentsPost> _posts = [];

  // 当前激活（显示操作菜单）的动态ID
  String? _activePostId;
  bool _isLoadingMore = false;
  int _offset = 0;
  static const int _pageSize = 5;

  // Getters
  MomentsUser get currentUser => _currentUser;
  List<MomentsPost> get posts => _posts;
  String? get activePostId => _activePostId;
  bool get isLoadingMore => _isLoadingMore;

  MomentsProvider() {
    _database = AppDatabase();
    _loadPosts();
    _loadCurrentUser();
  }

  /// 重新从数据库加载数据（用于数据导入后刷新）
  Future<void> reload() async {
    await _loadPosts();
    await _loadCurrentUser();
  }

  /// 从数据库加载动态
  Future<void> _loadPosts() async {
    _offset = 0;
    _posts = await _database.getAllMoments(limit: _pageSize, offset: _offset);
    _offset = _posts.length;
    notifyListeners();
  }

  /// 加载更多动态
  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final morePosts =
          await _database.getAllMoments(limit: _pageSize, offset: _offset);
      if (morePosts.isNotEmpty) {
        _posts.addAll(morePosts);
        _offset += morePosts.length;
      }
    } catch (e) {
      debugPrint('[MomentsProvider] 加载更多朋友圈失败: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 强制刷新数据（供外部调用）
  /// 刷新时会获取最新的动态，并与当前已加载的动态合并，保留加载进度
  Future<void> refresh() async {
    try {
      // 获取最新的第一页数据
      final latestPosts =
          await _database.getAllMoments(limit: _pageSize, offset: 0);

      final Map<String, MomentsPost> merged = {};
      // 先放旧的（保留顺序）
      for (var p in _posts) {
        merged[p.id] = p;
      }
      // 再放新的（覆盖或新增）
      for (var p in latestPosts) {
        merged[p.id] = p;
      }

      _posts = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 更新 offset 确保后续 loadMore 正确
      _offset = _posts.length;
      notifyListeners();
    } catch (e) {
      debugPrint('[MomentsProvider] 刷新朋友圈失败: $e');
      // 如果合并失败，回退到全量加载第一页
      await _loadPosts();
    }
  }

  /// 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      // 无论数据库是否有数据，都尝试从 SharedPreferences 迁移
      // 这样可以确保从任何中间版本升级时都不会丢失数据
      await _migrateFromSharedPreferences();

      // 从数据库加载
      final settings = await _database.getMomentsUserSettings();
      if (settings != null) {
        _currentUser = MomentsUser(
          id: 'current_user',
          name: settings.name,
          avatarUrl:
              settings.avatarUrl ?? 'https://picsum.photos/200/200?random=1',
          avatarData: settings.avatarData,
          coverImageUrl: settings.coverImageUrl,
          coverImageData: settings.coverImageData,
          signature: settings.signature,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载朋友圈用户信息失败: $e');
    }
  }

  /// 从 SharedPreferences 迁移数据到数据库（兼容旧版本）
  /// 使用增量更新策略：只在数据库中没有用户设置时才添加，不覆盖已有数据
  /// [已弃用] 此方法仅用于兼容旧版本数据
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('moments_current_user');
      if (userJson != null) {
        // 只在数据库中没有用户设置时才添加
        final existingSettings = await _database.getMomentsUserSettings();
        if (existingSettings == null) {
          final user = MomentsUser.fromJson(jsonDecode(userJson));

          // 保存到数据库
          await _database.saveMomentsUserSettings(
            name: user.name,
            avatarUrl: user.avatarUrl,
            coverImageUrl: user.coverImageUrl,
            signature: user.signature,
          );
          debugPrint('[MomentsProvider] 已从 SharedPreferences 增量添加朋友圈用户设置');
        }

        // 无论是否添加，都清除旧数据
        await prefs.remove('moments_current_user');
      }
    } catch (e) {
      debugPrint('[MomentsProvider] 增量添加朋友圈用户设置失败: $e');
    }
  }

  /// 保存当前用户信息到数据库
  Future<void> _saveCurrentUser() async {
    try {
      await _database.saveMomentsUserSettings(
        name: _currentUser.name,
        avatarUrl: _currentUser.avatarUrl,
        avatarData: _currentUser.avatarData,
        coverImageUrl: _currentUser.coverImageUrl,
        coverImageData: _currentUser.coverImageData,
        signature: _currentUser.signature,
      );
      debugPrint('[MomentsProvider] 保存朋友圈用户设置成功');
    } catch (e) {
      debugPrint('[MomentsProvider] 保存朋友圈用户设置失败: $e');
    }
  }

  /// 设置当前激活的动态ID
  void setActivePostId(String? id) {
    if (_activePostId != id) {
      _activePostId = id;
      notifyListeners();
    }
  }

  /// 从AI聊天消息创建朋友圈动态
  Future<void> addMomentFromChat(String content, MomentsUser user) async {
    final newPost = MomentsPost(
      id: 'moment_${StorageUtils.getUniqueTimestamp()}',
      user: user,
      content: content,
      mediaItems: [], // AI生成的moment不包含图片
      createdAt: DateTime.now(),
    );

    await _database.insertMoment(newPost);
    await _loadPosts(); // 重新加载以保持同步
  }

  /// 点赞/取消点赞
  Future<void> toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final likes = List<MomentLike>.from(post.likes);

    // 检查当前用户是否已点赞（包括已取消的）
    final likeIndex =
        likes.indexWhere((like) => like.user.id == _currentUser.id);

    if (likeIndex != -1) {
      final existingLike = likes[likeIndex];
      // 切换取消状态
      likes[likeIndex] = MomentLike(
        user: existingLike.user,
        createdAt: DateTime.now(), // 记录动作发生的时间
        isCancelled: !existingLike.isCancelled,
      );
    } else {
      // 未点赞，添加点赞
      likes.insert(
        0,
        MomentLike(
          user: _currentUser,
          createdAt: DateTime.now(),
          isCancelled: false,
        ),
      );
    }

    final updatedPost = post.copyWith(likes: likes);
    await _database.insertMoment(updatedPost); // Update DB
    await _loadPosts();
  }

  /// 添加评论
  Future<String?> addComment(
    String postId,
    String content, {
    MomentsUser? replyTo,
  }) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return null;

    final post = _posts[postIndex];
    final comments = List<MomentsComment>.from(post.comments);

    final commentId = 'c_${StorageUtils.getUniqueTimestamp()}';
    final newComment = MomentsComment(
      id: commentId,
      user: _currentUser,
      content: content,
      createdAt: DateTime.now(),
      replyTo: replyTo,
    );

    comments.add(newComment);

    final updatedPost = post.copyWith(comments: comments);
    await _database.insertMoment(updatedPost); // Update DB
    await _loadPosts();
    return commentId;
  }

  /// 删除评论
  Future<void> deleteComment(String postId, String commentId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final comments = List<MomentsComment>.from(post.comments);

    comments.removeWhere((comment) => comment.id == commentId);

    final updatedPost = post.copyWith(comments: comments);
    await _database.insertMoment(updatedPost); // Update DB
    await _loadPosts();
  }

  /// 发布新动态
  Future<void> publishPost({
    String? content,
    List<MediaItem>? mediaItems,
    String? location,
  }) async {
    final List<MediaItem> savedMediaItems = [];

    if (mediaItems != null) {
      for (int i = 0; i < mediaItems.length; i++) {
        final item = mediaItems[i];
        final result = await _saveImageWithData(item.url, 'moment_media_$i');
        if (result != null) {
          // 存储相对路径
          final relPath = await StorageUtils.toRelativePath(result.path);
          savedMediaItems.add(MediaItem(
            url: relPath,
            type: item.type,
            thumbnailUrl: item.thumbnailUrl,
          ));
        } else {
          savedMediaItems.add(item);
        }
      }
    }

    final newPost = MomentsPost(
      id: 'post_${StorageUtils.getUniqueTimestamp()}',
      user: _currentUser,
      content: content,
      mediaItems: savedMediaItems,
      mediaData: null, // 优化：不再存储 Base64 列表
      createdAt: DateTime.now(),
      location: location,
    );

    await _database.insertMoment(newPost);
    await _loadPosts();
  }

  /// 删除动态
  Future<void> deletePost(String postId) async {
    await _database.deleteMoment(postId);
    await _loadPosts();
  }

  /// 更新动态内容
  Future<void> updatePostContent(String postId, String newContent) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final updatedPost = post.copyWith(content: newContent);
    await _database.insertMoment(updatedPost);
    await _loadPosts();
  }

  /// 更新用户信息
  void updateCurrentUser(MomentsUser user) {
    _currentUser = user;
    _saveCurrentUser();
    notifyListeners();
  }

  /// 更新当前用户封面
  Future<void> updateCurrentUserCover(String coverUrl) async {
    final result = await _saveImageWithData(coverUrl, 'current_user_cover');
    _currentUser = _currentUser.copyWith(
      coverImageUrl: result?.path ?? coverUrl,
      coverImageData: result?.data,
    );
    await _saveCurrentUser();
    notifyListeners();
  }

  /// 更新当前用户头像
  Future<void> updateCurrentUserAvatar(String avatarUrl) async {
    final result = await _saveImageWithData(avatarUrl, 'current_user_avatar');
    _currentUser = _currentUser.copyWith(
      avatarUrl: result?.path ?? avatarUrl,
      avatarData: result?.data,
    );
    await _saveCurrentUser();
    notifyListeners();
  }

  /// 将图片保存到应用文档目录，并返回路径和二进制数据
  Future<({String path, Uint8List data})?> _saveImageWithData(
      String? sourcePath, String id) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    if (sourcePath.startsWith('http')) return null; // 不处理网络图片

    try {
      // 确保文件在持久化目录中
      final persistentPath = await StorageUtils.ensurePersistent(sourcePath, id,
          subDir: 'moments');
      final absPath = await StorageUtils.toAbsolutePath(persistentPath);
      final file = File(absPath);

      if (!await file.exists()) return null;

      // 读取二进制数据用于数据库备份
      final bytes = await file.readAsBytes();

      return (path: persistentPath, data: bytes);
    } catch (e) {
      debugPrint('[MomentsProvider] 处理图片失败: $e');
      return null;
    }
  }

  /// 更新当前用户昵称
  void updateCurrentUserName(String name) {
    _currentUser = _currentUser.copyWith(name: name);
    _saveCurrentUser();
    notifyListeners();
  }

  /// 更新当前用户签名
  void updateCurrentUserSignature(String signature) {
    _currentUser = _currentUser.copyWith(signature: signature);
    _saveCurrentUser();
    notifyListeners();
  }

  /// 检查是否已点赞
  bool isLiked(String postId) {
    final post = _posts.firstWhere(
      (post) => post.id == postId,
      orElse: () => _posts.first,
    );
    return post.likes
        .any((like) => like.user.id == _currentUser.id && !like.isCancelled);
  }
}
