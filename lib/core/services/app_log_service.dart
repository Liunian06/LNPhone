import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 软件日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 软件日志条目
class AppLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? data;

  AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.data,
  });

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name.toUpperCase(),
      'category': category,
      'message': message,
      if (data != null) 'data': data,
    };
  }

  /// 转换为 JSONL 行
  String toJsonLine() {
    return jsonEncode(toJson());
  }
}

/// 软件日志服务
/// 用于记录用户操作、后台活动、API调用等信息，便于排查问题
/// 使用 JSONL 格式存储，支持高并发写入
class AppLogService {
  static const String _logFileName = 'app_logs.jsonl';
  static const int _maxLogLines = 10000; // 最多保留10000行日志
  static const int _maxLogSizeMB = 10; // 最大日志文件大小 10MB

  // 使用队列实现高并发写入
  static final List<String> _pendingLogs = [];
  static Completer<void>? _writeCompleter;
  static bool _isProcessing = false;

  // 互斥锁，确保写入操作的原子性
  static final _writeLock = _AsyncLock();

  /// 获取日志文件路径
  static Future<String> _getLogFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }

  /// 记录日志（高并发安全）
  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String category = 'App',
    Map<String, dynamic>? data,
  }) async {
    try {
      final entry = AppLogEntry(
        timestamp: DateTime.now(),
        level: level,
        category: category,
        message: message,
        data: data,
      );

      final logLine = entry.toJsonLine();

      // 同时输出到控制台（仅调试模式）
      if (kDebugMode) {
        debugPrint(
            '[AppLog] ${entry.level.name.toUpperCase()} [$category] $message');
      }

      // 添加到待写入队列
      _pendingLogs.add(logLine);

      // 触发异步写入
      _scheduleWrite();
    } catch (e) {
      debugPrint('[AppLogService] 记录日志失败: $e');
    }
  }

  /// 调度写入操作
  static void _scheduleWrite() {
    if (_isProcessing) return;

    _isProcessing = true;

    // 使用微任务确保不阻塞当前操作
    Future.microtask(() async {
      await _processQueue();
      _isProcessing = false;
    });
  }

  /// 处理待写入队列
  static Future<void> _processQueue() async {
    await _writeLock.synchronized(() async {
      if (_pendingLogs.isEmpty) return;

      // 取出所有待写入的日志
      final logsToWrite = List<String>.from(_pendingLogs);
      _pendingLogs.clear();

      try {
        final filePath = await _getLogFilePath();
        final file = File(filePath);

        // 追加写入（每行一个 JSON 对象）
        final sink = file.openWrite(mode: FileMode.append);
        for (final log in logsToWrite) {
          sink.writeln(log);
        }
        await sink.flush();
        await sink.close();

        // 检查文件大小，必要时进行轮转
        await _checkAndRotate(file);
      } catch (e) {
        debugPrint('[AppLogService] 写入日志失败: $e');
        // 写入失败时，将日志放回队列前端
        _pendingLogs.insertAll(0, logsToWrite);
      }
    });
  }

  /// 检查并轮转日志文件
  static Future<void> _checkAndRotate(File file) async {
    try {
      if (!await file.exists()) return;

      final size = await file.length();
      final maxSize = _maxLogSizeMB * 1024 * 1024;

      if (size > maxSize) {
        // 读取文件内容
        final lines = await file.readAsLines();

        // 只保留后半部分
        if (lines.length > _maxLogLines ~/ 2) {
          final newLines = lines.sublist(lines.length - _maxLogLines ~/ 2);
          await file.writeAsString('${newLines.join('\n')}\n');
          debugPrint('[AppLogService] 日志文件已轮转，保留 ${newLines.length} 行');
        }
      }
    } catch (e) {
      debugPrint('[AppLogService] 日志轮转失败: $e');
    }
  }

  /// 强制刷新缓冲区（应用退出时调用）
  static Future<void> flush() async {
    // 等待当前队列处理完成
    if (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _processQueue();
  }

  /// 快捷方法：记录调试日志
  static Future<void> debug(String message,
      {String category = 'Debug', Map<String, dynamic>? data}) {
    return log(message, level: LogLevel.debug, category: category, data: data);
  }

  /// 快捷方法：记录信息日志
  static Future<void> info(String message,
      {String category = 'Info', Map<String, dynamic>? data}) {
    return log(message, level: LogLevel.info, category: category, data: data);
  }

  /// 快捷方法：记录警告日志
  static Future<void> warning(String message,
      {String category = 'Warning', Map<String, dynamic>? data}) {
    return log(message,
        level: LogLevel.warning, category: category, data: data);
  }

  /// 快捷方法：记录错误日志
  static Future<void> error(String message,
      {String category = 'Error', Map<String, dynamic>? data}) {
    return log(message, level: LogLevel.error, category: category, data: data);
  }

  // ==================== 后台服务相关日志 ====================

  /// 记录后台服务启动
  static Future<void> logBackgroundServiceStart() {
    return log('后台服务已启动', category: 'Background', level: LogLevel.info);
  }

  /// 记录后台检查开始
  static Future<void> logBackgroundCheckStart({bool force = false}) {
    return log(
      '后台检查开始',
      category: 'Background',
      level: LogLevel.info,
      data: {'force': force},
    );
  }

  /// 记录后台检查设置
  static Future<void> logBackgroundCheckSettings({
    required bool enableActiveReply,
    required int intervalMinutes,
    required int lastActiveTime,
    required int currentTime,
  }) {
    final inactiveSeconds = (currentTime - lastActiveTime) ~/ 1000;
    return log(
      '后台检查设置',
      category: 'Background',
      level: LogLevel.info,
      data: {
        'enableActiveReply': enableActiveReply,
        'intervalMinutes': intervalMinutes,
        'inactiveSeconds': inactiveSeconds,
        'lastActiveTime': DateTime.fromMillisecondsSinceEpoch(lastActiveTime)
            .toIso8601String(),
      },
    );
  }

  /// 记录后台会话检查
  static Future<void> logBackgroundSessionCheck({
    required String sessionId,
    required int lastMessageTime,
    required int currentTime,
    required bool willTrigger,
  }) {
    final inactiveSeconds = (currentTime - lastMessageTime) ~/ 1000;
    return log(
      '检查会话',
      category: 'Background',
      level: LogLevel.info,
      data: {
        'sessionId': sessionId,
        'inactiveSeconds': inactiveSeconds,
        'willTrigger': willTrigger,
      },
    );
  }

  /// 记录后台跳过原因
  static Future<void> logBackgroundSkip(String reason) {
    return log('后台检查跳过: $reason', category: 'Background', level: LogLevel.info);
  }

  /// 记录后台检查完成
  static Future<void> logBackgroundCheckEnd() {
    return log('后台检查结束', category: 'Background', level: LogLevel.info);
  }

  /// 记录后台错误
  static Future<void> logBackgroundError(String message, dynamic error,
      [StackTrace? stackTrace]) {
    return log(
      '$message: $error',
      category: 'Background',
      level: LogLevel.error,
      data: stackTrace != null
          ? {'stackTrace': stackTrace.toString().split('\n').take(5).join('\n')}
          : null,
    );
  }

  // ==================== API 调用相关日志 ====================

  /// 记录 API 调用开始
  static Future<void> logApiCallStart({
    required String provider,
    required String model,
    required String endpoint,
    String? sessionId,
    bool isBackground = false,
  }) {
    return log(
      'API 调用开始',
      category: 'API',
      level: LogLevel.info,
      data: {
        'provider': provider,
        'model': model,
        'endpoint': endpoint,
        if (sessionId != null) 'sessionId': sessionId,
        'isBackground': isBackground,
      },
    );
  }

  /// 记录 API 调用成功
  static Future<void> logApiCallSuccess({
    required String provider,
    required String model,
    required double durationSeconds,
    int? inputTokens,
    int? outputTokens,
    int? messageCount,
    bool isBackground = false,
  }) {
    return log(
      'API 调用成功',
      category: 'API',
      level: LogLevel.info,
      data: {
        'provider': provider,
        'model': model,
        'durationSeconds': durationSeconds.toStringAsFixed(2),
        if (inputTokens != null) 'inputTokens': inputTokens,
        if (outputTokens != null) 'outputTokens': outputTokens,
        if (messageCount != null) 'messageCount': messageCount,
        'isBackground': isBackground,
      },
    );
  }

  /// 记录 API 调用失败
  static Future<void> logApiCallError({
    required String provider,
    required String model,
    required String error,
    double? durationSeconds,
    bool isBackground = false,
  }) {
    return log(
      'API 调用失败',
      category: 'API',
      level: LogLevel.error,
      data: {
        'provider': provider,
        'model': model,
        'error': error,
        if (durationSeconds != null)
          'durationSeconds': durationSeconds.toStringAsFixed(2),
        'isBackground': isBackground,
      },
    );
  }

  /// 记录 API 调用超时
  static Future<void> logApiCallTimeout({
    required String provider,
    required String model,
    required int timeoutSeconds,
    bool isBackground = false,
  }) {
    return log(
      'API 调用超时',
      category: 'API',
      level: LogLevel.error,
      data: {
        'provider': provider,
        'model': model,
        'timeoutSeconds': timeoutSeconds,
        'isBackground': isBackground,
      },
    );
  }

  // ==================== 用户操作相关日志 ====================

  /// 记录应用启动
  static Future<void> logAppStart() {
    return log('应用启动', category: 'App', level: LogLevel.info);
  }

  /// 记录应用进入后台
  static Future<void> logAppBackground() {
    return log('应用进入后台', category: 'App', level: LogLevel.info);
  }

  /// 记录应用返回前台
  static Future<void> logAppForeground() {
    return log('应用返回前台', category: 'App', level: LogLevel.info);
  }

  /// 记录用户发送消息
  static Future<void> logUserSendMessage({
    required String sessionId,
    required String messageType,
  }) {
    return log(
      '用户发送消息',
      category: 'Chat',
      level: LogLevel.info,
      data: {
        'sessionId': sessionId,
        'messageType': messageType,
      },
    );
  }

  /// 记录 AI 回复保存
  static Future<void> logAiReplySaved({
    required String sessionId,
    required int messageCount,
    bool isBackground = false,
  }) {
    return log(
      'AI 回复已保存',
      category: 'Chat',
      level: LogLevel.info,
      data: {
        'sessionId': sessionId,
        'messageCount': messageCount,
        'isBackground': isBackground,
      },
    );
  }

  /// 记录通知发送
  static Future<void> logNotificationSent({
    required String title,
    required int notificationId,
    bool success = true,
  }) {
    return log(
      success ? '通知已发送' : '通知发送失败',
      category: 'Notification',
      level: success ? LogLevel.info : LogLevel.error,
      data: {
        'title': title,
        'notificationId': notificationId,
      },
    );
  }

  // ==================== 导出功能 ====================

  /// 导出日志文件
  static Future<String> exportLogs() async {
    try {
      // 先刷新缓冲区
      await flush();

      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('日志文件不存在');
      }

      // 生成导出文件名（使用 JSONL 扩展名）
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/app_logs_export_$timestamp.jsonl';

      // 复制文件
      await file.copy(exportPath);

      debugPrint('[AppLogService] 日志已导出到: $exportPath');
      return exportPath;
    } catch (e) {
      debugPrint('[AppLogService] 导出日志失败: $e');
      rethrow;
    }
  }

  /// 获取日志文件大小
  static Future<int> getLogFileSize() async {
    try {
      // 先刷新缓冲区
      await flush();

      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('[AppLogService] 获取日志大小失败: $e');
      return 0;
    }
  }

  /// 获取日志行数
  static Future<int> getLogCount() async {
    try {
      // 先刷新缓冲区
      await flush();

      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final lines = await file.readAsLines();
        return lines.where((line) => line.trim().isNotEmpty).length;
      }
      return 0;
    } catch (e) {
      debugPrint('[AppLogService] 获取日志行数失败: $e');
      return 0;
    }
  }

  /// 清空日志
  static Future<void> clearLogs() async {
    try {
      _pendingLogs.clear();
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('[AppLogService] 日志已清空');
      }
    } catch (e) {
      debugPrint('[AppLogService] 清空日志失败: $e');
    }
  }
}

/// 异步互斥锁，用于保证高并发写入的原子性
class _AsyncLock {
  Completer<void>? _completer;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    // 等待前一个操作完成
    while (_completer != null) {
      await _completer!.future;
    }

    _completer = Completer<void>();
    try {
      return await action();
    } finally {
      final completer = _completer;
      _completer = null;
      completer?.complete();
    }
  }
}
