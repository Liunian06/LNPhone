import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
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
  static const String _logDirName = 'logs';
  static const String _oldLogFileName = 'app_logs.jsonl';
  static const int _maxLogSizeMB = 10; // 单个日志文件最大大小 10MB
  static const int _defaultKeepDays = 3; // 默认保留3天日志

  // 使用队列实现高并发写入
  static final List<String> _pendingLogs = [];
  static Completer<void>? _writeCompleter;
  static bool _isProcessing = false;

  // 互斥锁，确保写入操作的原子性
  static final _writeLock = _AsyncLock();

  /// 获取日志目录路径
  static Future<Directory> _getLogDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/$_logDirName');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return logDir;
  }

  /// 获取当天的日志文件路径
  /// 增加 Isolate 标识，防止多 Isolate 同时写入同一个文件导致冲突
  static Future<String> _getTodayLogFilePath() async {
    final dir = await _getLogDirectory();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 获取当前 Isolate 名称，用于区分日志文件
    // 主 Isolate 通常没有名字或叫 'main'，后台 Isolate 通常有特定名字
    final isolateName =
        Isolate.current.debugName?.replaceAll(' ', '_') ?? 'unknown';
    final suffix = isolateName.contains('background') ? 'bg' : 'main';

    return '${dir.path}/app_log_${dateStr}_$suffix.jsonl';
  }

  /// 获取旧日志文件路径（用于迁移/删除）
  static Future<String> _getOldLogFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_oldLogFileName';
  }

  /// 记录日志（高并发安全）
  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String category = 'App',
    Map<String, dynamic>? data,
  }) async {
    try {
      // 对数据和消息进行截断处理，防止单条日志过大
      final processedData = _truncateData(data);
      final processedMessage = message.length > 2000
          ? '${message.substring(0, 2000)}... [truncated]'
          : message;

      final entry = AppLogEntry(
        timestamp: DateTime.now(),
        level: level,
        category: category,
        message: processedMessage,
        data: processedData,
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
        // 检查并删除旧日志文件（仅执行一次）
        await _migrateOldLogs();

        final filePath = await _getTodayLogFilePath();
        final file = File(filePath);

        // 追加写入（每行一个 JSON 对象）
        // 使用 encoding: utf8 明确指定编码
        final sink = file.openWrite(mode: FileMode.append, encoding: utf8);
        for (final log in logsToWrite) {
          sink.writeln(log);
        }
        await sink.flush();
        await sink.close();

        // 检查文件大小，必要时进行轮转
        await _checkAndRotate(file);

        // 自动清理过期日志
        await _cleanExpiredLogs();
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
        debugPrint(
            '[AppLogService] 日志文件过大 (${(size / 1024 / 1024).toStringAsFixed(2)}MB)，开始轮转...');

        // 优化：不再一次性读取整个文件，而是读取末尾的一部分
        // 我们保留约 2MB 的最新日志
        const int preserveSize = 2 * 1024 * 1024;
        final raf = await file.open(mode: FileMode.read);
        try {
          await raf.setPosition(size - preserveSize);
          final bytes = await raf.read(preserveSize);
          await raf.close();

          String content = utf8.decode(bytes, allowMalformed: true);
          // 找到第一个换行符，确保我们从完整的一行开始
          final firstNewline = content.indexOf('\n');
          if (firstNewline != -1 && firstNewline < content.length - 1) {
            content = content.substring(firstNewline + 1);
          }

          // 写入新内容（覆盖原文件）
          await file.writeAsString(content, encoding: utf8);
          debugPrint(
              '[AppLogService] 日志轮转完成，新大小: ${(content.length / 1024).toStringAsFixed(2)}KB');
        } catch (e) {
          await raf.close();
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('[AppLogService] 日志轮转失败: $e');
      // 如果轮转彻底失败且文件依然超大，为了防止撑爆磁盘或持续 OOM，采取激进策略：清空文件
      try {
        final size = await file.length();
        if (size > _maxLogSizeMB * 1024 * 1024 * 2) {
          await file.writeAsString('', encoding: utf8);
          debugPrint('[AppLogService] 日志文件极度超限且轮转失败，已强制清空');
        }
      } catch (_) {}
    }
  }

  static bool _hasMigrated = false;

  /// 迁移旧日志（删除旧的 app_logs.jsonl）
  static Future<void> _migrateOldLogs() async {
    if (_hasMigrated) return;
    try {
      final oldPath = await _getOldLogFilePath();
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
        debugPrint('[AppLogService] 已删除旧日志文件: $oldPath');
      }
      _hasMigrated = true;
    } catch (e) {
      debugPrint('[AppLogService] 删除旧日志失败: $e');
    }
  }

  /// 清理过期日志
  /// 移除对 AppDatabase 的依赖，防止初始化死锁
  static Future<void> _cleanExpiredLogs() async {
    try {
      final logDir = await _getLogDirectory();
      // 默认保留 3 天，不再从数据库读取以保证稳定性
      const keepDays = _defaultKeepDays;
      final now = DateTime.now();
      final threshold = now.subtract(Duration(days: keepDays));

      if (!await logDir.exists()) return;

      final List<FileSystemEntity> files = logDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.jsonl')) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          // 匹配 app_log_YYYY-MM-DD_suffix.jsonl
          final match = RegExp(r'app_log_(\d{4}-\d{2}-\d{2})_.*\.jsonl')
              .firstMatch(fileName);
          if (match != null) {
            final dateStr = match.group(1);
            if (dateStr != null) {
              final fileDate = DateTime.tryParse(dateStr);
              if (fileDate != null && fileDate.isBefore(threshold)) {
                // 检查是否是当天的文件，避免误删
                final todayStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                if (dateStr != todayStr) {
                  await file.delete();
                  debugPrint('[AppLogService] 已清理过期日志: $fileName');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AppLogService] 清理过期日志失败: $e');
    }
  }

  /// 递归截断数据中的超长字符串
  static Map<String, dynamic>? _truncateData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final Map<String, dynamic> result = {};
    const int maxStringLength = 2000; // 单个字符串最大长度

    data.forEach((key, value) {
      if (value is String) {
        if (value.length > maxStringLength) {
          result[key] =
              '${value.substring(0, maxStringLength)}... [truncated ${value.length - maxStringLength} chars]';
        } else {
          result[key] = value;
        }
      } else if (value is Map<String, dynamic>) {
        result[key] = _truncateData(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _truncateData(item);
          } else if (item is String && item.length > maxStringLength) {
            return '${item.substring(0, maxStringLength)}... [truncated]';
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });

    return result;
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

  /// 导出所有日志文件（打包为 ZIP）
  static Future<String> exportLogs() async {
    try {
      // 先刷新缓冲区
      await flush();

      final logDir = await _getLogDirectory();
      final List<FileSystemEntity> files = logDir.listSync();
      final logFiles = files
          .where((f) => f is File && f.path.endsWith('.jsonl'))
          .cast<File>()
          .toList();

      if (logFiles.isEmpty) {
        throw Exception('没有可导出的日志文件');
      }

      // 生成导出文件名
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/app_logs_$timestamp.zip';

      // 使用 archive 库打包
      final archive = Archive();
      for (var file in logFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }

      final zipEncoder = ZipEncoder();
      final encodedZip = zipEncoder.encode(archive);
      if (encodedZip == null) throw Exception('ZIP 编码失败');

      final zipFile = File(exportPath);
      await zipFile.writeAsBytes(encodedZip);

      debugPrint('[AppLogService] 日志已打包导出到: $exportPath');
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

      final filePath = await _getTodayLogFilePath();
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

      final filePath = await _getTodayLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        // 优化：流式读取文件统计行数，避免 OOM
        int count = 0;
        await file
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
          if (line.trim().isNotEmpty) count++;
        });
        return count;
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
      final logDir = await _getLogDirectory();
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        await logDir.create();
        debugPrint('[AppLogService] 所有日志已清空');
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
