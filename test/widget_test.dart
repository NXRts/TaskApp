import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/models/subtask.dart';
import 'package:taskapp/models/subject.dart';
import 'package:taskapp/models/user_profile.dart';
import 'package:taskapp/models/attendance_record.dart';
import 'package:taskapp/widgets/timetable_matrix_view.dart';
import 'package:taskapp/screens/calendar_screen.dart';
import 'package:taskapp/services/schedule_export_service.dart';
import 'package:taskapp/widgets/wallpaper_schedule_widget.dart';

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

    // 1 Presence (Hadir) -> totalAbsences stays 0, explicitlyAttendedCount = 1
    final subjectWithHadir = subject.copyWith(
      absences: [
        AttendanceRecord(
          id: 'hadir-1',
          meetingNumber: 1,
          date: DateTime(2026, 9, 1),
          type: 'hadir',
          note: 'Masuk kuliah tatap muka',
        ),
      ],
    );
    expect(subjectWithHadir.totalAbsences, 0);
    expect(subjectWithHadir.explicitlyAttendedCount, 1);
    expect(subjectWithHadir.attendedMeetings, 16);
    expect(subjectWithHadir.attendancePercentage, 100.0);
    expect(subjectWithHadir.attendanceStatus, AttendanceStatus.safe);

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

  test('Subject timetable startMinutes, endMinutes, duration, and FreeStudyWindow', () {
    final s1 = Subject(
      id: 'sub-1',
      name: 'Kalkulus',
      dayOfWeek: 1, // Senin
      timeRange: '08:00 - 10:30',
      room: 'Lab 3',
      creditHours: 3,
    );

    expect(s1.startMinutes, 480); // 08:00
    expect(s1.endMinutes, 630);   // 10:30
    expect(s1.safeEndMinutes, 630);
    expect(s1.durationMinutes, 150); // 2.5 hours

    final s2 = Subject(
      id: 'sub-2',
      name: 'Pemrograman Mobile',
      dayOfWeek: 1, // Senin
      timeRange: '13:00 - 15:30',
      room: 'Ruang 402',
      creditHours: 3,
    );

    expect(s2.startMinutes, 780); // 13:00
    expect(s2.endMinutes, 930);   // 15:30

    // Gap between s1 and s2: 780 - 630 = 150 minutes (2h 30m)
    final freeWindow = FreeStudyWindow(
      dayOfWeek: 1,
      startMinutes: s1.safeEndMinutes,
      endMinutes: s2.startMinutes,
      precedingSubject: s1,
      succeedingSubject: s2,
    );

    expect(freeWindow.durationMinutes, 150);
    expect(freeWindow.durationFormatted, '2j 30m');
    expect(freeWindow.timeRangeFormatted, '10:30 - 13:00');
  });

  test('CalendarTimeHelper 24-hour and 12-hour AM/PM format conversions', () {
    // 24-Hour hour labels
    expect(CalendarTimeHelper.formatHourLabel(0, true), '00:00');
    expect(CalendarTimeHelper.formatHourLabel(6, true), '06:00');
    expect(CalendarTimeHelper.formatHourLabel(12, true), '12:00');
    expect(CalendarTimeHelper.formatHourLabel(15, true), '15:00');
    expect(CalendarTimeHelper.formatHourLabel(23, true), '23:00');
    expect(CalendarTimeHelper.formatHourLabel(24, true), '24:00');

    // 12-Hour AM/PM hour labels
    expect(CalendarTimeHelper.formatHourLabel(0, false), '12 AM');
    expect(CalendarTimeHelper.formatHourLabel(6, false), '6 AM');
    expect(CalendarTimeHelper.formatHourLabel(11, false), '11 AM');
    expect(CalendarTimeHelper.formatHourLabel(12, false), '12 PM');
    expect(CalendarTimeHelper.formatHourLabel(15, false), '3 PM');
    expect(CalendarTimeHelper.formatHourLabel(23, false), '11 PM');
    expect(CalendarTimeHelper.formatHourLabel(24, false), '12 AM');

    // Minute conversions
    expect(CalendarTimeHelper.formatMinutes(0, true), '00:00');
    expect(CalendarTimeHelper.formatMinutes(0, false), '12:00 AM');

    expect(CalendarTimeHelper.formatMinutes(450, true), '07:30'); // 7*60+30 = 450
    expect(CalendarTimeHelper.formatMinutes(450, false), '7:30 AM');

    expect(CalendarTimeHelper.formatMinutes(720, true), '12:00');
    expect(CalendarTimeHelper.formatMinutes(720, false), '12:00 PM');

    expect(CalendarTimeHelper.formatMinutes(810, true), '13:30'); // 13*60+30 = 810
    expect(CalendarTimeHelper.formatMinutes(810, false), '1:30 PM');

    expect(CalendarTimeHelper.formatMinutes(1439, true), '23:59');
    expect(CalendarTimeHelper.formatMinutes(1439, false), '11:59 PM');

    // DateTime conversion
    final dtMorning = DateTime(2026, 11, 13, 8, 15);
    expect(CalendarTimeHelper.formatDateTime(dtMorning, true), '08:15');
    expect(CalendarTimeHelper.formatDateTime(dtMorning, false), '8:15 AM');

    final dtAfternoon = DateTime(2026, 11, 13, 16, 45);
    expect(CalendarTimeHelper.formatDateTime(dtAfternoon, true), '16:45');
    expect(CalendarTimeHelper.formatDateTime(dtAfternoon, false), '4:45 PM');
  });

  test('ScheduleExportService day name mapping and PDF generation', () async {
    // 1. Day name mapping
    expect(ScheduleExportService.getDayName(1), 'Senin');
    expect(ScheduleExportService.getDayName(2), 'Selasa');
    expect(ScheduleExportService.getDayName(3), 'Rabu');
    expect(ScheduleExportService.getDayName(4), 'Kamis');
    expect(ScheduleExportService.getDayName(5), 'Jumat');
    expect(ScheduleExportService.getDayName(6), 'Sabtu');
    expect(ScheduleExportService.getDayName(7), 'Minggu');
    expect(ScheduleExportService.getDayName(null), 'Lainnya');
    expect(ScheduleExportService.getDayName(0), 'Lainnya');

    // 2. Generate PDF document bytes
    final profile = UserProfile(
      name: 'Budi Santoso',
      campus: 'Universitas Indonesia',
      studyProgram: 'Ilmu Komputer',
      semester: 4,
    );

    final subjects = [
      Subject(
        id: 'sub-algo',
        name: 'Algoritma & Struktur Data',
        creditHours: 4,
        dayOfWeek: 1, // Senin
        timeRange: '08:00 - 10:30',
        room: 'Lab 2',
        lecturer: 'Dr. Hendra',
      ),
      Subject(
        id: 'sub-db',
        name: 'Basis Data',
        creditHours: 3,
        dayOfWeek: 2, // Selasa
        timeRange: '13:00 - 15:30',
        room: 'R.304',
        lecturer: 'Prof. Sri',
      ),
    ];

    final tasks = [
      TaskItem(
        id: 'task-1',
        title: 'Tugas Bab 3 Binary Tree',
        dueDate: DateTime(2026, 11, 20, 23, 59),
        priority: TaskPriority.high,
        subjectId: 'sub-algo',
      ),
      TaskItem(
        id: 'task-2',
        title: 'Desain ERD Toko Buku',
        dueDate: DateTime(2026, 11, 22, 17, 0),
        priority: TaskPriority.medium,
        subjectId: 'sub-db',
      ),
    ];

    final pdfBytes = await ScheduleExportService.generateStudySummaryPdf(
      profile: profile,
      subjects: subjects,
      tasks: tasks,
    );

    expect(pdfBytes, isNotEmpty);
    // Standard PDF signature starts with '%PDF'
    final pdfHeader = String.fromCharCodes(pdfBytes.sublist(0, 4));
    expect(pdfHeader, '%PDF');
  });

  testWidgets('WallpaperScheduleWidget renders student info and subjects', (tester) async {
    final profile = UserProfile(
      name: 'Siti Aminah',
      campus: 'Institut Teknologi Bandung',
      studyProgram: 'Teknik Elektro',
      semester: 6,
    );

    final subjects = [
      Subject(
        id: 'sub-el-1',
        name: 'Sinyal & Sistem',
        creditHours: 3,
        dayOfWeek: 1, // Senin
        timeRange: '07:00 - 09:30',
        room: 'Lab Elektro',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 640,
              child: WallpaperScheduleWidget(
                profile: profile,
                subjects: subjects,
                showLecturer: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('SMT 6'), findsOneWidget);
    expect(find.text('3 SKS'), findsNWidgets(2)); // Card header and subject item
    expect(find.text('Sinyal & Sistem'), findsOneWidget);
    expect(find.text('SENIN'), findsOneWidget);
  });
}
