import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/add_subject_dialog.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Subject Detail Screen
class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    final currentSubject = subjectProvider.getSubjectById(subject.id) ?? subject;
    final subjectTasks = taskProvider.getTasksForSubject(currentSubject.id);
    final pendingCount = subjectTasks.where((t) => !t.isCompleted).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSubject.name),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 20, color: textSecondary),
            tooltip: 'Edit Matkul',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddSubjectDialog(initialSubject: currentSubject),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.urgentRose),
            tooltip: 'Hapus Matkul',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Mata Kuliah?'),
                  content: Text('Anda yakin ingin menghapus "${currentSubject.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentRose),
                      onPressed: () {
                        subjectProvider.deleteSubject(currentSubject.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Block
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: currentSubject.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentSubject.code.isNotEmpty ? currentSubject.code : 'MATKUL',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text('• ${currentSubject.creditHours} SKS', style: TextStyle(fontSize: 12, color: textSecondary)),
                      const Spacer(),
                      Text(
                        '$pendingCount tugas aktif',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: pendingCount > 0 ? AppTheme.warningOchre : AppTheme.successSage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (currentSubject.lecturer.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Dosen: ${currentSubject.lecturer}', style: TextStyle(fontSize: 12.5, color: textSecondary)),
                    ),
                  if (currentSubject.room.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Ruangan: ${currentSubject.room}', style: TextStyle(fontSize: 12.5, color: textSecondary)),
                    ),
                  if (currentSubject.dayOfWeek != null)
                    Text(
                      'Jadwal: ${currentSubject.dayName} ${currentSubject.timeRange ?? ''}',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Associated Tasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAFTAR TUGAS MATKUL INI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
                ),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddTaskModal(),
                    );
                  },
                  child: Text(
                    '+ Tugas Baru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (subjectTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 36, color: textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada tugas untuk mata kuliah ini',
                        style: TextStyle(fontSize: 13.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: subjectTasks.map((t) => TaskCard(task: t)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
