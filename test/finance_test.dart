import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taskapp/models/finance_wallet.dart';
import 'package:taskapp/models/finance_transaction.dart';
import 'package:taskapp/models/finance_envelope.dart';
import 'package:taskapp/models/finance_loan.dart';
import 'package:taskapp/models/finance_settings.dart';
import 'package:taskapp/providers/finance_provider.dart';
import 'package:taskapp/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_finance_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Finance Models serialize and deserialize correctly', () {
    // 1. FinanceWallet
    final wallet = FinanceWallet(
      id: 'cash',
      name: 'Uang Saku Tunai',
      balance: 150000.0,
      iconKey: 'cash',
      colorValue: 0xFF10B981,
    );
    final walletMap = wallet.toMap();
    final restoredWallet = FinanceWallet.fromMap(walletMap);
    expect(restoredWallet.id, 'cash');
    expect(restoredWallet.name, 'Uang Saku Tunai');
    expect(restoredWallet.balance, 150000.0);

    // 2. FinanceTransaction
    final tx = FinanceTransaction(
      id: 'tx-1',
      title: 'Nasi Padang Komplit',
      amount: 25000.0,
      type: 'expense',
      category: 'food_daily',
      walletId: 'cash',
      date: DateTime(2026, 11, 17, 12, 30),
      note: 'Makan siang sebelum praktikum',
      envelopeId: 'env_food',
    );
    final txMap = tx.toMap();
    final restoredTx = FinanceTransaction.fromMap(txMap);
    expect(restoredTx.id, 'tx-1');
    expect(restoredTx.amount, 25000.0);
    expect(restoredTx.isExpense, true);
    expect(restoredTx.category, 'food_daily');

    // 3. FinanceEnvelope
    final env = FinanceEnvelope(
      id: 'env_kos',
      name: 'Kos & Tagihan Tetap',
      monthlyBudget: 800000.0,
      iconKey: 'home',
      colorValue: 0xFF6366F1,
    );
    final envMap = env.toMap();
    final restoredEnv = FinanceEnvelope.fromMap(envMap);
    expect(restoredEnv.id, 'env_kos');
    expect(restoredEnv.monthlyBudget, 800000.0);

    // 4. FinanceLoan
    final loan = FinanceLoan(
      id: 'loan-1',
      friendName: 'Andi Saputra',
      amount: 35000.0,
      type: 'lend',
      description: 'Nalangi print makalah bab 3',
      date: DateTime(2026, 11, 17),
    );
    final loanMap = loan.toMap();
    final restoredLoan = FinanceLoan.fromMap(loanMap);
    expect(restoredLoan.friendName, 'Andi Saputra');
    expect(restoredLoan.amount, 35000.0);
    expect(restoredLoan.isLend, true);
    expect(restoredLoan.isSettled, false);

    // 5. FinanceSettings
    final settings = FinanceSettings(monthlyAllowanceDate: 25);
    final settingsMap = settings.toMap();
    final restoredSettings = FinanceSettings.fromMap(settingsMap);
    expect(restoredSettings.monthlyAllowanceDate, 25);

    // 6. FinanceCategory short names
    expect(FinanceCategory.expenseCategories.first.shortName, 'Makan');
    expect(FinanceCategory.incomeCategories.first.shortName, 'Ortu');
  });

  test('FinanceProvider handles wallets, transactions, safe-to-spend, envelopes, and loans', () async {
    final storage = StorageService();
    await storage.init(customPath: tempDir.path);

    final provider = FinanceProvider(storage);
    expect(provider.wallets.length, 3); // 3 default wallets
    expect(provider.envelopes.length, 4); // 4 default envelopes

    // Set initial balance for wallets
    await provider.updateWalletBalance('cash', 100000.0);
    await provider.updateWalletBalance('bank', 500000.0);
    expect(provider.getWalletBalance('cash'), 100000.0);
    expect(provider.getWalletBalance('bank'), 500000.0);
    expect(provider.totalBalance, 600000.0);

    // Add Income Transaction (Kiriman Ortu Rp 1.000.000 ke Bank)
    final incomeTx = FinanceTransaction(
      id: 'tx-inc-1',
      title: 'Kiriman Ortu Awal Bulan',
      amount: 1000000.0,
      type: 'income',
      category: 'parent_allowance',
      walletId: 'bank',
      date: DateTime.now(),
    );
    await provider.addTransaction(incomeTx);
    expect(provider.getWalletBalance('bank'), 1500000.0);
    expect(provider.totalBalance, 1600000.0);
    expect(provider.monthlyIncome, 1000000.0);

    // Add Expense Transaction (Makan Rp 30.000 dari Cash)
    final expenseTx = FinanceTransaction(
      id: 'tx-exp-1',
      title: 'Makan Ayam Geprek',
      amount: 30000.0,
      type: 'expense',
      category: 'food_daily',
      walletId: 'cash',
      date: DateTime.now(),
      envelopeId: 'env_food',
    );
    await provider.addTransaction(expenseTx);
    expect(provider.getWalletBalance('cash'), 70000.0);
    expect(provider.totalBalance, 1570000.0);
    expect(provider.monthlyExpense, 30000.0);
    expect(provider.netCashFlow, 970000.0);

    // Safe-to-Spend calculations
    expect(provider.spentToday, 30000.0);
    expect(provider.daysUntilNextAllowance > 0, true);
    expect(provider.safeToSpendToday > 0, true);

    // Envelopes budget tracking
    final foodSpent = provider.getEnvelopeSpent('env_food');
    expect(foodSpent, 30000.0);

    // Loans / Split Bill tracking
    final loan = FinanceLoan(
      id: 'loan-1',
      friendName: 'Rudi',
      amount: 25000.0,
      type: 'lend',
      description: 'Nalangi fotokopi modul',
      date: DateTime.now(),
    );
    await provider.addLoan(loan);
    expect(provider.totalLentUnsettled, 25000.0);
    expect(provider.totalBorrowedUnsettled, 0.0);

    // Toggle settled
    await provider.toggleLoanSettled('loan-1');
    expect(provider.totalLentUnsettled, 0.0);
    expect(provider.settledLoans.length, 1);
  });

  test('StorageService exports and imports FinTrack data seamlessly in full backup JSON', () async {
    final storage = StorageService();
    await storage.init(customPath: tempDir.path);

    final provider = FinanceProvider(storage);
    await provider.updateWalletBalance('cash', 250000.0);

    await provider.addTransaction(FinanceTransaction(
      id: 'tx-backup-1',
      title: 'Beli Buku Pemrograman',
      amount: 85000.0,
      type: 'expense',
      category: 'books_academic',
      walletId: 'cash',
      date: DateTime.now(),
      envelopeId: 'env_academic',
    ));

    await provider.addLoan(FinanceLoan(
      id: 'loan-backup-1',
      friendName: 'Bima',
      amount: 50000.0,
      type: 'lend',
      description: 'Pinjam bayar kas himpunan',
      date: DateTime.now(),
    ));

    // Export backup JSON
    final jsonStr = storage.exportBackupJson(pretty: false);
    expect(jsonStr.contains('finance_wallets'), true);
    expect(jsonStr.contains('finance_transactions'), true);
    expect(jsonStr.contains('Beli Buku Pemrograman'), true);
    expect(jsonStr.contains('loan-backup-1'), true);

    // Import into fresh instance
    final importResult = await storage.importBackupJson(jsonStr);
    expect(importResult, true);

    final restoredTransactions = storage.getFinanceTransactions();
    expect(restoredTransactions.length, 1);
    expect(restoredTransactions.first.title, 'Beli Buku Pemrograman');
    expect(restoredTransactions.first.amount, 85000.0);

    final restoredLoans = storage.getFinanceLoans();
    expect(restoredLoans.length, 1);
    expect(restoredLoans.first.friendName, 'Bima');
  });
}
