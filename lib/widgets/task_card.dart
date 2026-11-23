import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import 'task_detail_modal.dart';

/// Pure helper utilities for calculating quick reschedule target dates
/// while preserving the task's original deadline hour and minute.
class TaskRescheduleHelper {
  /// Tomorrow (`now + 1 day`) preserving [currentDueDate]'s time of day.
  static DateTime tomorrow(DateTime now, DateTime currentDueDate) {
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      currentDueDate.hour,
      currentDueDate.minute,
    );
  }

  /// Upcoming Saturday (`DateTime.saturday`) preserving [currentDueDate]'s time of day.
  /// If [now] is already Saturday or Sunday, schedules for the following Saturday.
  static DateTime upcomingWeekend(DateTime now, DateTime currentDueDate) {
    int daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    if (daysUntilSaturday <= 0) {
      daysUntilSaturday = 7;
    }
    return DateTime(
      now.year,
      now.month,
      now.day + daysUntilSaturday,
      currentDueDate.hour,
      currentDueDate.minute,
    );
  }

  /// Next week (`now + 7 days`) preserving [currentDueDate]'s time of day.
  static DateTime nextWeek(DateTime now, DateTime currentDueDate) {
    return DateTime(
      now.year,
      now.month,
      now.day + 7,
      currentDueDate.hour,
      currentDueDate.minute,
    );
  }
}

/// Modern Editorial Task Item Component with Custom Smooth Swipe Gestures:
/// - Swipe Right: Instant Complete / Reopen with progressive icon scale, haptic threshold tick & Undo snackbar.
/// - Swipe Left: Quick Reschedule (Besok, Akhir Pekan, Minggu Depan, Pilih Tanggal) or Delete.
class TaskCard extends StatefulWidget {
  final TaskItem task;
  final bool enableSwipeActions;

  const TaskCard({
    super.key,
    required this.task,
    this.enableSwipeActions = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 88.0;

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;
  double _dragOffset = 0.0;
  bool _hasCrossedThreshold = false;

  TaskItem get task => widget.task;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final anim = _snapAnimation;
        if (anim != null && mounted) {
          setState(() {
            _dragOffset = anim.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _triggerHaptic({bool heavy = false}) {
    try {
      if (heavy) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  void _animateBackToZero() {
    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutCubic,
      ),
    );
    _snapController.forward(from: 0.0);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_snapController.isAnimating) {
      _snapController.stop();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    final cardWidth = context.size?.width ?? 420.0;
    // Allow full 1:1 horizontal drag across the entire card width without artificial clamping
    final nextOffset = (_dragOffset + delta).clamp(-cardWidth, cardWidth);

    final crossedNow = nextOffset.abs() >= _triggerDistance;
    if (crossedNow && !_hasCrossedThreshold) {
      _hasCrossedThreshold = true;
      _triggerHaptic();
    } else if (!crossedNow && _hasCrossedThreshold) {
      _hasCrossedThreshold = false;
    }

    setState(() {
      _dragOffset = nextOffset;
    });
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final finalOffset = _dragOffset;
    final velocity = details.primaryVelocity ?? 0.0;
    final triggeredRight = finalOffset >= _triggerDistance ||
        (finalOffset > 36.0 && velocity > 650.0);
    final triggeredLeft = finalOffset <= -_triggerDistance ||
        (finalOffset < -36.0 && velocity < -650.0);

    _hasCrossedThreshold = false;
    _animateBackToZero();

    if (triggeredRight) {
      await _handleQuickComplete(context);
    } else if (triggeredLeft) {
      await _showQuickRescheduleOrDeleteSheet(context);
    }
  }

  void _onHorizontalDragCancel() {
    _hasCrossedThreshold = false;
    _animateBackToZero();
  }

  Future<void> _handleQuickComplete(BuildContext context) async {
    _triggerHaptic(heavy: true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final wasCompleted = task.isCompleted;
    await taskProvider.toggleTaskStatus(task.id);

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasCompleted
              ? '↩️ Tugas "${task.title}" diaktifkan kembali'
              : '✅ Tugas "${task.title}" selesai!',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () {
            taskProvider.toggleTaskStatus(task.id);
          },
        ),
      ),
    );
  }

  Future<void> _showQuickRescheduleOrDeleteSheet(BuildContext context) async {
    _triggerHaptic();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    final now = DateTime.now();
    final tomorrowDate = TaskRescheduleHelper.tomorrow(now, task.dueDate);
    final weekendDate = TaskRescheduleHelper.upcomingWeekend(now, task.dueDate);
    final nextWeekDate = TaskRescheduleHelper.nextWeek(now, task.dueDate);
    final dateFmt = DateFormat('EEE, d MMM • HH:mm');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: surfaceCol,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderCol, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: borderCol,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.warningOchre.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.update_rounded,
                      size: 18,
                      color: AppTheme.warningOchre,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tunda Deadline atau Hapus',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${task.title} • Tenggat: ${dateFmt.format(task.dueDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildRescheduleOptionTile(
                context: context,
                sheetCtx: sheetCtx,
                icon: Icons.wb_sunny_outlined,
                iconColor: AppTheme.warningOchre,
                title: 'Besok',
                subtitle: dateFmt.format(tomorrowDate),
                targetDate: tomorrowDate,
                isDark: isDark,
                borderCol: borderCol,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              _buildRescheduleOptionTile(
                context: context,
                sheetCtx: sheetCtx,
                icon: Icons.weekend_outlined,
                iconColor: accentCol,
                title: 'Akhir Pekan',
                subtitle: dateFmt.format(weekendDate),
                targetDate: weekendDate,
                isDark: isDark,
                borderCol: borderCol,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              _buildRescheduleOptionTile(
                context: context,
                sheetCtx: sheetCtx,
                icon: Icons.next_week_outlined,
                iconColor: AppTheme.successSage,
                title: 'Minggu Depan (+7 Hari)',
                subtitle: dateFmt.format(nextWeekDate),
                targetDate: nextWeekDate,
                isDark: isDark,
                borderCol: borderCol,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),

              // Custom Date & Time Picker Option
              Material(
                color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: borderCol, width: 0.8),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await _pickCustomRescheduleDate(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    child: Row(
                      children: [
                        Icon(Icons.edit_calendar_outlined, size: 18, color: accentCol),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Pilih Tanggal & Jam Lainnya...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: borderCol, height: 1),
              const SizedBox(height: 12),

              // Quick Delete Action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.urgentRose,
                    side: BorderSide(color: AppTheme.urgentRose.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    final deletedTitle = task.title;
                    await taskProvider.deleteTask(task.id);
                    if (context.mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('🗑️ Tugas "$deletedTitle" dihapus'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Hapus Tugas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRescheduleOptionTile({
    required BuildContext context,
    required BuildContext sheetCtx,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required DateTime targetDate,
    required bool isDark,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Material(
      color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderCol, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          Navigator.pop(sheetCtx);
          await _applyReschedule(context, targetDate, label: title);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyReschedule(
    BuildContext context,
    DateTime newDueDate, {
    required String label,
  }) async {
    _triggerHaptic(heavy: true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final previousDueDate = task.dueDate;
    await taskProvider.rescheduleTask(task.id, newDueDate);

    if (!context.mounted) return;
    final formatted = DateFormat('EEE, d MMM HH:mm').format(newDueDate);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('📅 Deadline "${task.title}" dijadwalkan ke $label ($formatted)'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () {
            taskProvider.rescheduleTask(task.id, previousDueDate);
          },
        ),
      ),
    );
  }

  Future<void> _pickCustomRescheduleDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = task.dueDate.isBefore(now) ? now : task.dueDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(task.dueDate),
    );
    if (!context.mounted) return;

    final newDueDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? task.dueDate.hour,
      pickedTime?.minute ?? task.dueDate.minute,
    );
    await _applyReschedule(context, newDueDate, label: 'Tanggal Kustom');
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    final subject = subjectProvider.getSubjectById(task.subjectId);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final cardBgColor =
        Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.darkSurface : AppTheme.lightSurface);
    final cardBorderColor = task.isOverdue && !task.isCompleted
        ? AppTheme.urgentRose.withValues(alpha: 0.25)
        : borderCol;

    Color deadlineColor;
    if (task.isCompleted) {
      deadlineColor = textSecondary;
    } else if (task.isOverdue || task.timeLeft.inHours <= 24) {
      deadlineColor = AppTheme.urgentRose;
    } else if (task.timeLeft.inDays <= 3) {
      deadlineColor = AppTheme.warningOchre;
    } else {
      deadlineColor = textSecondary;
    }

    final innerRow = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TaskDetailModal(task: task),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Tactile Checkbox
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleQuickComplete(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? AppTheme.successSage
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: task.isCompleted
                            ? AppTheme.successSage
                            : (isDark ? const Color(0xFF3F424E) : const Color(0xFFD4D4D8)),
                        width: 1.5,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),

              // Main Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiet Top Metadata Row (Subject dot + Name + Deadline)
                    Row(
                      children: [
                        if (task.category == TaskCategory.academic && subject != null) ...[
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: subject.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              subject.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          if (task.taskType != TaskType.individual &&
                              task.taskType != TaskType.general) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• ${task.typeLabel}',
                              style: TextStyle(fontSize: 10.5, color: textSecondary),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'Pribadi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Deadline pill / text
                        Text(
                          DateFormatter.formatDeadlineCountdown(task.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: (task.isOverdue || task.timeLeft.inHours <= 24) && !task.isCompleted
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: deadlineColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Task Title
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted ? textSecondary.withValues(alpha: 0.7) : textPrimary,
                      ),
                    ),

                    // Short Description if available
                    if (task.description.isNotEmpty && !task.isCompleted) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],

                    // Progressive Disclosure Bottom Metadata (Subtasks / Links / Notes)
                    if ((task.subtasks.isNotEmpty || task.attachments.isNotEmpty || task.notes != null) &&
                        !task.isCompleted) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          if (task.subtasks.isNotEmpty) ...[
                            Icon(Icons.checklist, size: 13, color: textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              '${task.completedSubtasksCount}/${task.subtasks.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (task.attachments.isNotEmpty) ...[
                            Icon(Icons.attach_file_rounded, size: 13, color: textSecondary),
                            const SizedBox(width: 2),
                            Text(
                              '${task.attachments.length}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (task.notes != null && task.notes!.isNotEmpty) ...[
                            Icon(Icons.notes, size: 13, color: textSecondary),
                            const SizedBox(width: 2),
                            Text('Catatan', style: TextStyle(fontSize: 11, color: textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cardBorderColor,
          width: 0.8,
        ),
        boxShadow: _dragOffset.abs() > 1.5
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: innerRow,
    );

    if (!widget.enableSwipeActions) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: cardWidget,
      );
    }

    final progress = (_dragOffset.abs() / _triggerDistance).clamp(0.0, 1.0);
    final isSwipingRight = _dragOffset > 0;
    final isThresholdReady = _dragOffset.abs() >= _triggerDistance;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onHorizontalDragCancel: _onHorizontalDragCancel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Recessed Action Layer (only rendered while dragging/snapping)
              if (_dragOffset.abs() > 0.5)
                Positioned.fill(
                  child: isSwipingRight
                      ? _buildSwipeRightActionUnderlay(
                          isDark: isDark,
                          progress: progress,
                          isReady: isThresholdReady,
                        )
                      : _buildSwipeLeftActionUnderlay(
                          isDark: isDark,
                          progress: progress,
                          isReady: isThresholdReady,
                        ),
                ),

              // Intact Rounded Foreground Card
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: cardWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Swipe Right Underlay: Instant Complete / Reopen
  Widget _buildSwipeRightActionUnderlay({
    required bool isDark,
    required double progress,
    required bool isReady,
  }) {
    final accent = task.isCompleted ? AppTheme.brandCobalt : AppTheme.successSage;
    final label = task.isCompleted ? 'Aktifkan' : 'Selesai';
    final icon = task.isCompleted ? Icons.replay_rounded : Icons.check_rounded;
    final scale = 0.88 + (0.12 * Curves.easeOutBack.transform(progress));
    final opacity = (0.35 + 0.65 * progress).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.only(left: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReady
              ? accent.withValues(alpha: isDark ? 0.45 : 0.35)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: 0.8,
        ),
      ),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isReady
                  ? accent
                  : accent.withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isReady
                    ? accent
                    : accent.withValues(alpha: isDark ? 0.38 : 0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14.5,
                  color: isReady ? Colors.white : accent,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: isReady
                        ? Colors.white
                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Swipe Left Underlay: Quick Reschedule (Besok / Akhir Pekan / Minggu Depan) or Delete
  Widget _buildSwipeLeftActionUnderlay({
    required bool isDark,
    required double progress,
    required bool isReady,
  }) {
    final scale = 0.88 + (0.12 * Curves.easeOutBack.transform(progress));
    final opacity = (0.35 + 0.65 * progress).clamp(0.0, 1.0);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.only(right: 12),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReady
              ? AppTheme.warningOchre.withValues(alpha: isDark ? 0.45 : 0.35)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: 0.8,
        ),
      ),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: isReady
                      ? AppTheme.warningOchre
                      : AppTheme.warningOchre.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isReady
                        ? AppTheme.warningOchre
                        : AppTheme.warningOchre.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13.5,
                      color: isReady ? Colors.white : AppTheme.warningOchre,
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      'Tunda',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: isReady ? Colors.white : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.urgentRose.withValues(
                    alpha: isReady ? (isDark ? 0.24 : 0.16) : (isDark ? 0.14 : 0.09),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.urgentRose.withValues(
                      alpha: isReady ? 0.45 : 0.28,
                    ),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 14.5,
                  color: AppTheme.urgentRose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
