import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../screens/main_screen.dart';
import '../screens/subject_detail_screen.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import 'record_absence_dialog.dart';

enum DailyClassTimingState {
  none,
  ongoing,
  upcomingToday,
  completedToday,
  upcomingNextDay,
}

/// Snapshot produced by [DailyCampusBriefingHelper.evaluate] representing today's
/// classes, live countdown to the next/active lecture, attendance prompt, and top priority task.
class DailyCampusBriefingSnapshot {
  final List<Subject> todayClasses;
  final Subject? highlightedSubject;
  final DailyClassTimingState timingState;
  final int minutesUntilStart;
  final int minutesRemainingInClass;
  final int nextMeetingNumber;
  final bool hasRecordedAttendanceToday;
  final TaskItem? mostUrgentTask;
  final int dueTodayTasksCount;

  const DailyCampusBriefingSnapshot({
    required this.todayClasses,
    required this.highlightedSubject,
    required this.timingState,
    required this.minutesUntilStart,
    required this.minutesRemainingInClass,
    required this.nextMeetingNumber,
    required this.hasRecordedAttendanceToday,
    required this.mostUrgentTask,
    required this.dueTodayTasksCount,
  });
}

/// Pure calculation helper for the Smart Daily Campus Briefing card (`SummaryCard`).
class DailyCampusBriefingHelper {
  /// Suggests the next unrecorded meeting number (`1..totalMeetings`) for [subject].
  static int suggestNextMeetingNumber(Subject subject) {
    final recordedNumbers = subject.absences.map((a) => a.meetingNumber).toSet();
    for (int m = 1; m <= subject.totalMeetings; m++) {
      if (!recordedNumbers.contains(m)) {
        return m;
      }
    }
    return subject.totalMeetings;
  }

  /// Checks whether [subject] already has an attendance record logged on [now]'s calendar date.
  static bool hasAttendanceOnDate(Subject subject, DateTime now) {
    return subject.absences.any(
      (a) =>
          a.date.year == now.year &&
          a.date.month == now.month &&
          a.date.day == now.day,
    );
  }

  /// Formats a duration in minutes into a concise Indonesian label (`"35 mnt"`, `"1j 20m"`, `"2 jam"`).
  static String formatMinutesCompact(int totalMinutes) {
    final clamped = totalMinutes < 0 ? 0 : totalMinutes;
    if (clamped < 60) {
      return '$clamped mnt';
    }
    final hours = clamped ~/ 60;
    final mins = clamped % 60;
    if (mins == 0) {
      return '$hours jam';
    }
    return '${hours}j ${mins}m';
  }

  /// Evaluates all [subjects] and [tasks] relative to [now] to build a [DailyCampusBriefingSnapshot].
  static DailyCampusBriefingSnapshot evaluate({
    required List<Subject> subjects,
    required List<TaskItem> tasks,
    required DateTime now,
  }) {
    final nowMinutes = now.hour * 60 + now.minute;
    final todayWeekday = now.weekday;

    final todayClasses = subjects
        .where((s) => s.dayOfWeek == todayWeekday)
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    Subject? highlightedSubject;
    DailyClassTimingState timingState = DailyClassTimingState.none;
    int minutesUntilStart = 0;
    int minutesRemainingInClass = 0;

    if (todayClasses.isNotEmpty) {
      // 1. Check if any class is currently ongoing
      for (final sub in todayClasses) {
        if (sub.startMinutes != 9999 &&
            nowMinutes >= sub.startMinutes &&
            nowMinutes <= sub.safeEndMinutes) {
          highlightedSubject = sub;
          timingState = DailyClassTimingState.ongoing;
          minutesRemainingInClass = sub.safeEndMinutes - nowMinutes;
          break;
        }
      }

      // 2. Otherwise check for the nearest upcoming class today
      if (highlightedSubject == null) {
        for (final sub in todayClasses) {
          if (sub.startMinutes == 9999 || sub.startMinutes > nowMinutes) {
            highlightedSubject = sub;
            timingState = DailyClassTimingState.upcomingToday;
            minutesUntilStart =
                sub.startMinutes == 9999 ? 0 : (sub.startMinutes - nowMinutes);
            break;
          }
        }
      }

      // 3. Otherwise all classes today have finished -> highlight the most recently finished class
      if (highlightedSubject == null) {
        highlightedSubject = todayClasses.last;
        timingState = DailyClassTimingState.completedToday;
      }
    } else {
      // Look ahead up to 7 days for the next scheduled class
      final scheduled = subjects.where((s) => s.dayOfWeek != null).toList();
      if (scheduled.isNotEmpty) {
        scheduled.sort((a, b) {
          final diffA = ((a.dayOfWeek! - todayWeekday) % 7 == 0)
              ? 7
              : (a.dayOfWeek! - todayWeekday) % 7;
          final diffB = ((b.dayOfWeek! - todayWeekday) % 7 == 0)
              ? 7
              : (b.dayOfWeek! - todayWeekday) % 7;
          if (diffA != diffB) return diffA.compareTo(diffB);
          return a.startMinutes.compareTo(b.startMinutes);
        });
        highlightedSubject = scheduled.first;
        timingState = DailyClassTimingState.upcomingNextDay;
      }
    }

    final pendingTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final dueTodayCount = pendingTasks
        .where(
          (t) =>
              t.dueDate.year == now.year &&
              t.dueDate.month == now.month &&
              t.dueDate.day == now.day,
        )
        .length;

    final nextMeeting = highlightedSubject != null
        ? suggestNextMeetingNumber(highlightedSubject)
        : 1;
    final recordedToday = highlightedSubject != null
        ? hasAttendanceOnDate(highlightedSubject, now)
        : false;

    return DailyCampusBriefingSnapshot(
      todayClasses: todayClasses,
      highlightedSubject: highlightedSubject,
      timingState: timingState,
      minutesUntilStart: minutesUntilStart,
      minutesRemainingInClass: minutesRemainingInClass,
      nextMeetingNumber: nextMeeting,
      hasRecordedAttendanceToday: recordedToday,
      mostUrgentTask: pendingTasks.isNotEmpty ? pendingTasks.first : null,
      dueTodayTasksCount: dueTodayCount,
    );
  }
}

/// Modern Editorial Overview & Smart Daily Campus Briefing Card
/// Maximizes existing `SubjectProvider` and `TaskProvider` data on the HomeScreen:
/// - Overall task completion progress, pending count, critical (<24h) badge & total SKS
/// - Live today's class briefing & countdown (Ongoing / Upcoming in X mins / Completed today / Next day)
/// - 1-Tap `[ ✓ Isi Presensi ]` and `[ 🎯 Fokus Tugas Ini ]` actions
class SummaryCard extends StatelessWidget {
  final DateTime? referenceNow;

  const SummaryCard({
    super.key,
    this.referenceNow,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    final total = taskProvider.totalCount;
    final completed = taskProvider.completedCount;
    final pending = taskProvider.pendingCount;
    final critical = taskProvider.criticalDeadlines.length;
    final progress = taskProvider.completionRate;
    final totalSks = subjectProvider.totalCreditHours;

    final now = referenceNow ?? DateTime.now();
    final briefing = DailyCampusBriefingHelper.evaluate(
      subjects: subjectProvider.subjects,
      tasks: taskProvider.allTasks,
      now: now,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMuted = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Label & Today's Kuliah + SKS Pills
          Row(
            children: [
              Expanded(
                child: Text(
                  'BRIEFING KAMPUS & BEBAN TUGAS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: textMuted,
                  ),
                ),
              ),
              if (briefing.todayClasses.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentCol.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentCol.withValues(alpha: 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${briefing.todayClasses.length} Kuliah Hari Ini',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: accentCol,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: Text(
                  '$totalSks SKS Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Key Metrics Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$pending',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'perlu diselesaikan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const Spacer(),
              if (critical > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.urgentRose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.urgentRose.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.urgentRose,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$critical Kritis (<24j)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.urgentRose,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Slender Linear Progress Bar (Editorial minimalism)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3.5,
              backgroundColor:
                  isDark ? const Color(0xFF242731) : const Color(0xFFEAEAEC),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.successSage : accentCol,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Sub-bar info text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed dari $total tugas selesai',
                style: TextStyle(fontSize: 11.5, color: textMuted),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          // Smart Daily Campus Briefing Section (shown when classes or pending tasks exist)
          if (briefing.highlightedSubject != null ||
              briefing.mostUrgentTask != null) ...[
            const SizedBox(height: 14),
            Divider(color: borderCol, height: 1),
            const SizedBox(height: 12),
            _buildCampusBriefingSection(
              context: context,
              briefing: briefing,
              isDark: isDark,
              borderCol: borderCol,
              textPrimary: textPrimary,
              textMuted: textMuted,
              accentCol: accentCol,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampusBriefingSection({
    required BuildContext context,
    required DailyCampusBriefingSnapshot briefing,
    required bool isDark,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required Color accentCol,
  }) {
    final subject = briefing.highlightedSubject;
    final urgentTask = briefing.mostUrgentTask;

    String statusBadgeText = '';
    Color statusBadgeColor = accentCol;

    if (subject != null) {
      switch (briefing.timingState) {
        case DailyClassTimingState.ongoing:
          final remLabel = DailyCampusBriefingHelper.formatMinutesCompact(
            briefing.minutesRemainingInClass,
          );
          statusBadgeText = 'Sedang Berlangsung • sisa $remLabel';
          statusBadgeColor = AppTheme.successSage;
          break;
        case DailyClassTimingState.upcomingToday:
          if (briefing.minutesUntilStart > 0) {
            final waitLabel = DailyCampusBriefingHelper.formatMinutesCompact(
              briefing.minutesUntilStart,
            );
            statusBadgeText = 'Mulai dalam $waitLabel';
          } else {
            statusBadgeText = 'Kuliah Hari Ini';
          }
          statusBadgeColor = AppTheme.warningOchre;
          break;
        case DailyClassTimingState.completedToday:
          statusBadgeText = briefing.hasRecordedAttendanceToday
              ? 'Selesai Hari Ini • Presensi Tercatat'
              : 'Kuliah Selesai • Belum Isi Presensi';
          statusBadgeColor = briefing.hasRecordedAttendanceToday
              ? AppTheme.successSage
              : AppTheme.warningOchre;
          break;
        case DailyClassTimingState.upcomingNextDay:
          statusBadgeText = 'Jadwal Berikutnya • ${subject.dayName}';
          statusBadgeColor = accentCol;
          break;
        case DailyClassTimingState.none:
          break;
      }
    }

    final metadataParts = <String>[];
    if (subject != null) {
      if (subject.timeRange != null && subject.timeRange!.trim().isNotEmpty) {
        metadataParts.add(subject.timeRange!.trim());
      }
      if (subject.room.trim().isNotEmpty) {
        metadataParts.add('R. ${subject.room.trim()}');
      }
      if (subject.lecturer.trim().isNotEmpty) {
        metadataParts.add(subject.lecturer.trim());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subject != null)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectDetailScreen(subject: subject),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightBorderSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: subject.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBadgeColor.withValues(
                            alpha: isDark ? 0.18 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          statusBadgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (metadataParts.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      metadataParts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),

        if (urgentTask != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                urgentTask.isOverdue || urgentTask.timeLeft.inHours <= 24
                    ? Icons.priority_high_rounded
                    : Icons.assignment_outlined,
                size: 14,
                color: urgentTask.isOverdue || urgentTask.timeLeft.inHours <= 24
                    ? AppTheme.urgentRose
                    : textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Fokus Prioritas: ${urgentTask.title} (${DateFormatter.formatDeadlineCountdown(urgentTask.dueDate)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 10),

        // 1-Tap Quick Action Buttons Row: [ ✓ Isi Presensi ] & [ 🎯 Fokus Tugas Ini ]
        Row(
          children: [
            if (subject != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: briefing.hasRecordedAttendanceToday
                        ? AppTheme.successSage
                        : textPrimary,
                    side: BorderSide(
                      color: briefing.hasRecordedAttendanceToday
                          ? AppTheme.successSage.withValues(alpha: 0.45)
                          : borderCol,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => RecordAbsenceDialog(
                        subjectId: subject.id,
                        totalMeetings: subject.totalMeetings,
                        defaultMeetingNumber: briefing.nextMeetingNumber,
                      ),
                    );
                  },
                  icon: Icon(
                    briefing.hasRecordedAttendanceToday
                        ? Icons.verified_rounded
                        : Icons.fact_check_outlined,
                    size: 15,
                    color: AppTheme.successSage,
                  ),
                  label: Text(
                    briefing.hasRecordedAttendanceToday
                        ? 'Presensi P${briefing.nextMeetingNumber > 1 ? briefing.nextMeetingNumber - 1 : 1} Tercatat'
                        : 'Isi Presensi (P${briefing.nextMeetingNumber})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (subject != null && urgentTask != null) const SizedBox(width: 8),
            if (urgentTask != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentCol,
                    side: BorderSide(
                      color: accentCol.withValues(alpha: 0.40),
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    MainScreen.focusTaskInPomodoro(context, urgentTask.id);
                  },
                  icon: Icon(
                    Icons.center_focus_strong_outlined,
                    size: 15,
                    color: accentCol,
                  ),
                  label: const Text(
                    'Fokus Tugas Ini',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
