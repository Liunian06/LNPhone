import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';

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
    final amount = message.content;
    final messageText = message.metadata?['message'] ?? '恭喜发财，大吉大利';

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messageText,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '微信红包',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '¥$amount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
    final messageText = message.metadata?['message'] ?? '转账';

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageText,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '¥$amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图片占位
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const Center(
              child: Icon(Icons.shopping_bag, size: 48, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 地图占位
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const Center(
              child: Icon(Icons.map, size: 48, color: Colors.blue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
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
    final emojiId = message.content;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.5),
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_emotions, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                emojiId,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
