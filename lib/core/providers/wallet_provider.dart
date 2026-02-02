import 'dart:math';
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../models/wallet_model.dart';
import '../utils/storage_utils.dart';

/// 钱包状态管理Provider
class WalletProvider extends ChangeNotifier {
  final AppDatabase _db;

  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  bool _isLoaded = false;
  String? _lastError;

  WalletProvider(this._db) {
    // 延迟加载，避免在构造函数中直接调用异步方法
    Future.microtask(() => _loadWalletData());
  }

  String? get lastError => _lastError;

  // Getters
  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoaded => _isLoaded;

  /// 格式化余额显示
  String get formattedBalance {
    if (_balance >= 1000000000000) {
      // 万亿级别
      final value = _balance / 1000000000000;
      return '${_formatNumber(value)}万亿';
    } else if (_balance >= 100000000) {
      // 亿级别
      final value = _balance / 100000000;
      return '${_formatNumber(value)}亿';
    } else if (_balance >= 10000) {
      // 万级别
      final value = _balance / 10000;
      return '${_formatNumber(value)}万';
    } else {
      return _formatNumber(_balance);
    }
  }

  /// 格式化数字，如果是整数则不显示小数点
  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  /// 完整余额文本
  String get fullBalanceText => '¥${_balance.toStringAsFixed(2)}';

  /// 加载钱包数据
  Future<void> _loadWalletData() async {
    try {
      debugPrint('[WalletProvider] 开始加载钱包数据...');
      _balance = await _db.getWalletBalance();
      debugPrint('[WalletProvider] 余额加载成功: $_balance');

      _transactions = await _db.getAllWalletTransactions();
      debugPrint('[WalletProvider] 交易记录加载成功: ${_transactions.length} 条');

      _isLoaded = true;
      _lastError = null;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[WalletProvider] 加载钱包数据失败: $e');
      debugPrint('[WalletProvider] 堆栈: $stackTrace');
      _lastError = e.toString();
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 刷新钱包数据
  Future<void> refresh() async {
    await _loadWalletData();
  }

  /// 设置余额（手动调整）
  Future<void> setBalance(double newBalance) async {
    final clampedBalance = newBalance.clamp(0.0, Wallet.maxBalance);
    final oldBalance = _balance;

    // 如果余额有变化，创建调整记录
    if (clampedBalance != oldBalance) {
      final difference = clampedBalance - oldBalance;
      final transaction = WalletTransaction(
        id: _generateId(),
        type: WalletTransactionType.adjustment,
        direction: difference > 0
            ? TransactionDirection.income
            : TransactionDirection.expense,
        amount: difference.abs(),
        description: '手动调整余额',
        timestamp: StorageUtils.getUniqueTimestamp(),
      );

      await _db.insertWalletTransaction(transaction);
    }

    await _db.setWalletBalance(clampedBalance);
    _balance = clampedBalance;
    await _loadWalletData(); // 重新加载交易记录
  }

  /// 收入（红包、转账收款）
  Future<void> addIncome({
    required WalletTransactionType type,
    required double amount,
    String? description,
    String? relatedContactName,
    String? relatedSessionId,
    String? relatedMessageId,
  }) async {
    if (amount <= 0) return;

    // 确保数据已加载
    if (!_isLoaded) {
      await _loadWalletData();
    }

    final newBalance = (_balance + amount).clamp(0.0, Wallet.maxBalance);

    final transaction = WalletTransaction(
      id: _generateId(),
      type: type,
      direction: TransactionDirection.income,
      amount: amount,
      description: description,
      relatedContactName: relatedContactName,
      relatedSessionId: relatedSessionId,
      relatedMessageId: relatedMessageId,
      timestamp: StorageUtils.getUniqueTimestamp(),
    );

    await _db.insertWalletTransaction(transaction);
    await _db.setWalletBalance(newBalance);
    _balance = newBalance;
    await _loadWalletData();
  }

  /// 支出（红包、转账付款）
  Future<void> addExpense({
    required WalletTransactionType type,
    required double amount,
    String? description,
    String? relatedContactName,
    String? relatedSessionId,
    String? relatedMessageId,
  }) async {
    if (amount <= 0) return;

    // 确保数据已加载
    if (!_isLoaded) {
      await _loadWalletData();
    }

    // 如果余额不足，仍然允许扣款（模拟场景）
    final newBalance = (_balance - amount).clamp(0.0, Wallet.maxBalance);

    final transaction = WalletTransaction(
      id: _generateId(),
      type: type,
      direction: TransactionDirection.expense,
      amount: amount,
      description: description,
      relatedContactName: relatedContactName,
      relatedSessionId: relatedSessionId,
      relatedMessageId: relatedMessageId,
      timestamp: StorageUtils.getUniqueTimestamp(),
    );

    await _db.insertWalletTransaction(transaction);
    await _db.setWalletBalance(newBalance);
    _balance = newBalance;
    await _loadWalletData();
  }

  /// 处理红包收取
  Future<void> receiveRedPacket({
    required double amount,
    required String senderName,
    String? sessionId,
    String? messageId,
  }) async {
    await addIncome(
      type: WalletTransactionType.redpacket,
      amount: amount,
      description: '来自 $senderName 的红包',
      relatedContactName: senderName,
      relatedSessionId: sessionId,
      relatedMessageId: messageId,
    );
  }

  /// 处理红包发送
  Future<void> sendRedPacket({
    required double amount,
    required String receiverName,
    String? sessionId,
    String? messageId,
  }) async {
    await addExpense(
      type: WalletTransactionType.redpacket,
      amount: amount,
      description: '发给 $receiverName 的红包',
      relatedContactName: receiverName,
      relatedSessionId: sessionId,
      relatedMessageId: messageId,
    );
  }

  /// 处理转账收款
  Future<void> receiveTransfer({
    required double amount,
    required String senderName,
    String? sessionId,
    String? messageId,
  }) async {
    await addIncome(
      type: WalletTransactionType.transfer,
      amount: amount,
      description: '来自 $senderName 的转账',
      relatedContactName: senderName,
      relatedSessionId: sessionId,
      relatedMessageId: messageId,
    );
  }

  /// 处理转账付款
  Future<void> sendTransfer({
    required double amount,
    required String receiverName,
    String? sessionId,
    String? messageId,
  }) async {
    await addExpense(
      type: WalletTransactionType.transfer,
      amount: amount,
      description: '转账给 $receiverName',
      relatedContactName: receiverName,
      relatedSessionId: sessionId,
      relatedMessageId: messageId,
    );
  }

  /// 删除交易记录
  Future<void> deleteTransaction(String id) async {
    await _db.deleteWalletTransaction(id);
    await _loadWalletData();
  }

  /// 清空所有交易记录并重置余额
  Future<void> resetWallet() async {
    await _db.clearAllWalletTransactions();
    await _db.setWalletBalance(0.0);
    _balance = 0.0;
    _transactions = [];
    notifyListeners();
  }

  /// 生成唯一ID
  String _generateId() {
    return StorageUtils.getUniqueTimestamp().toString();
  }
}
