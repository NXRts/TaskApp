import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/subject.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import '../services/task_attachment_service.dart';
import 'task_attachment_tile.dart';
import 'task_attachment_picker_sheet.dart';
import 'add_task_modal.dart';

/// Modern Editorial Task Detail Bottom Sheet
class TaskDetailModal extends StatefulWidget {
  final TaskItem task;

  const TaskDetailModal({super.key, required this.task});

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  final TextEditingController _newSubtaskController = TextEditingController();

  @override
  void dispose() {
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _shareTaskToClipboard(BuildContext context, TaskItem task, Subject? subject) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *${task.title.toUpperCase()}*');
    if (subject != null) {
      buffer.writeln('📚 Mata Kuliah: ${subject.name}');
    }
    buffer.writeln(
        '⏰ Tenggat: ${DateFormatter.formatFullDate(task.dueDate)} (${DateFormatter.formatTime(task.dueDate)})');
    buffer.writeln('📌 Tipe: ${task.typeLabel}');

    if (task.subtasks.isNotEmpty) {
      buffer.writeln('\n*Checklist Pengerjaan:*');
      for (var sub in task.subtasks) {
        buffer.writeln('${sub.isCompleted ? "[x]" : "[ ]"} ${sub.title}');
      }
    }

    if (task.attachments.isNotEmpty) {
      buffer.writeln('\n*Lampiran / Berkas Tugas:*');
      for (var att in task.attachments) {
        buffer.writeln('• ${TaskAttachmentService.getDisplayName(att)}');
      }
    }

    if (task.notes != null && task.notes!.isNotEmpty) {
      buffer.writeln('\n📝 *Catatan:* ${task.notes}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Checklist tugas disalin! Siap dikirim ke WhatsApp/grup.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    final currentTask = taskProvider.allTasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );

    final subject = subjectProvider.getSubjectById(currentTask.subjectId);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Metadata Row & Action Icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: currentTask.category == TaskCategory.academic && subject != null
                        ? RichText(
                            text: TextSpan(
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: subject.color, shape: BoxShape.circle),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: subject.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                                TextSpan(
                                  text: '  •  ${currentTask.typeLabel}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            'Pribadi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                      tooltip: 'Edit',
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddTaskModal(initialTask: currentTask),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.urgentRose),
                      tooltip: 'Hapus',
                      onPressed: () {
                        taskProvider.deleteTask(currentTask.id);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              currentTask.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                decoration: currentTask.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),

            const SizedBox(height: 6),

            // Deadline info
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: currentTask.isOverdue && !currentTask.isCompleted
                      ? AppTheme.urgentRose
                      : textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Tenggat: ${DateFormatter.formatFullDate(currentTask.dueDate)} (${DateFormatter.formatTime(currentTask.dueDate)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: currentTask.isOverdue && !currentTask.isCompleted
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: currentTask.isOverdue && !currentTask.isCompleted
                          ? AppTheme.urgentRose
                          : textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            if (currentTask.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                currentTask.description,
                style: TextStyle(fontSize: 13, height: 1.35, color: textSecondary),
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: borderCol),
            const SizedBox(height: 12),

            // Sub-tugas Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUB-TUGAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: textSecondary,
                  ),
                ),
                Text(
                  '${currentTask.completedSubtasksCount} dari ${currentTask.subtasks.length} Selesai',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (currentTask.subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Belum ada sub-tugas. Tambahkan langkah kecil di bawah:',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              )
            else
              Column(
                children: currentTask.subtasks.map((sub) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taskProvider.toggleSubTask(currentTask.id, sub.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: sub.isCompleted ? AppTheme.successSage : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: sub.isCompleted
                                      ? AppTheme.successSage
                                      : (isDark ? const Color(0xFF3F424E) : const Color(0xFFD4D4D8)),
                                  width: 1.3,
                                ),
                              ),
                              child: sub.isCompleted
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sub.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: sub.isCompleted ? textSecondary : textPrimary,
                              decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close, size: 15, color: textSecondary),
                          onPressed: () => taskProvider.deleteSubTask(currentTask.id, sub.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            // Add subtask input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    style: TextStyle(fontSize: 12.5, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: '+ Tambah langkah baru...',
                      hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    ),
                    onSubmitted: (val) {
                      taskProvider.addSubTask(currentTask.id, val);
                      _newSubtaskController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: borderCol),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  ),
                  onPressed: () {
                    taskProvider.addSubTask(currentTask.id, _newSubtaskController.text);
                    _newSubtaskController.clear();
                  },
                  child: const Text('Tambah', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

            // Attachments Section
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LAMPIRAN & DOKUMEN TUGAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: textSecondary,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () async {
                    final picked = await TaskAttachmentPickerSheet.show(context);
                    if (picked.isNotEmpty && context.mounted) {
                      for (final p in picked) {
                        await taskProvider.addAttachmentToTask(currentTask.id, p);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              picked.length == 1
                                  ? 'Berhasil melampirkan 1 berkas'
                                  : 'Berhasil melampirkan ${picked.length} berkas',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppTheme.brandCobalt),
                        const SizedBox(width: 4),
                        const Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandCobalt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (currentTask.attachments.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await TaskAttachmentPickerSheet.show(context);
                    if (picked.isNotEmpty && context.mounted) {
                      for (final p in picked) {
                        await taskProvider.addAttachmentToTask(currentTask.id, p);
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.attachment_rounded, size: 18, color: textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Belum ada foto catatan atau PDF soal. Ketuk untuk melampirkan.',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Column(
                children: currentTask.attachments.map((att) {
                  return TaskAttachmentTile(
                    pathOrUrl: att,
                    showDeleteButton: true,
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(
                            'Hapus Lampiran?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          content: Text(
                            'Apakah Anda yakin ingin menghapus lampiran "${TaskAttachmentService.getDisplayName(att)}"?',
                            style: TextStyle(fontSize: 12.5, color: textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await taskProvider.removeAttachmentFromTask(currentTask.id, att);
                      }
                    },
                  );
                }).toList(),
              ),
            ],

            // Notes
            if (currentTask.notes != null && currentTask.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'CATATAN DOSEN / TIPS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: Text(
                  currentTask.notes!,
                  style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.3),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // 1-Click WhatsApp Export Button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderCol),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Salin Checklist untuk WhatsApp', style: TextStyle(fontSize: 12.5)),
                onPressed: () => _shareTaskToClipboard(context, currentTask, subject),
              ),
            ),

            const SizedBox(height: 8),

            // Toggle Completion Action
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTask.isCompleted
                      ? (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorder)
                      : AppTheme.successSage,
                  foregroundColor: currentTask.isCompleted ? textPrimary : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  taskProvider.toggleTaskStatus(currentTask.id);
                  Navigator.pop(context);
                },
                child: Text(
                  currentTask.isCompleted ? 'Buka Kembali Tugas' : 'Tandai Selesai',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
