import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/models/wallet_model.dart';
import '../core/theme/app_theme.dart';

/// 余额编辑界面
class EditBalanceScreen extends StatefulWidget {
  const EditBalanceScreen({super.key});

  @override
  State<EditBalanceScreen> createState() => _EditBalanceScreenState();
}

class _EditBalanceScreenState extends State<EditBalanceScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = '请输入金额');
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null) {
      setState(() => _errorText = '请输入有效的数字');
      return;
    }

    if (amount < 0) {
      setState(() => _errorText = '金额不能为负数');
      return;
    }

    if (amount > Wallet.maxBalance) {
      setState(() => _errorText = '金额不能超过1万亿');
      return;
    }

    setState(() => _errorText = null);

    final walletProvider = context.read<WalletProvider>();
    walletProvider.addIncome(
      type: WalletTransactionType.recharge,
      amount: amount,
      description: '钱包充值',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('充值成功')),
    );
    Navigator.pop(context);
  }

  void _setQuickAmount(double amount) {
    _controller.text = amount.toStringAsFixed(2);
    setState(() => _errorText = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        title: Text(
          '充值',
          style: TextStyle(color: context.primaryTextColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _validateAndSave,
            child: const Text(
              '保存',
              style: TextStyle(
                color: AppTheme.wechatGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前余额显示
            Consumer<WalletProvider>(
              builder: (context, provider, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.wechatGreen,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前余额',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.fullBalanceText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 输入框标题
            Text(
              '充值金额 (CNY)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            // 输入框
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: _errorText != null
                    ? Border.all(color: Colors.red, width: 1)
                    : null,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
                decoration: InputDecoration(
                  prefixText: '¥ ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: context.secondaryTextColor.withOpacity(0.5),
                  ),
                ),
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
            ),
            // 错误提示
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // 最大限额提示
            Text(
              '最大限额: ¥1,000,000,000,000.00 (1万亿)',
              style: TextStyle(
                fontSize: 12,
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            // 快捷金额按钮
            Text(
              '快捷设置',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickAmountButton(context, 0, '清空'),
                _buildQuickAmountButton(context, 100, '¥100'),
                _buildQuickAmountButton(context, 1000, '¥1000'),
                _buildQuickAmountButton(context, 10000, '¥1万'),
                _buildQuickAmountButton(context, 100000, '¥10万'),
                _buildQuickAmountButton(context, 1000000, '¥100万'),
                _buildQuickAmountButton(context, 10000000, '¥1000万'),
                _buildQuickAmountButton(context, 100000000, '¥1亿'),
                _buildQuickAmountButton(context, 1000000000, '¥10亿'),
                _buildQuickAmountButton(context, 10000000000, '¥100亿'),
                _buildQuickAmountButton(context, 100000000000, '¥1000亿'),
                _buildQuickAmountButton(context, 1000000000000, '¥1万亿',
                    isMaxAmount: true),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(
    BuildContext context,
    double amount,
    String label, {
    bool isMaxAmount = false,
  }) {
    return GestureDetector(
      onTap: () {
        _setQuickAmount(amount);
        if (isMaxAmount) {
          _showEasterEggDialog(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.primaryTextColor,
          ),
        ),
      ),
    );
  }

  void _showEasterEggDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('🎉 恭喜 🎉'),
          ],
        ),
        content: const Text(
          '富可敌国！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('低调低调'),
          ),
        ],
      ),
    );
  }
}
