import 'package:drift/drift.dart';

/// 表情包类型
enum EmojiType {
  global, // 全局表情
  role, // 角色专属表情
}

/// 表情包模型
class EmojiModel {
  final String id;
  final String meaning; // 含义，用于引导大模型 (simple_content)
  final String? rawContent; // 详细描述，用于区分相似表情 (raw_content)
  final String? groupId; // 分组ID (对于全局表情是自定义分组，对于角色表情通常是角色ID)
  final String localPath; // 本地图片路径
  final EmojiType type;
  final String? roleId; // 如果是角色表情，关联的角色ID
  final int createdAt;

  EmojiModel({
    required this.id,
    required this.meaning,
    this.rawContent,
    this.groupId,
    required this.localPath,
    required this.type,
    this.roleId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meaning': meaning,
      'rawContent': rawContent,
      'groupId': groupId,
      'localPath': localPath,
      'type': type.index,
      'roleId': roleId,
      'createdAt': createdAt,
    };
  }

  factory EmojiModel.fromJson(Map<String, dynamic> json) {
    return EmojiModel(
      id: json['id'],
      meaning: json['meaning'],
      rawContent: json['rawContent'],
      groupId: json['groupId'],
      localPath: json['localPath'],
      type: EmojiType.values[json['type']],
      roleId: json['roleId'],
      createdAt: json['createdAt'],
    );
  }
}
