class FinanceSettings {
  int monthlyAllowanceDate; // 1-31, tanggal rutin kiriman orang tua / transfer bulanan
  String currencySymbol;

  FinanceSettings({
    this.monthlyAllowanceDate = 25,
    this.currencySymbol = 'Rp',
  });

  Map<String, dynamic> toMap() {
    return {
      'monthlyAllowanceDate': monthlyAllowanceDate,
      'currencySymbol': currencySymbol,
    };
  }

  factory FinanceSettings.fromMap(Map<dynamic, dynamic> map) {
    return FinanceSettings(
      monthlyAllowanceDate: map['monthlyAllowanceDate'] as int? ?? 25,
      currencySymbol: map['currencySymbol'] as String? ?? 'Rp',
    );
  }

  FinanceSettings copyWith({
    int? monthlyAllowanceDate,
    String? currencySymbol,
  }) {
    return FinanceSettings(
      monthlyAllowanceDate: monthlyAllowanceDate ?? this.monthlyAllowanceDate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
