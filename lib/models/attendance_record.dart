class AttendanceRecord {
  final String id;
  final int meetingNumber; // 1 to totalMeetings (e.g. 1-16)
  final DateTime date;
  final String type; // 'hadir', 'sakit', 'izin', 'alfa'
  final String note;

  AttendanceRecord({
    required this.id,
    required this.meetingNumber,
    required this.date,
    required this.type,
    this.note = '',
  });

  bool get isAttended => type.toLowerCase() == 'hadir';

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'alfa':
      default:
        return 'Alfa';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meetingNumber': meetingNumber,
      'date': date.toIso8601String(),
      'type': type,
      'note': note,
    };
  }

  factory AttendanceRecord.fromMap(Map<dynamic, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String? ?? '',
      meetingNumber: map['meetingNumber'] as int? ?? 1,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: map['type'] as String? ?? 'alfa',
      note: map['note'] as String? ?? '',
    );
  }

  AttendanceRecord copyWith({
    String? id,
    int? meetingNumber,
    DateTime? date,
    String? type,
    String? note,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      meetingNumber: meetingNumber ?? this.meetingNumber,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}

