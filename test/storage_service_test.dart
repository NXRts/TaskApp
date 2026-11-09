import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taskapp/models/subject.dart';
import 'package:taskapp/models/subtask.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/models/user_profile.dart';
import 'package:taskapp/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('StorageService purges dummy data and preserves user profile', () async {
    expect(StorageService(), same(StorageService()));

    final tasksBox = await Hive.openBox(StorageService.tasksBoxName);
    final subjectsBox = await Hive.openBox(StorageService.subjectsBoxName);
    final settingsBox = await Hive.openBox(StorageService.settingsBoxName);

    await tasksBox.put('task-1', {'id': 'task-1', 'title': 'Dummy Task'});
    await subjectsBox.put('sub-1', {'id': 'sub-1', 'name': 'Dummy Subject'});
    await settingsBox.put('user_profile', {
      'name': 'Budi Santoso',
      'campus': 'Universitas Indonesia',
      'studyProgram': 'Sistem Informasi',
      'semester': 4,
    });

    await StorageService().init(customPath: tempDir.path);

    expect(tasksBox.isEmpty, true);
    expect(subjectsBox.isEmpty, true);

    final profile = StorageService().getUserProfile();
    expect(profile.name, 'Budi Santoso');
    expect(profile.semester, 4);
  });

  test('StorageService exports and imports 100% of all application data without exception', () async {
    final storage = StorageService();
    await storage.init(customPath: tempDir.path);

    // 1. Populate all data types: Subject, Task (with SubTasks, attachments, notes), UserProfile, Theme, Pomodoro
    final subject = Subject(
      id: 'sub-custom-1',
      name: 'Algoritma & Struktur Data',
      code: 'IF-201',
      lecturer: 'Dr. Hendra',
      room: 'Lab 2',
      colorValue: 0xFF059669,
      creditHours: 4,
      dayOfWeek: 2,
      timeRange: '10:00 - 12:30',
    );
    await storage.saveSubject(subject);

    final task = TaskItem(
      id: 'task-custom-1',
      title: 'Implementasi Graph Dijkstra',
      description: 'Buat simulasi rute terpendek',
      subjectId: 'sub-custom-1',
      dueDate: DateTime(2026, 11, 20, 23, 59),
      isCompleted: false,
      priority: TaskPriority.high,
      category: TaskCategory.academic,
      taskType: TaskType.practice,
      subtasks: [
        SubTask(id: 'st-a', title: 'Buat struktur adjacency list', isCompleted: true),
        SubTask(id: 'st-b', title: 'Uji kompleksitas priority queue', isCompleted: false),
      ],
      attachments: ['https://github.com/example/dijkstra'],
      notes: 'Gunakan dataset peta kampus',
    );
    await storage.saveTask(task);

    await storage.saveUserProfile(UserProfile(
      name: 'Nadia Putri',
      campus: 'Institut Teknologi Bandung',
      studyProgram: 'Teknik Informatika',
      semester: 6,
    ));
    await storage.setDarkMode(true);
    await storage.setCompletedPomodoroSessions(7);

    // 2. Export full JSON backup
    final exportedJson = storage.exportBackupJson(pretty: true);
    expect(exportedJson.contains('Nadia Putri'), true);
    expect(exportedJson.contains('Implementasi Graph Dijkstra'), true);
    expect(exportedJson.contains('Algoritma & Struktur Data'), true);

    // 3. Wipe all current data to simulate a fresh device
    await storage.deleteTask('task-custom-1');
    await storage.deleteSubject('sub-custom-1');
    await storage.saveUserProfile(UserProfile(name: 'Default', campus: '-', studyProgram: '-', semester: 1));
    await storage.setDarkMode(false);
    await storage.setCompletedPomodoroSessions(0);

    expect(storage.getTasks().isEmpty, true);
    expect(storage.getSubjects().isEmpty, true);
    expect(storage.isDarkMode(), false);
    expect(storage.getCompletedPomodoroSessions(), 0);

    // 4. Import JSON backup and verify 100% restoration
    final importResult = await storage.importBackupJson(exportedJson);
    expect(importResult, true);

    final restoredSubjects = storage.getSubjects();
    expect(restoredSubjects.length, 1);
    expect(restoredSubjects.first.name, 'Algoritma & Struktur Data');
    expect(restoredSubjects.first.creditHours, 4);
    expect(restoredSubjects.first.lecturer, 'Dr. Hendra');

    final restoredTasks = storage.getTasks();
    expect(restoredTasks.length, 1);
    expect(restoredTasks.first.title, 'Implementasi Graph Dijkstra');
    expect(restoredTasks.first.subtasks.length, 2);
    expect(restoredTasks.first.subtasks.first.isCompleted, true);
    expect(restoredTasks.first.attachments.first, 'https://github.com/example/dijkstra');
    expect(restoredTasks.first.notes, 'Gunakan dataset peta kampus');

    final restoredProfile = storage.getUserProfile();
    expect(restoredProfile.name, 'Nadia Putri');
    expect(restoredProfile.campus, 'Institut Teknologi Bandung');
    expect(restoredProfile.semester, 6);

    expect(storage.isDarkMode(), true);
    expect(storage.getCompletedPomodoroSessions(), 7);
  });
}
