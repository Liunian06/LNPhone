import 'dart:convert';
import 'dart:typed_data';

/// 朋友圈用户模型
class MomentsUser {
  final String id;
  final String name;
  final String avatarUrl;
  final Uint8List? avatarData; // 头像二进制数据
  final String? coverImageUrl; // 个人封面图
  final Uint8List? coverImageData; // 封面图二进制数据
  final String? signature; // 个人签名

  MomentsUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.avatarData,
    this.coverImageUrl,
    this.coverImageData,
    this.signature,
  });

  factory MomentsUser.fromJson(Map<String, dynamic> json) {
    return MomentsUser(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      avatarData:
          json['avatarData'] != null ? base64Decode(json['avatarData']) : null,
      coverImageUrl: json['coverImageUrl'],
      coverImageData: json['coverImageData'] != null
          ? base64Decode(json['coverImageData'])
          : null,
      signature: json['signature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'avatarData': avatarData != null ? base64Encode(avatarData!) : null,
      'coverImageUrl': coverImageUrl,
      'coverImageData':
          coverImageData != null ? base64Encode(coverImageData!) : null,
      'signature': signature,
    };
  }

  /// 复制并更新
  MomentsUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    Uint8List? avatarData,
    String? coverImageUrl,
    Uint8List? coverImageData,
    String? signature,
  }) {
    return MomentsUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarData: avatarData ?? this.avatarData,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageData: coverImageData ?? this.coverImageData,
      signature: signature ?? this.signature,
    );
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

/// 朋友圈点赞模型
class MomentLike {
  final MomentsUser user;
  final DateTime createdAt;
  final bool isCancelled; // 是否已取消点赞

  MomentLike({
    required this.user,
    required this.createdAt,
    this.isCancelled = false,
  });

  factory MomentLike.fromJson(Map<String, dynamic> json) {
    return MomentLike(
      user: MomentsUser.fromJson(json['user']),
      createdAt: DateTime.parse(json['createdAt']),
      isCancelled: json['isCancelled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isCancelled': isCancelled,
    };
  }
}

/// 朋友圈动态模型
class MomentsPost {
  final String id;
  final MomentsUser user;
  final String? content; // 文字内容
  final List<MediaItem> mediaItems; // 图片/视频
  final List<String>? mediaData; // 媒体文件二进制数据 (Base64 列表)
  final DateTime createdAt;
  final List<MomentLike> likes; // 点赞列表
  final List<MomentsComment> comments; // 评论列表
  final String? location; // 位置信息

  MomentsPost({
    required this.id,
    required this.user,
    this.content,
    this.mediaItems = const [],
    this.mediaData,
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
      mediaItems: (json['mediaItems'] as List?)
              ?.map((item) => MediaItem.fromJson(item))
              .toList() ??
          [],
      mediaData:
          (json['mediaData'] as List?)?.map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      likes: (json['likes'] as List?)?.map((l) {
            // 兼容旧数据：如果旧数据是 MomentsUser，则转换为 MomentLike
            if (l is Map<String, dynamic> && !l.containsKey('createdAt')) {
              return MomentLike(
                user: MomentsUser.fromJson(l),
                createdAt: DateTime.parse(json['createdAt']), // 默认使用动态发布时间
              );
            }
            return MomentLike.fromJson(l);
          }).toList() ??
          [],
      comments: (json['comments'] as List?)
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
      'mediaData': mediaData,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes.map((l) => l.toJson()).toList(),
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
    List<String>? mediaData,
    DateTime? createdAt,
    List<MomentLike>? likes,
    List<MomentsComment>? comments,
    String? location,
  }) {
    return MomentsPost(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      mediaItems: mediaItems ?? this.mediaItems,
      mediaData: mediaData ?? this.mediaData,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      location: location ?? this.location,
    );
  }
}
