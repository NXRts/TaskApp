import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk memutar bunyi lonceng zen dan menampilkan notifikasi
/// saat sesi fokus atau istirahat Pomodoro selesai.
class PomodoroAlertService {
  static final PomodoroAlertService _instance = PomodoroAlertService._internal();
  factory PomodoroAlertService() => _instance;
  static PomodoroAlertService get instance => _instance;

  PomodoroAlertService._internal();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  AudioPlayer? _audioPlayer;

  AudioPlayer get audioPlayer => _audioPlayer ??= AudioPlayer();
  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      _notificationsPlugin ??= FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool soundEnabled = true;
  bool notificationEnabled = true;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inisialisasi Audio Player
      await audioPlayer.setReleaseMode(ReleaseMode.stop);

      // 2. Inisialisasi Local Notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Buka TaskApp',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await notificationsPlugin.initialize(initSettings);

      // Minta izin notifikasi untuk Android 13+ (API 33+)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('PomodoroAlertService initialization error: $e');
    }
  }

  File? _cachedFocusSound;
  File? _cachedBreakSound;

  Future<bool> _playLinuxAudio(String soundFile) async {
    try {
      final isBreak = soundFile.contains('break');
      File? targetFile = isBreak ? _cachedBreakSound : _cachedFocusSound;

      if (targetFile == null || !await targetFile.exists()) {
        final byteData = await rootBundle.load('assets/$soundFile');
        final tempDir = await Directory.systemTemp.createTemp('taskapp_audio_');
        final fileName = soundFile.split('/').last;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        if (isBreak) {
          _cachedBreakSound = file;
        } else {
          _cachedFocusSound = file;
        }
        targetFile = file;
      }

      for (final cmd in ['pw-play', 'aplay', 'paplay']) {
        try {
          final res = await Process.run(cmd, [targetFile.path]);
          if (res.exitCode == 0) return true;
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Fallback Linux audio playback error: $e');
    }
    return false;
  }

  void _triggerHaptic(bool isBreak) {
    try {
      if (isBreak) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Memutar bunyi lonceng zen & getaran
  Future<void> playAlertSound({required bool isBreak}) async {
    if (!soundEnabled) return;

    final soundFile = isBreak ? 'sounds/break_complete.wav' : 'sounds/focus_complete.wav';

    // Pada Linux desktop, gunakan pemutar audio sistem native (pw-play / aplay / paplay)
    // agar terbebas dari ketergantungan plugin GStreamer (gst-plugins-good / wavparse)
    if (!kIsWeb && Platform.isLinux) {
      final played = await _playLinuxAudio(soundFile);
      if (played) {
        _triggerHaptic(isBreak);
        return;
      }
    }

    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint('Error playing sound via audioplayers: $e');
      if (!kIsWeb && Platform.isLinux) {
        await _playLinuxAudio(soundFile);
      } else {
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    }

    _triggerHaptic(isBreak);
  }

  /// Menampilkan notifikasi sistem operasi
  Future<void> showNotification({
    required bool isBreak,
    String? taskTitle,
  }) async {
    if (!notificationEnabled) return;

    final String title = isBreak ? '☕ Waktu Rehat Selesai!' : '🎉 Sesi Fokus Selesai!';
    final String body = isBreak
        ? 'Istirahat 5 menit selesai. Siap kembali fokus produktif?'
        : (taskTitle != null && taskTitle.trim().isNotEmpty
            ? 'Target "$taskTitle" 25 menit selesai! Ambil rehat 5 menit.'
            : 'Hebat! 25 menit sesi fokus selesai. Waktunya istirahat sejenak.');

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_timer_channel',
      'Timer Pomodoro',
      channelDescription: 'Notifikasi penyelesaian sesi fokus dan rehat Pomodoro',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await notificationsPlugin.show(
        isBreak ? 101 : 100,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Trigger suara & notifikasi sekaligus saat timer habis
  Future<void> notifySessionComplete({
    required bool isBreak,
    String? taskTitle,
  }) async {
    await Future.wait([
      playAlertSound(isBreak: isBreak),
      showNotification(isBreak: isBreak, taskTitle: taskTitle),
    ]);
  }

  void dispose() {
    _audioPlayer?.dispose();
  }
}
