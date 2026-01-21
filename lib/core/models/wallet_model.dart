/// 钱包交易类型
enum WalletTransactionType {
  transfer, // 转账
  redpacket, // 红包
  recharge, // 充值
  withdraw, // 提现
  adjustment, // 手动调整
}

/// 钱包交易方向
enum TransactionDirection {
  income, // 收入
  expense, // 支出
}

/// 钱包交易记录模型
class WalletTransaction {
  final String id;
  final WalletTransactionType type;
  final TransactionDirection direction;
  final double amount; // 金额（始终为正数）
  final String? description; // 交易描述
  final String? relatedContactName; // 相关联系人名称
  final String? relatedSessionId; // 相关会话ID
  final String? relatedMessageId; // 相关消息ID
  final int timestamp;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    this.description,
    this.relatedContactName,
    this.relatedSessionId,
    this.relatedMessageId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'direction': direction.index,
      'amount': amount,
      'description': description,
      'relatedContactName': relatedContactName,
      'relatedSessionId': relatedSessionId,
      'relatedMessageId': relatedMessageId,
      'timestamp': timestamp,
    };
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      type: WalletTransactionType.values[json['type']],
      direction: TransactionDirection.values[json['direction']],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      relatedContactName: json['relatedContactName'],
      relatedSessionId: json['relatedSessionId'],
      relatedMessageId: json['relatedMessageId'],
      timestamp: json['timestamp'],
    );
  }

  /// 获取交易类型显示名称
  String get typeDisplayName {
    switch (type) {
      case WalletTransactionType.transfer:
        return direction == TransactionDirection.income ? '转账-收款' : '转账-付款';
      case WalletTransactionType.redpacket:
        return direction == TransactionDirection.income ? '红包-收取' : '红包-发出';
      case WalletTransactionType.recharge:
        return '充值';
      case WalletTransactionType.withdraw:
        return '提现';
      case WalletTransactionType.adjustment:
        return direction == TransactionDirection.income ? '余额调整(+)' : '余额调整(-)';
    }
  }

  /// 获取金额显示文本（带正负号）
  String get amountDisplayText {
    final sign = direction == TransactionDirection.income ? '+' : '-';
    return '$sign¥${amount.toStringAsFixed(2)}';
  }
}

/// 钱包模型
class Wallet {
  final double balance; // 当前余额
  final List<WalletTransaction> transactions; // 交易记录

  /// 余额最大值：1万亿 CNY
  static const double maxBalance = 1000000000000.0;

  Wallet({
    required this.balance,
    this.transactions = const [],
  });

  /// 格式化余额显示
  String get formattedBalance {
    if (balance >= 100000000) {
      // 亿级别
      return '${(balance / 100000000).toStringAsFixed(2)}亿';
    } else if (balance >= 10000) {
      // 万级别
      return '${(balance / 10000).toStringAsFixed(2)}万';
    } else {
      return balance.toStringAsFixed(2);
    }
  }

  /// 获取完整余额显示（始终显示完整数字）
  String get fullBalanceText {
    return '¥${balance.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] as num).toDouble(),
      transactions: (json['transactions'] as List?)
              ?.map((t) => WalletTransaction.fromJson(t))
              .toList() ??
          [],
    );
  }

  /// 创建默认钱包
  factory Wallet.defaultWallet() {
    return Wallet(balance: 0.0, transactions: []);
  }

  /// 复制并修改
  Wallet copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
  }) {
    return Wallet(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
    );
  }
}
