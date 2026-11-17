import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/finance_transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';

class AddTransactionModal extends StatefulWidget {
  final FinanceTransaction? initialTransaction;
  final String? defaultType; // 'expense' or 'income'

  const AddTransactionModal({
    super.key,
    this.initialTransaction,
    this.defaultType,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late String _type; // 'expense' or 'income'
  late String _walletId;
  late String _categoryKey;
  late DateTime _date;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    if (tx != null) {
      _type = tx.type;
      _walletId = tx.walletId;
      _categoryKey = tx.category;
      _date = tx.date;
      _amount = tx.amount;
      _titleController = TextEditingController(text: tx.title);
      _amountController =
          TextEditingController(text: tx.amount.toInt().toString());
      _noteController = TextEditingController(text: tx.note ?? '');
    } else {
      _type = widget.defaultType ?? 'expense';
      _walletId = 'cash';
      _categoryKey = _type == 'expense' ? 'food_daily' : 'parent_allowance';
      _date = DateTime.now();
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _categoryKey = _type == 'expense' ? 'food_daily' : 'parent_allowance';
    });
  }

  void _addAmount(double add) {
    setState(() {
      _amount += add;
      _amountController.text = _amount.toInt().toString();
    });
  }

  void _clearAmount() {
    setState(() {
      _amount = 0.0;
      _amountController.clear();
    });
  }

  void _onAmountChanged(String val) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(cleaned) ?? 0.0;
    setState(() {
      _amount = parsed;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  void _save() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal transaksi yang valid'),
          backgroundColor: AppTheme.urgentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cat = FinanceCategory.getByKey(_categoryKey, defaultType: _type);
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : cat.name;

    final financeProvider = context.read<FinanceProvider>();

    if (widget.initialTransaction != null) {
      final updated = widget.initialTransaction!.copyWith(
        title: title,
        amount: _amount,
        type: _type,
        category: _categoryKey,
        walletId: _walletId,
        date: _date,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        envelopeId: cat.defaultEnvelopeId,
      );
      financeProvider.updateTransaction(updated);
    } else {
      final newTx = FinanceTransaction(
        id: const Uuid().v4(),
        title: title,
        amount: _amount,
        type: _type,
        category: _categoryKey,
        walletId: _walletId,
        date: _date,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        envelopeId: cat.defaultEnvelopeId,
      );
      financeProvider.addTransaction(newTx);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final isExpense = _type == 'expense';
    final themeAccent =
        isExpense ? AppTheme.urgentRose : AppTheme.successSage;

    final availableCategories = isExpense
        ? FinanceCategory.expenseCategories
        : FinanceCategory.incomeCategories;

    final wallets = context.watch<FinanceProvider>().wallets;

    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: borderCol, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 14,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header & Type Switcher (Pengeluaran vs Pemasukan)
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initialTransaction != null
                        ? 'Edit Transaksi'
                        : 'Catat Finansial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrim,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderCol, width: 0.8),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _buildTypeToggle(
                        label: 'Pengeluaran',
                        isSelected: isExpense,
                        activeColor: AppTheme.urgentRose,
                        onTap: () => _onTypeChanged('expense'),
                      ),
                      _buildTypeToggle(
                        label: 'Pemasukan',
                        isSelected: !isExpense,
                        activeColor: AppTheme.successSage,
                        onTap: () => _onTypeChanged('income'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Amount Input Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeAccent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isExpense ? 'NOMINAL PENGELUARAN' : 'NOMINAL PEMASUKAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: themeAccent,
                        ),
                      ),
                      if (_amount > 0)
                        InkWell(
                          onTap: _clearAmount,
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: themeAccent,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          autofocus: widget.initialTransaction == null,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: textPrim,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: textMuted.withValues(alpha: 0.5),
                              fontSize: 26,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onAmountChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Preset Chips (+5k, +10k, +20k, +50k, +100k)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('+5k', 5000),
                        const SizedBox(width: 6),
                        _buildPresetChip('+10k', 10000),
                        const SizedBox(width: 6),
                        _buildPresetChip('+20k', 20000),
                        const SizedBox(width: 6),
                        _buildPresetChip('+50k', 50000),
                        const SizedBox(width: 6),
                        _buildPresetChip('+100k', 100000),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pilihan Dompet / Kantong Saldo
            Text(
              'SUMBER KANTONG / DOMPET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: wallets.map((w) {
                  final isSelected = _walletId == w.id;
                  IconData icon = Icons.payments_outlined;
                  if (w.iconKey == 'bank') icon = Icons.account_balance_outlined;
                  if (w.iconKey == 'ewallet') icon = Icons.smartphone_outlined;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _walletId = w.id),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppTheme.darkAccent.withValues(alpha: 0.2)
                                  : AppTheme.lightAccent.withValues(alpha: 0.08))
                              : (isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : AppTheme.lightBg),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? AppTheme.darkAccent
                                    : AppTheme.lightAccent)
                                : borderCol,
                            width: isSelected ? 1.4 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 15,
                              color: isSelected
                                  ? (isDark
                                      ? AppTheme.darkAccent
                                      : AppTheme.lightAccent)
                                  : textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              w.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? textPrim : textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Pilihan Kategori Mahasiswa
            Text(
              'KATEGORI ${isExpense ? 'PENGELUARAN' : 'PEMASUKAN'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableCategories.map((c) {
                final isSelected = _categoryKey == c.key;
                return InkWell(
                  onTap: () => setState(() => _categoryKey = c.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(c.colorValue).withValues(alpha: 0.15)
                          : (isDark
                              ? AppTheme.darkSurfaceElevated
                              : AppTheme.lightBg),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Color(c.colorValue)
                            : borderCol,
                        width: isSelected ? 1.4 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          c.icon,
                          size: 14,
                          color: Color(c.colorValue),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected ? textPrim : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Catatan / Deskripsi Transaksi & Tanggal
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(fontSize: 13, color: textPrim),
                    decoration: InputDecoration(
                      hintText: 'Keterangan (misal: Nasi Padang + Es Teh)',
                      hintStyle: TextStyle(fontSize: 12, color: textMuted),
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkSurfaceElevated
                          : AppTheme.lightBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceElevated
                          : AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderCol, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: textMuted),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatShortDate(_date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textPrim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.initialTransaction != null
                      ? 'Simpan Perubahan'
                      : (isExpense
                          ? 'Simpan Pengeluaran'
                          : 'Simpan Pemasukan'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return InkWell(
      onTap: () => _addAmount(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderCol, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          ),
        ),
      ),
    );
  }
}
