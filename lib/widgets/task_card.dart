import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import 'task_detail_modal.dart';

/// Modern Editorial Task Item Component
/// Scannable in < 2 seconds, minimal visual noise, clear typographic hierarchy.
class TaskCard extends StatelessWidget {
  final TaskItem task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    final subject = subjectProvider.getSubjectById(task.subjectId);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    // Restrained deadline urgency color
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: task.isOverdue && !task.isCompleted
              ? AppTheme.urgentRose.withValues(alpha: 0.25)
              : borderCol,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
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
                  onTap: () {
                    Provider.of<TaskProvider>(context, listen: false)
                        .toggleTaskStatus(task.id);
                  },
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
                              Icon(Icons.link, size: 13, color: textSecondary),
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
      ),
    );
  }
}
