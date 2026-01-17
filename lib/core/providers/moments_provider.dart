import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moments_model.dart';
import '../database/database.dart';

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

  // Getters
  MomentsUser get currentUser => _currentUser;
  List<MomentsPost> get posts => _posts;
  String? get activePostId => _activePostId;

  MomentsProvider() {
    _database = AppDatabase();
    _loadPosts();
    _loadCurrentUser();
  }

  /// 从数据库加载动态
  Future<void> _loadPosts() async {
    _posts = await _database.getAllMoments();
    notifyListeners();
  }

  /// 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('moments_current_user');
      if (userJson != null) {
        _currentUser = MomentsUser.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载朋友圈用户信息失败: $e');
    }
  }

  /// 保存当前用户信息
  Future<void> _saveCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'moments_current_user',
        jsonEncode(_currentUser.toJson()),
      );
    } catch (e) {
      debugPrint('保存朋友圈用户信息失败: $e');
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
      id: 'moment_${DateTime.now().millisecondsSinceEpoch}',
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
    final likes = List<MomentsUser>.from(post.likes);

    // 检查当前用户是否已点赞
    final likeIndex = likes.indexWhere((user) => user.id == _currentUser.id);

    if (likeIndex != -1) {
      // 已点赞，取消点赞
      likes.removeAt(likeIndex);
    } else {
      // 未点赞，添加点赞
      likes.insert(0, _currentUser);
    }

    final updatedPost = post.copyWith(likes: likes);
    await _database.insertMoment(updatedPost); // Update DB
    await _loadPosts();
  }

  /// 添加评论
  Future<void> addComment(
    String postId,
    String content, {
    MomentsUser? replyTo,
  }) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final comments = List<MomentsComment>.from(post.comments);

    final newComment = MomentsComment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      user: _currentUser,
      content: content,
      createdAt: DateTime.now(),
      replyTo: replyTo,
    );

    comments.add(newComment);

    final updatedPost = post.copyWith(comments: comments);
    await _database.insertMoment(updatedPost); // Update DB
    await _loadPosts();
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
    final newPost = MomentsPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      user: _currentUser,
      content: content,
      mediaItems: mediaItems ?? [],
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

  /// 更新用户信息
  void updateCurrentUser(MomentsUser user) {
    _currentUser = user;
    _saveCurrentUser();
    notifyListeners();
  }

  /// 更新当前用户封面
  void updateCurrentUserCover(String coverUrl) {
    _currentUser = MomentsUser(
      id: _currentUser.id,
      name: _currentUser.name,
      avatarUrl: _currentUser.avatarUrl,
      coverImageUrl: coverUrl,
    );
    _saveCurrentUser();
    notifyListeners();
  }

  /// 更新当前用户头像
  void updateCurrentUserAvatar(String avatarUrl) {
    _currentUser = MomentsUser(
      id: _currentUser.id,
      name: _currentUser.name,
      avatarUrl: avatarUrl,
      coverImageUrl: _currentUser.coverImageUrl,
    );
    _saveCurrentUser();
    notifyListeners();
  }

  /// 检查是否已点赞
  bool isLiked(String postId) {
    final post = _posts.firstWhere(
      (post) => post.id == postId,
      orElse: () => _posts.first,
    );
    return post.likes.any((user) => user.id == _currentUser.id);
  }
}
