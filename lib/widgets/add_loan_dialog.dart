import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/finance_loan.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';

class AddLoanDialog extends StatefulWidget {
  final FinanceLoan? initialLoan;

  const AddLoanDialog({super.key, this.initialLoan});

  @override
  State<AddLoanDialog> createState() => _AddLoanDialogState();
}

class _AddLoanDialogState extends State<AddLoanDialog> {
  late String _type; // 'lend' (piutang / teman pinjam ke kita), 'borrow' (hutang / kita pinjam)
  late TextEditingController _friendNameController;
  late TextEditingController _amountController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final loan = widget.initialLoan;
    if (loan != null) {
      _type = loan.type;
      _friendNameController = TextEditingController(text: loan.friendName);
      _amountController =
          TextEditingController(text: loan.amount.toInt().toString());
      _descController = TextEditingController(text: loan.description);
    } else {
      _type = 'lend';
      _friendNameController = TextEditingController();
      _amountController = TextEditingController();
      _descController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _friendNameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _friendNameController.text.trim();
    final cleaned = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleaned) ?? 0.0;

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

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal pinjaman/talangan'),
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
        amount: amount,
        type: _type,
        description: _descController.text.trim(),
      );
      provider.addLoan(updated);
    } else {
      final newLoan = FinanceLoan(
        id: const Uuid().v4(),
        friendName: name,
        amount: amount,
        type: _type,
        description: _descController.text.trim(),
        date: DateTime.now(),
      );
      provider.addLoan(newLoan);
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

    final isLend = _type == 'lend';
    final accentCol = isLend ? AppTheme.brandCobalt : AppTheme.warningOchre;

    return Dialog(
      backgroundColor: bgCol,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderCol, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialLoan != null
                      ? 'Edit Catatan Patungan'
                      : 'Catat Patungan & Piutang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrim,
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
            const SizedBox(height: 14),

            // Type Segmented (Piutang vs Hutang)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'lend'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isLend
                              ? AppTheme.brandCobalt
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Saya Talangi Teman (Piutang)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLend
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isLend ? Colors.white : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'borrow'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isLend
                              ? AppTheme.warningOchre
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Saya Pinjam Teman (Hutang)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: !isLend
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: !isLend ? Colors.white : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Nama Teman
            TextField(
              controller: _friendNameController,
              style: TextStyle(fontSize: 13, color: textPrim),
              decoration: InputDecoration(
                labelText: 'Nama Teman',
                labelStyle: TextStyle(fontSize: 12, color: textMuted),
                hintText: 'Misal: Budi Santoso',
                hintStyle: TextStyle(fontSize: 12, color: textMuted),
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightBg,
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

            // Nominal
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
              decoration: InputDecoration(
                labelText: 'Nominal (Rp)',
                labelStyle: TextStyle(fontSize: 12, color: textMuted),
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentCol,
                ),
                hintText: '0',
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightBg,
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

            // Keperluan / Deskripsi
            TextField(
              controller: _descController,
              style: TextStyle(fontSize: 13, color: textPrim),
              decoration: InputDecoration(
                labelText: 'Keperluan / Keterangan',
                labelStyle: TextStyle(fontSize: 12, color: textMuted),
                hintText: 'Misal: Talangan geprek mas kobis / Print makalah',
                hintStyle: TextStyle(fontSize: 12, color: textMuted),
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightBg,
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
            const SizedBox(height: 18),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal', style: TextStyle(color: textMuted)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentCol,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Simpan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
