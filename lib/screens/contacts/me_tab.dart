import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/moments_provider.dart';
import '../../core/theme/app_theme.dart';
import 'me_list_screen.dart';
import '../wallet_screen.dart';

class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '我',
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户人设入口卡片
            _buildMeCard(context),
            // 钱包卡片入口
            _buildWalletCard(context),
          ],
        ),
      ),
    );
  }

  /// 用户人设入口卡片
  Widget _buildMeCard(BuildContext context) {
    return Consumer2<ContactProvider, MomentsProvider>(
      builder: (context, contactProvider, momentsProvider, _) {
        final meCount = contactProvider.meList.length;
        final momentsAvatar = momentsProvider.currentUser.avatarUrl;

        // 判断头像是本地文件还是网络图片
        final bool isLocalAvatar = momentsAvatar.isNotEmpty &&
            !momentsAvatar.startsWith('http') &&
            File(momentsAvatar).existsSync();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MeListScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 头像 - 同步朋友圈头像
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.isDarkMode
                            ? Colors.grey[700]
                            : const Color(0xFFF0F0F0),
                        image: isLocalAvatar
                            ? DecorationImage(
                                image: FileImage(File(momentsAvatar)),
                                fit: BoxFit.cover,
                              )
                            : momentsAvatar.startsWith('http')
                                ? DecorationImage(
                                    image: NetworkImage(momentsAvatar),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child:
                          (!isLocalAvatar && !momentsAvatar.startsWith('http'))
                              ? Icon(
                                  CupertinoIcons.person_fill,
                                  size: 28,
                                  color: context.secondaryTextColor,
                                )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    // 信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '我的人设',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meCount == 0 ? '点击添加人设' : '已创建 $meCount 个人设',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 箭头
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: context.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 钱包入口卡片
  Widget _buildWalletCard(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.wechatGreen,
                AppTheme.wechatGreen.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.wechatGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 钱包图标
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 余额信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '钱包',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                '¥',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                walletProvider.formattedBalance,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 箭头
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
