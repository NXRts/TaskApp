import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../screens/subject_detail_screen.dart';
import '../screens/pomodoro_screen.dart';
import 'add_task_modal.dart';
import 'add_subject_dialog.dart';
import '../utils/app_theme.dart';

/// Model representing a free time slot between classes in the study schedule
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

/// Visual Timetable Matrix (Jadwal Kuliah Mingguan 06.00 - 16.00)
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

  static const double _hourHeight = 60.0;
  static const double _timeColWidth = 52.0;
  static const double _gridTopOffset = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalController.hasClients) {
        final now = DateTime.now();
        // Jika sedang di jam siang (08.00 - 16.00), scroll lembut mendekati jam sekarang
        if (now.hour >= 8 && now.hour <= 16) {
          final targetHour = now.hour - 1;
          final targetOffset = (_gridTopOffset + (targetHour - 6) * _hourHeight - 10)
              .clamp(0.0, _verticalController.position.maxScrollExtent);
          _verticalController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

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

  /// Menghitung jeda kosong hanya di antara dua mata kuliah berurutan pada hari yang sama
  List<FreeStudyWindow> _computeFreeWindows(List<Subject> daySubjects, int day) {
    final windows = <FreeStudyWindow>[];
    if (daySubjects.length < 2) return windows;

    for (int i = 0; i < daySubjects.length - 1; i++) {
      final current = daySubjects[i];
      final next = daySubjects[i + 1];
      final gapStart = current.safeEndMinutes;
      final gapEnd = next.startMinutes;

      // Jeda minimal 20 menit di antara dua kelas kuliah
      if (gapEnd - gapStart >= 20) {
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
                            'Slot Jeda Kosong (Free Study Window)',
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
                          'Jeda waktu luang di antara kuliah "${window.precedingSubject!.name}" dan "${window.succeedingSubject!.name}".',
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
                                  ? 'Bisa dimanfaatkan untuk $pomodoroSessions sesi Pomodoro fokus atau mencicil tugas.'
                                  : 'Gunakan waktu ini untuk istirahat, makan, atau membaca ringkasan materi kuliah.',
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

    // Matriks jam 6 pagi s/d jam 4 sore (06:00 - 16:00)
    int startHour = 6;
    int endHour = 16;
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
    final double totalGridHeight = _gridTopOffset + totalHours * _hourHeight + 36.0;

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

    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final currentMinutesOfDay = now.hour * 60 + now.minute;

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

        // 3. Timetable Grid View (Synchronized 24-Hour Column + Day Columns)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double dayColWidth = _selectedDayFilter != 0
                  ? (constraints.maxWidth - _timeColWidth).clamp(240.0, 600.0)
                  : 142.0;

              return SingleChildScrollView(
                controller: _verticalController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Left: 24-Hour Labels Column (Never clipped)
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
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                            ),
                          ),
                          // Hour markers (06:00 s/d 16:00 with safe top offset)
                          SizedBox(
                            height: totalGridHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: List.generate(totalHours + 1, (index) {
                                final hour = startHour + index;
                                final top = _gridTopOffset + index * _hourHeight;
                                final label = '${hour.toString().padLeft(2, '0')}:00';
                                return Positioned(
                                  top: top - 7,
                                  left: 0,
                                  right: 6,
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
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

                            final freeWindows = _computeFreeWindows(daySubjects, day);
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

                                  // Day Body Grid (Stacked with hour lines, clean free windows, course blocks & live indicator)
                                  SizedBox(
                                    height: totalGridHeight,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // 1. Horizontal hour grid background lines (06:00 s/d 16:00)
                                        ...List.generate(totalHours + 1, (index) {
                                          final hour = startHour + index;
                                          final isMajor = hour % 3 == 0;
                                          return Positioned(
                                            top: _gridTopOffset + index * _hourHeight,
                                            left: 0,
                                            right: 0,
                                            child: Divider(
                                              height: 1,
                                              thickness: isMajor ? 0.8 : 0.5,
                                              color: isMajor
                                                  ? borderCol.withValues(alpha: 0.5)
                                                  : borderCol.withValues(alpha: 0.25),
                                            ),
                                          );
                                        }),

                                        // 2. Free Study Windows (Hanya di antara dua kelas kuliah)
                                        ...freeWindows.map((fw) {
                                          final top = _gridTopOffset + (fw.startMinutes - matrixStartMin) * (_hourHeight / 60.0);
                                          final height = fw.durationMinutes * (_hourHeight / 60.0);

                                          return Positioned(
                                            top: top + 1.5,
                                            left: 3,
                                            right: 3,
                                            height: (height - 3).clamp(24.0, totalGridHeight),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showFreeStudyWindowDialog(context, fw),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: (isDark ? AppTheme.darkAccent : AppTheme.brandCobalt)
                                                        .withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: (isDark ? AppTheme.darkAccent : AppTheme.brandCobalt)
                                                          .withValues(alpha: 0.25),
                                                      width: 0.8,
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
                                                          const SizedBox(width: 4),
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
                                                      if (height >= 38)
                                                        Text(
                                                          fw.timeRangeFormatted,
                                                          style: TextStyle(
                                                            fontSize: 8.5,
                                                            color: textSecondary.withValues(alpha: 0.75),
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
                                          final top = _gridTopOffset + (sub.startMinutes - matrixStartMin) * (_hourHeight / 60.0);
                                          final height = sub.durationMinutes * (_hourHeight / 60.0);

                                          return Positioned(
                                            top: top + 1.5,
                                            left: 3,
                                            right: 3,
                                            height: (height - 3).clamp(32.0, totalGridHeight),
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
                                                              size: 10.5,
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

                                        // 4. Live Current Time Indicator Line (Hanya pada hari ini jika dalam jam matriks)
                                        if (isToday && currentMinutesOfDay >= matrixStartMin && currentMinutesOfDay <= matrixEndMin) ...[
                                          Positioned(
                                            top: _gridTopOffset + (currentMinutesOfDay - matrixStartMin) * (_hourHeight / 60.0) - 1,
                                            left: 0,
                                            right: 0,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.urgentRose,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    height: 1.5,
                                                    color: AppTheme.urgentRose.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
