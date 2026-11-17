import 'package:flutter/material.dart';

class FinanceCategory {
  final String key;
  final String name;
  final String shortName;
  final String type; // 'income' or 'expense'
  final IconData icon;
  final int colorValue;
  final String? defaultEnvelopeId;

  const FinanceCategory({
    required this.key,
    required this.name,
    required this.shortName,
    required this.type,
    required this.icon,
    required this.colorValue,
    this.defaultEnvelopeId,
  });

  static const List<FinanceCategory> allCategories = [
    // --- PEMASUKAN MAHASISWA ---
    FinanceCategory(
      key: 'parent_allowance',
      name: 'Kiriman Orang Tua',
      shortName: 'Ortu',
      type: 'income',
      icon: Icons.volunteer_activism_outlined,
      colorValue: 0xFF10B981, // Emerald
    ),
    FinanceCategory(
      key: 'scholarship',
      name: 'Beasiswa Kuliah',
      shortName: 'Beasiswa',
      type: 'income',
      icon: Icons.school_outlined,
      colorValue: 0xFF3B82F6, // Blue
    ),
    FinanceCategory(
      key: 'internship_salary',
      name: 'Gaji Magang / Part-Time',
      shortName: 'Gaji Magang',
      type: 'income',
      icon: Icons.work_outline,
      colorValue: 0xFF8B5CF6, // Purple
    ),
    FinanceCategory(
      key: 'freelance',
      name: 'Joki Tugas / Freelance',
      shortName: 'Freelance',
      type: 'income',
      icon: Icons.laptop_mac_outlined,
      colorValue: 0xFF06B6D4, // Cyan
    ),
    FinanceCategory(
      key: 'award',
      name: 'Hadiah Lomba / Prestasi',
      shortName: 'Lomba',
      type: 'income',
      icon: Icons.emoji_events_outlined,
      colorValue: 0xFFF59E0B, // Amber
    ),
    FinanceCategory(
      key: 'other_income',
      name: 'Pemasukan Lainnya',
      shortName: 'Lainnya',
      type: 'income',
      icon: Icons.add_circle_outline,
      colorValue: 0xFF64748B, // Slate
    ),

    // --- PENGELUARAN POKOK & MAKAN ---
    FinanceCategory(
      key: 'food_daily',
      name: 'Makan & Minum Harian',
      shortName: 'Makan',
      type: 'expense',
      icon: Icons.restaurant,
      colorValue: 0xFFEF4444, // Red
      defaultEnvelopeId: 'env_food',
    ),
    FinanceCategory(
      key: 'kos_rent',
      name: 'Bayar Sewa Kos / Kontrakan',
      shortName: 'Kosan',
      type: 'expense',
      icon: Icons.home_outlined,
      colorValue: 0xFF6366F1, // Indigo
      defaultEnvelopeId: 'env_kos',
    ),
    FinanceCategory(
      key: 'kos_electricity',
      name: 'Token Listrik Kos',
      shortName: 'Listrik',
      type: 'expense',
      icon: Icons.bolt_outlined,
      colorValue: 0xFFF59E0B, // Amber
      defaultEnvelopeId: 'env_kos',
    ),
    FinanceCategory(
      key: 'laundry_water',
      name: 'Galon Air & Laundry',
      shortName: 'Laundry',
      type: 'expense',
      icon: Icons.local_laundry_service_outlined,
      colorValue: 0xFF0EA5E9, // Sky
      defaultEnvelopeId: 'env_kos',
    ),
    FinanceCategory(
      key: 'transport',
      name: 'Bensin & Transportasi',
      shortName: 'Bensin',
      type: 'expense',
      icon: Icons.two_wheeler_outlined,
      colorValue: 0xFF84CC16, // Lime
    ),

    // --- PENGELUARAN KULIAH & TUGAS ---
    FinanceCategory(
      key: 'print_academic',
      name: 'Print, Fotokopi & ATK',
      shortName: 'Print/ATK',
      type: 'expense',
      icon: Icons.print_outlined,
      colorValue: 0xFF3B82F6, // Cobalt
      defaultEnvelopeId: 'env_academic',
    ),
    FinanceCategory(
      key: 'books_academic',
      name: 'Buku & Diktat Materi',
      shortName: 'Buku',
      type: 'expense',
      icon: Icons.menu_book_outlined,
      colorValue: 0xFF0284C7, // Blue-dark
      defaultEnvelopeId: 'env_academic',
    ),
    FinanceCategory(
      key: 'class_dues',
      name: 'Kas Kelas / Himpunan',
      shortName: 'Kas Kelas',
      type: 'expense',
      icon: Icons.groups_outlined,
      colorValue: 0xFF64748B, // Slate
      defaultEnvelopeId: 'env_academic',
    ),
    FinanceCategory(
      key: 'ukt_tuition',
      name: 'Biaya UKT / SPP Kuliah',
      shortName: 'UKT/SPP',
      type: 'expense',
      icon: Icons.account_balance_outlined,
      colorValue: 0xFF4F46E5, // Indigo
    ),

    // --- GAYA HIDUP & SOSIAL ---
    FinanceCategory(
      key: 'coffee_social',
      name: 'Ngopi & Nongkrong Nugas',
      shortName: 'Ngopi',
      type: 'expense',
      icon: Icons.local_cafe_outlined,
      colorValue: 0xFFA855F7, // Purple
      defaultEnvelopeId: 'env_reward',
    ),
    FinanceCategory(
      key: 'entertainment',
      name: 'Hiburan, Bioskop & Game',
      shortName: 'Hiburan',
      type: 'expense',
      icon: Icons.sports_esports_outlined,
      colorValue: 0xFFEC4899, // Pink
      defaultEnvelopeId: 'env_reward',
    ),
    FinanceCategory(
      key: 'online_shopping',
      name: 'Belanja Online & Paket',
      shortName: 'Belanja',
      type: 'expense',
      icon: Icons.shopping_bag_outlined,
      colorValue: 0xFFF97316, // Orange
    ),
    FinanceCategory(
      key: 'other_expense',
      name: 'Pengeluaran Lainnya',
      shortName: 'Lainnya',
      type: 'expense',
      icon: Icons.remove_circle_outline,
      colorValue: 0xFF64748B, // Slate
    ),
  ];

  static FinanceCategory getByKey(String key, {String defaultType = 'expense'}) {
    try {
      return allCategories.firstWhere((c) => c.key == key);
    } catch (_) {
      return FinanceCategory(
        key: key,
        name: key.replaceAll('_', ' ').toUpperCase(),
        shortName: key.replaceAll('_', ' ').toUpperCase(),
        type: defaultType,
        icon: defaultType == 'income'
            ? Icons.add_circle_outline
            : Icons.remove_circle_outline,
        colorValue: 0xFF64748B,
      );
    }
  }

  static List<FinanceCategory> get incomeCategories =>
      allCategories.where((c) => c.type == 'income').toList();

  static List<FinanceCategory> get expenseCategories =>
      allCategories.where((c) => c.type == 'expense').toList();
}

class FinanceTransaction {
  final String id;
  String title;
  double amount;
  String type; // 'income' or 'expense'
  String category;
  String walletId;
  DateTime date;
  String? note;
  String? envelopeId;

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.walletId,
    required this.date,
    this.note,
    this.envelopeId,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  FinanceCategory get categoryMeta =>
      FinanceCategory.getByKey(category, defaultType: type);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'walletId': walletId,
      'date': date.toIso8601String(),
      'note': note,
      'envelopeId': envelopeId,
    };
  }

  factory FinanceTransaction.fromMap(Map<dynamic, dynamic> map) {
    return FinanceTransaction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Transaksi',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'other_expense',
      walletId: map['walletId'] as String? ?? 'cash',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
      envelopeId: map['envelopeId'] as String?,
    );
  }

  FinanceTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    String? walletId,
    DateTime? date,
    String? note,
    String? envelopeId,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
      envelopeId: envelopeId ?? this.envelopeId,
    );
  }
}
