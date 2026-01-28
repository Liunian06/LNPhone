import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/chat_model.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/emoji_provider.dart';

/// 红包气泡
class RedpacketBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const RedpacketBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final messageText = message.metadata?['message'] ?? '恭喜发财，大吉大利';
    final status = message.metadata?['status'] ??
        'unclaimed'; // unclaimed, opened, refunded
    final isOpened = status == 'opened';
    final isRefunded = status == 'refunded';
    final isProcessed = isOpened || isRefunded;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.8),
      decoration: BoxDecoration(
        color: isProcessed
            ? const Color(0xFFF7E2B8) // 已处理后的浅色背景
            : const Color(0xFFFA9D3B), // 未领取的橙色背景
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: isProcessed
                        ? Icon(
                            isRefunded
                                ? Icons.undo
                                : Icons.check_circle_outline,
                            color: const Color(0xFFFBD98D),
                            size: 24,
                          )
                        : const Text(
                            '🧧',
                            style: TextStyle(fontSize: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isProcessed)
                        Text(
                          isRefunded ? '已退还' : '已领取',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: const Text(
              '红包',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 转账气泡
class TransferBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const TransferBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final amount = message.content;
    final messageText = message.metadata?['message'] ?? '转账给朋友';
    final status =
        message.metadata?['status'] ?? 'pending'; // pending, accepted, rejected
    final isAccepted = status == 'accepted';
    final isRejected = status == 'rejected';
    final isProcessed = isAccepted || isRejected;

    // 根据状态决定背景色
    Color backgroundColor;
    if (isRejected) {
      backgroundColor = const Color(0xFFCCCCCC); // 拒收后的灰色背景
    } else if (isAccepted) {
      backgroundColor = const Color(0xFFF7E2B8); // 已收款的浅色背景
    } else {
      backgroundColor = const Color(0xFFFA9D3B); // 待收款的橙色背景
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, // 白色圆圈背景
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRejected
                          ? const Color(0xFF999999)
                          : const Color(0xFFFA9D3B),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isRejected
                          ? Icons.close
                          : (isAccepted ? Icons.check : Icons.compare_arrows),
                      color: isRejected
                          ? const Color(0xFF999999)
                          : const Color(0xFFFA9D3B),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¥$amount',
                        style: TextStyle(
                          color: isRejected ? Colors.black54 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isRejected ? '已拒收' : (isAccepted ? '已收款' : messageText),
                        style: TextStyle(
                          color: isRejected ? Colors.black38 : Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isRejected
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: Text(
              '转账',
              style: TextStyle(
                color: isRejected ? Colors.black38 : Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 商品推荐气泡
class ProductBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const ProductBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final name = message.metadata?['name'] ?? '商品';
    final price = message.metadata?['price'] ?? '0';
    final description = message.content;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.7),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图片占位
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Icon(Icons.shopping_bag,
                  size: 48, color: context.secondaryTextColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 13, color: context.secondaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '¥$price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 链接分享气泡
class LinkBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const LinkBubble({super.key, required this.message, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final title = message.metadata?['title'] ?? '链接';
    final url = message.metadata?['url'] ?? '';
    final description = message.content;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(context.isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.link, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.primaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 13, color: context.secondaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.secondaryTextColor.withOpacity(0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 备忘录气泡
class NoteBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const NoteBubble({super.key, required this.message, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final title = message.metadata?['title'] ?? '备忘录';
    final content = message.content;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF3D3520)
            : const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: const Color(0xFFFFD700)
                .withOpacity(context.isDarkMode ? 0.5 : 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            color: Color(0xFFFFAA00),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(
                        fontSize: 14, color: context.secondaryTextColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 位置分享气泡
class LocationBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const LocationBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final location = message.content;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.7),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 仿真地图背景
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                children: [
                  // 地图背景层 - 模拟街道地图
                  CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _MapBackgroundPainter(
                      isDarkMode: context.isDarkMode,
                    ),
                  ),
                  // 定位标记
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标记阴影
                        Container(
                          width: 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // 向上偏移显示标记
                        Transform.translate(
                          offset: const Offset(0, -4),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFE53935),
                            size: 40,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFFE53935), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                        fontSize: 14, color: context.primaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 仿真地图背景绘制器
class _MapBackgroundPainter extends CustomPainter {
  final bool isDarkMode;

  _MapBackgroundPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    // 背景色 - 模拟地图底色
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFE8F4E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 主要道路颜色
    final mainRoadPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFFFFFFF)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // 次要道路颜色
    final secondaryRoadPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF3D4A5C) : const Color(0xFFF5F5F5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // 绘制主要横向道路
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      mainRoadPaint,
    );

    // 绘制主要纵向道路
    final centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      mainRoadPaint,
    );

    // 绘制次要横向道路
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      secondaryRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      secondaryRoadPaint,
    );

    // 绘制次要纵向道路
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      secondaryRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      secondaryRoadPaint,
    );

    // 绘制建筑物块（模拟）
    final buildingPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF374151) : const Color(0xFFD4E6D4);

    // 左上建筑群
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.15,
            size.height * 0.15),
        const Radius.circular(2),
      ),
      buildingPaint,
    );

    // 右上建筑群
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.8, size.height * 0.05, size.width * 0.15,
            size.height * 0.12),
        const Radius.circular(2),
      ),
      buildingPaint,
    );

    // 左下建筑群
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.8, size.width * 0.12,
            size.height * 0.15),
        const Radius.circular(2),
      ),
      buildingPaint,
    );

    // 右下建筑群
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.78, size.height * 0.78, size.width * 0.17,
            size.height * 0.17),
        const Radius.circular(2),
      ),
      buildingPaint,
    );

    // 添加一些小的建筑点缀
    final smallBuildingPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF404B5A) : const Color(0xFFCCDDCC);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.05, size.width * 0.08,
            size.height * 0.08),
        const Radius.circular(1),
      ),
      smallBuildingPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, size.height * 0.82, size.width * 0.1,
            size.height * 0.1),
        const Radius.circular(1),
      ),
      smallBuildingPaint,
    );

    // 绿地/公园区域
    final parkPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF2D4A3E) : const Color(0xFFC8E6C9);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.05, size.width * 0.18,
            size.height * 0.12),
        const Radius.circular(3),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 纪念日卡片气泡
class AnniversaryBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const AnniversaryBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final title = message.metadata?['title'] ?? '纪念日';
    final days = message.metadata?['days'] ?? '0';
    final label = message.metadata?['label'] ?? '还有';
    final date = message.metadata?['date'] ?? '';
    final blessing = message.content;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFC44569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                Text(
                  days,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '天',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                date,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
            if (blessing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  blessing,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 表情包气泡
class EmojiBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const EmojiBubble({super.key, required this.message, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    // 优先从 metadata 获取 emoji_id，如果不存在则尝试从 content 获取
    // content 可能存储的是含义，也可能是 ID
    final emojiId = message.metadata?['emoji_id'] ?? message.content;

    return FutureBuilder(
      future: context.read<EmojiProvider>().getEmojiById(emojiId),
      builder: (context, snapshot) {
        final emoji = snapshot.data;

        if (emoji != null) {
          return Container(
            constraints: BoxConstraints(maxWidth: maxWidth * 0.5),
            padding: const EdgeInsets.all(8),
            child: Image.file(
              File(emoji.localPath),
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          );
        }

        // 加载中或失败
        return const SizedBox.shrink();
      },
    );
  }
}
