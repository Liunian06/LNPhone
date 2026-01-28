enum TextPresetType { chat, image }

class TextPreset {
  final String id;
  final String name;
  final String content;
  final TextPresetType type;
  final bool isBuiltIn; // 是否为内置预设（不可查看内容）
  final int createdAt;
  final int updatedAt;

  TextPreset({
    required this.id,
    required this.name,
    required this.content,
    this.type = TextPresetType.chat,
    this.isBuiltIn = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'type': type.index,
      'isBuiltIn': isBuiltIn ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TextPreset.fromJson(Map<String, dynamic> json) {
    return TextPreset(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      type: TextPresetType.values[json['type'] ?? 0],
      isBuiltIn: (json['isBuiltIn'] ?? 0) == 1,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  TextPreset copyWith({
    String? id,
    String? name,
    String? content,
    TextPresetType? type,
    bool? isBuiltIn,
    int? createdAt,
    int? updatedAt,
  }) {
    return TextPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      type: type ?? this.type,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
