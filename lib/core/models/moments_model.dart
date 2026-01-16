/// 朋友圈用户模型
class MomentsUser {
  final String id;
  final String name;
  final String avatarUrl;
  final String? coverImageUrl; // 个人封面图

  MomentsUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.coverImageUrl,
  });

  factory MomentsUser.fromJson(Map<String, dynamic> json) {
    return MomentsUser(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      coverImageUrl: json['coverImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'coverImageUrl': coverImageUrl,
    };
  }
}

/// 朋友圈媒体类型
enum MediaType { image, video }

/// 朋友圈媒体项
class MediaItem {
  final String url;
  final MediaType type;
  final String? thumbnailUrl; // 视频缩略图

  MediaItem({required this.url, required this.type, this.thumbnailUrl});

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      url: json['url'],
      type: json['type'] == 'video' ? MediaType.video : MediaType.image,
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type == MediaType.video ? 'video' : 'image',
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

/// 朋友圈评论模型
class MomentsComment {
  final String id;
  final MomentsUser user;
  final String content;
  final DateTime createdAt;
  final MomentsUser? replyTo; // 回复给谁

  MomentsComment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    this.replyTo,
  });

  factory MomentsComment.fromJson(Map<String, dynamic> json) {
    return MomentsComment(
      id: json['id'],
      user: MomentsUser.fromJson(json['user']),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      replyTo: json['replyTo'] != null
          ? MomentsUser.fromJson(json['replyTo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'replyTo': replyTo?.toJson(),
    };
  }
}

/// 朋友圈动态模型
class MomentsPost {
  final String id;
  final MomentsUser user;
  final String? content; // 文字内容
  final List<MediaItem> mediaItems; // 图片/视频
  final DateTime createdAt;
  final List<MomentsUser> likes; // 点赞用户列表
  final List<MomentsComment> comments; // 评论列表
  final String? location; // 位置信息

  MomentsPost({
    required this.id,
    required this.user,
    this.content,
    this.mediaItems = const [],
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
    this.location,
  });

  factory MomentsPost.fromJson(Map<String, dynamic> json) {
    return MomentsPost(
      id: json['id'],
      user: MomentsUser.fromJson(json['user']),
      content: json['content'],
      mediaItems:
          (json['mediaItems'] as List?)
              ?.map((item) => MediaItem.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      likes:
          (json['likes'] as List?)
              ?.map((user) => MomentsUser.fromJson(user))
              .toList() ??
          [],
      comments:
          (json['comments'] as List?)
              ?.map((comment) => MomentsComment.fromJson(comment))
              .toList() ??
          [],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'mediaItems': mediaItems.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'likes': likes.map((user) => user.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'location': location,
    };
  }

  /// 复制并更新
  MomentsPost copyWith({
    String? id,
    MomentsUser? user,
    String? content,
    List<MediaItem>? mediaItems,
    DateTime? createdAt,
    List<MomentsUser>? likes,
    List<MomentsComment>? comments,
    String? location,
  }) {
    return MomentsPost(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      mediaItems: mediaItems ?? this.mediaItems,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      location: location ?? this.location,
    );
  }
}
