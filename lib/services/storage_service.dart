import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String tasksBoxName = 'tasks_box_v1';
  static const String subjectsBoxName = 'subjects_box_v1';
  static const String settingsBoxName = 'settings_box_v1';

  late Box _tasksBox;
  late Box _subjectsBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _tasksBox = await Hive.openBox(tasksBoxName);
    _subjectsBox = await Hive.openBox(subjectsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    // Seed initial dummy data if first run
    if (_subjectsBox.isEmpty && _tasksBox.isEmpty) {
      await _seedDefaultData();
    }
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
    await _subjectsBox.delete(id);
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
    await _tasksBox.delete(id);
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

  // --- SEED SAMPLE DATA ---
  Future<void> _seedDefaultData() async {
    final sub1 = Subject(
      id: 'sub-1',
      name: 'Pemrograman Mobile & Web',
      code: 'IF-301',
      lecturer: 'Dr. Irfan Hakim, M.Kom',
      room: 'Lab Komputer 3',
      colorValue: 0xFF4F46E5, // Indigo
      creditHours: 3,
      dayOfWeek: 1,
      timeRange: '08:00 - 10:30',
    );

    final sub2 = Subject(
      id: 'sub-2',
      name: 'Basis Data Lanjut',
      code: 'IF-202',
      lecturer: 'Bu Rina Kartika, M.T.',
      room: 'Gedung B, R302',
      colorValue: 0xFF059669, // Emerald
      creditHours: 3,
      dayOfWeek: 3,
      timeRange: '10:45 - 13:15',
    );

    final sub3 = Subject(
      id: 'sub-3',
      name: 'Kecerdasan Buatan (AI)',
      code: 'IF-304',
      lecturer: 'Prof. Andy Wijaya',
      room: 'Ruang Seminar 401',
      colorValue: 0xFF7C3AED, // Violet
      creditHours: 3,
      dayOfWeek: 4,
      timeRange: '13:30 - 16:00',
    );

    final sub4 = Subject(
      id: 'sub-4',
      name: 'Kewirausahaan & Etika',
      code: 'UNV-102',
      lecturer: 'Pak Hendra, M.M.',
      room: 'Auditorium Utama',
      colorValue: 0xFFD97706, // Amber
      creditHours: 2,
      dayOfWeek: 5,
      timeRange: '09:00 - 10:40',
    );

    await saveSubject(sub1);
    await saveSubject(sub2);
    await saveSubject(sub3);
    await saveSubject(sub4);

    final now = DateTime.now();

    final task1 = TaskItem(
      id: 'task-1',
      title: 'Laporan Praktikum REST API & State Management',
      description: 'Implementasikan CRUD lokal dan rekam demo video berdurasi maksimal 3 menit.',
      subjectId: 'sub-1',
      dueDate: DateTime(now.year, now.month, now.day, 23, 59), // Hari ini jam 23:59
      priority: TaskPriority.high,
      category: TaskCategory.academic,
      taskType: TaskType.practice,
      subtasks: [
        SubTask(id: 'st-1', title: 'Desain skema model data', isCompleted: true),
        SubTask(id: 'st-2', title: 'Setup database lokal & controller', isCompleted: true),
        SubTask(id: 'st-3', title: 'Bikin PDF laporan & link GitHub', isCompleted: false),
      ],
      attachments: ['https://github.com/example/api-task'],
      notes: 'Format PDF wajib menggunakan template kampus.',
    );

    final task2 = TaskItem(
      id: 'task-2',
      title: 'Tugas Kelompok: Normalisasi Skema BCNF',
      description: 'Diskusikan studi kasus sistem pemesanan tiket dengan anggota kelompok 4.',
      subjectId: 'sub-2',
      dueDate: now.add(const Duration(days: 2)),
      priority: TaskPriority.medium,
      category: TaskCategory.academic,
      taskType: TaskType.group,
      subtasks: [
        SubTask(id: 'st-4', title: 'Identifikasi Functional Dependencies', isCompleted: true),
        SubTask(id: 'st-5', title: 'Ubah ke bentuk 3NF & BCNF', isCompleted: false),
        SubTask(id: 'st-6', title: 'Buat slide presentasi Canva', isCompleted: false),
      ],
      attachments: ['https://drive.google.com/sample-erd'],
      notes: 'Bagi tugas slide: Alex (Bab 1), Dinda (Bab 2).',
    );

    final task3 = TaskItem(
      id: 'task-3',
      title: 'Kuis AI: Algoritma Heuristik & A* Search',
      description: 'Pelajari bab 3 dan 4 buku Russell & Norvig sebelum kuis dimulai.',
      subjectId: 'sub-3',
      dueDate: now.add(const Duration(days: 4)),
      priority: TaskPriority.medium,
      category: TaskCategory.academic,
      taskType: TaskType.quiz,
    );

    final task4 = TaskItem(
      id: 'task-4',
      title: 'Beli Kertas HVS A4 & Map Folio Praktikum',
      description: 'Beli di fotocopy depan kampus sebelum jam praktikum dimulai.',
      dueDate: DateTime(now.year, now.month, now.day, 16, 0),
      priority: TaskPriority.low,
      category: TaskCategory.personal,
      taskType: TaskType.general,
      isCompleted: false,
    );

    await saveTask(task1);
    await saveTask(task2);
    await saveTask(task3);
    await saveTask(task4);
  }
}

