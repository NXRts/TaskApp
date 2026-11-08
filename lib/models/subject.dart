import 'package:flutter/material.dart';

class Subject {
  final String id;
  String name;
  String code;
  String lecturer;
  String room;
  int colorValue;
  int creditHours; // SKS
  int? dayOfWeek; // 1 = Senin, 7 = Minggu
  String? timeRange;

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
  });

  Color get color => Color(colorValue);

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
    );
  }
}

