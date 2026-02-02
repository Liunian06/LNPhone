import 'dart:convert';
import 'dart:typed_data';

class ContactRole {
  final String id;
  final String name;
  final String? avatarPath;
  final Uint8List? avatarData;
  final String description;
  final String? appearance;
  final List<String> referenceImages;
  final List<String>? referenceImagesData; // 参考图二进制数据 (Base64 列表)
  final List<String> subscribedGroupIds;
  final List<String> subscribedEmojiIds;

  ContactRole({
    required this.id,
    required this.name,
    this.avatarPath,
    this.avatarData,
    required this.description,
    this.appearance,
    this.referenceImages = const [],
    this.referenceImagesData,
    this.subscribedGroupIds = const [],
    this.subscribedEmojiIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'avatarData': avatarData != null ? base64Encode(avatarData!) : null,
      'description': description,
      'appearance': appearance,
      'referenceImages': referenceImages,
      'referenceImagesData': referenceImagesData,
      'subscribedGroupIds': subscribedGroupIds,
      'subscribedEmojiIds': subscribedEmojiIds,
    };
  }

  factory ContactRole.fromJson(Map<String, dynamic> json) {
    return ContactRole(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      avatarData:
          json['avatarData'] != null ? base64Decode(json['avatarData']) : null,
      description: json['description'],
      appearance: json['appearance'],
      referenceImages: (json['referenceImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      referenceImagesData: (json['referenceImagesData'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
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
  final Uint8List? avatarData;
  final String info;
  final String? appearance;
  final List<String> referenceImages;
  final List<String>? referenceImagesData; // 参考图二进制数据 (Base64 列表)

  ContactMe({
    required this.id,
    required this.name,
    this.avatarPath,
    this.avatarData,
    required this.info,
    this.appearance,
    this.referenceImages = const [],
    this.referenceImagesData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'avatarData': avatarData != null ? base64Encode(avatarData!) : null,
      'info': info,
      'appearance': appearance,
      'referenceImages': referenceImages,
      'referenceImagesData': referenceImagesData,
    };
  }

  factory ContactMe.fromJson(Map<String, dynamic> json) {
    return ContactMe(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      avatarData:
          json['avatarData'] != null ? base64Decode(json['avatarData']) : null,
      info: json['info'],
      appearance: json['appearance'],
      referenceImages: (json['referenceImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      referenceImagesData: (json['referenceImagesData'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
