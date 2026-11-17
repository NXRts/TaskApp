class FinanceEnvelope {
  final String id;
  String name;
  double monthlyBudget;
  String iconKey;
  int colorValue;

  FinanceEnvelope({
    required this.id,
    required this.name,
    required this.monthlyBudget,
    this.iconKey = 'folder',
    this.colorValue = 0xFF3B82F6,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'monthlyBudget': monthlyBudget,
      'iconKey': iconKey,
      'colorValue': colorValue,
    };
  }

  factory FinanceEnvelope.fromMap(Map<dynamic, dynamic> map) {
    return FinanceEnvelope(
      id: map['id'] as String? ?? 'env_custom',
      name: map['name'] as String? ?? 'Amplop',
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      iconKey: map['iconKey'] as String? ?? 'folder',
      colorValue: map['colorValue'] as int? ?? 0xFF3B82F6,
    );
  }

  FinanceEnvelope copyWith({
    String? id,
    String? name,
    double? monthlyBudget,
    String? iconKey,
    int? colorValue,
  }) {
    return FinanceEnvelope(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  static List<FinanceEnvelope> defaultEnvelopes() {
    return [
      FinanceEnvelope(
        id: 'env_kos',
        name: 'Kos & Tagihan Tetap',
        monthlyBudget: 750000.0,
        iconKey: 'home',
        colorValue: 0xFF6366F1, // Indigo
      ),
      FinanceEnvelope(
        id: 'env_food',
        name: 'Makan & Kebutuhan Pokok',
        monthlyBudget: 900000.0,
        iconKey: 'restaurant',
        colorValue: 0xFFEF4444, // Red
      ),
      FinanceEnvelope(
        id: 'env_academic',
        name: 'Print & Kebutuhan Kuliah',
        monthlyBudget: 150000.0,
        iconKey: 'school',
        colorValue: 0xFF3B82F6, // Cobalt
      ),
      FinanceEnvelope(
        id: 'env_reward',
        name: 'Self-Reward & Nongkrong',
        monthlyBudget: 200000.0,
        iconKey: 'local_cafe',
        colorValue: 0xFFA855F7, // Purple
      ),
    ];
  }
}
