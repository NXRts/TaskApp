class FinanceLoan {
  final String id;
  String friendName;
  double amount;
  String type; // 'lend' (piutang / teman pinjam ke kita), 'borrow' (hutang / kita pinjam)
  String description;
  DateTime date;
  bool isSettled;
  DateTime? settledAt;

  FinanceLoan({
    required this.id,
    required this.friendName,
    required this.amount,
    this.type = 'lend',
    this.description = '',
    required this.date,
    this.isSettled = false,
    this.settledAt,
  });

  bool get isLend => type == 'lend'; // Piutang (uang kita di orang lain)
  bool get isBorrow => type == 'borrow'; // Hutang (kita berhutang ke orang)

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendName': friendName,
      'amount': amount,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'isSettled': isSettled,
      'settledAt': settledAt?.toIso8601String(),
    };
  }

  factory FinanceLoan.fromMap(Map<dynamic, dynamic> map) {
    return FinanceLoan(
      id: map['id'] as String? ?? '',
      friendName: map['friendName'] as String? ?? 'Teman',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'lend',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSettled: map['isSettled'] as bool? ?? false,
      settledAt: map['settledAt'] != null
          ? DateTime.tryParse(map['settledAt'] as String)
          : null,
    );
  }

  FinanceLoan copyWith({
    String? id,
    String? friendName,
    double? amount,
    String? type,
    String? description,
    DateTime? date,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return FinanceLoan(
      id: id ?? this.id,
      friendName: friendName ?? this.friendName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }
}
