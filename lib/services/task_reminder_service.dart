import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import 'pomodoro_alert_service.dart';
import 'storage_service.dart';

/// Hasil pengujian pengiriman notifikasi sistem
class NotificationTestResult {
  final bool success;
  final String message;
  final String? errorDetail;
  final bool isPermissionDenied;

  const NotificationTestResult({
    required this.success,
    required this.message,
    this.errorDetail,
    this.isPermissionDenied = false,
  });
}

/// Service untuk menjadwalkan notifikasi pengingat batas waktu (deadline) tugas
/// secara otomatis (H-1 Pukul 19:00 dan H-3 Jam sebelum deadline).
class TaskReminderService {
  static final TaskReminderService _instance = TaskReminderService._internal();
  factory TaskReminderService() => _instance;
  static TaskReminderService get instance => _instance;

  TaskReminderService._internal();

  /// Global Navigator Key untuk menampilkan floating in-app banner
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const MethodChannel _settingsChannel = MethodChannel('com.taskapp.taskapp/settings');

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      _notificationsPlugin ??= FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'task_deadline_alarms_v3';
  static const String channelName = 'Pengingat Deadline Tugas';
  static const String channelDescription =
      'Notifikasi pengingat H-1 dan H-3 jam sebelum deadline tugas akademik';

  static bool _timeZonesInitialized = false;

  /// Memastikan database zona waktu telah terinisialisasi
  static void ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      _timeZonesInitialized = true;
    } catch (_) {}
  }

  /// Inisialisasi plugin notifikasi dan zona waktu lokal
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inisialisasi Zona Waktu
      ensureTimeZonesInitialized();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        debugPrint('TaskReminderService: timezone lookup fallback, using local: $e');
      }

      // 2. Inisialisasi Plugin Local Notifications
      const androidSettings = AndroidInitializationSettings('app_icon');
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

      // 3. Permintaan izin notifikasi & alarm presisi untuk Android 13+ & 14+
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();

        // Buat Android Notification Channel dengan prioritas tertinggi dan getaran
        const androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidImpl?.createNotificationChannel(androidChannel);

        // Bersihkan channel versi lama jika ada agar konfigurasi mutakhir diterapkan
        try {
          await androidImpl?.deleteNotificationChannel('task_deadline_alarms_v2');
          await androidImpl?.deleteNotificationChannel('task_deadline_channel');
        } catch (_) {}
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('TaskReminderService initialization error: $e');
    }
  }

  /// Menghitung waktu pengingat H-1 (sehari sebelum dueDate pada pukul 19:00)
  static DateTime calculateH1ReminderTime(DateTime dueDate) {
    final previousDay = dueDate.subtract(const Duration(days: 1));
    return DateTime(previousDay.year, previousDay.month, previousDay.day, 19, 0, 0);
  }

  /// Menghitung waktu pengingat darurat H-3 Jam sebelum deadline
  static DateTime calculateH3HoursReminderTime(DateTime dueDate) {
    return dueDate.subtract(const Duration(hours: 3));
  }

  /// Menghitung waktu pengingat kritis H-30 Menit sebelum deadline
  static DateTime calculateH30MinutesReminderTime(DateTime dueDate) {
    return dueDate.subtract(const Duration(minutes: 30));
  }

  /// Menghasilkan Notification ID unik dan deterministik untuk tiap jenis alarm tugas
  /// type 0 = H-1 Hari (19:00)
  /// type 1 = H-3 Jam Darurat
  /// type 2 = H-30 Menit Kritis
  static int getNotificationId(String taskId, int type) {
    final hash = taskId.hashCode.abs() % 10000000;
    return (hash * 3) + type;
  }

  /// Membuka halaman pengaturan notifikasi aplikasi di sistem Android
  static Future<bool> openAppNotificationSettings() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _settingsChannel.invokeMethod<bool>('openNotificationSettings');
        return result ?? false;
      } catch (e) {
        debugPrint('Error opening notification settings: $e');
      }
    }
    return false;
  }

  /// Detail konfigurasi notifikasi Android & iOS
  NotificationDetails _buildNotificationDetails({bool isUrgent = false}) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: 'app_icon',
      visibility: NotificationVisibility.public,
      ticker: 'Pengingat Deadline Tugas',
      color: const Color(0xFF2563EB), // Brand cobalt
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      presentBadge: true,
      presentList: true,
      sound: 'task_alarm.mp3',
    );

    const linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
      timeout: LinuxNotificationTimeout(5000),
      defaultActionName: 'Buka TaskApp',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );
  }

  /// Jadwalkan pengingat deadline untuk satu tugas
  Future<void> scheduleTaskReminders(TaskItem task, {String? subjectName}) async {
    // Jika tugas sudah selesai, batalkan seluruh pengingat yang ada
    if (task.isCompleted) {
      await cancelTaskReminders(task.id);
      return;
    }

    final storage = StorageService.instance;
    // Periksa apakah fitur pengingat diaktifkan di pengaturan pengguna
    if (!storage.getTaskRemindersEnabled()) {
      await cancelTaskReminders(task.id);
      return;
    }

    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('d MMM');
    final formattedDue = '${dateFormat.format(task.dueDate)} pukul ${timeFormat.format(task.dueDate)}';
    final matkulInfo = subjectName != null && subjectName.trim().isNotEmpty ? ' ($subjectName)' : '';

    // 1. Jadwalkan Pengingat H-1 (Pukul 19:00 sehari sebelum deadline)
    final h1Id = getNotificationId(task.id, 0);
    if (storage.getReminderH1Enabled()) {
      final h1Time = calculateH1ReminderTime(task.dueDate);
      if (h1Time.isAfter(now)) {
        await _scheduleSingleZonedNotification(
          id: h1Id,
          title: '⏰ Pengingat Tugas Besok: ${task.title}',
          body: 'Tugas "${task.title}"$matkulInfo jatuh tempo besok ($formattedDue). Jangan lupa diselesaikan!',
          scheduledTime: h1Time,
          isUrgent: false,
        );
      } else {
        await _safeCancel(h1Id);
      }
    } else {
      await _safeCancel(h1Id);
    }

    // 2. Jadwalkan Pengingat Darurat H-3 Jam (Tepat 3 jam sebelum deadline)
    final h3Id = getNotificationId(task.id, 1);
    if (storage.getReminderH3HoursEnabled()) {
      final h3Time = calculateH3HoursReminderTime(task.dueDate);
      if (h3Time.isAfter(now)) {
        await _scheduleSingleZonedNotification(
          id: h3Id,
          title: '⚠️ 3 Jam Menjelang Deadline: ${task.title}',
          body: 'Batas waktu pengumpulan tugas "${task.title}"$matkulInfo pukul ${timeFormat.format(task.dueDate)} hari ini!',
          scheduledTime: h3Time,
          isUrgent: true,
        );
      } else {
        await _safeCancel(h3Id);
      }
    } else {
      await _safeCancel(h3Id);
    }

    // 3. Jadwalkan Pengingat Kritis H-30 Menit (Tepat 30 menit sebelum deadline)
    final h30mId = getNotificationId(task.id, 2);
    if (storage.getReminderH30MinutesEnabled()) {
      final h30mTime = calculateH30MinutesReminderTime(task.dueDate);
      if (h30mTime.isAfter(now)) {
        await _scheduleSingleZonedNotification(
          id: h30mId,
          title: '🚨 30 Menit Menjelang Deadline: ${task.title}',
          body: 'Segera kumpulkan! Waktu tersisa 30 menit lagi untuk tugas "${task.title}"$matkulInfo.',
          scheduledTime: h30mTime,
          isUrgent: true,
        );
      } else {
        await _safeCancel(h30mId);
      }
    } else {
      await _safeCancel(h30mId);
    }
  }

  /// Map timer aktif untuk penjadwalan presisi di lingkungan Desktop (Linux/Windows)
  /// dan pemantauan aktif saat aplikasi sedang berjalan.
  static final Map<int, Timer> _activeTimers = {};

  static int get activeTimersCount => _activeTimers.length;

  /// Jadwalkan notifikasi menggunakan in-memory timer (untuk Desktop Linux/Windows & Foreground)
  /// serta zonedSchedule untuk Android/iOS/macOS
  Future<void> _scheduleSingleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool isUrgent,
  }) async {
    // 1. Kelola In-Memory Timer (selalu aktif untuk Desktop Linux/Windows & saat aplikasi aktif)
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);

    final now = DateTime.now();
    final duration = scheduledTime.difference(now);
    if (!duration.isNegative) {
      _activeTimers[id] = Timer(duration, () async {
        _activeTimers.remove(id);
        await _triggerReminderNotification(
          id: id,
          title: title,
          body: body,
          isUrgent: isUrgent,
        );
      });
      debugPrint('TaskReminderService: Timer didaftarkan untuk ID $id, akan berbunyi dalam ${duration.inSeconds} detik (pada $scheduledTime)');
    }

    // 2. Jika di Android / iOS / macOS, daftarkan juga ke sistem AlarmManager native
    // agar dapat membangunkan perangkat meskipun aplikasi ditutup total
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        ensureTimeZonesInitialized();
        final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
        final details = _buildNotificationDetails(isUrgent: isUrgent);

        try {
          await notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tzTime,
            details,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          if (e is Error && e.toString().contains('_instance')) {
            // Unit test headless environment without native notification channels
            return;
          }
          // Fallback jika mode alarmClock ditolak, gunakan exactAllowWhileIdle
          try {
            await notificationsPlugin.zonedSchedule(
              id,
              title,
              body,
              tzTime,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          } catch (_) {
            // Fallback terakhir: inexactAllowWhileIdle
            try {
              await notificationsPlugin.zonedSchedule(
                id,
                title,
                body,
                tzTime,
                details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
              );
            } catch (_) {}
          }
        }
      } catch (e) {
        if (e is Error && e.toString().contains('_instance')) return;
        debugPrint('Error scheduling task reminder notification (id: $id): $e');
      }
    }
  }

  /// Memicu eksekusi notifikasi alarm deadline secara langsung (suara + libnotify OS + in-app banner)
  Future<void> _triggerReminderNotification({
    required int id,
    required String title,
    required String body,
    required bool isUrgent,
  }) async {
    // 1. Bunyikan alarm suara native sistem
    try {
      await _playDirectAlarmSound();
    } catch (_) {}

    // 2. Kirim notifikasi sistem operasi (bekerja di Linux desktop via libnotify dan Android)
    try {
      final details = _buildNotificationDetails(isUrgent: isUrgent);
      await notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Error showing reminder notification via show(): $e');
    }

    // 3. Khusus Linux Desktop, panggil notify-send dengan auto-dismiss 5 detik
    if (!kIsWeb && Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-t',
          '5000',
          '-u',
          isUrgent ? 'critical' : 'normal',
          '-a',
          'TaskApp',
          title,
          body,
        ]);
      } catch (_) {}
    }

    // 4. Tampilkan banner mengambang (floating banner) di atas layar aplikasi
    showInAppFloatingBanner(
      title: title,
      body: body,
      isUrgent: isUrgent,
    );
  }

  /// Batalkan ketiga pengingat untuk tugas tertentu
  Future<void> cancelTaskReminders(String taskId) async {
    await _safeCancel(getNotificationId(taskId, 0));
    await _safeCancel(getNotificationId(taskId, 1));
    await _safeCancel(getNotificationId(taskId, 2));
  }

  Future<void> _safeCancel(int id) async {
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);
    try {
      await notificationsPlugin.cancel(id);
    } catch (e) {
      if (e is Error && e.toString().contains('_instance')) return;
    }
  }

  /// Sinkronkan dan perbarui seluruh alarm untuk daftar tugas yang ada
  Future<void> syncAllTaskReminders(
    List<TaskItem> tasks,
    Map<String, String> subjectNames,
  ) async {
    final storage = StorageService.instance;
    if (!storage.getTaskRemindersEnabled()) {
      await cancelAllReminders();
      return;
    }

    for (final task in tasks) {
      if (task.isCompleted) {
        await cancelTaskReminders(task.id);
      } else {
        final subjectName = task.subjectId != null ? subjectNames[task.subjectId] : null;
        await scheduleTaskReminders(task, subjectName: subjectName);
      }
    }
  }

  /// Batalkan seluruh alarm tugas
  Future<void> cancelAllReminders() async {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    try {
      await notificationsPlugin.cancelAll();
    } catch (e) {
      if (e is Error && e.toString().contains('_instance')) return;
      debugPrint('Error canceling all reminders: $e');
    }
  }

  static OverlayEntry? _activeBannerEntry;

  /// Menampilkan banner notifikasi mengambang (floating banner) di bagian atas layar
  /// saat aplikasi sedang terbuka / aktif di latar depan
  static void showInAppFloatingBanner({
    required String title,
    required String body,
    bool isUrgent = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    // Hapus banner aktif jika ada sebelumnya
    _activeBannerEntry?.remove();
    _activeBannerEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _FloatingBannerWidget(
          title: title,
          body: body,
          isUrgent: isUrgent,
          isDark: isDark,
          onDismiss: () {
            if (_activeBannerEntry == entry) {
              entry.remove();
              _activeBannerEntry = null;
            }
          },
        );
      },
    );

    _activeBannerEntry = entry;
    overlayState.insert(entry);

    // Otomatis hilangkan setelah durasi tertentu
    Future.delayed(duration, () {
      if (_activeBannerEntry == entry) {
        entry.remove();
        _activeBannerEntry = null;
      }
    });
  }

  AudioPlayer? _testAudioPlayer;
  AudioPlayer get testAudioPlayer => _testAudioPlayer ??= AudioPlayer();

  /// Memutar bunyi lonceng alarm secara langsung melalui audioplayer atau audio native
  Future<void> _playDirectAlarmSound() async {
    try {
      if (!kIsWeb && Platform.isLinux) {
        // Pada Linux Desktop gunakan pemutar audio native sistem (pw-play / aplay / paplay)
        // untuk mencegah galat GStreamer plugin missing
        await PomodoroAlertService.instance.playAlertSound(isBreak: false);
        return;
      }
      await testAudioPlayer.stop();
      await testAudioPlayer.play(AssetSource('sounds/focus_complete.wav'));
    } catch (e) {
      debugPrint('Error playing direct alarm sound: $e');
    }
  }

  /// Kirim notifikasi uji coba langsung untuk memastikan notifikasi bekerja di HP / sistem pengguna
  /// type 0: H-1 Hari
  /// type 1: H-3 Jam
  /// type 2: H-30 Menit
  Future<NotificationTestResult> showTestNotification({
    int type = 0,
    bool? isUrgent,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final effectiveType = isUrgent != null ? (isUrgent ? 1 : 0) : type;

    // 0. Periksa izin notifikasi sistem pada Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final areEnabled = await androidImpl?.areNotificationsEnabled();
      if (areEnabled == false) {
        final granted = await androidImpl?.requestNotificationsPermission();
        if (granted != true) {
          debugPrint('Notification permission is not granted on Android');
          return const NotificationTestResult(
            success: false,
            message: 'Izin notifikasi dinonaktifkan di sistem HP Anda.',
            isPermissionDenied: true,
          );
        }
      }
    }

    final String title;
    final String body;
    final bool urgent;
    final int notifId;
    if (effectiveType == 2) {
      title = '🚨 30 Menit Menjelang Deadline';
      body = 'Contoh: Segera kumpulkan! Waktu tersisa 30 menit lagi untuk tugas "Praktikum Sistem Operasi".';
      urgent = true;
      notifId = 997;
    } else if (effectiveType == 1) {
      title = '⚠️ 3 Jam Menjelang Deadline';
      body = 'Contoh: Batas waktu tugas "Praktikum Sistem Operasi" pukul 23:59 hari ini!';
      urgent = true;
      notifId = 999;
    } else {
      title = '⏰ Pengingat Tugas Besok';
      body = 'Contoh: Tugas "Algoritma Pemrograman" jatuh tempo besok pukul 19:00.';
      urgent = false;
      notifId = 998;
    }

    // 1. Putar bunyi alarm secara langsung di HP / PC pengguna
    try {
      await _playDirectAlarmSound();
    } catch (_) {}

    // 2. Kirim notifikasi resmi sistem operasi native (muncul di luar aplikasi / panel kontrol HP)
    bool shown = false;
    String? errorDetail;
    try {
      final details = _buildNotificationDetails(isUrgent: urgent);
      await notificationsPlugin.show(
        notifId,
        title,
        body,
        details,
      );
      shown = true;
    } catch (e) {
      debugPrint('Error showing test reminder system notification: $e');
      errorDetail = e.toString();
      // Fallback: coba kirim notifikasi standar tanpa parameter tambahan
      try {
        const fallbackDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: 'app_icon',
          ),
          linux: LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.normal,
            timeout: LinuxNotificationTimeout(5000),
            defaultActionName: 'Buka TaskApp',
          ),
        );
        await notificationsPlugin.show(
          notifId,
          title,
          body,
          fallbackDetails,
        );
        shown = true;
        errorDetail = null;
      } catch (e2) {
        debugPrint('Fallback notification also failed: $e2');
        errorDetail = e2.toString();
      }
    }

    // 3. Khusus Linux Desktop, panggil juga notify-send dengan timeout 5 detik agar otomatis menghilang
    if (!kIsWeb && Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-t',
          '5000',
          '-u',
          'normal',
          '-a',
          'TaskApp',
          title,
          body,
        ]);
        shown = true;
      } catch (_) {}
    }

    if (shown) {
      final label = effectiveType == 2
          ? 'H-30 menit'
          : (effectiveType == 1 ? 'H-3 jam' : 'H-1');
      return NotificationTestResult(
        success: true,
        message: 'Notifikasi uji coba $label dikirimkan ke panel kontrol sistem!',
      );
    } else {
      return NotificationTestResult(
        success: false,
        message: 'Gagal mengirim notifikasi: ${errorDetail ?? "Kesalahan tidak diketahui"}',
        errorDetail: errorDetail,
      );
    }
  }
}

/// Widget banner mengambang (floating banner) dengan animasi slide & fade dari atas layar
class _FloatingBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final bool isUrgent;
  final bool isDark;
  final VoidCallback onDismiss;

  const _FloatingBannerWidget({
    required this.title,
    required this.body,
    required this.isUrgent,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<_FloatingBannerWidget> createState() => _FloatingBannerWidgetState();
}

class _FloatingBannerWidgetState extends State<_FloatingBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  void _dismiss() async {
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bgCol = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = widget.isUrgent
        ? Colors.amber.shade700
        : (widget.isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB));
    final iconCol = widget.isUrgent
        ? const Color(0xFFD97706)
        : (widget.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));
    final textCol = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Positioned(
      top: topPadding + 10,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconCol.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isUrgent
                            ? Icons.warning_amber_rounded
                            : Icons.notifications_active_rounded,
                        color: iconCol,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: textCol,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconCol.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.isUrgent ? 'DARURAT' : 'PENGINGAT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: iconCol,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.body,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: subTextCol,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: subTextCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
