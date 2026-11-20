import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:taskapp/models/subject.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/providers/subject_provider.dart';
import 'package:taskapp/providers/task_provider.dart';
import 'package:taskapp/screens/calendar_screen.dart';
import 'package:taskapp/services/storage_service.dart';
import 'package:taskapp/utils/app_theme.dart';
import 'package:taskapp/widgets/monthly_calendar_grid.dart';

void main() {
  group('MonthlyCalendarHelper', () {
    test('buildMonthGridDays generates Monday-first full weeks', () {
      // November 2026 starts on Sunday (leading 6 days: Oct 26..31) -> 6 weeks (42 cells)
      final novDays = MonthlyCalendarHelper.buildMonthGridDays(DateTime(2026, 11, 1));
      expect(novDays.length, 42);
      expect(novDays.first, DateTime(2026, 10, 26));
      expect(novDays.first.weekday, DateTime.monday);
      expect(novDays.last, DateTime(2026, 12, 6));
      expect(novDays.last.weekday, DateTime.sunday);

      // February 2021 starts on Monday and has 28 days -> exactly 4 weeks (28 cells)
      final feb2021Days = MonthlyCalendarHelper.buildMonthGridDays(DateTime(2021, 2, 1));
      expect(feb2021Days.length, 28);
      expect(feb2021Days.first, DateTime(2021, 2, 1));
      expect(feb2021Days.last, DateTime(2021, 2, 28));

      // Leap year February 2024 starts on Thursday -> 5 weeks (35 cells)
      final feb2024Days = MonthlyCalendarHelper.buildMonthGridDays(DateTime(2024, 2, 1));
      expect(feb2024Days.length, 35);
      expect(feb2024Days.contains(DateTime(2024, 2, 29)), isTrue);
    });

    test('getTaskMarkerColors prioritizes urgent/incomplete tasks and caps at 3', () {
      final futureBase = DateTime.now().add(const Duration(days: 10));
      final tasks = [
        TaskItem(
          id: 't-done',
          title: 'Selesai',
          dueDate: futureBase,
          isCompleted: true,
          priority: TaskPriority.high,
        ),
        TaskItem(
          id: 't-low',
          title: 'Rendah',
          dueDate: futureBase,
          priority: TaskPriority.low,
        ),
        TaskItem(
          id: 't-med',
          title: 'Sedang',
          dueDate: futureBase,
          priority: TaskPriority.medium,
        ),
        TaskItem(
          id: 't-high',
          title: 'Tinggi',
          dueDate: futureBase,
          priority: TaskPriority.high,
        ),
      ];

      final colors = MonthlyCalendarHelper.getTaskMarkerColors(tasks);
      expect(colors.length, 3);
      expect(colors[0], AppTheme.urgentRose);
      expect(colors[1], AppTheme.warningOchre);
      expect(colors[2], AppTheme.brandCobalt);

      // Completed-only day returns sage
      final doneColors = MonthlyCalendarHelper.getTaskMarkerColors([tasks.first]);
      expect(doneColors, [AppTheme.successSage]);
    });

    test('getSubjectMarkerColors returns up to 2 unique subject colors', () {
      final subjects = [
        Subject(id: 's1', name: 'Kalkulus', colorValue: 0xFF3B82F6, dayOfWeek: 1),
        Subject(id: 's2', name: 'Algoritma', colorValue: 0xFF3B82F6, dayOfWeek: 1),
        Subject(id: 's3', name: 'Basis Data', colorValue: 0xFF10B981, dayOfWeek: 1),
        Subject(id: 's4', name: 'Sistem Operasi', colorValue: 0xFFF59E0B, dayOfWeek: 1),
      ];

      final colors = MonthlyCalendarHelper.getSubjectMarkerColors(subjects);
      expect(colors.length, 2);
      expect(colors[0], const Color(0xFF3B82F6));
      expect(colors[1], const Color(0xFF10B981));
    });
  });

  group('MonthlyCalendarGrid & CalendarScreen integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('calendar_test_');
      Hive.init(tempDir.path);
      // Pre-open boxes with in-memory backend so widget tests avoid dart:io file locks inside FakeAsync.
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
      await StorageService().init(customPath: tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('MonthlyCalendarGrid renders weekday headers, task count, and handles date tap',
        (tester) async {
      DateTime? tappedDate;
      final focusedMonth = DateTime(2026, 11, 1);
      final selectedDate = DateTime(2026, 11, 20);
      final tasks = [
        TaskItem(
          id: 'task-nov-1',
          title: 'Makalah Etika',
          dueDate: DateTime(2026, 11, 25, 23, 59),
          priority: TaskPriority.high,
        ),
      ];
      final subjects = [
        Subject(
          id: 'sub-1',
          name: 'Pemrograman Mobile',
          dayOfWeek: DateTime.friday,
          timeRange: '08:00-10:00',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MonthlyCalendarGrid(
              focusedMonth: focusedMonth,
              selectedDate: selectedDate,
              today: selectedDate,
              tasks: tasks,
              subjects: subjects,
              onDateSelected: (d) => tappedDate = d,
            ),
          ),
        ),
      );

      for (final header in MonthlyCalendarHelper.weekdayHeaders) {
        expect(find.text(header), findsOneWidget);
      }
      expect(find.text('1 tugas bulan ini'), findsOneWidget);
      expect(find.text('Kuliah'), findsOneWidget);

      await tester.tap(find.text('25'));
      await tester.pump();
      expect(tappedDate, DateTime(2026, 11, 25));
    });

    testWidgets('CalendarScreen toggles between Strip and Bulanan view and persists preference',
        (tester) async {
      final storage = StorageService.instance;
      final taskProvider = TaskProvider(storage);
      final subjectProvider = SubjectProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ChangeNotifierProvider<SubjectProvider>.value(value: subjectProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default mode is Horizontal Strip
      expect(find.text('Strip'), findsOneWidget);
      expect(find.text('Bulanan'), findsOneWidget);
      expect(find.byType(MonthlyCalendarGrid), findsNothing);

      // Switch to Monthly Grid View
      await tester.tap(find.text('Bulanan'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyCalendarGrid), findsOneWidget);
      expect(storage.getIsMonthlyCalendarView(), isTrue);

      // Switch back to Horizontal Strip
      await tester.tap(find.text('Strip'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyCalendarGrid), findsNothing);
      expect(storage.getIsMonthlyCalendarView(), isFalse);
    });

    testWidgets('CalendarScreen aligns 23:00-24:00 labels evenly and keeps 23:59 tasks above 24:00 line',
        (tester) async {
      final storage = StorageService.instance;
      await storage.setTaskRemindersEnabled(false);
      final now = DateTime.now();
      await storage.saveTask(
        TaskItem(
          id: 'task-2359',
          title: 'Membuat Video EAP',
          dueDate: DateTime(now.year, now.month, now.day, 23, 59),
          priority: TaskPriority.medium,
        ),
      );
      final taskProvider = TaskProvider(storage);
      final subjectProvider = SubjectProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ChangeNotifierProvider<SubjectProvider>.value(value: subjectProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // CalendarScreen delegates the main FAB to MainScreen (no duplicate FAB)
      expect(find.byType(FloatingActionButton), findsNothing);

      // Hour labels 23:00 and 24:00 must be spaced by exactly _hourHeight (62.0)
      final y23 = tester.getCenter(find.text('23:00')).dy;
      final y24 = tester.getCenter(find.text('24:00')).dy;
      expect(y24 - y23, moreOrLessEquals(62.0, epsilon: 0.5));

      // Task due at 23:59 stays within the 23:00-24:00 slot and does not cross 24:00
      final cardFinder = find.ancestor(
        of: find.text('Membuat Video EAP'),
        matching: find.byType(GestureDetector),
      );
      final cardRect = tester.getRect(cardFinder.first);
      expect(cardRect.bottom, lessThanOrEqualTo(y24 + 0.5));
      expect(find.text('23:59'), findsOneWidget);
    });
  });
}
