import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import 'add_task_modal.dart';

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

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    // Refresh current task from provider if it changed
    final currentTask = taskProvider.allTasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );

    final subject = subjectProvider.getSubjectById(currentTask.subjectId);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Badges & Actions
            Row(
              children: [
                if (currentTask.category == TaskCategory.academic && subject != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: subject.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subject.color,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('👤 Pribadi', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentTask.typeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddTaskModal(initialTask: currentTask),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    taskProvider.deleteTask(currentTask.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Title
            Text(
              currentTask.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: currentTask.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),

            const SizedBox(height: 8),

            // Deadline info
            Row(
              children: [
                const Icon(Icons.alarm, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Tenggat: ${DateFormatter.formatFullDate(currentTask.dueDate)} (${DateFormatter.formatTime(currentTask.dueDate)})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (currentTask.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                currentTask.description,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Subtasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Langkah (Sub-tugas):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${currentTask.completedSubtasksCount}/${currentTask.subtasks.length} Selesai',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (currentTask.subtasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada sub-tugas. Tambahkan langkah kecil di bawah agar tidak menunda!',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              Column(
                children: currentTask.subtasks.map((sub) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: sub.isCompleted,
                      title: Text(
                        sub.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          decoration: sub.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: sub.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      activeColor: AppTheme.successGreen,
                      onChanged: (_) {
                        taskProvider.toggleSubTask(currentTask.id, sub.id);
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () {
                          taskProvider.deleteSubTask(currentTask.id, sub.id);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Add Subtask input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    decoration: InputDecoration(
                      hintText: '+ Tambah sub-tugas baru...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (val) {
                      taskProvider.addSubTask(currentTask.id, val);
                      _newSubtaskController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    taskProvider.addSubTask(
                      currentTask.id,
                      _newSubtaskController.text,
                    );
                    _newSubtaskController.clear();
                  },
                  child: const Text('Tambah'),
                ),
              ],
            ),

            // Attachments
            if (currentTask.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Tautan / Lampiran:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: currentTask.attachments.map((url) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tautan: $url')),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                decoration: TextDecoration.underline,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Notes
            if (currentTask.notes != null && currentTask.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Catatan Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text(
                  currentTask.notes!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Toggle Completion Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTask.isCompleted
                      ? Colors.grey
                      : AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(currentTask.isCompleted ? Icons.undo : Icons.check_circle),
                label: Text(
                  currentTask.isCompleted
                      ? 'Tandai Belum Selesai'
                      : 'Tandai Selesai (Selesai Dikerjakan)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  taskProvider.toggleTaskStatus(currentTask.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

