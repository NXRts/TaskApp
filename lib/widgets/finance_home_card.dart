import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../screens/finance_screen.dart';

class FinanceHomeCard extends StatelessWidget {
  const FinanceHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final status = finance.safeToSpendStatus;
    Color statusColor;
    String statusLabel;

    if (status == 'neutral') {
      statusColor = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;
      statusLabel = 'Siap';
    } else if (status == 'safe') {
      statusColor = AppTheme.successSage;
      statusLabel = 'Aman';
    } else if (status == 'warning') {
      statusColor = AppTheme.warningOchre;
      statusLabel = 'Waspada';
    } else {
      statusColor = AppTheme.urgentRose;
      statusLabel = 'Overbudget';
    }

    final dailyBudget = finance.safeToSpendToday;
    final remainingToday = finance.remainingToday;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinanceScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Safe-to-Spend Hari Ini',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        currencyFormat.format(dailyBudget),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrim,
                        ),
                      ),
                      Text(
                        ' / hari',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  Sisa: ${currencyFormat.format(remainingToday >= 0 ? remainingToday : 0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: remainingToday >= 0
                              ? statusColor
                              : AppTheme.urgentRose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
