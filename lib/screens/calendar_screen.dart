import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Calendar & Timeline Screen
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

  late DateTime _selectedDate;
  late DateTime _lastKnownToday;
  ScrollController? _dateScrollController;
  double _lastViewportWidth = 0;

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

  @override
  void initState() {
    super.initState();
    final today = _normalizeDate(DateTime.now());
    _lastKnownToday = today;
    _selectedDate = today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_pastDaysCount, animate: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (_dateScrollController == null) {
      _lastViewportWidth = screenWidth;
      _dateScrollController = ScrollController(
        initialScrollOffset: _calculateCenterOffset(_pastDaysCount, screenWidth),
      );
    } else if ((screenWidth - _lastViewportWidth).abs() > 1.0) {
      _lastViewportWidth = screenWidth;
      final selectedIndex = _pastDaysCount +
          _normalizeDate(_selectedDate).difference(_lastKnownToday).inDays;
      final targetIndex = selectedIndex.clamp(0, _totalDaysCount - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(targetIndex, animate: false);
      });
    }
  }

  @override
  void dispose() {
    _dateScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final now = DateTime.now();
    final today = _normalizeDate(now);

    // Jika hari sudah berganti (tanggal sebelumnya sudah terlewat), otomatis geser ke tanggal sekarang di tengah
    if (today != _lastKnownToday) {
      final previousToday = _lastKnownToday;
      _lastKnownToday = today;
      if (_normalizeDate(_selectedDate).isAtSameMomentAs(previousToday) ||
          _normalizeDate(_selectedDate).isBefore(today)) {
        _selectedDate = today;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToIndex(_pastDaysCount, animate: true);
        }
      });
    }

    final dayTasks = taskProvider.getTasksForDate(_selectedDate);
    final dateList = List.generate(_totalDaysCount, (index) {
      return today
          .subtract(const Duration(days: _pastDaysCount))
          .add(Duration(days: index));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender & Jadwal'),
        actions: [
          TextButton(
            onPressed: () {
              final currentToday = _normalizeDate(DateTime.now());
              setState(() {
                _lastKnownToday = currentToday;
                _selectedDate = currentToday;
              });
              _scrollToIndex(_pastDaysCount, animate: true);
            },
            child: Text(
              'Hari Ini',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Month Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Date Selector Strip (Things 3 style)
          SizedBox(
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
                final hasTasks = taskProvider.getTasksForDate(date).isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _scrollToIndex(index, animate: true);
                  },
                  child: Container(
                    width: _itemWidth,
                    margin: const EdgeInsets.symmetric(
                      horizontal: _itemHorizontalMargin,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                          : (isToday
                              ? (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                            : (isToday ? borderCol : Colors.transparent),
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
                            color: isSelected ? Colors.white70 : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Quiet dot indicator
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: hasTasks
                                ? (isSelected ? Colors.white : (isDark ? AppTheme.darkAccent : AppTheme.brandCobalt))
                                : Colors.transparent,
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

          const SizedBox(height: 10),
          Divider(color: borderCol, height: 1),

          // Day's Agenda Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(_selectedDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: textSecondary,
                  ),
                ),
                Text(
                  '${dayTasks.length} tugas',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
              ],
            ),
          ),

          // Day's Tasks
          Expanded(
            child: dayTasks.isEmpty
                ? Center(
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
                              builder: (_) => const AddTaskModal(),
                            );
                          },
                          child: const Text('Jadwalkan Tugas Baru', style: TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                    itemCount: dayTasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(task: dayTasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
