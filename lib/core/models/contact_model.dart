import 'dart:convert';

class ContactRole {
  final String id;
  final String name;
  final String? avatarPath;
  final String description;
  final String? appearance;
  final List<String> referenceImages;
  final List<String> subscribedGroupIds;
  final List<String> subscribedEmojiIds;

  ContactRole({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.description,
    this.appearance,
    this.referenceImages = const [],
    this.subscribedGroupIds = const [],
    this.subscribedEmojiIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'description': description,
      'appearance': appearance,
      'referenceImages': referenceImages,
      'subscribedGroupIds': subscribedGroupIds,
      'subscribedEmojiIds': subscribedEmojiIds,
    };
  }

  factory ContactRole.fromJson(Map<String, dynamic> json) {
    return ContactRole(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      description: json['description'],
      appearance: json['appearance'],
      referenceImages: (json['referenceImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subscribedGroupIds: (json['subscribedGroupIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subscribedEmojiIds: (json['subscribedEmojiIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class ContactMe {
  final String id;
  final String name;
  final String? avatarPath;
  final String info;
  final String? appearance;
  final List<String> referenceImages;

  ContactMe({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.info,
    this.appearance,
    this.referenceImages = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'info': info,
      'appearance': appearance,
      'referenceImages': referenceImages,
    };
  }

  factory ContactMe.fromJson(Map<String, dynamic> json) {
    return ContactMe(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      info: json['info'],
      appearance: json['appearance'],
      referenceImages: (json['referenceImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
