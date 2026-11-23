import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/finance_wallet.dart';
import '../models/finance_transaction.dart';
import '../models/finance_envelope.dart';
import '../models/finance_loan.dart';
import '../models/finance_settings.dart';
import '../models/pomodoro_session_record.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  static StorageService get instance => _instance;
  StorageService._internal();

  static const String tasksBoxName = 'tasks_box_v1';
  static const String subjectsBoxName = 'subjects_box_v1';
  static const String settingsBoxName = 'settings_box_v1';
  static const String financeBoxName = 'finance_box_v1';
  static const String financeTransactionsBoxName = 'finance_transactions_box_v1';
  static const String financeLoansBoxName = 'finance_loans_box_v1';
  static const String keyHasSeeded = 'has_seeded_v1';

  late Box _tasksBox;
  late Box _subjectsBox;
  late Box _settingsBox;
  late Box _financeBox;
  late Box _financeTransactionsBox;
  late Box _financeLoansBox;

  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }
    _tasksBox = await Hive.openBox(tasksBoxName);
    _subjectsBox = await Hive.openBox(subjectsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);
    _financeBox = await Hive.openBox(financeBoxName);
    _financeTransactionsBox = await Hive.openBox(financeTransactionsBoxName);
    _financeLoansBox = await Hive.openBox(financeLoansBoxName);

    // Hapus data dummy lama jika masih tersimpan di local storage
    const dummyTaskIds = ['task-1', 'task-2', 'task-3', 'task-4'];
    for (final id in dummyTaskIds) {
      if (_tasksBox.containsKey(id)) {
        await _tasksBox.delete(id);
      }
    }

    const dummySubjectIds = ['sub-1', 'sub-2', 'sub-3', 'sub-4'];
    for (final id in dummySubjectIds) {
      if (_subjectsBox.containsKey(id)) {
        await _subjectsBox.delete(id);
      }
    }

    // Inisialisasi dompet dan amplop bawaan FinTrack jika belum ada
    if (!_financeBox.containsKey('wallets')) {
      final defaultWallets = FinanceWallet.defaultWallets();
      await _financeBox.put(
        'wallets',
        defaultWallets.map((w) => w.toMap()).toList(),
      );
    }

    if (!_financeBox.containsKey('envelopes')) {
      final defaultEnvelopes = FinanceEnvelope.defaultEnvelopes();
      await _financeBox.put(
        'envelopes',
        defaultEnvelopes.map((e) => e.toMap()).toList(),
      );
    }

    await _settingsBox.put(keyHasSeeded, true);
  }

  // --- SUBJECTS ---
  List<Subject> getSubjects() {
    try {
      final list = <Subject>[];
      for (var key in _subjectsBox.keys) {
        final val = _subjectsBox.get(key);
        if (val is Map) {
          list.add(Subject.fromMap(val));
        }
      }
      list.sort();
      return list;
    } catch (e) {
      debugPrint('Error getting subjects: $e');
      return [];
    }
  }

  Future<void> saveSubject(Subject subject) async {
    await _subjectsBox.put(subject.id, subject.toMap());
  }

  Future<void> deleteSubject(String id) async {
    try {
      await _subjectsBox.delete(id);
    } catch (e) {
      debugPrint('Error deleting subject: $e');
    }
  }

  // --- TASKS ---
  List<TaskItem> getTasks() {
    try {
      final list = <TaskItem>[];
      for (var key in _tasksBox.keys) {
        final val = _tasksBox.get(key);
        if (val is Map) {
          list.add(TaskItem.fromMap(val));
        }
      }
      // Sort: uncompleted first, then by due date ascending
      list.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.dueDate.compareTo(b.dueDate);
      });
      return list;
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      return [];
    }
  }

  Future<void> saveTask(TaskItem task) async {
    await _tasksBox.put(task.id, task.toMap());
  }

  Future<void> deleteTask(String id) async {
    try {
      await _tasksBox.delete(id);
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  // --- USER PROFILE & SETTINGS ---
  UserProfile getUserProfile() {
    final val = _settingsBox.get('user_profile');
    if (val is Map) {
      return UserProfile.fromMap(val);
    }
    return UserProfile();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _settingsBox.put('user_profile', profile.toMap());
  }

  bool isDarkMode() {
    return _settingsBox.get('is_dark_mode', defaultValue: false) as bool;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put('is_dark_mode', isDark);
  }

  bool getIs24HourTimeFormat() {
    return _settingsBox.get('is_24_hour_format', defaultValue: true) as bool;
  }

  Future<void> setIs24HourTimeFormat(bool is24) async {
    await _settingsBox.put('is_24_hour_format', is24);
  }

  bool getIsMonthlyCalendarView() {
    return _settingsBox.get('calendar_is_monthly_view', defaultValue: false) as bool;
  }

  Future<void> setIsMonthlyCalendarView(bool isMonthly) async {
    await _settingsBox.put('calendar_is_monthly_view', isMonthly);
  }

  int getCompletedPomodoroSessions() {
    return _settingsBox.get('completed_pomodoro_sessions', defaultValue: 0) as int;
  }

  Future<void> setCompletedPomodoroSessions(int sessions) async {
    await _settingsBox.put('completed_pomodoro_sessions', sessions < 0 ? 0 : sessions);
  }

  Future<void> incrementPomodoroSession() async {
    final current = getCompletedPomodoroSessions();
    await _settingsBox.put('completed_pomodoro_sessions', current + 1);
  }

  // --- POMODORO ACADEMIC ANALYTICS RECORDS ---
  List<PomodoroSessionRecord> getPomodoroSessionRecords() {
    try {
      final raw = _settingsBox.get('pomodoro_session_records');
      if (raw is List) {
        final list = <PomodoroSessionRecord>[];
        for (final item in raw) {
          if (item is Map) {
            list.add(PomodoroSessionRecord.fromMap(item));
          }
        }
        list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting pomodoro session records: $e');
      return [];
    }
  }

  Future<void> savePomodoroSessionRecords(
    List<PomodoroSessionRecord> records,
  ) async {
    await _settingsBox.put(
      'pomodoro_session_records',
      records.map((r) => r.toMap()).toList(),
    );
  }

  Future<void> addPomodoroSessionRecord(PomodoroSessionRecord record) async {
    final current = getPomodoroSessionRecords();
    current.insert(0, record);
    await savePomodoroSessionRecords(current);
  }

  // --- AMBIENT ZEN SOUNDSCAPES PREFERENCES ---
  String getAmbientSoundTrack() {
    return _settingsBox.get('ambient_sound_track', defaultValue: 'off') as String;
  }

  Future<void> setAmbientSoundTrack(String trackId) async {
    await _settingsBox.put('ambient_sound_track', trackId);
  }

  double getAmbientSoundVolume() {
    final val = _settingsBox.get('ambient_sound_volume', defaultValue: 0.65);
    if (val is num) {
      return val.toDouble().clamp(0.0, 1.0);
    }
    return 0.65;
  }

  Future<void> setAmbientSoundVolume(double volume) async {
    await _settingsBox.put('ambient_sound_volume', volume.clamp(0.0, 1.0));
  }

  double getAmbientMasterVolume() {
    final val = _settingsBox.get('ambient_master_volume', defaultValue: 1.0);
    if (val is num) {
      return val.toDouble().clamp(0.0, 1.0);
    }
    return 1.0;
  }

  Future<void> setAmbientMasterVolume(double volume) async {
    await _settingsBox.put('ambient_master_volume', volume.clamp(0.0, 1.0));
  }

  int getAmbientTimerDuration() {
    final val = _settingsBox.get('ambient_timer_duration', defaultValue: 0);
    if (val is int) return val < 0 ? 0 : val;
    return 0;
  }

  Future<void> setAmbientTimerDuration(int seconds) async {
    await _settingsBox.put('ambient_timer_duration', seconds < 0 ? 0 : seconds);
  }

  Map<String, double> getAmbientTrackVolumes() {
    final raw = _settingsBox.get('ambient_track_volumes');
    final result = <String, double>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final v = entry.value;
        if (v is num) {
          result[entry.key.toString()] = v.toDouble().clamp(0.0, 1.0);
        }
      }
    }
    return result;
  }

  Future<void> setAmbientTrackVolumes(Map<String, double> volumes) async {
    await _settingsBox.put('ambient_track_volumes', Map<String, double>.from(volumes));
  }

  // --- TASK DEADLINE REMINDERS PREFERENCES ---
  bool getTaskRemindersEnabled() {
    return _settingsBox.get('task_reminders_enabled', defaultValue: true) as bool;
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    await _settingsBox.put('task_reminders_enabled', enabled);
  }

  bool getReminderH1Enabled() {
    return _settingsBox.get('reminder_h1_enabled', defaultValue: true) as bool;
  }

  Future<void> setReminderH1Enabled(bool enabled) async {
    await _settingsBox.put('reminder_h1_enabled', enabled);
  }

  bool getReminderH3HoursEnabled() {
    return _settingsBox.get('reminder_h3_hours_enabled', defaultValue: true) as bool;
  }

  Future<void> setReminderH3HoursEnabled(bool enabled) async {
    await _settingsBox.put('reminder_h3_hours_enabled', enabled);
  }

  bool getReminderH30MinutesEnabled() {
    return _settingsBox.get('reminder_h30_minutes_enabled', defaultValue: true) as bool;
  }

  Future<void> setReminderH30MinutesEnabled(bool enabled) async {
    await _settingsBox.put('reminder_h30_minutes_enabled', enabled);
  }

  // --- FINTRACK: WALLETS ---
  List<FinanceWallet> getFinanceWallets() {
    try {
      final val = _financeBox.get('wallets');
      if (val is List) {
        final list = <FinanceWallet>[];
        for (final item in val) {
          if (item is Map) {
            list.add(FinanceWallet.fromMap(item));
          }
        }
        if (list.isNotEmpty) return list;
      }
      return FinanceWallet.defaultWallets();
    } catch (e) {
      debugPrint('Error getting finance wallets: $e');
      return FinanceWallet.defaultWallets();
    }
  }

  Future<void> saveFinanceWallets(List<FinanceWallet> wallets) async {
    await _financeBox.put('wallets', wallets.map((w) => w.toMap()).toList());
  }

  // --- FINTRACK: TRANSACTIONS ---
  List<FinanceTransaction> getFinanceTransactions() {
    try {
      final list = <FinanceTransaction>[];
      for (var key in _financeTransactionsBox.keys) {
        final val = _financeTransactionsBox.get(key);
        if (val is Map) {
          list.add(FinanceTransaction.fromMap(val));
        }
      }
      // Urutkan transaksi terbaru di atas
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      debugPrint('Error getting finance transactions: $e');
      return [];
    }
  }

  Future<void> saveFinanceTransaction(FinanceTransaction tx) async {
    await _financeTransactionsBox.put(tx.id, tx.toMap());
  }

  Future<void> deleteFinanceTransaction(String id) async {
    try {
      await _financeTransactionsBox.delete(id);
    } catch (e) {
      debugPrint('Error deleting finance transaction: $e');
    }
  }

  // --- FINTRACK: ENVELOPES (AMPLOP ANGGARAN) ---
  List<FinanceEnvelope> getFinanceEnvelopes() {
    try {
      final val = _financeBox.get('envelopes');
      if (val is List) {
        final list = <FinanceEnvelope>[];
        for (final item in val) {
          if (item is Map) {
            list.add(FinanceEnvelope.fromMap(item));
          }
        }
        if (list.isNotEmpty) return list;
      }
      return FinanceEnvelope.defaultEnvelopes();
    } catch (e) {
      debugPrint('Error getting finance envelopes: $e');
      return FinanceEnvelope.defaultEnvelopes();
    }
  }

  Future<void> saveFinanceEnvelopes(List<FinanceEnvelope> envelopes) async {
    await _financeBox.put('envelopes', envelopes.map((e) => e.toMap()).toList());
  }

  // --- FINTRACK: LOANS (SPLIT BILL & IOU TRACKER) ---
  List<FinanceLoan> getFinanceLoans() {
    try {
      final list = <FinanceLoan>[];
      for (var key in _financeLoansBox.keys) {
        final val = _financeLoansBox.get(key);
        if (val is Map) {
          list.add(FinanceLoan.fromMap(val));
        }
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      debugPrint('Error getting finance loans: $e');
      return [];
    }
  }

  Future<void> saveFinanceLoan(FinanceLoan loan) async {
    await _financeLoansBox.put(loan.id, loan.toMap());
  }

  Future<void> deleteFinanceLoan(String id) async {
    try {
      await _financeLoansBox.delete(id);
    } catch (e) {
      debugPrint('Error deleting finance loan: $e');
    }
  }

  // --- FINTRACK: SETTINGS ---
  FinanceSettings getFinanceSettings() {
    try {
      final val = _financeBox.get('settings');
      if (val is Map) {
        return FinanceSettings.fromMap(val);
      }
      return FinanceSettings();
    } catch (e) {
      debugPrint('Error getting finance settings: $e');
      return FinanceSettings();
    }
  }

  Future<void> saveFinanceSettings(FinanceSettings settings) async {
    await _financeBox.put('settings', settings.toMap());
  }

  static dynamic _deepConvertToJsonCompatible(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, val) => MapEntry(key.toString(), _deepConvertToJsonCompatible(val)),
      );
    } else if (value is List) {
      return value.map(_deepConvertToJsonCompatible).toList();
    }
    return value;
  }

  // --- BACKUP & RESTORE (100% FULL DATA SOVEREIGNTY) ---
  String exportBackupJson({bool pretty = true}) {
    final subjects = getSubjects();
    final subjectsList = subjects.map((s) => s.toMap()).toList();

    final tasks = getTasks();
    final tasksList = tasks.map((t) => t.toMap()).toList();

    final profileMap = getUserProfile().toMap();
    final darkMode = isDarkMode();
    final pomodoroSessions = getCompletedPomodoroSessions();

    final rawSettings = <String, dynamic>{};
    for (var key in _settingsBox.keys) {
      rawSettings[key.toString()] = _deepConvertToJsonCompatible(_settingsBox.get(key));
    }
    rawSettings['user_profile'] = profileMap;
    rawSettings['is_dark_mode'] = darkMode;
    rawSettings['completed_pomodoro_sessions'] = pomodoroSessions;
    rawSettings[keyHasSeeded] = true;

    // FinTrack export
    final wallets = getFinanceWallets();
    final walletsList = wallets.map((w) => w.toMap()).toList();

    final transactions = getFinanceTransactions();
    final transactionsList = transactions.map((tx) => tx.toMap()).toList();

    final envelopes = getFinanceEnvelopes();
    final envelopesList = envelopes.map((e) => e.toMap()).toList();

    final loans = getFinanceLoans();
    final loansList = loans.map((l) => l.toMap()).toList();

    final financeSettings = getFinanceSettings().toMap();

    final totalSubtasks = tasks.fold<int>(0, (sum, t) => sum + t.subtasks.length);
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalSks = subjects.fold<int>(0, (sum, s) => sum + s.creditHours);

    final data = <String, dynamic>{
      'app': 'TaskApp',
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'summary': {
        'subjects_count': subjectsList.length,
        'total_credit_hours': totalSks,
        'tasks_count': tasksList.length,
        'completed_tasks_count': completedTasks,
        'pending_tasks_count': tasksList.length - completedTasks,
        'subtasks_count': totalSubtasks,
        'completed_pomodoro_sessions': pomodoroSessions,
        'total_focus_minutes': pomodoroSessions * 25,
        'finance_transactions_count': transactionsList.length,
        'finance_wallets_count': walletsList.length,
        'finance_envelopes_count': envelopesList.length,
        'finance_active_loans_count': loans.where((l) => !l.isSettled).length,
      },
      'user_profile': profileMap,
      'settings': {
        'is_dark_mode': darkMode,
        'completed_pomodoro_sessions': pomodoroSessions,
        'total_focus_minutes': pomodoroSessions * 25,
        'has_seeded_v1': true,
        'raw_settings': rawSettings,
      },
      'subjects': subjectsList,
      'tasks': tasksList,
      'finance_wallets': walletsList,
      'finance_transactions': transactionsList,
      'finance_envelopes': envelopesList,
      'finance_loans': loansList,
      'finance_settings': financeSettings,
    };

    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return jsonEncode(data);
  }

  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return false;

      final hasKnownSection = decoded.containsKey('subjects') ||
          decoded.containsKey('tasks') ||
          decoded.containsKey('user_profile') ||
          decoded.containsKey('settings') ||
          decoded.containsKey('is_dark_mode') ||
          decoded.containsKey('finance_transactions') ||
          decoded.containsKey('completed_pomodoro_sessions');
      if (!hasKnownSection) return false;

      // 1. Pulihkan seluruh Mata Kuliah (Subjects)
      if (decoded.containsKey('subjects') && decoded['subjects'] is List) {
        await _subjectsBox.clear();
        for (var sub in decoded['subjects']) {
          if (sub is Map && sub['id'] != null) {
            final normalizedSub = Subject.fromMap(sub).toMap();
            await _subjectsBox.put(normalizedSub['id'] as String, normalizedSub);
          }
        }
      }

      // 2. Pulihkan seluruh Tugas beserta Sub-tugas, Lampiran, & Catatan (Tasks)
      if (decoded.containsKey('tasks') && decoded['tasks'] is List) {
        await _tasksBox.clear();
        for (var task in decoded['tasks']) {
          if (task is Map && task['id'] != null) {
            final normalizedTask = TaskItem.fromMap(task).toMap();
            await _tasksBox.put(normalizedTask['id'] as String, normalizedTask);
          }
        }
      }

      // 3. Pulihkan Pengaturan & Statistik (Settings, Theme, Pomodoro)
      if (decoded.containsKey('settings') && decoded['settings'] is Map) {
        final settingsMap = decoded['settings'] as Map;

        if (settingsMap['raw_settings'] is Map) {
          final raw = settingsMap['raw_settings'] as Map;
          for (final entry in raw.entries) {
            await _settingsBox.put(
              entry.key.toString(),
              _deepConvertToJsonCompatible(entry.value),
            );
          }
        }

        if (settingsMap['is_dark_mode'] is bool) {
          await setDarkMode(settingsMap['is_dark_mode'] as bool);
        }
        if (settingsMap['completed_pomodoro_sessions'] is int) {
          await setCompletedPomodoroSessions(
            settingsMap['completed_pomodoro_sessions'] as int,
          );
        }
        if (settingsMap['user_profile'] is Map) {
          final profile = UserProfile.fromMap(settingsMap['user_profile'] as Map);
          await saveUserProfile(profile);
        }
      }

      // 4. Pulihkan kunci level root (kompatibilitas penuh v1 & v2)
      if (decoded.containsKey('user_profile') && decoded['user_profile'] is Map) {
        final profile = UserProfile.fromMap(decoded['user_profile'] as Map);
        await saveUserProfile(profile);
      }
      if (decoded.containsKey('is_dark_mode') && decoded['is_dark_mode'] is bool) {
        await setDarkMode(decoded['is_dark_mode'] as bool);
      }
      if (decoded.containsKey('completed_pomodoro_sessions') &&
          decoded['completed_pomodoro_sessions'] is int) {
        await setCompletedPomodoroSessions(
          decoded['completed_pomodoro_sessions'] as int,
        );
      }

      // 5. Pulihkan data FinTrack Mahasiswa
      if (decoded.containsKey('finance_wallets') && decoded['finance_wallets'] is List) {
        final wallets = <FinanceWallet>[];
        for (var w in decoded['finance_wallets']) {
          if (w is Map) {
            wallets.add(FinanceWallet.fromMap(w));
          }
        }
        if (wallets.isNotEmpty) {
          await saveFinanceWallets(wallets);
        }
      }

      if (decoded.containsKey('finance_transactions') &&
          decoded['finance_transactions'] is List) {
        await _financeTransactionsBox.clear();
        for (var tx in decoded['finance_transactions']) {
          if (tx is Map && tx['id'] != null) {
            final normalizedTx = FinanceTransaction.fromMap(tx).toMap();
            await _financeTransactionsBox.put(
              normalizedTx['id'] as String,
              normalizedTx,
            );
          }
        }
      }

      if (decoded.containsKey('finance_envelopes') &&
          decoded['finance_envelopes'] is List) {
        final envelopes = <FinanceEnvelope>[];
        for (var e in decoded['finance_envelopes']) {
          if (e is Map) {
            envelopes.add(FinanceEnvelope.fromMap(e));
          }
        }
        if (envelopes.isNotEmpty) {
          await saveFinanceEnvelopes(envelopes);
        }
      }

      if (decoded.containsKey('finance_loans') &&
          decoded['finance_loans'] is List) {
        await _financeLoansBox.clear();
        for (var l in decoded['finance_loans']) {
          if (l is Map && l['id'] != null) {
            final normalizedLoan = FinanceLoan.fromMap(l).toMap();
            await _financeLoansBox.put(
              normalizedLoan['id'] as String,
              normalizedLoan,
            );
          }
        }
      }

      if (decoded.containsKey('finance_settings') &&
          decoded['finance_settings'] is Map) {
        await saveFinanceSettings(
          FinanceSettings.fromMap(decoded['finance_settings'] as Map),
        );
      }

      await _settingsBox.put(keyHasSeeded, true);
      return true;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }
}
