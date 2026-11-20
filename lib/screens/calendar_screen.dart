import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../services/storage_service.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/task_detail_modal.dart';
import '../screens/subject_detail_screen.dart';
import '../screens/schedule_export_screen.dart';
import '../widgets/monthly_calendar_grid.dart';
import '../utils/app_theme.dart';

/// Helper class for 24-hour and 12-hour AM/PM time formatting
class CalendarTimeHelper {
  static String formatHourLabel(int hour, bool is24Hour) {
    if (is24Hour) {
      return '${hour.toString().padLeft(2, '0')}:00';
    }
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  static String formatMinutes(int minutes, bool is24Hour) {
    final h = (minutes ~/ 60).clamp(0, 24);
    final m = (minutes % 60).clamp(0, 59);
    final mStr = m.toString().padLeft(2, '0');
    if (is24Hour) {
      return '${h.toString().padLeft(2, '0')}:$mStr';
    }
    final displayHour = h % 12 == 0 ? 12 : h % 12;
    final period = h >= 12 && h < 24 ? 'PM' : 'AM';
    return '$displayHour:$mStr $period';
  }

  static String formatDateTime(DateTime dateTime, bool is24Hour) {
    return formatMinutes(dateTime.hour * 60 + dateTime.minute, is24Hour);
  }
}

/// Helper model for timeline rendering
class _TimelineItem {
  final String id;
  final bool isSubject;
  final int startMinutes;
  final int endMinutes;
  final Subject? subject;
  final TaskItem? task;

  const _TimelineItem({
    required this.id,
    required this.isSubject,
    required this.startMinutes,
    required this.endMinutes,
    this.subject,
    this.task,
  });
}

class _PositionedItem {
  final _TimelineItem item;
  final int colIndex;
  final int totalCols;
  final double left;
  final double width;

  const _PositionedItem({
    required this.item,
    required this.colIndex,
    required this.totalCols,
    required this.left,
    required this.width,
  });
}

/// Modern Editorial Calendar & Daily Timetable Screen
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _pastDaysCount = 14;
  static const int _totalDaysCount = 45;
  static const double _itemWidth = 48.0;
  static const double _itemHorizontalMargin = 3.0;
  static const double _itemExtent = _itemWidth + (_itemHorizontalMargin * 2);
  static const double _listHorizontalPadding = 16.0;

  static const double _hourHeight = 62.0;
  static const double _timeColWidth = 56.0;
  static const double _gridTopOffset = 14.0;

  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  late DateTime _lastKnownToday;
  ScrollController? _dateScrollController;
  final ScrollController _timelineScrollController = ScrollController();
  double _lastViewportWidth = 0;

  // View state: 0 = Garis Waktu (Timeline Timetable), 1 = Daftar Tugas (List)
  int _selectedView = 0;
  bool _is24HourFormat = true;
  bool _isMonthlyView = false;

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  double _calculateCenterOffset(int index, double viewportWidth) {
    final double itemCenter =
        _listHorizontalPadding + (index * _itemExtent) + (_itemExtent / 2);
    final double targetOffset = itemCenter - (viewportWidth / 2);
    return targetOffset < 0.0 ? 0.0 : targetOffset;
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    final controller = _dateScrollController;
    if (controller == null || !controller.hasClients) return;
    final viewportWidth = controller.position.viewportDimension;
    final maxScroll = controller.position.maxScrollExtent;
    final targetOffset =
        _calculateCenterOffset(index, viewportWidth).clamp(0.0, maxScroll);
    if (animate) {
      controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      controller.jumpTo(targetOffset);
    }
  }

  void _scrollToAppropriateHour({bool animate = true}) {
    if (!_timelineScrollController.hasClients) return;
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final targetHour = isToday ? (now.hour - 1).clamp(0, 23) : 7;
    final targetOffset = (_gridTopOffset + targetHour * _hourHeight - 16.0)
        .clamp(0.0, _timelineScrollController.position.maxScrollExtent);

    if (animate) {
      _timelineScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _timelineScrollController.jumpTo(targetOffset);
    }
  }

  @override
  void initState() {
    super.initState();
    final today = _normalizeDate(DateTime.now());
    _lastKnownToday = today;
    _selectedDate = today;
    _focusedMonth = DateTime(today.year, today.month, 1);
    _is24HourFormat = StorageService.instance.getIs24HourTimeFormat();
    _isMonthlyView = StorageService.instance.getIsMonthlyCalendarView();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMonthlyView) {
        _scrollToIndex(_pastDaysCount, animate: false);
      }
      _scrollToAppropriateHour(animate: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (_dateScrollController == null) {
      _lastViewportWidth = screenWidth;
      _dateScrollController = ScrollController(
        initialScrollOffset: _calculateCenterOffset(
          _resolveStripSelectedIndex(_lastKnownToday),
          screenWidth,
        ),
      );
    } else if ((screenWidth - _lastViewportWidth).abs() > 1.0) {
      _lastViewportWidth = screenWidth;
      if (!_isMonthlyView) {
        final targetIndex = _resolveStripSelectedIndex(_lastKnownToday);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(targetIndex, animate: false);
        });
      }
    }
  }

  @override
  void dispose() {
    _dateScrollController?.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _toggleTimeFormat() {
    setState(() {
      _is24HourFormat = !_is24HourFormat;
    });
    StorageService.instance.setIs24HourTimeFormat(_is24HourFormat);
  }

  void _toggleCalendarDisplayMode(bool isMonthly) {
    if (_isMonthlyView == isMonthly) return;
    setState(() {
      _isMonthlyView = isMonthly;
      _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });
    StorageService.instance.setIsMonthlyCalendarView(isMonthly);
    if (!isMonthly) {
      final today = _normalizeDate(DateTime.now());
      final selectedIndex = _resolveStripSelectedIndex(today);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(selectedIndex, animate: false);
      });
    }
  }

  void _changeFocusedMonth(int monthDelta) {
    final today = _normalizeDate(DateTime.now());
    final newMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + monthDelta, 1);
    setState(() {
      _focusedMonth = newMonth;
      if (_selectedDate.year != newMonth.year ||
          _selectedDate.month != newMonth.month) {
        if (newMonth.year == today.year && newMonth.month == today.month) {
          _selectedDate = today;
        } else {
          _selectedDate = newMonth;
        }
      }
    });
    if (_selectedView == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAppropriateHour(animate: true);
      });
    }
  }

  bool _isDateInDefaultStrip(DateTime today) {
    final diff = _normalizeDate(_selectedDate).difference(today).inDays;
    return diff >= -_pastDaysCount && diff < (_totalDaysCount - _pastDaysCount);
  }

  int _resolveStripSelectedIndex(DateTime today) {
    if (!_isDateInDefaultStrip(today)) {
      return _pastDaysCount;
    }
    return (_pastDaysCount +
            _normalizeDate(_selectedDate).difference(today).inDays)
        .clamp(0, _totalDaysCount - 1);
  }

  List<DateTime> _buildStripDateList(DateTime today) {
    final anchor =
        _isDateInDefaultStrip(today) ? today : _normalizeDate(_selectedDate);
    return List.generate(_totalDaysCount, (index) {
      return DateTime(
        anchor.year,
        anchor.month,
        anchor.day - _pastDaysCount + index,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    final now = DateTime.now();
    final today = _normalizeDate(now);

    // Auto-advance today if midnight crossed
    if (today != _lastKnownToday) {
      final previousToday = _lastKnownToday;
      _lastKnownToday = today;
      if (_normalizeDate(_selectedDate).isAtSameMomentAs(previousToday) ||
          _normalizeDate(_selectedDate).isBefore(today)) {
        _selectedDate = today;
        _focusedMonth = DateTime(today.year, today.month, 1);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (!_isMonthlyView) {
            _scrollToIndex(_resolveStripSelectedIndex(today), animate: true);
          }
          _scrollToAppropriateHour(animate: true);
        }
      });
    }

    final dayTasks = taskProvider.getTasksForDate(_selectedDate);
    final daySubjects = subjectProvider.subjects
        .where((s) => s.dayOfWeek == _selectedDate.weekday)
        .toList();

    final dateList = _buildStripDateList(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender & Jadwal'),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Ekspor Wallpaper & PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleExportScreen()),
              );
            },
          ),
          TextButton(
            onPressed: () {
              final currentToday = _normalizeDate(DateTime.now());
              setState(() {
                _lastKnownToday = currentToday;
                _selectedDate = currentToday;
                _focusedMonth =
                    DateTime(currentToday.year, currentToday.month, 1);
              });
              if (!_isMonthlyView) {
                _scrollToIndex(_pastDaysCount, animate: true);
              }
              _scrollToAppropriateHour(animate: true);
            },
            child: Text(
              'Hari Ini',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: accentCol,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Month Label + Month Navigation + Strip/Monthly Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('MMMM yyyy')
                              .format(
                                _isMonthlyView ? _focusedMonth : _selectedDate,
                              )
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isMonthlyView) ...[
                        const SizedBox(width: 6),
                        _buildMonthNavButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Bulan Sebelumnya',
                          onTap: () => _changeFocusedMonth(-1),
                          textSecondary: textSecondary,
                          borderCol: borderCol,
                        ),
                        const SizedBox(width: 4),
                        _buildMonthNavButton(
                          icon: Icons.chevron_right_rounded,
                          tooltip: 'Bulan Berikutnya',
                          onTap: () => _changeFocusedMonth(1),
                          textSecondary: textSecondary,
                          borderCol: borderCol,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildCalendarDisplayToggle(
                  isDark,
                  textPrimary,
                  textSecondary,
                  borderCol,
                  accentCol,
                ),
              ],
            ),
          ),

          // Calendar Selector: Horizontal Strip OR Full Monthly Grid View
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isMonthlyView
                ? GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -250) {
                        _changeFocusedMonth(1);
                      } else if (velocity > 250) {
                        _changeFocusedMonth(-1);
                      }
                    },
                    child: MonthlyCalendarGrid(
                      focusedMonth: _focusedMonth,
                      selectedDate: _selectedDate,
                      today: today,
                      tasks: taskProvider.allTasks,
                      subjects: subjectProvider.subjects,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                          _focusedMonth = DateTime(date.year, date.month, 1);
                        });
                        if (_selectedView == 0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToAppropriateHour(animate: true);
                          });
                        }
                      },
                    ),
                  )
                : SizedBox(
                    height: 70,
                    child: ListView.builder(
                      controller: _dateScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: _listHorizontalPadding,
                      ),
                      itemExtent: _itemExtent,
                      itemCount: dateList.length,
                      itemBuilder: (context, index) {
                        final date = dateList[index];
                        final isSelected = date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;
                        final isToday = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final hasTasks =
                            taskProvider.getTasksForDate(date).isNotEmpty;
                        final hasClasses = subjectProvider.subjects
                            .any((s) => s.dayOfWeek == date.weekday);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _focusedMonth =
                                  DateTime(date.year, date.month, 1);
                            });
                            _scrollToIndex(index, animate: true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToAppropriateHour(animate: true);
                            });
                          },
                          child: Container(
                            width: _itemWidth,
                            margin: const EdgeInsets.symmetric(
                              horizontal: _itemHorizontalMargin,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppTheme.darkAccent
                                      : AppTheme.lightAccent)
                                  : (isToday
                                      ? (isDark
                                          ? AppTheme.darkSurfaceElevated
                                          : AppTheme.lightBorderSubtle)
                                      : Colors.transparent),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                        ? AppTheme.darkAccent
                                        : AppTheme.lightAccent)
                                    : (isToday
                                        ? borderCol
                                        : Colors.transparent),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white70
                                        : textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Quiet dot indicator
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: hasTasks
                                        ? (isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? AppTheme.darkAccent
                                                : AppTheme.brandCobalt))
                                        : (hasClasses
                                            ? (isSelected
                                                ? Colors.white70
                                                : (isDark
                                                    ? Colors.white30
                                                    : Colors.black26))
                                            : Colors.transparent),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          const SizedBox(height: 6),
          Divider(color: borderCol, height: 1),

          // Day's Agenda Controls & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Date title + View Mode Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_selectedDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View Toggle (Garis Waktu vs Daftar)
                    _buildViewSwitcher(isDark, textPrimary, textSecondary, borderCol, accentCol),
                  ],
                ),
                const SizedBox(height: 8),
                // Bottom row: Counts badge + Time Format Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (daySubjects.isNotEmpty) ...[
                          _buildBadge(
                            label: '${daySubjects.length} Kuliah',
                            icon: Icons.school_outlined,
                            color: accentCol,
                          ),
                          const SizedBox(width: 6),
                        ],
                        _buildBadge(
                          label: '${dayTasks.length} Tugas',
                          icon: Icons.check_circle_outline_rounded,
                          color: dayTasks.isNotEmpty ? AppTheme.urgentRose : textSecondary,
                        ),
                      ],
                    ),
                    // 24 Jam vs 12 Jam AM/PM Toggle Button
                    _buildTimeFormatButton(isDark, textPrimary, textSecondary, borderCol, accentCol),
                  ],
                ),
              ],
            ),
          ),

          // Main Content: Garis Waktu (Timetable Hours) or Daftar Tugas (List)
          Expanded(
            child: _selectedView == 0
                ? _buildTimetableHoursView(
                    context,
                    daySubjects,
                    dayTasks,
                    isDark,
                    textPrimary,
                    textSecondary,
                    borderCol,
                    accentCol,
                  )
                : _buildTasksListView(
                    context,
                    dayTasks,
                    isDark,
                    textSecondary,
                    borderCol,
                  ),
          ),
        ],
      ),
    );
  }

  /// Calendar display mode toggle (Horizontal Strip vs Monthly Grid View)
  Widget _buildCalendarDisplayToggle(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color accentCol,
  ) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCalendarDisplayButton(
            icon: Icons.view_week_outlined,
            label: 'Strip',
            isSelected: !_isMonthlyView,
            onTap: () => _toggleCalendarDisplayMode(false),
            isDark: isDark,
            accentCol: accentCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildCalendarDisplayButton(
            icon: Icons.calendar_month_outlined,
            label: 'Bulanan',
            isSelected: _isMonthlyView,
            onTap: () => _toggleCalendarDisplayMode(true),
            isDark: isDark,
            accentCol: accentCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDisplayButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentCol,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? accentCol : textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color textSecondary,
    required Color borderCol,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderCol, width: 0.8),
        ),
        child: Icon(icon, size: 16, color: textSecondary),
      ),
    );
  }

  /// View switcher segmented widget
  Widget _buildViewSwitcher(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color accentCol,
  ) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton(
            index: 0,
            icon: Icons.schedule_rounded,
            label: 'Garis Waktu',
            isSelected: _selectedView == 0,
            isDark: isDark,
            accentCol: accentCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildViewButton(
            index: 1,
            icon: Icons.format_list_bulleted_rounded,
            label: 'Daftar',
            isSelected: _selectedView == 1,
            isDark: isDark,
            accentCol: accentCol,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color accentCol,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedView = index);
        if (index == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAppropriateHour(animate: false);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? accentCol : textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format jam 24h vs 12h toggle button
  Widget _buildTimeFormatButton(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color accentCol,
  ) {
    return InkWell(
      onTap: _toggleTimeFormat,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderCol, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled_rounded, size: 12, color: accentCol),
            const SizedBox(width: 5),
            Text(
              _is24HourFormat ? '24 Jam' : '12 Jam (AM/PM)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 13, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 24-Hour Timetable Grid View (Shows all 24 hours even if empty)
  Widget _buildTimetableHoursView(
    BuildContext context,
    List<Subject> daySubjects,
    List<TaskItem> dayTasks,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color accentCol,
  ) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final double totalHeight = _gridTopOffset + (24 * _hourHeight) + 96.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double rightColumnWidth =
            (constraints.maxWidth - _timeColWidth - 16.0).clamp(120.0, 1200.0);

        // Prepare timeline items
        final List<_TimelineItem> items = [];

        // 1. Add classes for this day
        for (final subject in daySubjects) {
          if (subject.startMinutes != 9999) {
            items.add(_TimelineItem(
              id: 'subject-${subject.id}',
              isSubject: true,
              startMinutes: subject.startMinutes,
              endMinutes: subject.safeEndMinutes,
              subject: subject,
            ));
          }
        }

        // 2. Add tasks for this day (clamp layout start so late tasks like 23:59 stay above 24:00)
        for (final task in dayTasks) {
          final rawMinutes = task.dueDate.hour * 60 + task.dueDate.minute;
          final layoutStart = rawMinutes.clamp(0, 1440 - 50);
          items.add(_TimelineItem(
            id: 'task-${task.id}',
            isSubject: false,
            startMinutes: layoutStart,
            endMinutes: layoutStart + 50,
            task: task,
          ));
        }

        // Position items to prevent overlaps
        final positionedItems = _calculateEventPositions(items, rightColumnWidth);

        return SingleChildScrollView(
          controller: _timelineScrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Background Hour Slots & Divider Lines (0 to 23)
                for (int hour = 0; hour < 24; hour++)
                  Positioned(
                    top: _gridTopOffset + (hour * _hourHeight),
                    left: _timeColWidth,
                    right: 0,
                    height: _hourHeight,
                    child: InkWell(
                      onTap: () {
                        // Quick add task prefilled at this hour
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddTaskModal(
                            initialDueDate: DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              hour,
                              0,
                            ),
                          ),
                        );
                      },
                      splashColor: accentCol.withValues(alpha: 0.05),
                      highlightColor: accentCol.withValues(alpha: 0.02),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: borderCol.withValues(alpha: 0.5),
                              width: 0.6,
                            ),
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.add_rounded,
                          size: 13,
                          color: textSecondary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),

                // Hour Time Labels (00:00 to 24:00) aligned evenly on each grid line
                for (int hour = 0; hour <= 24; hour++)
                  Positioned(
                    top: _gridTopOffset + (hour * _hourHeight) - 7.5,
                    left: 0,
                    width: _timeColWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        CalendarTimeHelper.formatHourLabel(hour, _is24HourFormat),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: textSecondary.withValues(alpha: 0.8),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                // Bottom 24:00 (12 AM) boundary line
                Positioned(
                  top: _gridTopOffset + (24 * _hourHeight),
                  left: _timeColWidth,
                  right: 0,
                  child: Container(
                    height: 0.6,
                    color: borderCol.withValues(alpha: 0.5),
                  ),
                ),

                // Vertical timeline separator between Time column and Grid
                Positioned(
                  top: _gridTopOffset,
                  height: 24 * _hourHeight,
                  left: _timeColWidth,
                  child: Container(
                    width: 0.8,
                    color: borderCol.withValues(alpha: 0.6),
                  ),
                ),

                // 2. Render Scheduled Classes & Tasks
                for (final pos in positionedItems)
                  _buildPositionedItemWidget(
                    pos,
                    isDark,
                    textPrimary,
                    textSecondary,
                    borderCol,
                    accentCol,
                  ),

                // 3. Live Current Time Line Indicator (Only when selected date is today)
                if (isToday) ...[
                  Builder(
                    builder: (context) {
                      final currentMinutes = now.hour * 60 + now.minute;
                      final indicatorTop = _gridTopOffset + (currentMinutes / 60.0) * _hourHeight;

                      return Positioned(
                        top: indicatorTop - 4,
                        left: _timeColWidth - 4,
                        right: 16,
                        child: Row(
                          children: [
                            // Current time dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.urgentRose,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Current time horizontal line
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: AppTheme.urgentRose.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calculate positions and split columns if events overlap
  List<_PositionedItem> _calculateEventPositions(
    List<_TimelineItem> events,
    double availableWidth,
  ) {
    final sorted = List<_TimelineItem>.from(events)
      ..sort((a, b) {
        final cmp = a.startMinutes.compareTo(b.startMinutes);
        if (cmp != 0) return cmp;
        return (b.endMinutes - b.startMinutes).compareTo(a.endMinutes - a.startMinutes);
      });

    final List<_PositionedItem> result = [];

    for (int i = 0; i < sorted.length; i++) {
      final ev = sorted[i];
      final overlaps = sorted.where((other) {
        if (other.id == ev.id) return false;
        return !(other.endMinutes <= ev.startMinutes || other.startMinutes >= ev.endMinutes);
      }).toList();

      if (overlaps.isEmpty) {
        result.add(_PositionedItem(
          item: ev,
          colIndex: 0,
          totalCols: 1,
          left: 6.0,
          width: availableWidth - 10.0,
        ));
      } else {
        int colIndex = 0;
        if (!ev.isSubject && overlaps.any((o) => o.isSubject)) {
          colIndex = 1;
        } else {
          final overlapBefore = overlaps.indexWhere((o) => sorted.indexOf(o) < i);
          if (overlapBefore != -1) {
            colIndex = 1;
          }
        }
        final colWidth = (availableWidth - 16.0) / 2.0;
        final left = 6.0 + (colIndex * (colWidth + 6.0));
        result.add(_PositionedItem(
          item: ev,
          colIndex: colIndex,
          totalCols: 2,
          left: left,
          width: colWidth,
        ));
      }
    }

    return result;
  }

  Widget _buildPositionedItemWidget(
    _PositionedItem pos,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color accentCol,
  ) {
    final item = pos.item;
    final double maxGridBottom = _gridTopOffset + (24 * _hourHeight);
    final double rawTop = _gridTopOffset + (item.startMinutes / 60.0) * _hourHeight;

    if (item.isSubject && item.subject != null) {
      final subject = item.subject!;
      final durationMinutes = item.endMinutes - item.startMinutes;
      final rawHeight = (durationMinutes / 60.0) * _hourHeight;
      final height = rawHeight.clamp(48.0, 500.0);

      final subjectColor = subject.color;
      final top = rawTop.clamp(_gridTopOffset, maxGridBottom - height);
      final timeStr =
          '${CalendarTimeHelper.formatMinutes(subject.startMinutes, _is24HourFormat)} - ${CalendarTimeHelper.formatMinutes(subject.safeEndMinutes, _is24HourFormat)}';

      return Positioned(
        top: top,
        left: _timeColWidth + pos.left,
        width: pos.width,
        height: height,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectDetailScreen(subject: subject),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: subjectColor.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: subjectColor.withValues(alpha: isDark ? 0.6 : 0.5),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        subject.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (subject.room.isNotEmpty) ...[
                      Icon(Icons.room_outlined, size: 11, color: textSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          subject.room,
                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${subject.creditHours} SKS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: subjectColor,
                      ),
                    ),
                  ],
                ),
                if (height > 58) ...[
                  const Spacer(),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else if (!item.isSubject && item.task != null) {
      final task = item.task!;
      const double height = 50.0;
      final double top = rawTop.clamp(_gridTopOffset, maxGridBottom - height);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final timeStr = CalendarTimeHelper.formatDateTime(task.dueDate, _is24HourFormat);

      Color priorityColor;
      switch (task.priority) {
        case TaskPriority.high:
          priorityColor = AppTheme.urgentRose;
          break;
        case TaskPriority.medium:
          priorityColor = AppTheme.warningOchre;
          break;
        case TaskPriority.low:
          priorityColor = AppTheme.successSage;
          break;
      }

      return Positioned(
        top: top,
        left: _timeColWidth + pos.left,
        width: pos.width,
        height: height,
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => TaskDetailModal(task: task),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: task.isCompleted
                    ? borderCol
                    : (task.isOverdue ? AppTheme.urgentRose.withValues(alpha: 0.5) : borderCol),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Completion Checkbox
                InkWell(
                  onTap: () {
                    taskProvider.toggleTaskStatus(task.id);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      task.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: task.isCompleted
                          ? AppTheme.successSage
                          : textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Priority Dot
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                // Title and Time
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted ? textSecondary : textPrimary,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted ? textSecondary : accentCol,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Traditional List View of Tasks
  Widget _buildTasksListView(
    BuildContext context,
    List<TaskItem> dayTasks,
    bool isDark,
    Color textSecondary,
    Color borderCol,
  ) {
    if (dayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 36,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Tidak ada tenggat tugas pada hari ini',
              style: TextStyle(fontSize: 13.5, color: textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderCol),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTaskModal(
                    initialDueDate: DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      23,
                      59,
                    ),
                  ),
                );
              },
              child: const Text('Jadwalkan Tugas Baru', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      itemCount: dayTasks.length,
      itemBuilder: (context, index) {
        return TaskCard(task: dayTasks[index]);
      },
    );
  }
}
