import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_envelope.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';

class EditEnvelopeDialog extends StatefulWidget {
  final FinanceEnvelope envelope;

  const EditEnvelopeDialog({super.key, required this.envelope});

  @override
  State<EditEnvelopeDialog> createState() => _EditEnvelopeDialogState();
}

class _EditEnvelopeDialogState extends State<EditEnvelopeDialog> {
  late TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(
      text: widget.envelope.monthlyBudget.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _save() {
    final cleaned = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final budget = double.tryParse(cleaned) ?? 0.0;

    if (budget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anggaran tidak boleh negatif'),
          backgroundColor: AppTheme.urgentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<FinanceProvider>().updateEnvelopeBudget(widget.envelope.id, budget);
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
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(widget.envelope.colorValue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mail_outline,
                      size: 20,
                      color: Color(widget.envelope.colorValue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atur Anggaran Amplop',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.envelope.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrim,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'ANGGARAN BULANAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrim,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(widget.envelope.colorValue),
                ),
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
                      backgroundColor: Color(widget.envelope.colorValue),
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
