import 'dart:convert';

enum ApiProvider { openai, gemini, volcengine, openaicompatible }

enum ApiPresetType { chat, image }

class ApiPreset {
  String id;
  String name;
  ApiPresetType type;
  ApiProvider provider;
  String baseUrl;
  String apiKey;
  String model;
  double temperature;
  double topP;
  bool isStream;
  bool enableThinking;

  ApiPreset({
    required this.id,
    required this.name,
    this.type = ApiPresetType.chat,
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.isStream = true,
    this.enableThinking = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'provider': provider.index,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'temperature': temperature,
      'topP': topP,
      'isStream': isStream,
      'enableThinking': enableThinking,
    };
  }

  factory ApiPreset.fromJson(Map<String, dynamic> json) {
    return ApiPreset(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'New Preset',
      type: ApiPresetType.values[json['type'] ?? 0],
      provider: ApiProvider.values[json['provider'] ?? 0],
      baseUrl: json['baseUrl'] ?? '',
      apiKey: json['apiKey'] ?? '',
      model: json['model'] ?? '',
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      topP: (json['topP'] ?? 0.9).toDouble(),
      isStream: json['isStream'] ?? true,
      enableThinking: json['enableThinking'] ?? true,
    );
  }

  ApiPreset copyWith({
    String? id,
    String? name,
    ApiPresetType? type,
    ApiProvider? provider,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    double? topP,
    bool? isStream,
    bool? enableThinking,
  }) {
    return ApiPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      isStream: isStream ?? this.isStream,
      enableThinking: enableThinking ?? this.enableThinking,
    );
  }
}
