import 'dart:convert';

class ApiLog {
  final String callTime; // ISO 8601 format
  final String provider; // openai 或 gemini
  final String apiUrl;
  final String modelId;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final double durationSeconds;
  final String? error;

  ApiLog({
    required this.callTime,
    required this.provider,
    required this.apiUrl,
    required this.modelId,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    required this.durationSeconds,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'callTime': callTime,
      'provider': provider,
      'apiUrl': apiUrl,
      'modelId': modelId,
      if (inputTokens != null) 'inputTokens': inputTokens,
      if (outputTokens != null) 'outputTokens': outputTokens,
      if (totalTokens != null) 'totalTokens': totalTokens,
      'durationSeconds': durationSeconds,
      'error': error, // 始终输出error字段，没有错误时为null
    };
  }

  String toJsonLine() {
    return jsonEncode(toJson());
  }

  factory ApiLog.fromJson(Map<String, dynamic> json) {
    return ApiLog(
      callTime: json['callTime'] as String,
      provider: json['provider'] as String,
      apiUrl: json['apiUrl'] as String,
      modelId: json['modelId'] as String,
      inputTokens: json['inputTokens'] as int?,
      outputTokens: json['outputTokens'] as int?,
      totalTokens: json['totalTokens'] as int?,
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      error: json['error'] as String?,
    );
  }
}
