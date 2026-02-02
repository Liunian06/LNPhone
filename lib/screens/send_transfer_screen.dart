import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/theme/app_theme.dart';

/// 转账界面
class SendTransferScreen extends StatefulWidget {
  final String receiverName;
  final String? receiverAvatar;
  final String chatId;
  final Function(double amount, String message) onSend;

  const SendTransferScreen({
    super.key,
    required this.receiverName,
    this.receiverAvatar,
    required this.chatId,
    required this.onSend,
  });

  @override
  State<SendTransferScreen> createState() => _SendTransferScreenState();
}

class _SendTransferScreenState extends State<SendTransferScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = '转账给你';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _errorMessage = '请输入转账金额';
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = '请输入有效金额';
      });
      return;
    }

    // 移除20万元转账上限限制

    final walletProvider = context.read<WalletProvider>();
    if (amount > walletProvider.balance) {
      setState(() {
        _errorMessage = '余额不足';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      // 从钱包扣款
      await walletProvider.sendTransfer(
        amount: amount,
        receiverName: widget.receiverName,
        sessionId: widget.chatId,
      );

      // 回调发送转账消息
      widget.onSend(amount, _messageController.text.trim());

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '转账失败: $e';
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '转账',
          style: TextStyle(color: context.primaryTextColor, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 收款人信息卡片
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // 收款人头像和名称
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: widget.receiverAvatar != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        File(widget.receiverAvatar!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 30,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '转账给 ${widget.receiverName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 金额输入
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¥',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: context.primaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    minWidth: 100, maxWidth: 250),
                                child: TextField(
                                  controller: _amountController,
                                  focusNode: _amountFocusNode,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryTextColor,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    border: InputBorder.none,
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: context.secondaryTextColor,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    if (_errorMessage != null) {
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // 余额显示
                        Consumer<WalletProvider>(
                          builder: (context, wallet, child) {
                            return Text(
                              '当前余额: ¥${wallet.balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 转账说明
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '转账说明',
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            maxLength: 10,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.primaryTextColor,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              hintText: '填写转账说明',
                              hintStyle:
                                  TextStyle(color: context.secondaryTextColor),
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部转账按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF07C160),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor:
                        const Color(0xFF07C160).withOpacity(0.5),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '转账',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
