import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/services/pomodoro_alert_service.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/providers/task_provider.dart';
import 'package:taskapp/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PomodoroAlertService singleton and default toggles', () {
    final alertService = PomodoroAlertService.instance;
    expect(alertService.soundEnabled, true);
    expect(alertService.notificationEnabled, true);

    alertService.soundEnabled = false;
    expect(alertService.soundEnabled, false);
    alertService.soundEnabled = true;

    alertService.notificationEnabled = false;
    expect(alertService.notificationEnabled, false);
    alertService.notificationEnabled = true;
  });

  test('TaskProvider getTaskById returns matching task or null', () async {
    final tempDir = await Directory.systemTemp.createTemp('pomodoro_test_');
    final storage = StorageService();
    await storage.init(customPath: tempDir.path);
    final provider = TaskProvider(storage);

    final dummy = TaskItem(
      id: 'pomodoro-target-1',
      title: 'Tugas Kalkulus Lanjut',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );
    await provider.addTask(dummy);

    expect(provider.getTaskById('pomodoro-target-1')?.title, 'Tugas Kalkulus Lanjut');
    expect(provider.getTaskById('non-existent-id'), isNull);
    expect(provider.getTaskById(null), isNull);

    await tempDir.delete(recursive: true);
  });
}
