import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/theme/app_theme.dart';

class RedPacketResultScreen extends StatelessWidget {
  final ChatMessage message;
  final ContactRole role;
  final ContactMe me;

  const RedPacketResultScreen({
    super.key,
    required this.message,
    required this.role,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    final amount = message.content;
    final messageText = message.metadata?['message'] ?? '恭喜发财，大吉大利';
    final senderName = message.isMe ? me.name : role.name;
    final avatarPath = message.isMe ? me.avatarPath : role.avatarPath;

    final isDark = context.isDarkMode;
    final bgColor = isDark ? context.chatBackground : const Color(0xFFF1F1F1);
    final textColor = context.primaryTextColor;
    final secondaryColor = context.secondaryTextColor;
    final cardColor = context.surfaceColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD95940),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFE0B2)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFFFFE0B2)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部红色区域
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 80,
                color: const Color(0xFFD95940),
              ),
              // 弧形装饰
              Positioned(
                bottom: -40,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD95940),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.elliptical(300, 40),
                    ),
                  ),
                ),
              ),
              // 头像
              Positioned(
                bottom: -30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.grey[300],
                  ),
                  child: avatarPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(avatarPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person,
                                  color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // 发送者信息
          Text(
            '$senderName的红包',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            messageText,
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 40),
          // 金额
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD95940),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '元',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 已存入零钱提示
          GestureDetector(
            onTap: () {
              // TODO: 跳转到零钱页面
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '已存入零钱，可直接消费',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD95940),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Color(0xFFD95940),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // 领取记录（居中显示）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: cardColor,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[300],
                  ),
                  child: me.avatarPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(me.avatarPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person,
                                  color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // 格式化时间 HH:mm
                        '${DateTime.fromMillisecondsSinceEpoch(message.timestamp).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(message.timestamp).minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$amount元',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
