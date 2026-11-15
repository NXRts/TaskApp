import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import 'storage_service.dart';

/// Service untuk menjadwalkan notifikasi pengingat batas waktu (deadline) tugas
/// secara otomatis (H-1 Pukul 19:00 dan H-3 Jam sebelum deadline).
class TaskReminderService {
  static final TaskReminderService _instance = TaskReminderService._internal();
  factory TaskReminderService() => _instance;
  static TaskReminderService get instance => _instance;

  TaskReminderService._internal();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      _notificationsPlugin ??= FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'task_deadline_alarms_v2';
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

      // 3. Permintaan izin notifikasi & alarm presisi untuk Android 13+ & 14+
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();

        // Buat Android Notification Channel dengan suara raw dan prioritas tertinggi
        final androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('task_alarm'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
        await androidImpl?.createNotificationChannel(androidChannel);

        // Bersihkan channel lama jika ada agar tidak bentrok
        try {
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

  /// Menghasilkan Notification ID unik dan deterministik untuk tiap jenis alarm tugas
  /// type 0 = H-1 Hari (19:00)
  /// type 1 = H-3 Jam Darurat
  static int getNotificationId(String taskId, int type) {
    final hash = taskId.hashCode.abs() % 100000000;
    return (hash * 2) + (type == 0 ? 0 : 1);
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
      sound: const RawResourceAndroidNotificationSound('task_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: isUrgent ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      color: const Color(0xFF2563EB), // Brand cobalt
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'task_alarm.mp3',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
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
  }

  /// Jadwalkan notifikasi menggunakan zonedSchedule dengan fallback yang tangguh
  Future<void> _scheduleSingleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool isUrgent,
  }) async {
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

  /// Batalkan kedua pengingat untuk tugas tertentu
  Future<void> cancelTaskReminders(String taskId) async {
    await _safeCancel(getNotificationId(taskId, 0));
    await _safeCancel(getNotificationId(taskId, 1));
  }

  Future<void> _safeCancel(int id) async {
    try {
      await notificationsPlugin.cancel(id);
    } catch (_) {}
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
    try {
      await notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all reminders: $e');
    }
  }

  /// Kirim notifikasi uji coba langsung untuk memastikan notifikasi bekerja di HP pengguna
  Future<void> showTestNotification({bool isUrgent = false}) async {
    try {
      final details = _buildNotificationDetails(isUrgent: isUrgent);
      await notificationsPlugin.show(
        isUrgent ? 999 : 998,
        isUrgent ? '⚠️ Uji Coba: 3 Jam Menjelang Deadline' : '⏰ Uji Coba: Pengingat Tugas Besok',
        isUrgent
            ? 'Ini contoh notifikasi darurat H-3 jam batas pengumpulan tugas akademik.'
            : 'Ini contoh notifikasi H-1 pada pukul 19:00 sebelum deadline tugas.',
        details,
      );
    } catch (e) {
      debugPrint('Error showing test reminder notification: $e');
    }
  }
}
