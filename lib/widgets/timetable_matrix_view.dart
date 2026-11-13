import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../screens/subject_detail_screen.dart';
import '../screens/pomodoro_screen.dart';
import 'add_task_modal.dart';
import 'add_subject_dialog.dart';
import '../utils/app_theme.dart';

/// Model representing a free time slot between classes or in the study schedule
class FreeStudyWindow {
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final Subject? precedingSubject;
  final Subject? succeedingSubject;

  const FreeStudyWindow({
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.precedingSubject,
    this.succeedingSubject,
  });

  int get durationMinutes => endMinutes - startMinutes;

  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}j ${mins}m';
    if (hours > 0) return '$hours Jam';
    return '$mins Menit';
  }

  String get timeRangeFormatted {
    final sH = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final sM = (startMinutes % 60).toString().padLeft(2, '0');
    final eH = (endMinutes ~/ 60).toString().padLeft(2, '0');
    final eM = (endMinutes % 60).toString().padLeft(2, '0');
    return '$sH:$sM - $eH:$eM';
  }
}

/// Visual Timetable Matrix (Jadwal Kuliah Mingguan Bentuk Matriks Visual)
class TimetableMatrixView extends StatefulWidget {
  const TimetableMatrixView({super.key});

  @override
  State<TimetableMatrixView> createState() => _TimetableMatrixViewState();
}

class _TimetableMatrixViewState extends State<TimetableMatrixView> {
  // 0: Semua Hari (Grid Penuh), 1-7: Hari tertentu
  int _selectedDayFilter = 0;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double _hourHeight = 64.0;
  static const double _timeColWidth = 52.0;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  String _getDayName(int day) {
    switch (day) {
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
        return '';
    }
  }

  List<FreeStudyWindow> _computeFreeWindows(
    List<Subject> daySubjects,
    int day,
    int matrixStartMin,
    int matrixEndMin,
  ) {
    final windows = <FreeStudyWindow>[];
    if (daySubjects.isEmpty) return windows;

    // 1. Cek jeda sebelum kuliah pertama
    final first = daySubjects.first;
    if (first.startMinutes - matrixStartMin >= 45) {
      windows.add(
        FreeStudyWindow(
          dayOfWeek: day,
          startMinutes: matrixStartMin,
          endMinutes: first.startMinutes,
          succeedingSubject: first,
        ),
      );
    }

    // 2. Cek jeda di antara dua mata kuliah berurutan
    for (int i = 0; i < daySubjects.length - 1; i++) {
      final current = daySubjects[i];
      final next = daySubjects[i + 1];
      final gapStart = current.safeEndMinutes;
      final gapEnd = next.startMinutes;

      // Jeda minimal 25 menit dianggap waktu luang belajar/istirahat
      if (gapEnd - gapStart >= 25) {
        windows.add(
          FreeStudyWindow(
            dayOfWeek: day,
            startMinutes: gapStart,
            endMinutes: gapEnd,
            precedingSubject: current,
            succeedingSubject: next,
          ),
        );
      }
    }

    // 3. Cek jeda setelah kuliah terakhir hingga jam akhir matriks
    final last = daySubjects.last;
    if (matrixEndMin - last.safeEndMinutes >= 45) {
      windows.add(
        FreeStudyWindow(
          dayOfWeek: day,
          startMinutes: last.safeEndMinutes,
          endMinutes: matrixEndMin,
          precedingSubject: last,
        ),
      );
    }

    return windows;
  }

  void _showFreeStudyWindowDialog(BuildContext context, FreeStudyWindow window) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    final dayName = _getDayName(window.dayOfWeek);
    final pomodoroSessions = (window.durationMinutes / 30).floor();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.coffee_rounded, color: accentCol, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Slot Waktu Kosong (Free Study Window)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dayName • ${window.timeRangeFormatted} (${window.durationFormatted})',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Explanation card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (window.precedingSubject != null && window.succeedingSubject != null)
                        Text(
                          'Jeda antara kuliah "${window.precedingSubject!.name}" dan "${window.succeedingSubject!.name}".',
                          style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.3),
                        )
                      else if (window.succeedingSubject != null)
                        Text(
                          'Waktu luang pagi sebelum kuliah "${window.succeedingSubject!.name}" dimulai.',
                          style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.3),
                        )
                      else if (window.precedingSubject != null)
                        Text(
                          'Waktu luang sore setelah kuliah "${window.precedingSubject!.name}" selesai.',
                          style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.3),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates_outlined, size: 14, color: accentCol),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pomodoroSessions > 0
                                  ? 'Cukup untuk $pomodoroSessions sesi fokus Pomodoro atau menyelesaikan tugas mendesak.'
                                  : 'Gunakan jeda singkat ini untuk istirahat atau mengulang catatan kuliah.',
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderCol),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const AddTaskModal(),
                          );
                        },
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('Buat Tugas', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentCol,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PomodoroScreen()),
                          );
                        },
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: const Text('Fokus Pomodoro', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final subjects = subjectProvider.subjects;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    // Deteksi batas jam matriks secara dinamis (default 07.00 - 18.00)
    int startHour = 7;
    int endHour = 18;
    for (final s in subjects) {
      if (s.startMinutes < 9999) {
        final sh = s.startMinutes ~/ 60;
        if (sh < startHour) startHour = sh;
      }
      if (s.safeEndMinutes < 9999) {
        final eh = (s.safeEndMinutes + 59) ~/ 60;
        if (eh > endHour) endHour = eh;
      }
    }

    final totalHours = endHour - startHour;
    final matrixStartMin = startHour * 60;
    final matrixEndMin = endHour * 60;
    final totalGridHeight = totalHours * _hourHeight;

    // Cek apakah ada jadwal di hari Minggu (7)
    final hasSundayClass = subjects.any((s) => s.dayOfWeek == 7);
    final allDays = [1, 2, 3, 4, 5, 6, if (hasSundayClass) 7];

    // Matkul yang belum memiliki hari atau jam
    final unscheduledSubjects = subjects.where(
      (s) => s.dayOfWeek == null || s.startMinutes == 9999,
    ).toList();

    // Tentukan hari mana saja yang akan ditampilkan di kolom
    final displayedDays = _selectedDayFilter == 0
        ? allDays
        : [_selectedDayFilter];

    final todayWeekday = DateTime.now().weekday;

    return Column(
      children: [
        // 1. Day Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDayChip(0, 'Semua (Grid)', _selectedDayFilter == 0, accentCol, isDark),
                const SizedBox(width: 6),
                ...allDays.map((d) {
                  final dayName = _getDayName(d);
                  final isToday = d == todayWeekday;
                  final label = isToday ? '$dayName (Hari ini)' : dayName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildDayChip(
                      d,
                      label,
                      _selectedDayFilter == d,
                      accentCol,
                      isDark,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // 2. Unscheduled notice banner (if any)
        if (unscheduledSubjects.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningOchre.withValues(alpha: 0.09),
              border: Border(bottom: BorderSide(color: AppTheme.warningOchre.withValues(alpha: 0.25), width: 0.8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.warningOchre),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${unscheduledSubjects.length} mata kuliah belum memiliki jam/hari.',
                    style: TextStyle(fontSize: 11.5, color: textPrimary),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddSubjectDialog(initialSubject: unscheduledSubjects.first),
                    );
                  },
                  child: const Text('Atur Jadwal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

        // 3. Timetable Grid View (Synchronized Time Column + Day Columns)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double dayColWidth = _selectedDayFilter != 0
                  ? (constraints.maxWidth - _timeColWidth).clamp(240.0, 600.0)
                  : 135.0;

              return SingleChildScrollView(
                controller: _verticalController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Left: Time Labels Column
                    SizedBox(
                      width: _timeColWidth,
                      child: Column(
                        children: [
                          // Header offset matching day column headers
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: borderCol, width: 0.8),
                                right: BorderSide(color: borderCol, width: 0.8),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Jam',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                            ),
                          ),
                          // Hour markers
                          SizedBox(
                            height: totalGridHeight,
                            child: Stack(
                              children: List.generate(totalHours + 1, (index) {
                                final hour = startHour + index;
                                final top = index * _hourHeight;
                                return Positioned(
                                  top: top - 7,
                                  left: 0,
                                  right: 6,
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Horizontal Scrollable Day Columns
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: displayedDays.map((day) {
                            final daySubjects = subjects
                                .where((s) => s.dayOfWeek == day && s.startMinutes < 9999)
                                .toList()
                              ..sort();

                            final freeWindows = _computeFreeWindows(
                              daySubjects,
                              day,
                              matrixStartMin,
                              matrixEndMin,
                            );

                            final isToday = day == todayWeekday;

                            return Container(
                              width: dayColWidth,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: borderCol.withValues(alpha: 0.6), width: 0.8),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Day Header Cell
                                  Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? accentCol.withValues(alpha: 0.08)
                                          : Theme.of(context).cardTheme.color,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isToday ? accentCol : borderCol,
                                          width: isToday ? 1.5 : 0.8,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getDayName(day),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                            color: isToday ? accentCol : textPrimary,
                                          ),
                                        ),
                                        Text(
                                          daySubjects.isEmpty
                                              ? 'Bebas kuliah'
                                              : '${daySubjects.length} matkul',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isToday ? accentCol : textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Day Body Grid (Stacked with hour lines, free windows, and course blocks)
                                  SizedBox(
                                    height: totalGridHeight,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // 1. Horizontal hour grid background lines
                                        ...List.generate(totalHours, (index) {
                                          return Positioned(
                                            top: index * _hourHeight,
                                            left: 0,
                                            right: 0,
                                            child: Divider(
                                              height: 1,
                                              thickness: 0.6,
                                              color: borderCol.withValues(alpha: 0.4),
                                            ),
                                          );
                                        }),

                                        // 2. Free Study Windows (Slot Waktu Kosong)
                                        ...freeWindows.map((fw) {
                                          final top = (fw.startMinutes - matrixStartMin) * (_hourHeight / 60.0);
                                          final height = fw.durationMinutes * (_hourHeight / 60.0);

                                          return Positioned(
                                            top: top + 2,
                                            left: 3,
                                            right: 3,
                                            height: (height - 4).clamp(24.0, totalGridHeight),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showFreeStudyWindowDialog(context, fw),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppTheme.darkSurfaceElevated.withValues(alpha: 0.4)
                                                        : AppTheme.lightBorderSubtle.withValues(alpha: 0.6),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: borderCol.withValues(alpha: 0.8),
                                                      width: 0.8,
                                                      strokeAlign: BorderSide.strokeAlignInside,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.coffee_rounded,
                                                            size: 11,
                                                            color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Flexible(
                                                            child: Text(
                                                              'Jeda ${fw.durationFormatted}',
                                                              style: TextStyle(
                                                                fontSize: 9.5,
                                                                fontWeight: FontWeight.w600,
                                                                color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (height >= 40)
                                                        Text(
                                                          fw.timeRangeFormatted,
                                                          style: TextStyle(
                                                            fontSize: 8.5,
                                                            color: textSecondary.withValues(alpha: 0.8),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),

                                        // 3. Class Subject Blocks
                                        ...daySubjects.map((sub) {
                                          final top = (sub.startMinutes - matrixStartMin) * (_hourHeight / 60.0);
                                          final height = sub.durationMinutes * (_hourHeight / 60.0);

                                          return Positioned(
                                            top: top + 2,
                                            left: 3,
                                            right: 3,
                                            height: (height - 4).clamp(32.0, totalGridHeight),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => SubjectDetailScreen(subject: sub),
                                                    ),
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: sub.color.withValues(alpha: isDark ? 0.25 : 0.14),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: sub.color.withValues(alpha: 0.85),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      // Title & SKS
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              sub.name,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                                color: isDark ? Colors.white : Colors.black87,
                                                                height: 1.15,
                                                              ),
                                                              maxLines: height < 50 ? 1 : 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      // Room / Location
                                                      if (height >= 45 && sub.room.isNotEmpty) ...[
                                                        const SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.meeting_room_outlined,
                                                              size: 10,
                                                              color: sub.color,
                                                            ),
                                                            const SizedBox(width: 3),
                                                            Expanded(
                                                              child: Text(
                                                                sub.room,
                                                                style: TextStyle(
                                                                  fontSize: 9.5,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],

                                                      // Time Range
                                                      if (height >= 60 && sub.timeRange != null) ...[
                                                        const Spacer(),
                                                        Text(
                                                          sub.timeRange!,
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w500,
                                                            color: isDark ? Colors.white60 : Colors.black54,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayChip(
    int day,
    String label,
    bool isSelected,
    Color accentCol,
    bool isDark,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _selectedDayFilter = day),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? accentCol
              : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? accentCol : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
