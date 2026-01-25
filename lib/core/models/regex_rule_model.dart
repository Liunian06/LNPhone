import 'dart:convert';

enum RegexRuleType {
  regex, // 正则表达式
  replace, // 普通查找替换
}

class RegexRule {
  final String id;
  final String name;
  final String pattern; // 正则表达式或查找内容
  final String replacement; // 替换内容
  final RegexRuleType type;
  final bool isEnabled;
  final int order; // 排序权重，越小越靠前

  const RegexRule({
    required this.id,
    required this.name,
    required this.pattern,
    required this.replacement,
    required this.type,
    this.isEnabled = true,
    this.order = 0,
  });

  RegexRule copyWith({
    String? id,
    String? name,
    String? pattern,
    String? replacement,
    RegexRuleType? type,
    bool? isEnabled,
    int? order,
  }) {
    return RegexRule(
      id: id ?? this.id,
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      replacement: replacement ?? this.replacement,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pattern': pattern,
      'replacement': replacement,
      'type': type.index,
      'isEnabled': isEnabled,
      'order': order,
    };
  }

  factory RegexRule.fromJson(Map<String, dynamic> json) {
    return RegexRule(
      id: json['id'] as String,
      name: json['name'] as String,
      pattern: json['pattern'] as String,
      replacement: json['replacement'] as String,
      type: RegexRuleType.values[json['type'] as int],
      isEnabled: json['isEnabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'RegexRule(id: $id, name: $name, pattern: $pattern, replacement: $replacement, type: $type, isEnabled: $isEnabled, order: $order)';
  }
}
