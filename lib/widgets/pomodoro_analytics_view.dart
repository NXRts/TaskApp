import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_session_record.dart';
import '../models/subject.dart';
import '../providers/settings_provider.dart';
import '../providers/subject_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

/// Offline Pomodoro Academic Analytics View:
/// - Study Streak Counter (current consecutive days + longest streak) & summary metrics
/// - Daily Focus Minutes Bar Chart (Monday–Sunday of the active week)
/// - 4-Week Study Consistency Heatmap Grid (28 days, 5 intensity tiers)
/// - Per-Subject Study Hours Breakdown with color-coded progress bars
class PomodoroAnalyticsView extends StatelessWidget {
  final DateTime? referenceDate;

  const PomodoroAnalyticsView({
    super.key,
    this.referenceDate,
  });

  List<Subject> _resolveSubjects(BuildContext context) {
    try {
      return Provider.of<SubjectProvider>(context).subjects;
    } catch (_) {
      return StorageService.instance.getSubjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final records = settingsProvider.pomodoroSessionRecords;
    final subjects = _resolveSubjects(context);
    final now = referenceDate ?? DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.darkSurface : AppTheme.lightSurface);
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    final currentStreak = PomodoroAnalyticsHelper.currentStreakDays(records, now);
    final longestStreak = PomodoroAnalyticsHelper.longestStreakDays(records);
    final weekDailyMins = PomodoroAnalyticsHelper.weeklyDailyMinutes(records, now);
    final weekTotalMins = weekDailyMins.fold<int>(0, (sum, m) => sum + m);
    final totalAllTimeMins = settingsProvider.totalFocusMinutes;
    final totalSessions = settingsProvider.completedPomodoroSessions >= records.length
        ? settingsProvider.completedPomodoroSessions
        : records.length;
    final heatmapWeeks = PomodoroAnalyticsHelper.buildWeeklyHeatmapGrid(
      records,
      now,
      weeksCount: 4,
    );
    final subjectBreakdowns = PomodoroAnalyticsHelper.buildSubjectBreakdown(
      records,
      subjects,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top KPI Row: Streak Belajar & Total Jam Semester
          _buildTopMetricsRow(
            isDark: isDark,
            cardBg: cardBg,
            borderCol: borderCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentCol: accentCol,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weekTotalMins: weekTotalMins,
            totalAllTimeMins: totalAllTimeMins,
            totalSessions: totalSessions,
          ),

          const SizedBox(height: 12),

          // 2. Weekly Bar Chart (Senin - Minggu)
          _buildWeeklyBarChartCard(
            isDark: isDark,
            cardBg: cardBg,
            borderCol: borderCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentCol: accentCol,
            weekDailyMins: weekDailyMins,
            weekTotalMins: weekTotalMins,
            now: now,
          ),

          const SizedBox(height: 12),

          // 3. 4-Week Study Consistency Heatmap Grid
          _buildHeatmapCard(
            isDark: isDark,
            cardBg: cardBg,
            borderCol: borderCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            heatmapWeeks: heatmapWeeks,
            now: now,
          ),

          const SizedBox(height: 12),

          // 4. Subject Focus Breakdown Card
          _buildSubjectBreakdownCard(
            isDark: isDark,
            cardBg: cardBg,
            borderCol: borderCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            subjectBreakdowns: subjectBreakdowns,
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetricsRow({
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentCol,
    required int currentStreak,
    required int longestStreak,
    required int weekTotalMins,
    required int totalAllTimeMins,
    required int totalSessions,
  }) {
    return Row(
      children: [
        // Streak Belajar Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.warningOchre.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: AppTheme.warningOchre,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Streak Belajar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'hari beruntun',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: currentStreak > 0 ? AppTheme.warningOchre : textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rekor terbaik: $longestStreak hari',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Total Fokus Semester Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: accentCol,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Fokus',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      PomodoroAnalyticsHelper.formatDurationCompact(totalAllTimeMins),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '($totalSessions sesi)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Minggu ini: ${PomodoroAnalyticsHelper.formatDurationCompact(weekTotalMins)}',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChartCard({
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentCol,
    required List<int> weekDailyMins,
    required int weekTotalMins,
    required DateTime now,
  }) {
    final maxMins = weekDailyMins.fold<int>(0, (prev, m) => m > prev ? m : prev);
    final chartCeiling = maxMins < 50 ? 50 : maxMins;
    final todayIndex = now.weekday - 1; // 0 = Mon .. 6 = Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 17, color: accentCol),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Menit Fokus Harian (Senin–Minggu)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentCol.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$weekTotalMins mnt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (idx) {
                final mins = weekDailyMins[idx];
                final ratio = (mins / chartCeiling).clamp(0.0, 1.0);
                final barHeight = mins > 0 ? (14.0 + ratio * 72.0) : 6.0;
                final isToday = idx == todayIndex;
                final barColor = mins > 0
                    ? (isToday ? AppTheme.successSage : accentCol)
                    : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorder);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        mins > 0 ? '${mins}m' : '0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: mins > 0 ? FontWeight.w700 : FontWeight.w400,
                          color: mins > 0 ? textPrimary : textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 22,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.successSage.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          PomodoroAnalyticsHelper.weekdayShortLabels[idx],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? AppTheme.successSage : textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard({
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
    required List<List<MapEntry<DateTime, int>>> heatmapWeeks,
    required DateTime now,
  }) {
    final today = PomodoroAnalyticsHelper.dateOnly(now);
    final shortDateFmt = DateFormat('d MMM');

    Color cellColorForLevel(int level) {
      switch (level) {
        case 1:
          return AppTheme.successSage.withValues(alpha: isDark ? 0.28 : 0.24);
        case 2:
          return AppTheme.successSage.withValues(alpha: isDark ? 0.50 : 0.45);
        case 3:
          return AppTheme.successSage.withValues(alpha: isDark ? 0.75 : 0.70);
        case 4:
          return AppTheme.successSage;
        default:
          return isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle;
      }
    }

    int activeDaysIn4Weeks = 0;
    for (final week in heatmapWeeks) {
      for (final dayEntry in week) {
        if (dayEntry.value > 0) activeDaysIn4Weeks++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: AppTheme.successSage,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Heatmap Konsistensi Belajar (4 Minggu)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                '$activeDaysIn4Weeks/28 hari aktif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Headers
          Row(
            children: [
              const SizedBox(width: 58),
              ...List.generate(7, (idx) {
                return Expanded(
                  child: Center(
                    child: Text(
                      PomodoroAnalyticsHelper.weekdayShortLabels[idx],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),

          // 4 Week Rows
          ...heatmapWeeks.map((weekRow) {
            final weekStartLabel = shortDateFmt.format(weekRow.first.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      weekStartLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  ...weekRow.map((entry) {
                    final date = entry.key;
                    final mins = entry.value;
                    final level = PomodoroAnalyticsHelper.heatmapIntensityLevel(mins);
                    final isToday = date == today;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Tooltip(
                          message: '${DateFormat('EEE, d MMM').format(date)}: $mins menit fokus',
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: cellColorForLevel(level),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isToday
                                    ? AppTheme.warningOchre
                                    : (level > 0
                                        ? AppTheme.successSage.withValues(alpha: 0.35)
                                        : borderCol),
                                width: isToday ? 1.4 : 0.6,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: level > 0 || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: level >= 3
                                      ? Colors.white
                                      : (level > 0 ? textPrimary : textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          // Intensity Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Intensitas:',
                style: TextStyle(fontSize: 10.5, color: textSecondary),
              ),
              const SizedBox(width: 6),
              Text('0m', style: TextStyle(fontSize: 10, color: textSecondary)),
              const SizedBox(width: 4),
              ...List.generate(5, (lvl) {
                return Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: cellColorForLevel(lvl),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: borderCol, width: 0.5),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text('100m+', style: TextStyle(fontSize: 10, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdownCard({
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
    required List<SubjectStudyBreakdown> subjectBreakdowns,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 17,
                color: AppTheme.brandCobalt,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Alokasi Jam Belajar per Mata Kuliah',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (subjectBreakdowns.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 26,
                    color: textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Belum ada riwayat sesi fokus per mata kuliah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pilih tugas kuliah pada Timer Pomodoro untuk melacak distribusi jam belajar secara otomatis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ],
              ),
            )
          else
            ...subjectBreakdowns.map((item) {
              final subjectColor = Color(item.colorValue);
              final pctRatio = (item.percentage / 100.0).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: subjectColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${PomodoroAnalyticsHelper.formatDurationCompact(item.totalMinutes)} • ${item.sessionsCount} sesi (${item.percentage.round()}%)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pctRatio,
                        minHeight: 6,
                        backgroundColor:
                            isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
