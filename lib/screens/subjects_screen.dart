import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/add_subject_dialog.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjects = subjectProvider.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mata Kuliah & Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Mata Kuliah',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddSubjectDialog(),
              );
            },
          ),
        ],
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada mata kuliah yang didaftarkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan mata kuliah untuk semester ini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Mata Kuliah'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddSubjectDialog(),
                      );
                    },
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 80),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final tasks = taskProvider.getTasksForSubject(subject.id);
                final pendingCount = tasks.where((t) => !t.isCompleted).length;

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectDetailScreen(subject: subject),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: subject.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subject.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: subject.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${subject.creditHours} SKS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: subject.color,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (subject.lecturer.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    subject.lecturer,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          if (subject.room.isNotEmpty || subject.dayOfWeek != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  '${subject.room.isNotEmpty ? subject.room : ''} ${subject.dayOfWeek != null ? "• ${subject.dayName} (${subject.timeRange ?? ''})" : ''}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pendingCount > 0
                                    ? '$pendingCount tugas belum selesai'
                                    : 'Tidak ada tugas pending',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: pendingCount > 0 ? Colors.orange[800] : Colors.green,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

