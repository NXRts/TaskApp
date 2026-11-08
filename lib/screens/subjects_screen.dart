import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/add_subject_dialog.dart';
import 'subject_detail_screen.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Subjects Screen
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjects = subjectProvider.subjects;
    final totalSks = subjectProvider.totalCreditHours;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Text(
              '$totalSks SKS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Tambah Matkul',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddSubjectDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 40,
                    color: textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada mata kuliah',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daftarkan mata kuliah semester ini untuk mengelompokkan tugas.',
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderCol),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddSubjectDialog(),
                      );
                    },
                    child: const Text('Tambah Mata Kuliah', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final tasks = taskProvider.getTasksForSubject(subject.id);
                final pendingCount = tasks.where((t) => !t.isCompleted).length;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderCol, width: 0.8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectDetailScreen(subject: subject),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Subject dot + Name + SKS
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: subject.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subject.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${subject.creditHours} SKS',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Lecturer & Schedule info
                            if (subject.lecturer.isNotEmpty || subject.dayOfWeek != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  [
                                    if (subject.code.isNotEmpty) subject.code,
                                    if (subject.lecturer.isNotEmpty) subject.lecturer,
                                    if (subject.dayOfWeek != null)
                                      '${subject.dayName} (${subject.timeRange ?? ''})',
                                    if (subject.room.isNotEmpty) subject.room,
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                                ),
                              ),

                            const SizedBox(height: 10),
                            Divider(color: borderCol, height: 1),
                            const SizedBox(height: 8),

                            // Bottom row: Pending tasks count & arrow
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pendingCount > 0 ? '$pendingCount tugas aktif' : 'Semua tugas selesai',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: pendingCount > 0 ? AppTheme.warningOchre : AppTheme.successSage,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 12, color: textSecondary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
