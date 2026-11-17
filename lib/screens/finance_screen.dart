import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/finance_transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_loan_dialog.dart';
import '../widgets/edit_envelope_dialog.dart';
import '../widgets/adjust_wallet_dialog.dart';
import '../widgets/finance_settings_dialog.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _activeTab = 0; // 0: Transaksi, 1: Amplop, 2: Piutang, 3: Analisis
  String _txFilter = 'all'; // 'all', 'expense', 'income'

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final finance = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: bgCol,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'FinTrack',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textPrim,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkAccent.withValues(alpha: 0.15)
                                    : AppTheme.brandCobalt.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkAccent.withValues(alpha: 0.4)
                                      : AppTheme.brandCobalt.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'OFFLINE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? AppTheme.darkAccent
                                      : AppTheme.brandCobalt,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Buku Kas & Uang Harian Mahasiswa',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Tombol Konfigurasi Tanggal Kiriman Ortu
                    IconButton(
                      icon: Icon(Icons.tune_outlined,
                          size: 20, color: textMuted),
                      tooltip: 'Atur Tanggal Kiriman Bulanan',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const FinanceSettingsDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Hero Card: Safe-to-Spend Today
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSafeToSpendHero(context, finance, isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Multi-Dompet Strip (3 Kolom Seimbang Rapi)
            SliverToBoxAdapter(
              child: _buildWalletStrip(context, finance, isDark),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Segmented Tab Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabSwitcher(isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Active Tab Content
            if (_activeTab == 0) ...[
              _buildTransactionsTab(context, finance, isDark),
            ] else if (_activeTab == 1) ...[
              _buildEnvelopesTab(context, finance, isDark),
            ] else if (_activeTab == 2) ...[
              _buildLoansTab(context, finance, isDark),
            ] else ...[
              _buildAnalyticsTab(context, finance, isDark),
            ],

            // Ruang aman bawah agar tidak bertabrakan dengan FAB & Navigasi
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // --- HERO CARD: SAFE-TO-SPEND TODAY ---
  Widget _buildSafeToSpendHero(
      BuildContext context, FinanceProvider finance, bool isDark) {
    final status = finance.safeToSpendStatus;
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (status == 'neutral') {
      statusColor = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;
      statusTitle = 'Saldo Belum Diatur';
      statusIcon = Icons.account_balance_wallet_outlined;
    } else if (status == 'safe') {
      statusColor = AppTheme.successSage;
      statusTitle = 'Belanja Harian Aman';
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'warning') {
      statusColor = AppTheme.warningOchre;
      statusTitle = 'Mendekati Batas Harian';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppTheme.urgentRose;
      statusTitle = 'Melebihi Jatah Hari Ini';
      statusIcon = Icons.error_outline;
    }

    final dailyBudget = finance.safeToSpendToday;
    final spentToday = finance.spentToday;
    final remainingToday = finance.remainingToday;
    final daysRemaining = finance.daysUntilNextAllowance;
    final targetDate = finance.settings.monthlyAllowanceDate;

    double progress = 0.0;
    if (status == 'neutral') {
      progress = 0.0;
    } else if (dailyBudget > 0) {
      progress = spentToday / dailyBudget;
      if (progress > 1.0) progress = 1.0;
    } else {
      progress = 1.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    statusTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$daysRemaining hari menuju tgl $targetDate',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Safe-to-Spend Hari Ini',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencyFormat.format(dailyBudget),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ hari',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar Pengeluaran Hari Ini
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                status == 'neutral'
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : statusColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (status == 'neutral') ...[
            Text(
              'Ketuk dompet di bawah untuk menyetel saldo awal Anda',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextSecondary,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${_currencyFormat.format(spentToday)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  remainingToday >= 0
                      ? 'Sisa: ${_currencyFormat.format(remainingToday)}'
                      : 'Over: +${_currencyFormat.format(-remainingToday)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: remainingToday >= 0 ? statusColor : AppTheme.urgentRose,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- MULTI-DOMPET STRIP (3 KOLOM SEIMBANG TANPA POTONGAN) ---
  Widget _buildWalletStrip(
      BuildContext context, FinanceProvider finance, bool isDark) {
    final wallets = finance.wallets;
    final total = finance.totalBalance;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KANTONG SALDO & DOMPET',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              Text(
                'Total: ${_currencyFormat.format(total)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3 Kolom Dompet Seimbang Proporsional
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: wallets.take(3).map((w) {
              final balance = finance.getWalletBalance(w.id);

              IconData icon = Icons.payments_outlined;
              if (w.iconKey == 'bank') icon = Icons.account_balance_outlined;
              if (w.iconKey == 'ewallet') icon = Icons.smartphone_outlined;

              final isLast = w.id == wallets.take(3).last.id;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AdjustWalletDialog(wallet: w),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceElevated
                            : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 14, color: Color(w.colorValue)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  w.id == 'cash'
                                      ? 'Tunai'
                                      : (w.id == 'bank' ? 'Bank' : 'E-Wallet'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currencyFormat.format(balance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrim,
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
        ),
      ],
    );
  }

  // --- TAB SWITCHER (4 TAB SEIMBANG TANPA SESAK) ---
  Widget _buildTabSwitcher(bool isDark) {
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final tabs = [
      {'label': 'Transaksi', 'icon': Icons.swap_vert_rounded},
      {'label': 'Amplop', 'icon': Icons.mail_outline},
      {'label': 'Piutang', 'icon': Icons.handshake_outlined},
      {'label': 'Analisis', 'icon': Icons.pie_chart_outline},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _activeTab == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = i),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      size: 13,
                      color: isSelected
                          ? (isDark
                              ? AppTheme.darkAccent
                              : AppTheme.lightAccent)
                          : (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tabs[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary)
                            : (isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- TAB 1: TRANSAKSI & ARUS KAS ---
  Widget _buildTransactionsTab(
      BuildContext context, FinanceProvider finance, bool isDark) {
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final monthlyIn = finance.monthlyIncome;
    final monthlyOut = finance.monthlyExpense;
    final net = finance.netCashFlow;

    final allTx = finance.transactions;
    final filteredTx = allTx.where((tx) {
      if (_txFilter == 'expense') return tx.isExpense;
      if (_txFilter == 'income') return tx.isIncome;
      return true;
    }).toList();

    return SliverMainAxisGroup(
      slivers: [
        // Cash Flow Banner Bulan Ini (Rapi & Ringkas)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successSage,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(monthlyIn),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 28,
                      color: borderCol.withValues(alpha: 0.6)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pengeluaran',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.urgentRose,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currencyFormat.format(monthlyOut),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 28,
                      color: borderCol.withValues(alpha: 0.6)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arus Bersih',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: net >= 0
                                  ? AppTheme.successSage
                                  : AppTheme.urgentRose,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (net >= 0 ? '+' : '') + _currencyFormat.format(net),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: net >= 0
                                  ? AppTheme.successSage
                                  : AppTheme.urgentRose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Filter Chip Bar (Semua, Pengeluaran, Pemasukan)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Pengeluaran', 'expense', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Pemasukan', 'income', isDark),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Transactions List
        if (filteredTx.isEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceElevated.withValues(alpha: 0.4)
                      : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: borderCol.withValues(alpha: 0.7), width: 0.8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_outlined,
                            size: 22, color: textMuted),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tekan tombol + di pojok kanan bawah untuk mencatat pengeluaran atau pemasukan baru.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = filteredTx[index];
                  final cat = tx.categoryMeta;
                  final isExpense = tx.isExpense;

                  return Dismissible(
                    key: Key('tx_${tx.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.urgentRose,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 20),
                    ),
                    onDismissed: (_) {
                      finance.deleteTransaction(tx.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaksi dihapus'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                AddTransactionModal(initialTransaction: tx),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Color(cat.colorValue)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(cat.icon,
                                      size: 18, color: Color(cat.colorValue)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: textPrim,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          DateFormatter.formatShortDate(
                                              tx.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('•',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: textMuted)),
                                        const SizedBox(width: 6),
                                        Text(
                                          tx.walletId == 'bank'
                                              ? 'Bank'
                                              : (tx.walletId == 'ewallet'
                                                  ? 'E-Wallet'
                                                  : 'Tunai'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                (isExpense ? '- ' : '+ ') +
                                    _currencyFormat.format(tx.amount),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isExpense
                                      ? AppTheme.urgentRose
                                      : AppTheme.successSage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: filteredTx.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 2: AMPLOP ANGGARAN BULANAN (ENVELOPE BUDGETING) ---
  Widget _buildEnvelopesTab(
      BuildContext context, FinanceProvider finance, bool isDark) {
    final envelopes = finance.envelopes;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final env = envelopes[index];
            final spent = finance.getEnvelopeSpent(env.id);
            final budget = env.monthlyBudget;
            final remaining = budget - spent;
            double progress = budget > 0 ? (spent / budget) : 0.0;
            if (progress > 1.0) progress = 1.0;

            final envColor = Color(env.colorValue);

            IconData icon = Icons.mail_outline;
            if (env.iconKey == 'home') icon = Icons.home_outlined;
            if (env.iconKey == 'restaurant') icon = Icons.restaurant_outlined;
            if (env.iconKey == 'school') icon = Icons.school_outlined;
            if (env.iconKey == 'local_cafe') icon = Icons.local_cafe_outlined;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceElevated
                      : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: envColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(icon, size: 18, color: envColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                env.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrim,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Anggaran: ${_currencyFormat.format(budget)} / bln',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              size: 16, color: textMuted),
                          tooltip: 'Atur Anggaran',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => EditEnvelopeDialog(envelope: env),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            isDark ? Colors.white10 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 0.9 ? AppTheme.urgentRose : envColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terpakai: ${_currencyFormat.format(spent)} (${(progress * 100).toInt()}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                        Text(
                          remaining >= 0
                              ? 'Sisa: ${_currencyFormat.format(remaining)}'
                              : 'Over: +${_currencyFormat.format(-remaining)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: remaining >= 0
                                ? AppTheme.successSage
                                : AppTheme.urgentRose,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: envelopes.length,
        ),
      ),
    );
  }

  // --- TAB 3: PATUNGAN & PIUTANG TEMAN (SPLIT BILL & IOU TRACKER) ---
  Widget _buildLoansTab(
      BuildContext context, FinanceProvider finance, bool isDark) {
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final totalLent = finance.totalLentUnsettled;
    final totalBorrowed = finance.totalBorrowedUnsettled;
    final loans = finance.loans;

    return SliverMainAxisGroup(
      slivers: [
        // Summary Card Piutang vs Hutang
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uang Anda di Teman (Piutang)',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _currencyFormat.format(totalLent),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandCobalt,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 32,
                      color: borderCol.withValues(alpha: 0.6)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hutang Anda ke Teman',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _currencyFormat.format(totalBorrowed),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.warningOchre,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Tombol Tambah Patungan / Pinjaman
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddLoanDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Catat Patungan / Pinjaman Baru'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? AppTheme.darkAccent
                      : AppTheme.lightAccent,
                  side: BorderSide(
                    color: isDark
                        ? AppTheme.darkAccent
                        : AppTheme.lightAccent,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // List of Loans
        if (loans.isEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Belum ada catatan patungan atau piutang',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
            ),
          ),
        ] else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final loan = loans[index];
                  final isLend = loan.isLend;
                  final isSettled = loan.isSettled;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceElevated
                            : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSettled
                              ? borderCol.withValues(alpha: 0.4)
                              : (isLend
                                  ? AppTheme.brandCobalt.withValues(alpha: 0.3)
                                  : AppTheme.warningOchre.withValues(alpha: 0.3)),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              finance.toggleLoanSettled(loan.id);
                            },
                            icon: Icon(
                              isSettled
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSettled
                                  ? AppTheme.successSage
                                  : textMuted,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      loan.friendName,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        decoration: isSettled
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isSettled ? textMuted : textPrim,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (isLend
                                                ? AppTheme.brandCobalt
                                                : AppTheme.warningOchre)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isLend ? 'Piutang' : 'Hutang',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isLend
                                              ? AppTheme.brandCobalt
                                              : AppTheme.warningOchre,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loan.description.isNotEmpty
                                      ? loan.description
                                      : 'Tanpa keterangan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: textMuted,
                                    decoration: isSettled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(loan.amount),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSettled
                                      ? textMuted
                                      : (isLend
                                          ? AppTheme.brandCobalt
                                          : AppTheme.warningOchre),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSettled ? 'Lunas' : 'Belum Lunas',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isSettled
                                      ? AppTheme.successSage
                                      : textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 16, color: textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              finance.deleteLoan(loan.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: loans.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 4: ANALISIS ARUS KAS & BOCOR HALUS ---
  Widget _buildAnalyticsTab(
      BuildContext context, FinanceProvider finance, bool isDark) {
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrim =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final breakdown = finance.categoryExpensesThisMonth;
    final totalExpense = finance.monthlyExpense;

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search_outlined,
                          size: 18, color: AppTheme.warningOchre),
                      const SizedBox(width: 8),
                      Text(
                        'ANALISIS BOCOR HALUS BULAN INI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: textPrim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Identifikasi kategori pengeluaran terbesar untuk mencegah kehabisan uang saku sebelum akhir bulan.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (sortedEntries.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Belum ada data pengeluaran bulan ini',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...sortedEntries.map((e) {
                      final cat = FinanceCategory.getByKey(e.key);
                      final amount = e.value;
                      final percent = totalExpense > 0
                          ? ((amount / totalExpense) * 100).toInt()
                          : 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(cat.icon,
                                    size: 14, color: Color(cat.colorValue)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrim,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_currencyFormat.format(amount)} ($percent%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textPrim,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: totalExpense > 0
                                    ? (amount / totalExpense)
                                    : 0.0,
                                minHeight: 5,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(cat.colorValue)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _txFilter == value;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return InkWell(
      onTap: () => setState(() => _txFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppTheme.darkAccent.withValues(alpha: 0.2)
                  : AppTheme.lightAccent.withValues(alpha: 0.08))
              : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                : borderCol,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          ),
        ),
      ),
    );
  }
}
