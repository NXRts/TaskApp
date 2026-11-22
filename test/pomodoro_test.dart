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

  group('AmbientSoundGenerator & AmbientSoundService', () {
    test('generateWavBytes creates valid RIFF/WAVE PCM16 buffers and scales volume', () {
      for (final type in [
        AmbientSoundType.gentleRain,
        AmbientSoundType.quietStudy,
        AmbientSoundType.whiteNoise,
      ]) {
        final wav = AmbientSoundGenerator.generateWavBytes(
          type,
          sampleRate: 8000,
          durationSeconds: 1,
        );
        expect(wav.length, 44 + 8000 * 2);
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
        expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');

        // Verify non-silent audio payload and accurate volume scaling
        final bdFull = ByteData.sublistView(wav);
        int maxSampleFull = 0;
        for (int offset = 44; offset + 1 < wav.length; offset += 2) {
          final s = bdFull.getInt16(offset, Endian.little).abs();
          if (s > maxSampleFull) maxSampleFull = s;
        }
        expect(maxSampleFull, greaterThan(1000));

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

    test('AmbientSoundService persists track & volume and syncs with focus timer lifecycle',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('ambient_svc_test_');
      final storage = StorageService();
      await storage.init(customPath: tempDir.path);

      final ambient = AmbientSoundService.instance;
      ambient.testMode = true;
      await ambient.selectTrack(AmbientSoundType.off, storage: storage);

      expect(ambient.selectedTrack, AmbientSoundType.off);
      expect(ambient.isPlaying, isFalse);

      // Select Gentle Rain with autoPlay
      await ambient.selectTrack(
        AmbientSoundType.gentleRain,
        storage: storage,
        autoPlay: true,
      );
      expect(ambient.selectedTrack, AmbientSoundType.gentleRain);
      expect(ambient.isPlaying, isTrue);
      expect(storage.getAmbientSoundTrack(), 'gentle_rain');

      // Adjust volume -> does NOT reset playback cursor or interrupt isPlaying
      final cursorBeforeVolume = ambient.pcmReadCursor;
      expect(cursorBeforeVolume, greaterThan(0));
      await ambient.setVolume(0.4, storage: storage);
      expect(ambient.volume, closeTo(0.4, 0.001));
      expect(storage.getAmbientSoundVolume(), closeTo(0.4, 0.001));
      expect(ambient.isPlaying, isTrue);
      expect(ambient.pcmReadCursor, equals(cursorBeforeVolume));

      // Pause when focus timer stops (preserves cursor), resume advances from current cursor
      await ambient.onFocusTimerStopped();
      expect(ambient.isPlaying, isFalse);
      expect(ambient.pcmReadCursor, equals(cursorBeforeVolume));

      await ambient.onFocusTimerStarted();
      expect(ambient.isPlaying, isTrue);
      expect(ambient.pcmReadCursor, greaterThan(cursorBeforeVolume));

      // Switching to Off stops playback and resets cursor to 0
      await ambient.selectTrack(AmbientSoundType.off, storage: storage);
      expect(ambient.isPlaying, isFalse);
      expect(ambient.pcmReadCursor, equals(0));
      expect(storage.getAmbientSoundTrack(), 'off');

      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('PomodoroScreen renders Ambient Zen Soundscapes and controls playback',
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
      await ambient.selectTrack(AmbientSoundType.off, storage: storage);

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

      expect(find.text('SUARA LATAR ZEN (OFFLINE)'), findsOneWidget);
      expect(find.text('Hening'), findsOneWidget);
      expect(find.text('Hujan Lembut'), findsOneWidget);
      expect(find.text('Suasana Kafe'), findsOneWidget);
      expect(find.text('Ombak Malam'), findsOneWidget);

      // Select Hujan Lembut -> starts playing and shows subtitle + volume slider
      await tester.tap(find.text('Hujan Lembut'));
      await tester.pumpAndSettle();

      expect(ambient.selectedTrack, AmbientSoundType.gentleRain);
      expect(ambient.isPlaying, isTrue);
      expect(find.text(AmbientSoundType.gentleRain.subtitle), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);

      // Tap Aktif pill to pause ambient preview, then start Focus Timer to auto-resume
      await tester.tap(find.text('Aktif'));
      await tester.pumpAndSettle();
      expect(ambient.isPlaying, isFalse);
      expect(find.text('Putar'), findsOneWidget);

      await tester.tap(find.text('Mulai'));
      await tester.pump();
      expect(ambient.isPlaying, isTrue);

      await tester.tap(find.text('Jeda'));
      await tester.pump();
      expect(ambient.isPlaying, isFalse);

      await tester.runAsync(() async {
        await Hive.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });
  });
}
