class FinanceWallet {
  final String id;
  String name;
  double balance;
  String iconKey;
  int colorValue;

  FinanceWallet({
    required this.id,
    required this.name,
    this.balance = 0.0,
    this.iconKey = 'cash',
    this.colorValue = 0xFF10B981,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'iconKey': iconKey,
      'colorValue': colorValue,
    };
  }

  factory FinanceWallet.fromMap(Map<dynamic, dynamic> map) {
    return FinanceWallet(
      id: map['id'] as String? ?? 'cash',
      name: map['name'] as String? ?? 'Tunai',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      iconKey: map['iconKey'] as String? ?? 'cash',
      colorValue: map['colorValue'] as int? ?? 0xFF10B981,
    );
  }

  FinanceWallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? iconKey,
    int? colorValue,
  }) {
    return FinanceWallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  static List<FinanceWallet> defaultWallets() {
    return [
      FinanceWallet(
        id: 'cash',
        name: 'Tunai di Dompet',
        balance: 0.0,
        iconKey: 'cash',
        colorValue: 0xFF10B981, // Emerald
      ),
      FinanceWallet(
        id: 'bank',
        name: 'Rekening Bank / ATM',
        balance: 0.0,
        iconKey: 'bank',
        colorValue: 0xFF3B82F6, // Cobalt
      ),
      FinanceWallet(
        id: 'ewallet',
        name: 'E-Wallet (GoPay/Dana/OVO)',
        balance: 0.0,
        iconKey: 'ewallet',
        colorValue: 0xFF8B5CF6, // Purple
      ),
    ];
  }
}
