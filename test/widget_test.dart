import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/models/subtask.dart';
import 'package:taskapp/models/subject.dart';
import 'package:taskapp/models/user_profile.dart';
import 'package:taskapp/models/attendance_record.dart';
import 'package:taskapp/providers/subject_provider.dart';
import 'package:taskapp/providers/task_provider.dart';
import 'package:taskapp/services/storage_service.dart';
import 'package:taskapp/widgets/summary_card.dart';
import 'package:taskapp/widgets/task_card.dart';
import 'package:taskapp/widgets/timetable_matrix_view.dart';
import 'package:taskapp/screens/calendar_screen.dart';
import 'package:taskapp/services/schedule_export_service.dart';
import 'package:taskapp/services/task_reminder_service.dart';
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

    // 3. WallpaperSaveResult model tests
    const successResult = WallpaperSaveResult(
      isSuccess: true,
      isGallery: true,
      message: 'Wallpaper berhasil disimpan ke Galeri HP (Album: TaskApp)!',
    );
    expect(successResult.isSuccess, isTrue);
    expect(successResult.isGallery, isTrue);
    expect(successResult.message, contains('Galeri HP'));

    const localResult = WallpaperSaveResult(
      isSuccess: true,
      isGallery: false,
      filePath: '/storage/emulated/0/Download/wallpaper.png',
      message: 'Wallpaper tersimpan di: /storage/emulated/0/Download/wallpaper.png',
    );
    expect(localResult.isSuccess, isTrue);
    expect(localResult.isGallery, isFalse);
    expect(localResult.filePath, isNotNull);
  });

  test('TaskReminderService calculates exact H-1 and H-3 reminder times and unique IDs', () async {
    // 1. Waktu H-1 (sehari sebelumnya pukul 19:00)
    final due1 = DateTime(2026, 11, 20, 23, 59); // Jumat malam
    final h1_1 = TaskReminderService.calculateH1ReminderTime(due1);
    expect(h1_1.year, 2026);
    expect(h1_1.month, 11);
    expect(h1_1.day, 19);
    expect(h1_1.hour, 19);
    expect(h1_1.minute, 0);

    // Kasus tanggal 1 awal bulan
    final due2 = DateTime(2026, 12, 1, 9, 30);
    final h1_2 = TaskReminderService.calculateH1ReminderTime(due2);
    expect(h1_2.year, 2026);
    expect(h1_2.month, 11);
    expect(h1_2.day, 30);
    expect(h1_2.hour, 19);
    expect(h1_2.minute, 0);

    // 2. Waktu H-3 Jam (tepat 3 jam sebelum deadline)
    final h3_1 = TaskReminderService.calculateH3HoursReminderTime(due1);
    expect(h3_1, DateTime(2026, 11, 20, 20, 59));

    final dueMorning = DateTime(2026, 11, 21, 10, 0);
    final h3Morning = TaskReminderService.calculateH3HoursReminderTime(dueMorning);
    expect(h3Morning, DateTime(2026, 11, 21, 7, 0));

    // 3. Waktu H-30 Menit (tepat 30 menit sebelum deadline)
    final h30m_1 = TaskReminderService.calculateH30MinutesReminderTime(due1);
    expect(h30m_1, DateTime(2026, 11, 20, 23, 29));

    // 4. ID Notifikasi Deterministik
    final idH1 = TaskReminderService.getNotificationId('task-abc', 0);
    final idH3 = TaskReminderService.getNotificationId('task-abc', 1);
    final idH30m = TaskReminderService.getNotificationId('task-abc', 2);
    expect(idH1, isNot(idH3));
    expect(idH1, isNot(idH30m));
    expect(idH3, isNot(idH30m));
    expect(idH1 >= 0, isTrue);
    expect(idH3 >= 0, isTrue);
    expect(idH30m >= 0, isTrue);

    // Konsistensi ID
    expect(TaskReminderService.getNotificationId('task-abc', 0), idH1);
    expect(TaskReminderService.getNotificationId('task-abc', 1), idH3);
    expect(TaskReminderService.getNotificationId('task-abc', 2), idH30m);

    // Test pembatalan timer
    await TaskReminderService.instance.cancelTaskReminders('task-abc');
    await TaskReminderService.instance.cancelAllReminders();
    expect(TaskReminderService.activeTimersCount, 0);
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

  testWidgets('WallpaperScheduleWidget two-column layout fits all 6 days without cut-offs', (tester) async {
    final profile = UserProfile(
      name: 'Yusuf Arrofi',
      campus: 'UMUKA',
      studyProgram: 'Teknik Informatika',
      semester: 1,
    );

    final subjects = [
      Subject(id: 's1', name: 'Logika Informatika', creditHours: 3, dayOfWeek: 1, timeRange: '07.00-09.30', room: 'L.03.11'),
      Subject(id: 's2', name: 'Pengantar TI', creditHours: 2, dayOfWeek: 1, timeRange: '13.20-15.00', room: 'L01.01'),
      Subject(id: 's3', name: 'Kalkulus', creditHours: 3, dayOfWeek: 2, timeRange: '09.30-12.00', room: 'L.03.11'),
      Subject(id: 's4', name: 'Algoritma', creditHours: 2, dayOfWeek: 3, timeRange: '08.40-10.20', room: 'L.01.02'),
      Subject(id: 's5', name: 'Praktikum Algoritma', creditHours: 1, dayOfWeek: 3, timeRange: '13.20-15.00', room: 'Lab Kom'),
      Subject(id: 's6', name: 'Sistem Operasi', creditHours: 2, dayOfWeek: 4, timeRange: '07.00-08.40', room: 'L01.01'),
      Subject(id: 's7', name: 'Pendidikan Agama', creditHours: 2, dayOfWeek: 4, timeRange: '13.20-15.00', room: 'L02.01'),
      Subject(id: 's8', name: 'Praktikum SO', creditHours: 1, dayOfWeek: 5, timeRange: '08.00-09.20', room: 'Lab Kom'),
      Subject(id: 's9', name: 'Pendidikan Pancasila', creditHours: 2, dayOfWeek: 5, timeRange: '13.10-14.30', room: 'L.01.03'),
      Subject(id: 's10', name: 'English for Academic', creditHours: 2, dayOfWeek: 6, timeRange: '07.50-09.30', room: 'L.03.15'),
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
                layoutMode: WallpaperLayoutMode.twoColumns,
              ),
            ),
          ),
        ),
      ),
    );

    // Verify all 6 days are rendered
    expect(find.text('SENIN'), findsOneWidget);
    expect(find.text('SELASA'), findsOneWidget);
    expect(find.text('RABU'), findsOneWidget);
    expect(find.text('KAMIS'), findsOneWidget);
    expect(find.text('JUMAT'), findsOneWidget);
    expect(find.text('SABTU'), findsOneWidget);

    // Verify subjects from early week and late week are both rendered
    expect(find.text('Logika Informatika'), findsOneWidget);
    expect(find.text('English for Academic'), findsOneWidget);
  });

  testWidgets('WallpaperScheduleWidget single-column layout fits all 10 classes without overflow', (tester) async {
    final profile = UserProfile(
      name: 'Yusuf Arrofi',
      campus: 'UMUKA',
      studyProgram: 'Teknik Informatika',
      semester: 1,
    );

    final subjects = [
      Subject(id: 's1', name: 'Logika Informatika', creditHours: 3, dayOfWeek: 1, timeRange: '07.00-09.30', room: 'L.03.11'),
      Subject(id: 's2', name: 'Pengantar TI', creditHours: 2, dayOfWeek: 1, timeRange: '13.20-15.00', room: 'L01.01'),
      Subject(id: 's3', name: 'Kalkulus', creditHours: 3, dayOfWeek: 2, timeRange: '09.30-12.00', room: 'L.03.11'),
      Subject(id: 's4', name: 'Algoritma', creditHours: 2, dayOfWeek: 3, timeRange: '08.40-10.20', room: 'L.01.02'),
      Subject(id: 's5', name: 'Praktikum Algoritma', creditHours: 1, dayOfWeek: 3, timeRange: '13.20-15.00', room: 'Lab Kom'),
      Subject(id: 's6', name: 'Sistem Operasi', creditHours: 2, dayOfWeek: 4, timeRange: '07.00-08.40', room: 'L01.01'),
      Subject(id: 's7', name: 'Pendidikan Agama', creditHours: 2, dayOfWeek: 4, timeRange: '13.20-15.00', room: 'L02.01'),
      Subject(id: 's8', name: 'Praktikum SO', creditHours: 1, dayOfWeek: 5, timeRange: '08.00-09.20', room: 'Lab Kom'),
      Subject(id: 's9', name: 'Pendidikan Pancasila', creditHours: 2, dayOfWeek: 5, timeRange: '13.10-14.30', room: 'L.01.03'),
      Subject(id: 's10', name: 'English for Academic', creditHours: 2, dayOfWeek: 6, timeRange: '07.50-09.30', room: 'L.03.15'),
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
                layoutMode: WallpaperLayoutMode.singleColumn,
              ),
            ),
          ),
        ),
      ),
    );

    // Verify all 6 days are rendered cleanly in 1 column
    expect(find.text('SENIN'), findsOneWidget);
    expect(find.text('SELASA'), findsOneWidget);
    expect(find.text('RABU'), findsOneWidget);
    expect(find.text('KAMIS'), findsOneWidget);
    expect(find.text('JUMAT'), findsOneWidget);
    expect(find.text('SABTU'), findsOneWidget);

    // Both first and last classes are rendered
    expect(find.text('Logika Informatika'), findsOneWidget);
    expect(find.text('English for Academic'), findsOneWidget);
  });

  group('TaskRescheduleHelper & TaskCard Swipe Gestures', () {
    test('TaskRescheduleHelper preserves deadline hour/minute and computes target dates', () {
      // Wednesday, Nov 25, 2026 at 10:15
      final now = DateTime(2026, 11, 25, 10, 15);
      final dueDate = DateTime(2026, 11, 25, 21, 45);

      final tomorrow = TaskRescheduleHelper.tomorrow(now, dueDate);
      expect(tomorrow, DateTime(2026, 11, 26, 21, 45));

      // Next Saturday from Wednesday Nov 25 is Nov 28 (+3 days)
      final weekend = TaskRescheduleHelper.upcomingWeekend(now, dueDate);
      expect(weekend, DateTime(2026, 11, 28, 21, 45));
      expect(weekend.weekday, DateTime.saturday);

      // If now is already Saturday (Nov 28), upcomingWeekend jumps to next Saturday (Dec 5)
      final fromSaturday = TaskRescheduleHelper.upcomingWeekend(
        DateTime(2026, 11, 28, 9, 0),
        dueDate,
      );
      expect(fromSaturday, DateTime(2026, 12, 5, 21, 45));
      expect(fromSaturday.weekday, DateTime.saturday);

      final nextWeek = TaskRescheduleHelper.nextWeek(now, dueDate);
      expect(nextWeek, DateTime(2026, 12, 2, 21, 45));
    });

    testWidgets('TaskCard swipe right toggles completion & swipe left opens reschedule/delete sheet', (tester) async {
      late Directory tempDir;
      late StorageService storage;
      late TaskProvider taskProvider;
      late SubjectProvider subjectProvider;

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('swipe_task_test_');
        Hive.init(tempDir.path);
        for (final boxName in [
          'tasks_box_v1',
          'subjects_box_v1',
          'settings_box_v1',
          'finance_box_v1',
          'finance_transactions_box_v1',
          'finance_loans_box_v1',
        ]) {
          await Hive.openBox(boxName, bytes: Uint8List(0));
        }
        storage = StorageService();
        await storage.init(customPath: tempDir.path);
        await storage.setTaskRemindersEnabled(false);
        taskProvider = TaskProvider(storage);
        subjectProvider = SubjectProvider(storage);
      });

      final initialDue = DateTime.now().add(const Duration(hours: 5));
      await taskProvider.addTask(
        TaskItem(
          id: 'swipe-task-1',
          title: 'Laporan Praktikum Jarkom',
          dueDate: initialDue,
          priority: TaskPriority.high,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ChangeNotifierProvider<SubjectProvider>.value(value: subjectProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<TaskProvider>(
                builder: (context, provider, _) {
                  final tasks = provider.allTasks;
                  if (tasks.isEmpty) {
                    return const Center(child: Text('Tidak ada tugas'));
                  }
                  return ListView(
                    children: [
                      TaskCard(task: tasks.first),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laporan Praktikum Jarkom'), findsOneWidget);
      expect(taskProvider.allTasks.first.isCompleted, isFalse);

      // 1. Swipe Right (startToEnd) -> Instant Complete
      await tester.drag(find.byType(TaskCard), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(taskProvider.allTasks.first.isCompleted, isTrue);
      expect(find.textContaining('selesai!'), findsOneWidget);
      expect(find.text('Urungkan'), findsOneWidget);

      // 2. Swipe Left (endToStart) -> Open Quick Reschedule / Delete bottom sheet
      await tester.drag(find.byType(TaskCard), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Tunda Deadline atau Hapus'), findsOneWidget);
      expect(find.text('Besok'), findsOneWidget);
      expect(find.text('Akhir Pekan'), findsOneWidget);
      expect(find.text('Minggu Depan (+7 Hari)'), findsOneWidget);
      expect(find.text('Hapus Tugas'), findsOneWidget);

      // Tap 'Besok' to reschedule task to tomorrow
      final expectedTomorrow = TaskRescheduleHelper.tomorrow(DateTime.now(), initialDue);
      await tester.tap(find.text('Besok'));
      await tester.pumpAndSettle();

      final rescheduledDue = taskProvider.allTasks.first.dueDate;
      expect(rescheduledDue.year, expectedTomorrow.year);
      expect(rescheduledDue.month, expectedTomorrow.month);
      expect(rescheduledDue.day, expectedTomorrow.day);
      expect(rescheduledDue.hour, initialDue.hour);
      expect(rescheduledDue.minute, initialDue.minute);

      // 3. Swipe Left again and tap 'Hapus Tugas'
      await tester.drag(find.byType(TaskCard), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Tugas'));
      await tester.pumpAndSettle();

      expect(taskProvider.allTasks, isEmpty);
      expect(find.text('Tidak ada tugas'), findsOneWidget);

      await tester.runAsync(() async {
        await Hive.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });
  });

  group('DailyCampusBriefingHelper & SummaryCard Smart Briefing', () {
    test('DailyCampusBriefingHelper evaluates upcomingToday, ongoing, completedToday, and next meeting number', () {
      // Tuesday (weekday == 2), Nov 24, 2026
      final subjects = [
        Subject(
          id: 'sub-calc',
          name: 'Kalkulus II',
          dayOfWeek: DateTime.tuesday,
          timeRange: '09:30-11:10',
          room: 'L.03.11',
          lecturer: 'Pak Budi',
          absences: [
            AttendanceRecord(
              id: 'a1',
              meetingNumber: 1,
              date: DateTime(2026, 11, 17),
              type: 'hadir',
            ),
          ],
        ),
        Subject(
          id: 'sub-so',
          name: 'Sistem Operasi',
          dayOfWeek: DateTime.tuesday,
          timeRange: '13:20-15:00',
          room: 'Lab Kom',
        ),
      ];

      final tasks = [
        TaskItem(
          id: 't-urgent',
          title: 'Kuis Kalkulus Bab 4',
          dueDate: DateTime(2026, 11, 24, 21, 0),
          priority: TaskPriority.high,
        ),
      ];

      // 1. Before first class (08:55 -> 35 minutes before 09:30 Kalkulus II)
      final snapMorning = DailyCampusBriefingHelper.evaluate(
        subjects: subjects,
        tasks: tasks,
        now: DateTime(2026, 11, 24, 8, 55),
      );
      expect(snapMorning.todayClasses.length, 2);
      expect(snapMorning.highlightedSubject?.id, 'sub-calc');
      expect(snapMorning.timingState, DailyClassTimingState.upcomingToday);
      expect(snapMorning.minutesUntilStart, 35);
      expect(snapMorning.nextMeetingNumber, 2); // P1 recorded -> suggests P2
      expect(snapMorning.mostUrgentTask?.id, 't-urgent');
      expect(snapMorning.dueTodayTasksCount, 1);

      // 2. During first class (10:00 -> ongoing with 70 minutes remaining until 11:10)
      final snapOngoing = DailyCampusBriefingHelper.evaluate(
        subjects: subjects,
        tasks: tasks,
        now: DateTime(2026, 11, 24, 10, 0),
      );
      expect(snapOngoing.highlightedSubject?.id, 'sub-calc');
      expect(snapOngoing.timingState, DailyClassTimingState.ongoing);
      expect(snapOngoing.minutesRemainingInClass, 70);

      // 3. After all classes today (16:00 -> completedToday on Sistem Operasi)
      final snapAfternoon = DailyCampusBriefingHelper.evaluate(
        subjects: subjects,
        tasks: tasks,
        now: DateTime(2026, 11, 24, 16, 0),
      );
      expect(snapAfternoon.highlightedSubject?.id, 'sub-so');
      expect(snapAfternoon.timingState, DailyClassTimingState.completedToday);
      expect(snapAfternoon.hasRecordedAttendanceToday, isFalse);
    });

    testWidgets('SummaryCard renders Smart Daily Campus Briefing and opens RecordAbsenceDialog on 1-tap',
        (tester) async {
      late Directory tempDir;
      late StorageService storage;
      late TaskProvider taskProvider;
      late SubjectProvider subjectProvider;

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('briefing_card_test_');
        Hive.init(tempDir.path);
        for (final boxName in [
          StorageService.tasksBoxName,
          StorageService.subjectsBoxName,
          StorageService.settingsBoxName,
          StorageService.financeBoxName,
          StorageService.financeTransactionsBoxName,
          StorageService.financeLoansBoxName,
        ]) {
          await Hive.openBox(boxName, bytes: Uint8List(0));
        }
        storage = StorageService();
        await storage.init(customPath: tempDir.path);
        await storage.setTaskRemindersEnabled(false);
        taskProvider = TaskProvider(storage);
        subjectProvider = SubjectProvider(storage);
      });

      final refNow = DateTime(2026, 11, 24, 8, 55); // Tuesday 08:55
      await subjectProvider.addSubject(
        Subject(
          id: 'sub-briefing-1',
          name: 'Struktur Data',
          dayOfWeek: DateTime.tuesday,
          timeRange: '09:30-11:10',
          room: 'L.03.11',
          lecturer: 'Pak Budi',
        ),
      );
      await taskProvider.addTask(
        TaskItem(
          id: 'task-briefing-1',
          title: 'Implementasi Binary Tree',
          dueDate: DateTime(2026, 11, 24, 22, 0),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ChangeNotifierProvider<SubjectProvider>.value(value: subjectProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SummaryCard(referenceNow: refNow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Kuliah Hari Ini'), findsOneWidget);
      expect(find.text('Struktur Data'), findsOneWidget);
      expect(find.text('Mulai dalam 35 mnt'), findsOneWidget);
      expect(find.textContaining('R. L.03.11'), findsOneWidget);
      expect(find.textContaining('Fokus Prioritas: Implementasi Binary Tree'), findsOneWidget);
      expect(find.text('Isi Presensi (P1)'), findsOneWidget);
      expect(find.text('Fokus Tugas Ini'), findsOneWidget);

      // Tap 'Isi Presensi (P1)' -> opens RecordAbsenceDialog prefilled at P1
      await tester.tap(find.text('Isi Presensi (P1)'));
      await tester.pumpAndSettle();
      expect(find.text('Catat Presensi Perkuliahan'), findsOneWidget);
      expect(find.text('Ke-1'), findsOneWidget);

      await tester.runAsync(() async {
        await Hive.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });
  });
}
