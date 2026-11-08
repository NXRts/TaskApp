import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/models/subtask.dart';
import 'package:taskapp/models/subject.dart';

void main() {
  test('TaskItem progress and urgency calculations', () {
    final task = TaskItem(
      id: 'test-1',
      title: 'Tugas Kalkulus',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      subtasks: [
        SubTask(id: 's1', title: 'Soal 1', isCompleted: true),
        SubTask(id: 's2', title: 'Soal 2', isCompleted: false),
      ],
    );

    expect(task.subtasks.length, 2);
    expect(task.completedSubtasksCount, 1);
    expect(task.progress, 0.5);
    expect(task.isCompleted, false);
    expect(task.isOverdue, false);
  });

  test('Subject credit hours and mapping', () {
    final subject = Subject(
      id: 'sub-test',
      name: 'Pemrograman Web',
      creditHours: 3,
      dayOfWeek: 1,
    );

    expect(subject.dayName, 'Senin');
    expect(subject.creditHours, 3);
    final map = subject.toMap();
    final reconstructed = Subject.fromMap(map);
    expect(reconstructed.name, 'Pemrograman Web');
    expect(reconstructed.dayName, 'Senin');
  });
}
