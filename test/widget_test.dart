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

  test('Subject sorting by day of week and start time', () {
    final list = [
      Subject(
        id: '1',
        name: 'Kalkulus',
        dayOfWeek: 2, // Selasa
        timeRange: '09.30-12.00',
      ),
      Subject(
        id: '2',
        name: 'Praktikum Algoritma',
        dayOfWeek: 3, // Rabu
        timeRange: '13.20-15.00',
      ),
      Subject(
        id: '3',
        name: 'Sistem Operasi',
        dayOfWeek: 4, // Kamis
        timeRange: '07.00-08.40',
      ),
      Subject(
        id: '4',
        name: 'Pemrograman Berbasis Mobile',
        dayOfWeek: 1, // Senin
        timeRange: '09.30-11.10',
      ),
      Subject(
        id: '5',
        name: 'Pengantar Teknologi Informasi',
        dayOfWeek: 1, // Senin
        timeRange: '13.20-15.00',
      ),
      Subject(
        id: '6',
        name: 'Pendidikan Pancasila',
        dayOfWeek: 5, // Jumat
        timeRange: '13.10-14.30',
      ),
      Subject(
        id: '7',
        name: 'Matkul Tanpa Jadwal',
        dayOfWeek: null,
      ),
    ];

    list.sort();

    expect(list.map((s) => s.name).toList(), [
      'Pemrograman Berbasis Mobile', // Senin 09.30
      'Pengantar Teknologi Informasi', // Senin 13.20
      'Kalkulus', // Selasa 09.30
      'Praktikum Algoritma', // Rabu 13.20
      'Sistem Operasi', // Kamis 07.00
      'Pendidikan Pancasila', // Jumat 13.10
      'Matkul Tanpa Jadwal', // Tanpa hari
    ]);
  });
}
