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

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: borderCol, width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 18,
          right: 18,
          top: 12,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Judul & Tombol Tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTransaction != null
                        ? 'Edit Transaksi'
                        : (isExpense
                            ? 'Tambah Pengeluaran'
                            : 'Tambah Pemasukan'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textPrim,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20, color: textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Switcher Pilihan: [ Pengeluaran ] / [ Pemasukan ]
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _onTypeChanged('expense'),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isExpense
                                ? AppTheme.urgentRose
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 14,
                                color: isExpense ? Colors.white : textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pengeluaran',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isExpense
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isExpense ? Colors.white : textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _onTypeChanged('income'),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: !isExpense
                                ? AppTheme.successSage
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 14,
                                color: !isExpense ? Colors.white : textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pemasukan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: !isExpense
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: !isExpense ? Colors.white : textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Nominal Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: themeAccent.withValues(alpha: 0.35),
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
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
                            fontSize: 24,
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
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textPrim,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: textMuted.withValues(alpha: 0.4),
                                fontSize: 24,
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
              const SizedBox(height: 14),

              // Pilihan Dompet (3 Kolom Seimbang Tanpa Terpotong)
              Text(
                'SUMBER DOMPET',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: wallets.take(3).map((w) {
                  final isSelected = _walletId == w.id;
                  IconData icon = Icons.payments_outlined;
                  if (w.iconKey == 'bank') icon = Icons.account_balance_outlined;
                  if (w.iconKey == 'ewallet') icon = Icons.smartphone_outlined;

                  final isLast = w.id == wallets.take(3).last.id;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 8),
                      child: InkWell(
                        onTap: () => setState(() => _walletId = w.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppTheme.darkAccent.withValues(alpha: 0.2)
                                    : AppTheme.brandCobalt.withValues(alpha: 0.1))
                                : (isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBg),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? AppTheme.darkAccent
                                      : AppTheme.brandCobalt)
                                  : borderCol,
                              width: isSelected ? 1.4 : 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 14,
                                color: isSelected
                                    ? (isDark
                                        ? AppTheme.darkAccent
                                        : AppTheme.brandCobalt)
                                    : textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                w.id == 'cash'
                                    ? 'Tunai'
                                    : (w.id == 'bank' ? 'Bank' : 'E-Wallet'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? textPrim : textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Pilihan Kategori: Grid 3 Kolom Rapi (Bukan Deretan Vertikal Raksasa!)
              Text(
                'KATEGORI ${isExpense ? 'PENGELUARAN' : 'PEMASUKAN'}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // Grid Kategori 3 Kolom Kompak
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.3, // Kompak & Proporsional
                ),
                itemBuilder: (context, index) {
                  final c = availableCategories[index];
                  final isSelected = _categoryKey == c.key;
                  final catColor = Color(c.colorValue);

                  return InkWell(
                    onTap: () => setState(() => _categoryKey = c.key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.16)
                            : (isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lightBg),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? catColor
                              : borderCol,
                          width: isSelected ? 1.4 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(c.icon, size: 15, color: catColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              c.shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? textPrim : textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Catatan / Keterangan & Tanggal
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 13, color: textPrim),
                      decoration: InputDecoration(
                        hintText: 'Keterangan (misal: Nasi Padang)',
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
              const SizedBox(height: 16),

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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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
