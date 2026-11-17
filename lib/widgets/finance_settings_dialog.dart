import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';

class FinanceSettingsDialog extends StatefulWidget {
  const FinanceSettingsDialog({super.key});

  @override
  State<FinanceSettingsDialog> createState() => _FinanceSettingsDialogState();
}

class _FinanceSettingsDialogState extends State<FinanceSettingsDialog> {
  late int _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        context.read<FinanceProvider>().settings.monthlyAllowanceDate;
  }

  void _save() {
    final provider = context.read<FinanceProvider>();
    final updated = provider.settings.copyWith(
      monthlyAllowanceDate: _selectedDate,
    );
    provider.updateSettings(updated);
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
                    color: AppTheme.brandCobalt.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: AppTheme.brandCobalt,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfigurasi FinTrack',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Tanggal Kiriman Bulanan',
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
            const SizedBox(height: 14),
            Text(
              'Pilih tanggal rutin saat Anda menerima kiriman uang saku dari orang tua, beasiswa, atau gaji magang setiap bulannya. Tanggal ini dipakai untuk menghitung sisa hari dan jatah belanja aman harian (Safe-to-Spend).',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TANGGAL TRANSFER BULANAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Dropdown / selector for day 1-31
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedDate,
                  isExpanded: true,
                  dropdownColor: bgCol,
                  items: List.generate(31, (i) => i + 1).map((day) {
                    return DropdownMenuItem<int>(
                      value: day,
                      child: Text(
                        'Tanggal $day setiap bulan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrim,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDate = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                      backgroundColor: AppTheme.brandCobalt,
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
