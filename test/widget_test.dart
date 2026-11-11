import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/models/subtask.dart';
import 'package:taskapp/models/subject.dart';
import 'package:taskapp/models/attendance_record.dart';

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

  test('Attendance Sentinel metrics and dynamic status transitions', () {
    final subject = Subject(
      id: 'sub-sentinel',
      name: 'Struktur Data',
      totalMeetings: 16,
    );

    // Initial state: 0 absences -> 100% attendance, Safe status
    expect(subject.totalMeetings, 16);
    expect(subject.maxAllowedAbsences, 4);
    expect(subject.totalAbsences, 0);
    expect(subject.attendedMeetings, 16);
    expect(subject.attendancePercentage, 100.0);
    expect(subject.remainingAbsenceQuota, 4);
    expect(subject.attendanceStatus, AttendanceStatus.safe);

    // 1 Absence (Sakit) -> Still Safe (0-1)
    final subjectWith1Absence = subject.copyWith(
      absences: [
        AttendanceRecord(
          id: 'abs-1',
          meetingNumber: 1,
          date: DateTime(2026, 9, 1),
          type: 'sakit',
          note: 'Flu demam',
        ),
      ],
    );
    expect(subjectWith1Absence.totalAbsences, 1);
    expect(subjectWith1Absence.attendedMeetings, 15);
    expect(subjectWith1Absence.attendancePercentage, 93.75);
    expect(subjectWith1Absence.remainingAbsenceQuota, 3);
    expect(subjectWith1Absence.attendanceStatus, AttendanceStatus.safe);

    // 2-3 Absences -> Warning (Waspada)
    final subjectWith2Absences = subjectWith1Absence.copyWith(
      absences: [
        ...subjectWith1Absence.absences,
        AttendanceRecord(
          id: 'abs-2',
          meetingNumber: 3,
          date: DateTime(2026, 9, 15),
          type: 'izin',
          note: 'Urusan keluarga',
        ),
      ],
    );
    expect(subjectWith2Absences.totalAbsences, 2);
    expect(subjectWith2Absences.remainingAbsenceQuota, 2);
    expect(subjectWith2Absences.attendanceStatus, AttendanceStatus.warning);

    final subjectWith3Absences = subjectWith2Absences.copyWith(
      absences: [
        ...subjectWith2Absences.absences,
        AttendanceRecord(
          id: 'abs-3',
          meetingNumber: 6,
          date: DateTime(2026, 10, 5),
          type: 'sakit',
          note: 'Rawat jalan',
        ),
      ],
    );
    expect(subjectWith3Absences.totalAbsences, 3);
    expect(subjectWith3Absences.remainingAbsenceQuota, 1);
    expect(subjectWith3Absences.attendanceStatus, AttendanceStatus.warning);

    // 4+ Absences -> Critical (Kritis >= 4, Batas 75% terlampaui)
    final subjectWith4Absences = subjectWith3Absences.copyWith(
      absences: [
        ...subjectWith3Absences.absences,
        AttendanceRecord(
          id: 'abs-4',
          meetingNumber: 8,
          date: DateTime(2026, 10, 20),
          type: 'alfa',
          note: 'Kesiangan',
        ),
      ],
    );
    expect(subjectWith4Absences.totalAbsences, 4);
    expect(subjectWith4Absences.attendedMeetings, 12);
    expect(subjectWith4Absences.attendancePercentage, 75.0);
    expect(subjectWith4Absences.remainingAbsenceQuota, 0);
    expect(subjectWith4Absences.attendanceStatus, AttendanceStatus.critical);

    // Serialization and deserialization test
    final map = subjectWith4Absences.toMap();
    final reconstructed = Subject.fromMap(map);
    expect(reconstructed.totalMeetings, 16);
    expect(reconstructed.absences.length, 4);
    expect(reconstructed.absences[0].type, 'sakit');
    expect(reconstructed.absences[1].type, 'izin');
    expect(reconstructed.absences[3].type, 'alfa');
    expect(reconstructed.attendanceStatus, AttendanceStatus.critical);
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
