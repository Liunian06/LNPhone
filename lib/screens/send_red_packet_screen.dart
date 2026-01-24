import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/theme/app_theme.dart';

/// 发红包界面
class SendRedPacketScreen extends StatefulWidget {
  final String receiverName;
  final String? receiverAvatar;
  final String chatId;
  final Function(double amount, String message) onSend;

  const SendRedPacketScreen({
    super.key,
    required this.receiverName,
    this.receiverAvatar,
    required this.chatId,
    required this.onSend,
  });

  @override
  State<SendRedPacketScreen> createState() => _SendRedPacketScreenState();
}

class _SendRedPacketScreenState extends State<SendRedPacketScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = '恭喜发财，大吉大利';
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
        _errorMessage = '请输入金额';
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
      await walletProvider.sendRedPacket(
        amount: amount,
        receiverName: widget.receiverName,
        sessionId: widget.chatId,
      );

      // 回调发送红包消息
      widget.onSend(amount, _messageController.text.trim());

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '发送失败: $e';
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE53935),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '发红包',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 收款人信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: widget.receiverAvatar != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(widget.receiverAvatar!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '发给 ${widget.receiverName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 金额输入
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '红包金额',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '¥',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  filled: false,
                                  border: InputBorder.none,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
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
                        const Divider(height: 24),
                        // 祝福语输入
                        TextField(
                          controller: _messageController,
                          maxLength: 20,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            hintText: '填写祝福语',
                            hintStyle: TextStyle(color: Colors.grey),
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 余额显示
                  Consumer<WalletProvider>(
                    builder: (context, wallet, child) {
                      return Center(
                        child: Text(
                          '当前余额: ¥${wallet.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 底部发送按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE53935)),
                          ),
                        )
                      : const Text(
                          '塞钱进红包',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
