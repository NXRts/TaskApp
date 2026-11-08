import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/add_subject_dialog.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    // Refresh subject if edited
    final currentSubject = subjectProvider.getSubjectById(subject.id) ?? subject;
    final subjectTasks = taskProvider.getTasksForSubject(currentSubject.id);
    final pendingCount = subjectTasks.where((t) => !t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSubject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddSubjectDialog(initialSubject: currentSubject),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentSubject.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: currentSubject.color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentSubject.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentSubject.code.isNotEmpty ? currentSubject.code : 'MATKUL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentSubject.creditHours} SKS',
                        style: TextStyle(
                          color: currentSubject.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pendingCount Tugas Aktif',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentSubject.lecturer.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 6),
                          Text('Dosen: ${currentSubject.lecturer}'),
                        ],
                      ),
                    ),
                  if (currentSubject.room.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.room_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text('Ruang: ${currentSubject.room}'),
                        ],
                      ),
                    ),
                  if (currentSubject.dayOfWeek != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Jadwal: ${currentSubject.dayName} ${currentSubject.timeRange ?? ''}',
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tasks list for this course
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Tugas Mata Kuliah Ini:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Tugas'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddTaskModal(),
                    );
                  },
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
                      Icon(Icons.check_circle_outline, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada tugas untuk mata kuliah ini.',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
