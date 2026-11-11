import 'package:flutter/material.dart';
import 'attendance_record.dart';

enum AttendanceStatus {
  safe,     // 🟢 Aman (0-1 kali alfa/absen)
  warning,  // 🟡 Waspada (2-3 kali alfa/absen)
  critical, // 🔴 Kritis (>= 4 kali alfa/absen)
}

class Subject implements Comparable<Subject> {
  final String id;
  String name;
  String code;
  String lecturer;
  String room;
  int colorValue;
  int creditHours; // SKS
  int? dayOfWeek; // 1 = Senin, 7 = Minggu
  String? timeRange;
  int totalMeetings; // Preset default 16 pertemuan per semester
  List<AttendanceRecord> absences;

  Subject({
    required this.id,
    required this.name,
    this.code = '',
    this.lecturer = '',
    this.room = '',
    this.colorValue = 0xFF4F46E5, // Default indigo
    this.creditHours = 3,
    this.dayOfWeek,
    this.timeRange,
    this.totalMeetings = 16,
    List<AttendanceRecord>? absences,
  }) : absences = absences ?? [];

  Color get color => Color(colorValue);

  /// Menghitung menit awal dari timeRange (misal: "09.30-12.00" -> 570 menit)
  int get startMinutes {
    if (timeRange == null || timeRange!.trim().isEmpty) return 9999;
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(timeRange!);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!) ?? 0;
      final minute = int.tryParse(match.group(2)!) ?? 0;
      return hour * 60 + minute;
    }
    final hourOnly = RegExp(r'(\d{1,2})').firstMatch(timeRange!);
    if (hourOnly != null) {
      final hour = int.tryParse(hourOnly.group(1)!) ?? 0;
      return hour * 60;
    }
    return 9999;
  }

  @override
  int compareTo(Subject other) {
    // 1. Urutkan berdasarkan hari (1 = Senin .. 7 = Minggu). Yang belum ada hari di paling bawah.
    final dayA = dayOfWeek ?? 999;
    final dayB = other.dayOfWeek ?? 999;
    if (dayA != dayB) {
      return dayA.compareTo(dayB);
    }

    // 2. Urutkan berdasarkan jam mulai (menit ke-0 s/d 1439). Yang belum ada jam di paling bawah.
    final timeA = startMinutes;
    final timeB = other.startMinutes;
    if (timeA != timeB) {
      return timeA.compareTo(timeB);
    }

    // 3. Fallback: urutkan berdasarkan nama mata kuliah (A-Z)
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Tidak Ditentukan';
    }
  }

  // --- ATTENDANCE SENTINEL METRICS ---

  int get totalAbsences => absences.length;
  int get attendedMeetings => (totalMeetings - totalAbsences).clamp(0, totalMeetings);
  double get attendancePercentage => totalMeetings > 0
      ? (attendedMeetings / totalMeetings) * 100
      : 100.0;
  int get maxAllowedAbsences => (totalMeetings * 0.25).floor(); // Default 4 untuk 16 pertemuan
  int get remainingAbsenceQuota => (maxAllowedAbsences - totalAbsences).clamp(0, maxAllowedAbsences);

  /// Status Kehadiran Sesuai Aturan Kampus:
  /// 🟢 Aman: 0–1 kali alfa/absen
  /// 🟡 Waspada: 2–3 kali alfa/absen ("Sisa kuota izin Anda tinggal 1 kali")
  /// 🔴 Kritis: >= 4 kali alfa/absen ("Batas 75% terlampaui! Anda berisiko dilarang ikut UAS")
  AttendanceStatus get attendanceStatus {
    if (totalAbsences >= maxAllowedAbsences) {
      return AttendanceStatus.critical;
    } else if (totalAbsences >= 2) {
      return AttendanceStatus.warning;
    } else {
      return AttendanceStatus.safe;
    }
  }

  AttendanceRecord? getAbsenceForMeeting(int meetingNumber) {
    try {
      return absences.firstWhere((a) => a.meetingNumber == meetingNumber);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'lecturer': lecturer,
      'room': room,
      'colorValue': colorValue,
      'creditHours': creditHours,
      'dayOfWeek': dayOfWeek,
      'timeRange': timeRange,
      'totalMeetings': totalMeetings,
      'absences': absences.map((a) => a.toMap()).toList(),
    };
  }

  factory Subject.fromMap(Map<dynamic, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Tanpa Nama',
      code: map['code'] as String? ?? '',
      lecturer: map['lecturer'] as String? ?? '',
      room: map['room'] as String? ?? '',
      colorValue: map['colorValue'] as int? ?? 0xFF4F46E5,
      creditHours: map['creditHours'] as int? ?? 3,
      dayOfWeek: map['dayOfWeek'] as int?,
      timeRange: map['timeRange'] as String?,
      totalMeetings: map['totalMeetings'] as int? ?? 16,
      absences: (map['absences'] as List?)
              ?.map((a) => AttendanceRecord.fromMap(a as Map))
              .toList() ??
          [],
    );
  }

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? lecturer,
    String? room,
    int? colorValue,
    int? creditHours,
    int? dayOfWeek,
    String? timeRange,
    int? totalMeetings,
    List<AttendanceRecord>? absences,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      colorValue: colorValue ?? this.colorValue,
      creditHours: creditHours ?? this.creditHours,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeRange: timeRange ?? this.timeRange,
      totalMeetings: totalMeetings ?? this.totalMeetings,
      absences: absences ?? this.absences,
    );
  }
}

