import 'dart:convert';

class ContactRole {
  final String id;
  final String name;
  final String? avatarPath;
  final String description;

  ContactRole({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'description': description,
    };
  }

  factory ContactRole.fromJson(Map<String, dynamic> json) {
    return ContactRole(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      description: json['description'],
    );
  }
}

class ContactMe {
  final String id;
  final String name;
  final String? avatarPath;
  final String info;

  ContactMe({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.info,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatarPath': avatarPath, 'info': info};
  }

  factory ContactMe.fromJson(Map<String, dynamic> json) {
    return ContactMe(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      info: json['info'],
    );
  }
}
