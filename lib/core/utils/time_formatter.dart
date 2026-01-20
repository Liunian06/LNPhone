/// 时间格式化工具
class TimeFormatter {
  /// 将时间转换为朋友圈格式
  /// 例如: "刚刚"、"5分钟前"、"1小时前"、"昨天"、"2天前"、"1月5日"
  static String formatMomentsTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (time.year == now.year) {
      // 同一年，显示月日
      return '${time.month}月${time.day}日';
    } else {
      // 不同年，显示年月日
      return '${time.year}年${time.month}月${time.day}日';
    }
  }

  /// 将时间戳转换为相对时间格式
  /// 例如: "刚刚"、"5分钟前"、"1小时前"、"昨天"、"2天前"
  static String formatRelative(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return formatMomentsTime(time);
  }

  /// 将时间转换为详细格式
  /// 例如: "2024-01-09 17:30"
  static String formatDetailTime(DateTime time) {
    return '${time.year}-${_padZero(time.month)}-${_padZero(time.day)} '
        '${_padZero(time.hour)}:${_padZero(time.minute)}';
  }

  /// 补零
  static String _padZero(int value) {
    return value.toString().padLeft(2, '0');
  }
}
