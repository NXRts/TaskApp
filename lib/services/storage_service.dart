import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  static StorageService get instance => _instance;
  StorageService._internal();

  static const String tasksBoxName = 'tasks_box_v1';
  static const String subjectsBoxName = 'subjects_box_v1';
  static const String settingsBoxName = 'settings_box_v1';
  static const String keyHasSeeded = 'has_seeded_v1';

  late Box _tasksBox;
  late Box _subjectsBox;
  late Box _settingsBox;

  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }
    _tasksBox = await Hive.openBox(tasksBoxName);
    _subjectsBox = await Hive.openBox(subjectsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

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

    final totalSubtasks = tasks.fold<int>(0, (sum, t) => sum + t.subtasks.length);
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalSks = subjects.fold<int>(0, (sum, s) => sum + s.creditHours);

    final data = <String, dynamic>{
      'app': 'TaskApp',
      'version': 2,
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

      await _settingsBox.put(keyHasSeeded, true);
      return true;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }
}

