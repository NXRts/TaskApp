import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String tasksBoxName = 'tasks_box_v1';
  static const String subjectsBoxName = 'subjects_box_v1';
  static const String settingsBoxName = 'settings_box_v1';
  static const String keyHasSeeded = 'has_seeded_v1';

  late Box _tasksBox;
  late Box _subjectsBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
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

  int getCompletedPomodoroSessions() {
    return _settingsBox.get('completed_pomodoro_sessions', defaultValue: 0) as int;
  }

  Future<void> incrementPomodoroSession() async {
    final current = getCompletedPomodoroSessions();
    await _settingsBox.put('completed_pomodoro_sessions', current + 1);
  }

  // --- BACKUP & RESTORE ---
  String exportBackupJson() {
    final subjectsList = <dynamic>[];
    for (var key in _subjectsBox.keys) {
      subjectsList.add(_subjectsBox.get(key));
    }

    final tasksList = <dynamic>[];
    for (var key in _tasksBox.keys) {
      tasksList.add(_tasksBox.get(key));
    }

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'subjects': subjectsList,
      'tasks': tasksList,
      'user_profile': _settingsBox.get('user_profile'),
    };
    return jsonEncode(data);
  }

  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return false;

      if (decoded.containsKey('subjects') && decoded['subjects'] is List) {
        await _subjectsBox.clear();
        for (var sub in decoded['subjects']) {
          if (sub is Map && sub.containsKey('id')) {
            await _subjectsBox.put(sub['id'], sub);
          }
        }
      }

      if (decoded.containsKey('tasks') && decoded['tasks'] is List) {
        await _tasksBox.clear();
        for (var task in decoded['tasks']) {
          if (task is Map && task.containsKey('id')) {
            await _tasksBox.put(task['id'], task);
          }
        }
      }

      if (decoded.containsKey('user_profile') && decoded['user_profile'] is Map) {
        await _settingsBox.put('user_profile', decoded['user_profile']);
      }
      await _settingsBox.put(keyHasSeeded, true);
      return true;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }
}

