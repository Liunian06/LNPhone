import 'dart:convert';
import 'dart:typed_data';
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
  final Uint8List? emojiData; // [已弃用] 表情包二进制数据，保留用于向后兼容
  final String? backupPath; // [推荐] 表情包备份文件路径（文件备份，效率更高）
  final EmojiType type;
  final String? roleId; // 如果是角色表情，关联的角色ID
  final int createdAt;

  EmojiModel({
    required this.id,
    required this.meaning,
    this.rawContent,
    this.groupId,
    required this.localPath,
    this.emojiData,
    this.backupPath,
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
      'emojiData': emojiData != null ? base64Encode(emojiData!) : null,
      'backupPath': backupPath,
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
      emojiData:
          json['emojiData'] != null ? base64Decode(json['emojiData']) : null,
      backupPath: json['backupPath'],
      type: EmojiType.values[json['type']],
      roleId: json['roleId'],
      createdAt: json['createdAt'],
    );
  }

  EmojiModel copyWith({
    String? id,
    String? meaning,
    String? rawContent,
    String? groupId,
    String? localPath,
    Uint8List? emojiData,
    String? backupPath,
    EmojiType? type,
    String? roleId,
    int? createdAt,
  }) {
    return EmojiModel(
      id: id ?? this.id,
      meaning: meaning ?? this.meaning,
      rawContent: rawContent ?? this.rawContent,
      groupId: groupId ?? this.groupId,
      localPath: localPath ?? this.localPath,
      emojiData: emojiData ?? this.emojiData,
      backupPath: backupPath ?? this.backupPath,
      type: type ?? this.type,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
