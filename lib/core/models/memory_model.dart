/// 角色记忆模型
/// 每个角色可以有多条记忆，记忆跨会话持久保存
class RoleMemory {
  final String id;
  final String roleId; // 关联的角色 ID
  final String content; // 记忆内容
  final int createdAt; // 创建时间戳
  final int updatedAt; // 更新时间戳
  final String? sourceSessionId; // 来源会话 ID（可选）
  final MemoryCategory category; // 记忆分类

  RoleMemory({
    required this.id,
    required this.roleId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.sourceSessionId,
    this.category = MemoryCategory.general,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': roleId,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sourceSessionId': sourceSessionId,
      'category': category.index,
    };
  }

  factory RoleMemory.fromJson(Map<String, dynamic> json) {
    return RoleMemory(
      id: json['id'],
      roleId: json['roleId'],
      content: json['content'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      sourceSessionId: json['sourceSessionId'],
      category: MemoryCategory.values[json['category'] ?? 0],
    );
  }

  RoleMemory copyWith({
    String? id,
    String? roleId,
    String? content,
    int? createdAt,
    int? updatedAt,
    String? sourceSessionId,
    MemoryCategory? category,
  }) {
    return RoleMemory(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
      category: category ?? this.category,
    );
  }
}

/// 记忆分类
enum MemoryCategory {
  general, // 一般记忆
  important, // 重要事件
  preference, // 偏好喜好
  relationship, // 人际关系
  promise, // 承诺约定
  secret, // 秘密心事
}

/// 记忆分类扩展
extension MemoryCategoryExtension on MemoryCategory {
  String get displayName {
    switch (this) {
      case MemoryCategory.general:
        return '一般';
      case MemoryCategory.important:
        return '重要事件';
      case MemoryCategory.preference:
        return '偏好喜好';
      case MemoryCategory.relationship:
        return '人际关系';
      case MemoryCategory.promise:
        return '承诺约定';
      case MemoryCategory.secret:
        return '秘密心事';
    }
  }

  String get icon {
    switch (this) {
      case MemoryCategory.general:
        return '📝';
      case MemoryCategory.important:
        return '⭐';
      case MemoryCategory.preference:
        return '💝';
      case MemoryCategory.relationship:
        return '👥';
      case MemoryCategory.promise:
        return '🤝';
      case MemoryCategory.secret:
        return '🔒';
    }
  }
}
