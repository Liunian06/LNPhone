import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/models/wallet_model.dart';
import '../core/theme/app_theme.dart';
import 'edit_balance_screen.dart';

/// 钱包主界面
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        if (!walletProvider.isLoaded) {
          return Scaffold(
            backgroundColor: context.chatBackground,
            appBar: AppBar(
              backgroundColor: context.appBarBackground,
              title: Text(
                '钱包',
                style: TextStyle(color: context.primaryTextColor),
              ),
              leading: IconButton(
                icon:
                    Icon(Icons.arrow_back_ios, color: context.primaryTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: context.chatBackground,
          body: CustomScrollView(
            slivers: [
              // 自定义 AppBar
              SliverAppBar(
                backgroundColor: AppTheme.wechatGreen,
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.wechatGreen,
                          AppTheme.wechatGreen.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            '钱包余额 (CNY)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¥${walletProvider.balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 功能按钮区
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.add_circle_outline,
                        label: '充值',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditBalanceScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        label: '提现',
                        onTap: () {
                          final hour = DateTime.now().hour;
                          final String message = (hour >= 6 && hour < 22)
                              ? "还没到睡觉时间!"
                              : "早点睡，梦里什么都有";

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: Text(message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.history,
                        label: '账单',
                        onTap: () {
                          // 已经在当前页面显示账单
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // 交易记录标题
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '交易记录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.primaryTextColor,
                        ),
                      ),
                      if (walletProvider.transactions.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _showClearConfirmDialog(context, walletProvider);
                          },
                          child: Text(
                            '清空',
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 交易记录列表
              if (walletProvider.transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: context.secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无交易记录',
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction = walletProvider.transactions[index];
                      return _buildTransactionItem(context, transaction);
                    },
                    childCount: walletProvider.transactions.length,
                  ),
                ),
              // 底部安全区域
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.wechatGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.wechatGreen,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, WalletTransaction transaction) {
    final isIncome = transaction.direction == TransactionDirection.income;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(transaction.timestamp);
    final timeStr = '${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              color: _getTransactionColor(transaction.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeDisplayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description ?? timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 金额
          Text(
            transaction.amountDisplayText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppTheme.wechatGreen : context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.transfer:
        return Icons.swap_horiz;
      case WalletTransactionType.redpacket:
        return Icons.card_giftcard;
      case WalletTransactionType.recharge:
        return Icons.add_circle_outline;
      case WalletTransactionType.withdraw:
        return Icons.account_balance_wallet_outlined;
      case WalletTransactionType.adjustment:
        return Icons.tune;
    }
  }

  Color _getTransactionColor(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.transfer:
        return Colors.blue;
      case WalletTransactionType.redpacket:
        return Colors.red;
      case WalletTransactionType.recharge:
        return AppTheme.wechatGreen;
      case WalletTransactionType.withdraw:
        return Colors.orange;
      case WalletTransactionType.adjustment:
        return Colors.purple;
    }
  }

  void _showClearConfirmDialog(BuildContext context, WalletProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空交易记录'),
        content: const Text('确定要清空所有交易记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.resetWallet();
              Navigator.pop(context);
            },
            child: const Text(
              '清空',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
