import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:taskapp/models/pomodoro_session_record.dart';
import 'package:taskapp/models/subject.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/providers/settings_provider.dart';
import 'package:taskapp/providers/subject_provider.dart';
import 'package:taskapp/providers/task_provider.dart';
import 'package:taskapp/screens/pomodoro_screen.dart';
import 'package:taskapp/services/ambient_sound_service.dart';
import 'package:taskapp/services/pomodoro_alert_service.dart';
import 'package:taskapp/services/storage_service.dart';
import 'package:taskapp/utils/app_theme.dart';

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

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('AmbientSoundGenerator & Multi-Track AmbientSoundService', () {
    test('generateWavBytes creates valid RIFF/WAVE PCM16 buffers and scales volume', () {
      for (final track in [
        AmbientSoundTrack.rain,
        AmbientSoundTrack.fire,
        AmbientSoundTrack.cafe,
        AmbientSoundTrack.ocean,
      ]) {
        final wav = AmbientSoundGenerator.generateWavBytes(
          track,
          sampleRate: 8000,
          durationSeconds: 1,
        );
        expect(wav.length, 44 + 8000 * 2);
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
        expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');

        final bdFull = ByteData.sublistView(wav);
        int maxSampleFull = 0;
        for (int offset = 44; offset + 1 < wav.length; offset += 2) {
          final s = bdFull.getInt16(offset, Endian.little).abs();
          if (s > maxSampleFull) maxSampleFull = s;
        }
        expect(maxSampleFull, greaterThan(500));

        final halfWav = AmbientSoundGenerator.scaleWavVolume(wav, 0.5);
        final bdHalf = ByteData.sublistView(halfWav);
        int maxSampleHalf = 0;
        for (int offset = 44; offset + 1 < halfWav.length; offset += 2) {
          final s = bdHalf.getInt16(offset, Endian.little).abs();
          if (s > maxSampleHalf) maxSampleHalf = s;
        }
        expect(maxSampleHalf, closeTo(maxSampleFull * 0.5, 2.0));
      }
    });

    test('AmbientSoundService plays multiple tracks simultaneously, preserves cursor on volume change, and handles Play All / Reset',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('ambient_mixer_test_');
      final storage = StorageService();
      await storage.init(customPath: tempDir.path);

      final ambient = AmbientSoundService.instance;
      ambient.testMode = true;
      await ambient.resetAll(storage: storage);

      expect(ambient.isAnyPlaying, isFalse);
      expect(ambient.activePlayingCount, 0);
      expect(ambient.masterVolume, 1.0);

      // Play Rain and Fireplace simultaneously
      await ambient.toggleSound(AmbientSoundTrack.rain, storage: storage);
      await ambient.toggleSound(AmbientSoundTrack.fire, storage: storage);
      await ambient.toggleSound(AmbientSoundTrack.cafe, storage: storage);

      expect(ambient.isTrackPlaying(AmbientSoundTrack.rain), isTrue);
      expect(ambient.isTrackPlaying(AmbientSoundTrack.fire), isTrue);
      expect(ambient.isTrackPlaying(AmbientSoundTrack.cafe), isTrue);
      expect(ambient.isTrackPlaying(AmbientSoundTrack.ocean), isFalse);
      expect(ambient.activePlayingCount, 3);

      // Adjust volume of Rain -> does not reset cursor or stop other tracks
      final rainCursorBefore = ambient.getTrackCursor(AmbientSoundTrack.rain);
      expect(rainCursorBefore, greaterThan(0));
      await ambient.setSoundVolume(AmbientSoundTrack.rain, 0.8, storage: storage);
      expect(ambient.getTrackVolume(AmbientSoundTrack.rain), closeTo(0.8, 0.001));
      expect(ambient.getTrackCursor(AmbientSoundTrack.rain), equals(rainCursorBefore));
      expect(ambient.activePlayingCount, 3);

      // Master volume
      await ambient.setMasterVolume(0.7, storage: storage);
      expect(ambient.masterVolume, closeTo(0.7, 0.001));
      expect(storage.getAmbientMasterVolume(), closeTo(0.7, 0.001));

      // Play All activates all 9 FocEase sounds simultaneously
      await ambient.playAll();
      expect(ambient.activePlayingCount, AmbientSoundTrack.values.length);

      // Verify real-time PCM multi-track mixer sums all 9 active tracks simultaneously
      // and advances every track's sample cursor together
      await ambient.preloadAllTracks();
      final cursorsBeforeMix = <AmbientSoundTrack, int>{
        for (final t in AmbientSoundTrack.values) t: ambient.getTrackCursor(t),
      };
      final mixedPcm = ambient.mixActivePcmSamples(400);
      expect(mixedPcm.length, 400 * 2);
      for (final t in AmbientSoundTrack.values) {
        expect(ambient.getTrackCursor(t), isNot(equals(cursorsBeforeMix[t])));
      }

      // Verify seamless loop wrap-around across the end boundary without discontinuity
      await ambient.stopAll();
      await ambient.toggleSound(AmbientSoundTrack.stream);
      // Advance across a full loop cycle (200,000 effective samples for 15s @ 16kHz with 2.5s crossfade)
      final cycleChunk = ambient.mixActivePcmSamples(205000);
      expect(cycleChunk.length, 205000 * 2);
      // Cursor wrapped cleanly past the 200,000 boundary back into the start of the loop
      expect(ambient.getTrackCursor(AmbientSoundTrack.stream), lessThan(20000));

      // Pause All stops playback while preserving volumes
      await ambient.stopAll();
      expect(ambient.isAnyPlaying, isFalse);
      expect(ambient.getTrackVolume(AmbientSoundTrack.rain), closeTo(0.8, 0.001));

      // Reset All restores default 0.5 track volumes and 1.0 master volume
      await ambient.resetAll(storage: storage);
      expect(ambient.getTrackVolume(AmbientSoundTrack.rain), closeTo(0.5, 0.001));
      expect(ambient.masterVolume, closeTo(1.0, 0.001));

      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('PomodoroScreen separates Timer Pomodoro and Ambient Sounds tab and supports multi-track playback',
        (tester) async {
      late Directory tempDir;
      late StorageService storage;
      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('pomodoro_widget_test_');
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
      });

      final ambient = AmbientSoundService.instance;
      ambient.testMode = true;
      await ambient.resetAll(storage: storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TaskProvider(storage)),
            ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PomodoroScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify top section tabs exist inside Fokus screen
      expect(find.text('Pomodoro'), findsOneWidget);
      expect(find.text('Ambient'), findsOneWidget);
      expect(find.text('Statistik'), findsOneWidget);

      // Switch to Ambient tab
      await tester.tap(find.text('Ambient'));
      await tester.pumpAndSettle();

      // Verify FocEase controls and tracks are rendered
      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Reset'), findsWidgets);
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Fireplace'), findsOneWidget);
      expect(find.text('River'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('Cafe Ambience'), findsOneWidget);
      expect(find.text('Morning Birds'), findsOneWidget);

      // Tap Play All -> all 9 tracks play simultaneously and button changes to Pause All
      await tester.tap(find.text('Play All'));
      await tester.pumpAndSettle();

      expect(ambient.activePlayingCount, 9);
      expect(find.text('Pause All'), findsOneWidget);
      expect(find.text('9 Aktif'), findsOneWidget);

      // Tap Pause All -> stops all tracks
      await tester.tap(find.text('Pause All'));
      await tester.pumpAndSettle();
      expect(ambient.activePlayingCount, 0);

      await tester.runAsync(() async {
        await Hive.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });

    test('PomodoroAnalyticsHelper computes daily bar chart, streaks, heatmap, and subject breakdown', () {
      // Reference: Thursday, Nov 26, 2026
      final refDate = DateTime(2026, 11, 26, 15, 0);
      final subjects = [
        Subject(id: 'sub-calc', name: 'Kalkulus II', colorValue: 0xFF3B82F6),
        Subject(id: 'sub-algo', name: 'Struktur Data', colorValue: 0xFF10B981),
      ];

      final records = [
        // Mon Nov 23 (25m Kalkulus) -> gap on Tue Nov 24
        PomodoroSessionRecord(
          id: 'r1',
          completedAt: DateTime(2026, 11, 23, 9, 0),
          durationMinutes: 25,
          subjectId: 'sub-calc',
        ),
        // Wed Nov 25 (50m Struktur Data)
        PomodoroSessionRecord(
          id: 'r2',
          completedAt: DateTime(2026, 11, 25, 14, 0),
          durationMinutes: 50,
          subjectId: 'sub-algo',
        ),
        // Thu Nov 26 (25m Kalkulus + 25m General = 50m)
        PomodoroSessionRecord(
          id: 'r3',
          completedAt: DateTime(2026, 11, 26, 10, 0),
          durationMinutes: 25,
          subjectId: 'sub-calc',
        ),
        PomodoroSessionRecord(
          id: 'r4',
          completedAt: DateTime(2026, 11, 26, 13, 0),
          durationMinutes: 25,
          subjectId: null,
        ),
      ];

      // 1. Weekly daily minutes (Mon..Sun)
      final daily = PomodoroAnalyticsHelper.weeklyDailyMinutes(records, refDate);
      expect(daily, [25, 0, 50, 50, 0, 0, 0]);
      expect(PomodoroAnalyticsHelper.currentWeekTotalMinutes(records, refDate), 125);
      expect(PomodoroAnalyticsHelper.todayFocusMinutes(records, refDate), 50);

      // 2. Streak calculations: studied Wed Nov 25 & Thu Nov 26 -> current streak = 2, longest = 2
      expect(PomodoroAnalyticsHelper.currentStreakDays(records, refDate), 2);
      expect(PomodoroAnalyticsHelper.longestStreakDays(records), 2);

      // 3. 4-Week Heatmap Grid
      final grid = PomodoroAnalyticsHelper.buildWeeklyHeatmapGrid(records, refDate, weeksCount: 4);
      expect(grid.length, 4);
      expect(grid.last.length, 7);
      expect(grid.last[0].value, 25); // Monday
      expect(grid.last[2].value, 50); // Wednesday
      expect(grid.last[3].value, 50); // Thursday
      expect(PomodoroAnalyticsHelper.heatmapIntensityLevel(0), 0);
      expect(PomodoroAnalyticsHelper.heatmapIntensityLevel(25), 1);
      expect(PomodoroAnalyticsHelper.heatmapIntensityLevel(50), 2);
      expect(PomodoroAnalyticsHelper.heatmapIntensityLevel(75), 3);
      expect(PomodoroAnalyticsHelper.heatmapIntensityLevel(125), 4);

      // 4. Subject Breakdown: Kalkulus II (50m, 40%), Struktur Data (50m, 40%), Fokus Umum (25m, 20%)
      final breakdowns = PomodoroAnalyticsHelper.buildSubjectBreakdown(records, subjects);
      expect(breakdowns.length, 3);
      expect(breakdowns[0].totalMinutes, 50);
      expect(breakdowns[1].totalMinutes, 50);
      expect(breakdowns[2].name, 'Fokus Umum & Mandiri');
      expect(breakdowns[2].totalMinutes, 25);
      expect(breakdowns[2].percentage, closeTo(20.0, 0.1));
    });

    testWidgets('PomodoroScreen Statistik tab displays streak, daily bar chart, heatmap, and subject breakdown',
        (tester) async {
      late Directory tempDir;
      late StorageService storage;
      late SettingsProvider settingsProvider;
      late SubjectProvider subjectProvider;
      late TaskProvider taskProvider;

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('pomodoro_stats_test_');
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
        await storage.saveSubject(
          Subject(id: 'sub-jarkom', name: 'Jaringan Komputer', colorValue: 0xFF2563EB),
        );
        settingsProvider = SettingsProvider(storage);
        subjectProvider = SubjectProvider(storage);
        taskProvider = TaskProvider(storage);
      });

      await settingsProvider.recordCompletedSession(
        durationMinutes: 25,
        taskId: 't-1',
        taskTitle: 'Laporan Wireshark',
        subjectId: 'sub-jarkom',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ChangeNotifierProvider<SubjectProvider>.value(value: subjectProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PomodoroScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Statistik tab
      expect(find.text('Statistik'), findsOneWidget);
      await tester.tap(find.text('Statistik'));
      await tester.pumpAndSettle();

      // Verify Streak, Bar Chart, Heatmap, and Subject Breakdown render
      expect(find.text('Streak Belajar'), findsOneWidget);
      expect(find.text('hari beruntun'), findsOneWidget);
      expect(find.text('Menit Fokus Harian (Senin–Minggu)'), findsOneWidget);
      expect(find.text('Heatmap Konsistensi Belajar (4 Minggu)'), findsOneWidget);
      expect(find.text('Alokasi Jam Belajar per Mata Kuliah'), findsOneWidget);
      expect(find.text('Jaringan Komputer'), findsOneWidget);

      await tester.runAsync(() async {
        await Hive.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });
  });
}
