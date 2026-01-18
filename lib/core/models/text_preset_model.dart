class TextPreset {
  final String id;
  final String name;
  final String content;
  final int createdAt;
  final int updatedAt;

  TextPreset({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TextPreset.fromJson(Map<String, dynamic> json) {
    return TextPreset(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}
