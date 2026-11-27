import 'package:flutter/foundation.dart';
import '../models/finance_wallet.dart';
import '../models/finance_transaction.dart';
import '../models/finance_envelope.dart';
import '../models/finance_loan.dart';
import '../models/finance_settings.dart';
import '../services/storage_service.dart';

/// Immutable template representing a frequent or recent expense chip for 1-tap logging.
class FrequentExpenseChipTemplate {
  final String title;
  final double amount;
  final String category;
  final String walletId;
  final String? envelopeId;
  final int frequencyCount;
  final DateTime lastUsed;

  const FrequentExpenseChipTemplate({
    required this.title,
    required this.amount,
    required this.category,
    required this.walletId,
    this.envelopeId,
    required this.frequencyCount,
    required this.lastUsed,
  });

  FinanceCategory get categoryMeta =>
      FinanceCategory.getByKey(category, defaultType: 'expense');
}

class FinanceProvider with ChangeNotifier {
  final StorageService _storageService;

  List<FinanceWallet> _wallets = [];
  List<FinanceTransaction> _transactions = [];
  List<FinanceEnvelope> _envelopes = [];
  List<FinanceLoan> _loans = [];
  FinanceSettings _settings = FinanceSettings();

  FinanceProvider(this._storageService) {
    loadFinanceData();
  }

  List<FinanceWallet> get wallets => _wallets;
  List<FinanceTransaction> get transactions => _transactions;
  List<FinanceEnvelope> get envelopes => _envelopes;
  List<FinanceLoan> get loans => _loans;
  FinanceSettings get settings => _settings;

  void loadFinanceData() {
    _wallets = _storageService.getFinanceWallets();
    _transactions = _storageService.getFinanceTransactions();
    _envelopes = _storageService.getFinanceEnvelopes();
    _loans = _storageService.getFinanceLoans();
    _settings = _storageService.getFinanceSettings();
    notifyListeners();
  }

  // --- WALLET BALANCE CALCULATIONS ---
  double getWalletBalance(String walletId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => FinanceWallet(id: walletId, name: 'Dompet'),
    );

    double balance = wallet.balance; // Saldo awal yang disetel pengguna
    for (final tx in _transactions) {
      if (tx.walletId == walletId) {
        if (tx.isIncome) {
          balance += tx.amount;
        } else if (tx.isExpense) {
          balance -= tx.amount;
        }
      }
    }
    return balance;
  }

  double get totalBalance {
    double total = 0.0;
    for (final wallet in _wallets) {
      total += getWalletBalance(wallet.id);
    }
    return total;
  }

  // --- MONTHLY CASH FLOW ---
  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.isIncome &&
            tx.date.year == now.year &&
            tx.date.month == now.month)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.isExpense &&
            tx.date.year == now.year &&
            tx.date.month == now.month)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  double get netCashFlow => monthlyIncome - monthlyExpense;

  // --- SAFE-TO-SPEND TODAY (KALKULATOR UANG HARIAN AMAN) ---
  /// Sisa hari di bulan kalender berjalan (otomatis tanpa perlu setelan manual)
  int get daysRemainingInMonth {
    final now = DateTime.now();
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final remaining = daysInCurrentMonth - now.day + 1;
    return remaining > 0 ? remaining : 1;
  }

  int get daysUntilNextAllowance => daysRemainingInMonth;

  /// Saldo bebas (Saldo total dikurangi sisa anggaran amplop tetap seperti Kos & Tagihan)
  double get freeBalance {
    final total = totalBalance;
    if (total <= 0) return 0.0;

    // Hitung alokasi amplop tetap (selain makan harian) yang belum terpakai bulan ini
    double reservedForFixedEnvelopes = 0.0;
    for (final env in _envelopes) {
      if (env.id != 'env_food') {
        final spentInEnv = getEnvelopeSpent(env.id);
        final remainingInEnv = env.monthlyBudget - spentInEnv;
        if (remainingInEnv > 0) {
          reservedForFixedEnvelopes += remainingInEnv;
        }
      }
    }

    final available = total - reservedForFixedEnvelopes;
    return available > 0 ? available : (total * 0.5); // Fallback cerdas agar mahasiswa tetap punya jatah harian
  }

  double get safeToSpendToday {
    final days = daysRemainingInMonth;
    if (days <= 0) return freeBalance;
    final daily = freeBalance / days;
    return daily > 0 ? daily : 0.0;
  }

  double get spentToday {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.isExpense &&
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  double get remainingToday => safeToSpendToday - spentToday;

  String get safeToSpendStatus {
    final budget = safeToSpendToday;
    final spent = spentToday;
    final total = totalBalance;

    if (total <= 0 && spent <= 0) return 'neutral';
    if (budget <= 0 && spent > 0) return 'overbudget';
    if (spent > budget) return 'overbudget';
    if (spent >= budget * 0.75) return 'warning';
    return 'safe';
  }

  // --- ENVELOPE BUDGET CALCULATIONS ---
  double getEnvelopeSpent(String envelopeId) {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.isExpense &&
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            (tx.envelopeId == envelopeId ||
                (tx.envelopeId == null &&
                    tx.categoryMeta.defaultEnvelopeId == envelopeId)))
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  // --- IOU / SPLIT BILL & PINJAMAN TEMAN ---
  double get totalLentUnsettled {
    return _loans
        .where((l) => l.isLend && !l.isSettled)
        .fold<double>(0.0, (sum, l) => sum + l.amount);
  }

  double get totalBorrowedUnsettled {
    return _loans
        .where((l) => l.isBorrow && !l.isSettled)
        .fold<double>(0.0, (sum, l) => sum + l.amount);
  }

  List<FinanceLoan> get unsettledLoans =>
      _loans.where((l) => !l.isSettled).toList();

  List<FinanceLoan> get settledLoans =>
      _loans.where((l) => l.isSettled).toList();

  // --- ANALYTICS / BOCOR HALUS ---
  Map<String, double> get categoryExpensesThisMonth {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final tx in _transactions) {
      if (tx.isExpense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        map[tx.category] = (map[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return map;
  }

  // --- 1-TAP FREQUENT EXPENSE CHIPS ---
  /// Builds up to [maxCount] 1-tap quick expense chips derived from existing
  /// `FinanceTransaction` expense records in Hive (sorted by frequency desc, then recency desc),
  /// falling back to student-friendly defaults if fewer than [maxCount] unique patterns exist.
  List<FrequentExpenseChipTemplate> getFrequentExpenseTemplates({
    int maxCount = 4,
  }) {
    final defaultWalletId =
        _wallets.isNotEmpty ? _wallets.first.id : 'cash';

    final grouped = <String, ({
      String title,
      double amount,
      String category,
      String walletId,
      String? envelopeId,
      int count,
      DateTime lastUsed,
    })>{};

    for (final tx in _transactions) {
      if (!tx.isExpense || tx.amount <= 0) continue;
      final cleanTitle = tx.title.trim().isNotEmpty
          ? tx.title.trim()
          : tx.categoryMeta.shortName;
      final key =
          '${tx.category}|${tx.amount.round()}|${cleanTitle.toLowerCase()}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = (
          title: cleanTitle,
          amount: tx.amount,
          category: tx.category,
          walletId: tx.walletId,
          envelopeId: tx.envelopeId ?? tx.categoryMeta.defaultEnvelopeId,
          count: 1,
          lastUsed: tx.date,
        );
      } else {
        final isNewer = tx.date.isAfter(existing.lastUsed);
        grouped[key] = (
          title: isNewer ? cleanTitle : existing.title,
          amount: existing.amount,
          category: existing.category,
          walletId: isNewer ? tx.walletId : existing.walletId,
          envelopeId: isNewer
              ? (tx.envelopeId ?? tx.categoryMeta.defaultEnvelopeId)
              : existing.envelopeId,
          count: existing.count + 1,
          lastUsed: isNewer ? tx.date : existing.lastUsed,
        );
      }
    }

    final sortedEntries = grouped.values.toList()
      ..sort((a, b) {
        final cmpCount = b.count.compareTo(a.count);
        if (cmpCount != 0) return cmpCount;
        return b.lastUsed.compareTo(a.lastUsed);
      });

    final results = <FrequentExpenseChipTemplate>[
      for (final item in sortedEntries.take(maxCount))
        FrequentExpenseChipTemplate(
          title: item.title,
          amount: item.amount,
          category: item.category,
          walletId: item.walletId,
          envelopeId: item.envelopeId,
          frequencyCount: item.count,
          lastUsed: item.lastUsed,
        ),
    ];

    if (results.length < maxCount) {
      final fallbackPresets = <({
        String title,
        double amount,
        String category,
        String? envelopeId,
      })>[
        (
          title: 'Makan Harian',
          amount: 15000.0,
          category: 'food_daily',
          envelopeId: 'env_food',
        ),
        (
          title: 'Ngopi',
          amount: 12000.0,
          category: 'coffee_social',
          envelopeId: 'env_reward',
        ),
        (
          title: 'Galon / Laundry',
          amount: 20000.0,
          category: 'laundry_water',
          envelopeId: 'env_kos',
        ),
        (
          title: 'Bensin / Parkir',
          amount: 10000.0,
          category: 'transport',
          envelopeId: null,
        ),
      ];

      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      for (final preset in fallbackPresets) {
        if (results.length >= maxCount) break;
        final alreadyPresent = results.any(
          (r) =>
              r.category == preset.category &&
              r.amount.round() == preset.amount.round(),
        );
        if (!alreadyPresent) {
          results.add(
            FrequentExpenseChipTemplate(
              title: preset.title,
              amount: preset.amount,
              category: preset.category,
              walletId: defaultWalletId,
              envelopeId: preset.envelopeId,
              frequencyCount: 0,
              lastUsed: epoch,
            ),
          );
        }
      }
    }

    return results;
  }

  /// Immediately records a 1-tap expense transaction from [template] and returns
  /// the created [FinanceTransaction] so the caller can offer an Undo action.
  Future<FinanceTransaction> recordQuickExpenseFromTemplate(
    FrequentExpenseChipTemplate template, {
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final tx = FinanceTransaction(
      id: 'tx-quick-${now.microsecondsSinceEpoch}',
      title: template.title,
      amount: template.amount,
      type: 'expense',
      category: template.category,
      walletId: template.walletId,
      date: now,
      envelopeId: template.envelopeId ?? template.categoryMeta.defaultEnvelopeId,
    );
    await addTransaction(tx);
    return tx;
  }

  // --- ACTIONS: TRANSAKSI ---
  Future<void> addTransaction(FinanceTransaction tx) async {
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    await _storageService.saveFinanceTransaction(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(FinanceTransaction tx) async {
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _storageService.saveFinanceTransaction(tx);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _storageService.deleteFinanceTransaction(id);
    notifyListeners();
  }

  // --- ACTIONS: WALLETS ---
  Future<void> updateWalletBalance(String walletId, double initialBalance) async {
    final index = _wallets.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      _wallets[index].balance = initialBalance;
      await _storageService.saveFinanceWallets(_wallets);
      notifyListeners();
    }
  }

  // --- ACTIONS: ENVELOPES ---
  Future<void> updateEnvelopeBudget(String envelopeId, double newBudget) async {
    final index = _envelopes.indexWhere((e) => e.id == envelopeId);
    if (index != -1) {
      _envelopes[index].monthlyBudget = newBudget;
      await _storageService.saveFinanceEnvelopes(_envelopes);
      notifyListeners();
    }
  }

  // --- ACTIONS: LOANS (SPLIT BILL) ---
  Future<void> addLoan(FinanceLoan loan) async {
    _loans.insert(0, loan);
    _loans.sort((a, b) => b.date.compareTo(a.date));
    await _storageService.saveFinanceLoan(loan);
    notifyListeners();
  }

  Future<void> toggleLoanSettled(String loanId) async {
    final index = _loans.indexWhere((l) => l.id == loanId);
    if (index != -1) {
      final current = _loans[index];
      final newSettled = !current.isSettled;
      final updated = current.copyWith(
        isSettled: newSettled,
        settledAt: newSettled ? DateTime.now() : null,
      );
      _loans[index] = updated;
      await _storageService.saveFinanceLoan(updated);
      notifyListeners();
    }
  }

  Future<void> deleteLoan(String id) async {
    _loans.removeWhere((l) => l.id == id);
    await _storageService.deleteFinanceLoan(id);
    notifyListeners();
  }

  // --- ACTIONS: SETTINGS ---
  Future<void> updateSettings(FinanceSettings settings) async {
    _settings = settings;
    await _storageService.saveFinanceSettings(settings);
    notifyListeners();
  }
}
