import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../core/theme/app_theme.dart';

class TransferResultScreen extends StatelessWidget {
  final ChatMessage message;

  const TransferResultScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final amount = message.content;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final transferTimeStr =
        '${timestamp.year}年${timestamp.month.toString().padLeft(2, '0')}月${timestamp.day.toString().padLeft(2, '0')}日 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    final status = message.metadata?['status'] ?? 'pending';
    final acceptedTimeMs = message.metadata?['acceptedTime'];

    String? receiveTimeStr;
    if (acceptedTimeMs != null) {
      final receiveTime = DateTime.fromMillisecondsSinceEpoch(acceptedTimeMs);
      receiveTimeStr =
          '${receiveTime.year}年${receiveTime.month.toString().padLeft(2, '0')}月${receiveTime.day.toString().padLeft(2, '0')}日 ${receiveTime.hour.toString().padLeft(2, '0')}:${receiveTime.minute.toString().padLeft(2, '0')}:${receiveTime.second.toString().padLeft(2, '0')}';
    }

    final isMe = message.isMe;
    String statusText = '';
    IconData statusIcon = Icons.check;
    Color statusColor = const Color(0xFF07C160);

    if (status == 'accepted') {
      if (isMe) {
        statusText = '对方已收款';
      } else {
        statusText = '你已收款，资金已存入零钱';
      }
    } else if (status == 'rejected') {
      statusText = '已退还';
      statusIcon = Icons.assignment_return;
      statusColor = Colors.orange;
    } else {
      if (isMe) {
        statusText = '等待对方收款';
        statusIcon = Icons.access_time;
        statusColor = Colors.orange;
      } else {
        // 理论上接收者在 pending 状态下应该在 TransferReceiveScreen，不应该到这里
        statusText = '待收款';
      }
    }

    final bgColor = context.chatBackground;
    final textColor = context.primaryTextColor;
    final secondaryColor = context.secondaryTextColor;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 状态图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              statusText,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // 金额
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '¥',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  amount,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '零钱余额',
              style: TextStyle(
                color: Color(0xFF07C160),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            // 时间信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '转账时间',
                        style: TextStyle(color: secondaryColor, fontSize: 14),
                      ),
                      Text(
                        transferTimeStr,
                        style: TextStyle(color: secondaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                  if (receiveTimeStr != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '收款时间',
                          style: TextStyle(color: secondaryColor, fontSize: 14),
                        ),
                        Text(
                          receiveTimeStr,
                          style: TextStyle(color: secondaryColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
