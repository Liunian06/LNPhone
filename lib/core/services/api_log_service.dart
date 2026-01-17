import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/api_log.dart';

class ApiLogService {
  static const String _logFileName = 'api_logs.jsonl';

  /// 获取日志文件路径
  static Future<String> _getLogFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }

  /// 记录API调用日志
  static Future<void> logApiCall(ApiLog log) async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      // 追加写入JSONL格式（每行一个JSON对象）
      await file.writeAsString(
        '${log.toJsonLine()}\n',
        mode: FileMode.append,
      );

      print('[ApiLog] 日志已记录: ${log.callTime}');
    } catch (e) {
      print('[ApiLog] ❌ 记录日志失败: $e');
    }
  }

  /// 导出API日志到指定路径
  static Future<String> exportLogs() async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('日志文件不存在');
      }

      // 生成导出文件名（包含时间戳）
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/api_logs_export_$timestamp.jsonl';

      // 复制文件
      await file.copy(exportPath);

      print('[ApiLog] 日志已导出到: $exportPath');
      return exportPath;
    } catch (e) {
      print('[ApiLog] ❌ 导出日志失败: $e');
      rethrow;
    }
  }

  /// 清空日志
  static Future<void> clearLogs() async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('[ApiLog] 日志已清空');
      }
    } catch (e) {
      print('[ApiLog] ❌ 清空日志失败: $e');
    }
  }

  /// 获取日志文件大小
  static Future<int> getLogFileSize() async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('[ApiLog] ❌ 获取日志大小失败: $e');
      return 0;
    }
  }

  /// 获取日志行数
  static Future<int> getLogCount() async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final lines = await file.readAsLines();
        return lines.where((line) => line.trim().isNotEmpty).length;
      }
      return 0;
    } catch (e) {
      print('[ApiLog] ❌ 获取日志行数失败: $e');
      return 0;
    }
  }

  /// 格式化当前时间为日志时间格式
  static String formatLogTime(DateTime time) {
    return DateFormat('yyyy-MM-dd-HH-mm-ss').format(time);
  }
}
