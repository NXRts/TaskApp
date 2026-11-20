import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';

/// Pure helper utilities for Monthly Grid View calculations and marker colors.
class MonthlyCalendarHelper {
  static const List<String> weekdayHeaders = [
    'SEN',
    'SEL',
    'RAB',
    'KAM',
    'JUM',
    'SAB',
    'MIN',
  ];

  /// Normalizes a [DateTime] to midnight local date.
  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Generates all calendar cells (35 or 42 days, Monday-first) for [month].
  static List<DateTime> buildMonthGridDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingDays = firstOfMonth.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((leadingDays + daysInMonth) / 7).ceil() * 7;
    final startOffset = 1 - leadingDays;

    return List<DateTime>.generate(
      totalCells,
      (index) => DateTime(month.year, month.month, startOffset + index),
    );
  }

  /// Returns up to 3 semantic dot colors for tasks due on a given day.
  static List<Color> getTaskMarkerColors(
    List<TaskItem> dayTasks, {
    bool isDark = false,
  }) {
    if (dayTasks.isEmpty) return const [];

    final sorted = List<TaskItem>.from(dayTasks)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        if (a.isOverdue != b.isOverdue) {
          return a.isOverdue ? -1 : 1;
        }
        return b.priority.index.compareTo(a.priority.index);
      });

    final colors = <Color>[];
    for (final task in sorted) {
      final Color color;
      if (task.isCompleted) {
        color = AppTheme.successSage;
      } else if (task.isOverdue || task.priority == TaskPriority.high) {
        color = AppTheme.urgentRose;
      } else if (task.priority == TaskPriority.medium) {
        color = AppTheme.warningOchre;
      } else {
        color = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;
      }
      if (!colors.contains(color)) {
        colors.add(color);
      }
      if (colors.length >= 3) break;
    }

    return colors;
  }

  /// Returns up to 3 distinct subject colors for active classes on a weekday.
  static List<Color> getSubjectMarkerColors(List<Subject> daySubjects) {
    if (daySubjects.isEmpty) return const [];
    final colors = <Color>[];
    for (final subject in daySubjects) {
      if (!colors.contains(subject.color)) {
        colors.add(subject.color);
      }
      if (colors.length >= 2) break;
    }
    return colors;
  }
}

/// Full 1-month calendar grid widget with colored markers for task deadlines
/// and active lecture days.
class MonthlyCalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final List<TaskItem> tasks;
  final List<Subject> subjects;
  final ValueChanged<DateTime> onDateSelected;

  const MonthlyCalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
    required this.tasks,
    required this.subjects,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final textMuted = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final taskLowCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    final gridDays = MonthlyCalendarHelper.buildMonthGridDays(focusedMonth);
    final rowCount = gridDays.length ~/ 7;

    // Pre-index tasks by normalized date and subjects by weekday for fast lookup.
    final tasksByDate = <DateTime, List<TaskItem>>{};
    int monthTaskCount = 0;
    for (final task in tasks) {
      final dateKey = MonthlyCalendarHelper.normalizeDate(task.dueDate);
      tasksByDate.putIfAbsent(dateKey, () => []).add(task);
      if (task.dueDate.year == focusedMonth.year &&
          task.dueDate.month == focusedMonth.month) {
        monthTaskCount++;
      }
    }

    final subjectsByWeekday = <int, List<Subject>>{};
    for (final subject in subjects) {
      final day = subject.dayOfWeek;
      if (day != null) {
        subjectsByWeekday.putIfAbsent(day, () => []).add(subject);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weekday column labels (SEN .. MIN)
          Row(
            children: List.generate(7, (index) {
              final isWeekend = index >= 5;
              return Expanded(
                child: SizedBox(
                  height: 20,
                  child: Center(
                    child: Text(
                      MonthlyCalendarHelper.weekdayHeaders[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isWeekend
                            ? textMuted
                            : textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 2),

          // Calendar date matrix
          for (int row = 0; row < rowCount; row++)
            Row(
              children: List.generate(7, (col) {
                final date = gridDays[row * 7 + col];
                final isCurrentMonth = date.year == focusedMonth.year &&
                    date.month == focusedMonth.month;
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final dayTasks = tasksByDate[date] ?? const [];
                final daySubjects =
                    subjectsByWeekday[date.weekday] ?? const [];

                final taskColors = MonthlyCalendarHelper.getTaskMarkerColors(
                  dayTasks,
                  isDark: isDark,
                );
                final subjectColors =
                    MonthlyCalendarHelper.getSubjectMarkerColors(daySubjects);

                return Expanded(
                  child: _buildDateCell(
                    date: date,
                    isCurrentMonth: isCurrentMonth,
                    isSelected: isSelected,
                    isToday: isToday,
                    taskColors: taskColors,
                    subjectColors: subjectColors,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    borderCol: borderCol,
                    accentCol: accentCol,
                  ),
                );
              }),
            ),

          const SizedBox(height: 6),

          // Compact legend & monthly workload count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildDotLegendItem(
                        color: AppTheme.urgentRose,
                        label: 'Mendesak',
                        textSecondary: textSecondary,
                      ),
                      _buildDotLegendItem(
                        color: taskLowCol,
                        label: 'Tugas',
                        textSecondary: textSecondary,
                      ),
                      _buildDotLegendItem(
                        color: AppTheme.successSage,
                        label: 'Selesai',
                        textSecondary: textSecondary,
                      ),
                      _buildBarLegendItem(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.infoSlate,
                        label: 'Kuliah',
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$monthTaskCount tugas bulan ini',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isSelected,
    required bool isToday,
    required List<Color> taskColors,
    required List<Color> subjectColors,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color borderCol,
    required Color accentCol,
  }) {
    final Color bgColor;
    if (isSelected) {
      bgColor = accentCol;
    } else if (isToday) {
      bgColor = isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle;
    } else {
      bgColor = Colors.transparent;
    }

    final Color borderColor;
    if (isSelected) {
      borderColor = accentCol;
    } else if (isToday) {
      borderColor = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;
    } else {
      borderColor = Colors.transparent;
    }

    final Color dayTextColor;
    if (isSelected) {
      dayTextColor = Colors.white;
    } else if (!isCurrentMonth) {
      dayTextColor = textMuted.withValues(alpha: 0.55);
    } else if (isToday) {
      dayTextColor = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;
    } else {
      dayTextColor = textPrimary;
    }

    final hasMarkers = taskColors.isNotEmpty || subjectColors.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onDateSelected(date),
      child: Container(
        height: 36,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isToday && !isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.1,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : (isCurrentMonth ? FontWeight.w600 : FontWeight.w400),
                color: dayTextColor,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: hasMarkers
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < subjectColors.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Container(
                            width: 5,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white70
                                  : (isCurrentMonth
                                      ? subjectColors[i]
                                      : subjectColors[i].withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                        if (subjectColors.isNotEmpty && taskColors.isNotEmpty)
                          const SizedBox(width: 3),
                        for (int i = 0; i < taskColors.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Container(
                            width: 4.5,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentMonth
                                      ? taskColors[i]
                                      : taskColors[i].withValues(alpha: 0.45)),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotLegendItem({
    required Color color,
    required String label,
    required Color textSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildBarLegendItem({
    required Color color,
    required String label,
    required Color textSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: textSecondary),
        ),
      ],
    );
  }
}
