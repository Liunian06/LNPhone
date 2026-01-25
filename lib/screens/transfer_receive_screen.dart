import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/theme/app_theme.dart';

class TransferReceiveScreen extends StatelessWidget {
  final ChatMessage message;
  final ContactRole role;
  final ContactMe me;
  final void Function(BuildContext context) onAccept;
  final void Function(BuildContext context)? onReject;

  const TransferReceiveScreen({
    super.key,
    required this.message,
    required this.role,
    required this.me,
    required this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final amount = message.content;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final timeStr =
        '${timestamp.year}年${timestamp.month.toString().padLeft(2, '0')}月${timestamp.day.toString().padLeft(2, '0')}日 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    final bgColor = context.chatBackground;
    final textColor = context.primaryTextColor;
    final secondaryColor = context.secondaryTextColor;

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
            // 待收款图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00A0E9), width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.access_time,
                  color: Color(0xFF00A0E9),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '待你收款',
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
            const SizedBox(height: 40),
            // 转账时间
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '转账时间',
                    style: TextStyle(color: secondaryColor, fontSize: 14),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(color: secondaryColor, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 收款按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    onAccept(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF07C160),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '收款',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 退还提示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1天内未确认，将退还给对方。',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
                if (onReject != null)
                  GestureDetector(
                    onTap: () => onReject!(context),
                    child: const Text(
                      ' 立即退还',
                      style: TextStyle(
                        color: Color(0xFF576B95),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
