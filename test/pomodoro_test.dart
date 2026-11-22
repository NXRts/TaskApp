import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/providers/settings_provider.dart';
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
      expect(find.text('Timer Pomodoro'), findsOneWidget);
      expect(find.text('Ambient Sounds'), findsWidgets);

      // Switch to Ambient Sounds tab
      await tester.tap(find.text('Ambient Sounds').first);
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
  });
}
