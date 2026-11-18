import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/finance_loan.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';

class AddLoanDialog extends StatefulWidget {
  final FinanceLoan? initialLoan;

  const AddLoanDialog({super.key, this.initialLoan});

  @override
  State<AddLoanDialog> createState() => _AddLoanDialogState();
}

class _AddLoanDialogState extends State<AddLoanDialog> {
  late String _type; // 'lend' (talangi / piutang), 'borrow' (pinjam / hutang)
  late TextEditingController _friendNameController;
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late DateTime _date;
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    final loan = widget.initialLoan;
    if (loan != null) {
      _type = loan.type;
      _friendNameController = TextEditingController(text: loan.friendName);
      _amount = loan.amount;
      _amountController =
          TextEditingController(text: loan.amount.toInt().toString());
      _descController = TextEditingController(text: loan.description);
      _date = loan.date;
    } else {
      _type = 'lend';
      _friendNameController = TextEditingController();
      _amountController = TextEditingController();
      _descController = TextEditingController();
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _friendNameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(cleaned) ?? 0.0;
    setState(() {
      _amount = parsed;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _save() {
    final name = _friendNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama teman'),
          backgroundColor: AppTheme.urgentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal pinjaman/talangan yang valid'),
          backgroundColor: AppTheme.urgentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<FinanceProvider>();

    if (widget.initialLoan != null) {
      final updated = widget.initialLoan!.copyWith(
        friendName: name,
        amount: _amount,
        type: _type,
        description: _descController.text.trim(),
        date: _date,
      );
      provider.addLoan(updated);
    } else {
      final newLoan = FinanceLoan(
        id: const Uuid().v4(),
        friendName: name,
        amount: _amount,
        type: _type,
        description: _descController.text.trim(),
        date: _date,
      );
      provider.addLoan(newLoan);
    }

    Navigator.pop(context);
  }

  void _delete() {
    if (widget.initialLoan != null) {
      context.read<FinanceProvider>().deleteLoan(widget.initialLoan!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF16181F) : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final isLend = _type == 'lend';
    final accentCol = isLend ? AppTheme.brandCobalt : AppTheme.warningOchre;

    return Dialog(
      backgroundColor: bgCol,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderCol, width: 1),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialLoan != null
                            ? 'Edit Catatan Patungan'
                            : 'Catat Patungan & Piutang',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textPrim,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLend
                            ? 'Catatan dana yang Anda talangi'
                            : 'Catatan pinjaman Anda ke teman',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.initialLoan != null)
                        IconButton(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppTheme.urgentRose),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Hapus Catatan',
                        ),
                      if (widget.initialLoan != null) const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: 20, color: textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Switcher Pilihan Tipe: [ ↗ Saya Talangi ] vs [ ↙ Saya Pinjam ]
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101217)
                      : const Color(0xFFEFF2F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                padding: const EdgeInsets.all(3.5),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _type = 'lend'),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isLend
                                ? AppTheme.brandCobalt
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: isLend
                                ? [
                                    BoxShadow(
                                      color: AppTheme.brandCobalt
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_outward_rounded,
                                size: 14,
                                color: isLend ? Colors.white : textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Saya Talangi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isLend
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isLend ? Colors.white : textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _type = 'borrow'),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isLend
                                ? AppTheme.warningOchre
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !isLend
                                ? [
                                    BoxShadow(
                                      color: AppTheme.warningOchre
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 14,
                                color: !isLend ? Colors.white : textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Saya Pinjam',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: !isLend
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: !isLend ? Colors.white : textMuted,
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
              const SizedBox(height: 8),

              // Helper / Status Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentCol.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentCol.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLend
                          ? Icons.info_outline
                          : Icons.warning_amber_rounded,
                      size: 13,
                      color: accentCol,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isLend
                            ? 'Piutang: Teman berhutang pada Anda (akan ditagih)'
                            : 'Hutang: Anda meminjam uang teman (harus dibayar)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: accentCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Nama Teman Input
              Text(
                'NAMA TEMAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _friendNameController,
                style: TextStyle(fontSize: 13, color: textPrim),
                decoration: InputDecoration(
                  hintText: 'Misal: Budi Santoso / Siti',
                  hintStyle: TextStyle(fontSize: 12, color: textMuted),
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: accentCol,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkSurfaceElevated
                      : AppTheme.lightBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(height: 12),

              // Nominal Card dengan Quick Presets
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceElevated
                      : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentCol.withValues(alpha: 0.35),
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
                          isLend
                              ? 'NOMINAL TALANGAN (PIUTANG)'
                              : 'NOMINAL PINJAMAN (HUTANG)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: accentCol,
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
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Rp ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: accentCol,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            autofocus: false,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrim,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: textMuted.withValues(alpha: 0.4),
                                fontSize: 20,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: _onAmountChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick Preset Chips (+10k, +20k, +50k, +100k)
                    Row(
                      children: [
                        _buildPresetChip(
                            '+10k', 10000, accentCol, isDark, borderCol),
                        const SizedBox(width: 5),
                        _buildPresetChip(
                            '+20k', 20000, accentCol, isDark, borderCol),
                        const SizedBox(width: 5),
                        _buildPresetChip(
                            '+50k', 50000, accentCol, isDark, borderCol),
                        const SizedBox(width: 5),
                        _buildPresetChip(
                            '+100k', 100000, accentCol, isDark, borderCol),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Keperluan & Tanggal Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      style: TextStyle(fontSize: 12.5, color: textPrim),
                      decoration: InputDecoration(
                        hintText: 'Keterangan (misal: Geprek / Print)',
                        hintStyle: TextStyle(fontSize: 11.5, color: textMuted),
                        prefixIcon: Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: textMuted,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkSurfaceElevated
                            : AppTheme.lightBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
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
                              size: 13, color: textMuted),
                          const SizedBox(width: 5),
                          Text(
                            DateFormatter.formatShortDate(_date),
                            style: TextStyle(
                              fontSize: 11.5,
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
              const SizedBox(height: 18),

              // Buttons (Batal & Simpan)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textMuted,
                        side: BorderSide(color: borderCol, width: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentCol,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        widget.initialLoan != null
                            ? 'Simpan Perubahan'
                            : 'Simpan Catatan',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double amount, Color accentCol,
      bool isDark, Color borderCol) {
    return Expanded(
      child: InkWell(
        onTap: () => _addAmount(amount),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderCol, width: 0.8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: accentCol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
