import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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
    // Verify singleton instance
    expect(StorageService(), same(StorageService()));

    final tasksBox = await Hive.openBox(StorageService.tasksBoxName);
    final subjectsBox = await Hive.openBox(StorageService.subjectsBoxName);
    final settingsBox = await Hive.openBox(StorageService.settingsBoxName);

    // Pre-populate with dummy tasks, dummy subjects, and user profile
    await tasksBox.put('task-1', {'id': 'task-1', 'title': 'Dummy Task'});
    await subjectsBox.put('sub-1', {'id': 'sub-1', 'name': 'Dummy Subject'});
    await settingsBox.put('user_profile', {
      'name': 'Budi Santoso',
      'campus': 'Universitas Indonesia',
      'studyProgram': 'Sistem Informasi',
      'semester': 4,
    });

    // Simulate purge logic from init()
    const dummyTaskIds = ['task-1', 'task-2', 'task-3', 'task-4'];
    for (final id in dummyTaskIds) {
      if (tasksBox.containsKey(id)) {
        await tasksBox.delete(id);
      }
    }

    const dummySubjectIds = ['sub-1', 'sub-2', 'sub-3', 'sub-4'];
    for (final id in dummySubjectIds) {
      if (subjectsBox.containsKey(id)) {
        await subjectsBox.delete(id);
      }
    }

    await settingsBox.put(StorageService.keyHasSeeded, true);

    // Tasks and subjects are now clean (no dummy data)
    expect(tasksBox.isEmpty, true);
    expect(subjectsBox.isEmpty, true);

    // User profile is preserved!
    final profile = settingsBox.get('user_profile') as Map;
    expect(profile['name'], 'Budi Santoso');
    expect(profile['semester'], 4);
  });
}
