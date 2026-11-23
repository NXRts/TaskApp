import 'subject.dart';

/// Immutable record of a single completed Pomodoro focus session.
/// Stored 100% offline inside Hive (`settings_box_v1`) under `pomodoro_session_records`.
class PomodoroSessionRecord {
  final String id;
  final DateTime completedAt;
  final int durationMinutes;
  final String? taskId;
  final String? taskTitle;
  final String? subjectId;

  const PomodoroSessionRecord({
    required this.id,
    required this.completedAt,
    this.durationMinutes = 25,
    this.taskId,
    this.taskTitle,
    this.subjectId,
  });

  /// Normalized local calendar date (`YYYY-MM-DD`, time stripped).
  DateTime get dayOnly =>
      DateTime(completedAt.year, completedAt.month, completedAt.day);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'subjectId': subjectId,
    };
  }

  factory PomodoroSessionRecord.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['completedAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    final rawDuration = map['durationMinutes'];
    final duration = (rawDuration is int && rawDuration > 0)
        ? rawDuration
        : (rawDuration is num && rawDuration > 0 ? rawDuration.toInt() : 25);

    return PomodoroSessionRecord(
      id: (map['id'] ?? 'pomo-${parsedDate.millisecondsSinceEpoch}').toString(),
      completedAt: parsedDate,
      durationMinutes: duration,
      taskId: map['taskId']?.toString(),
      taskTitle: map['taskTitle']?.toString(),
      subjectId: map['subjectId']?.toString(),
    );
  }
}

/// Aggregated focus time breakdown for a single academic subject (or general study).
class SubjectStudyBreakdown {
  final String? subjectId;
  final String name;
  final int colorValue;
  final int totalMinutes;
  final int sessionsCount;
  final double percentage;

  const SubjectStudyBreakdown({
    required this.subjectId,
    required this.name,
    required this.colorValue,
    required this.totalMinutes,
    required this.sessionsCount,
    required this.percentage,
  });
}

/// Pure calculation engine for Pomodoro Academic Analytics:
/// - Daily bar chart minutes (Monday–Sunday of the reference week)
/// - Current & longest consecutive study streaks
/// - Multi-week consistency heatmap grid (4 weeks / 28 days)
/// - Per-subject focus duration breakdown
class PomodoroAnalyticsHelper {
  static const List<String> weekdayShortLabels = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns the Monday of the week containing [referenceDate].
  static DateTime startOfWeekMonday(DateTime referenceDate) {
    final normalized = dateOnly(referenceDate);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  /// Aggregates total focus minutes for each day of the current week (Monday = index 0 .. Sunday = index 6).
  static List<int> weeklyDailyMinutes(
    List<PomodoroSessionRecord> records,
    DateTime referenceDate,
  ) {
    final monday = startOfWeekMonday(referenceDate);
    final buckets = List<int>.filled(7, 0);

    for (final rec in records) {
      final d = rec.dayOnly;
      final diffDays = d.difference(monday).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        buckets[diffDays] += rec.durationMinutes;
      }
    }
    return buckets;
  }

  /// Total focus minutes in the week containing [referenceDate].
  static int currentWeekTotalMinutes(
    List<PomodoroSessionRecord> records,
    DateTime referenceDate,
  ) {
    return weeklyDailyMinutes(records, referenceDate)
        .fold<int>(0, (sum, m) => sum + m);
  }

  /// Total focus minutes logged on [referenceDate].
  static int todayFocusMinutes(
    List<PomodoroSessionRecord> records,
    DateTime referenceDate,
  ) {
    final today = dateOnly(referenceDate);
    int sum = 0;
    for (final rec in records) {
      if (rec.dayOnly == today) {
        sum += rec.durationMinutes;
      }
    }
    return sum;
  }

  /// Calculates the active consecutive study day streak as of [referenceDate].
  /// A streak stays alive if the student has studied today OR yesterday.
  static int currentStreakDays(
    List<PomodoroSessionRecord> records,
    DateTime referenceDate,
  ) {
    if (records.isEmpty) return 0;

    final activeDays = <DateTime>{};
    for (final rec in records) {
      if (rec.durationMinutes > 0) {
        activeDays.add(rec.dayOnly);
      }
    }
    if (activeDays.isEmpty) return 0;

    final today = dateOnly(referenceDate);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor;
    if (activeDays.contains(today)) {
      cursor = today;
    } else if (activeDays.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Calculates the all-time longest consecutive study day streak.
  static int longestStreakDays(List<PomodoroSessionRecord> records) {
    if (records.isEmpty) return 0;

    final activeDaysSet = <DateTime>{};
    for (final rec in records) {
      if (rec.durationMinutes > 0) {
        activeDaysSet.add(rec.dayOnly);
      }
    }
    if (activeDaysSet.isEmpty) return 0;

    final sortedDays = activeDaysSet.toList()..sort();
    int best = 1;
    int current = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final gap = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (gap == 1) {
        current++;
        if (current > best) best = current;
      } else if (gap > 1) {
        current = 1;
      }
    }
    return best;
  }

  /// Builds a multi-week heatmap grid ending on the Sunday of [referenceDate]'s week.
  /// Returns a list of [weeksCount] weeks (oldest week first, current week last),
  /// where each week has 7 `(DateTime date, int minutes)` entries from Monday to Sunday.
  static List<List<MapEntry<DateTime, int>>> buildWeeklyHeatmapGrid(
    List<PomodoroSessionRecord> records,
    DateTime referenceDate, {
    int weeksCount = 4,
  }) {
    final minutesByDay = <DateTime, int>{};
    for (final rec in records) {
      final d = rec.dayOnly;
      minutesByDay[d] = (minutesByDay[d] ?? 0) + rec.durationMinutes;
    }

    final currentMonday = startOfWeekMonday(referenceDate);
    final firstMonday =
        currentMonday.subtract(Duration(days: (weeksCount - 1) * 7));

    final grid = <List<MapEntry<DateTime, int>>>[];
    for (int w = 0; w < weeksCount; w++) {
      final weekStart = firstMonday.add(Duration(days: w * 7));
      final weekRow = <MapEntry<DateTime, int>>[];
      for (int d = 0; d < 7; d++) {
        final dayDate = weekStart.add(Duration(days: d));
        weekRow.add(MapEntry(dayDate, minutesByDay[dayDate] ?? 0));
      }
      grid.add(weekRow);
    }
    return grid;
  }

  /// Maps focus minutes on a single day to an intensity level `0..4` for the heatmap:
  /// - `0`: 0 minutes (no session)
  /// - `1`: 1–25 minutes (1 session)
  /// - `2`: 26–50 minutes (2 sessions)
  /// - `3`: 51–100 minutes (3–4 sessions)
  /// - `4`: 101+ minutes (5+ sessions / deep study day)
  static int heatmapIntensityLevel(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes <= 25) return 1;
    if (minutes <= 50) return 2;
    if (minutes <= 100) return 3;
    return 4;
  }

  /// Computes per-subject focus duration breakdown sorted by total minutes descending.
  /// Sessions without a matching subject are grouped under `'Fokus Umum & Mandiri'`.
  static List<SubjectStudyBreakdown> buildSubjectBreakdown(
    List<PomodoroSessionRecord> records,
    List<Subject> subjects,
  ) {
    if (records.isEmpty) return const [];

    final subjectById = <String, Subject>{
      for (final s in subjects) s.id: s,
    };

    final minutesByKey = <String, int>{};
    final sessionsByKey = <String, int>{};
    int grandTotalMinutes = 0;

    for (final rec in records) {
      if (rec.durationMinutes <= 0) continue;
      final sid = rec.subjectId;
      final key = (sid != null && subjectById.containsKey(sid)) ? sid : '_general_';
      minutesByKey[key] = (minutesByKey[key] ?? 0) + rec.durationMinutes;
      sessionsByKey[key] = (sessionsByKey[key] ?? 0) + 1;
      grandTotalMinutes += rec.durationMinutes;
    }

    if (grandTotalMinutes <= 0) return const [];

    final breakdowns = <SubjectStudyBreakdown>[];
    for (final entry in minutesByKey.entries) {
      final key = entry.key;
      final mins = entry.value;
      final count = sessionsByKey[key] ?? 1;
      final pct = (mins / grandTotalMinutes) * 100.0;

      if (key == '_general_') {
        breakdowns.add(
          SubjectStudyBreakdown(
            subjectId: null,
            name: 'Fokus Umum & Mandiri',
            colorValue: 0xFF64748B,
            totalMinutes: mins,
            sessionsCount: count,
            percentage: pct,
          ),
        );
      } else {
        final sub = subjectById[key]!;
        breakdowns.add(
          SubjectStudyBreakdown(
            subjectId: sub.id,
            name: sub.name,
            colorValue: sub.colorValue,
            totalMinutes: mins,
            sessionsCount: count,
            percentage: pct,
          ),
        );
      }
    }

    breakdowns.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return breakdowns;
  }

  /// Formats total minutes into human-readable Indonesian duration (`"2j 30m"` or `"45m"`).
  static String formatDurationCompact(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}j';
    return '${hours}j ${mins}m';
  }
}
