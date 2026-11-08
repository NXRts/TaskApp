import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';
import 'add_subject_dialog.dart';

class AddTaskModal extends StatefulWidget {
  final TaskItem? initialTask; // If editing

  const AddTaskModal({super.key, this.initialTask});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _attachmentController;
  late TextEditingController _notesController;
  final TextEditingController _subTaskInputController = TextEditingController();

  late TaskCategory _category;
  String? _selectedSubjectId;
  late TaskPriority _priority;
  late TaskType _taskType;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  final List<String> _subtasks = [];
  final List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    if (task != null) {
      _titleController = TextEditingController(text: task.title);
      _descController = TextEditingController(text: task.description);
      _attachmentController = TextEditingController();
      _notesController = TextEditingController(text: task.notes ?? '');
      _category = task.category;
      _selectedSubjectId = task.subjectId;
      _priority = task.priority;
      _taskType = task.taskType;
      _dueDate = task.dueDate;
      _dueTime = TimeOfDay.fromDateTime(task.dueDate);
      _subtasks.addAll(task.subtasks.map((s) => s.title));
      _attachments.addAll(task.attachments);
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _attachmentController = TextEditingController();
      _notesController = TextEditingController();
      _category = TaskCategory.academic;
      _priority = TaskPriority.medium;
      _taskType = TaskType.individual;
      _dueDate = DateTime.now().add(const Duration(days: 1));
      _dueTime = const TimeOfDay(hour: 23, minute: 59);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _attachmentController.dispose();
    _notesController.dispose();
    _subTaskInputController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueTime.hour,
          _dueTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _addSubtask() {
    final text = _subTaskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(text);
        _subTaskInputController.clear();
      });
    }
  }

  void _addAttachment() {
    final text = _attachmentController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _attachments.add(text);
        _attachmentController.clear();
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final finalDueDate = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (widget.initialTask != null) {
      final updated = widget.initialTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        subjectId: _category == TaskCategory.academic ? _selectedSubjectId : null,
        priority: _priority,
        taskType: _taskType,
        dueDate: finalDueDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        attachments: _attachments,
      );
      taskProvider.updateTask(updated);
    } else {
      final subtaskList = _subtasks
          .map((title) => SubTask(
                id: const Uuid().v4(),
                title: title,
                isCompleted: false,
              ))
          .toList();

      final newTask = TaskItem(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        subjectId: _category == TaskCategory.academic ? _selectedSubjectId : null,
        priority: _priority,
        taskType: _taskType,
        dueDate: finalDueDate,
        subtasks: subtaskList,
        attachments: _attachments,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      taskProvider.addTask(newTask);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final subjects = subjectProvider.subjects;

    // Auto select first subject if none selected
    if (_category == TaskCategory.academic &&
        _selectedSubjectId == null &&
        subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTask != null ? 'Edit Tugas' : 'Tambah Tugas Baru',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mode / Kategori: Akademik vs Pribadi
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _category = TaskCategory.academic),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _category == TaskCategory.academic
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '🎓 Tugas Kuliah',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _category == TaskCategory.academic
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _category = TaskCategory.personal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _category == TaskCategory.personal
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '👤 Tugas Pribadi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _category == TaskCategory.personal
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Tugas / Aktivitas *',
                  hintText: 'e.g. Laporan Praktikum Jaringan / Resume Bab 3',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.assignment_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tugas tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Description input
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Deskripsi / Detail Singkat',
                  hintText: 'Instruksi dosen, pembagian kelompok, dll.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // Mata Kuliah Dropdown (if Academic)
              if (_category == TaskCategory.academic) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mata Kuliah:', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Matkul Baru'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AddSubjectDialog(),
                        );
                      },
                    ),
                  ],
                ),
                if (subjects.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Belum ada mata kuliah. Tekan "Matkul Baru" di atas.'),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: subjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: sub.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(sub.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSubjectId = val);
                    },
                  ),
                const SizedBox(height: 14),

                // Tipe Tugas Kuliah
                const Text('Tipe Tugas:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildTypeChip(TaskType.individual, 'Individu'),
                    _buildTypeChip(TaskType.group, 'Kelompok'),
                    _buildTypeChip(TaskType.practice, 'Praktikum'),
                    _buildTypeChip(TaskType.quiz, 'Kuis'),
                    _buildTypeChip(TaskType.exam, 'UTS / UAS'),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Prioritas
              const Text('Prioritas:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildPriorityChip(TaskPriority.low, 'Rendah', AppTheme.infoBlue),
                  const SizedBox(width: 8),
                  _buildPriorityChip(TaskPriority.medium, 'Sedang', AppTheme.warningOrange),
                  const SizedBox(width: 8),
                  _buildPriorityChip(TaskPriority.high, 'Tinggi (Urgent)', AppTheme.urgentRed),
                ],
              ),

              const SizedBox(height: 16),

              // Tanggal & Jam Deadline
              const Text('Tenggat Waktu (Deadline):', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormatter.formatShortDate(_dueDate)),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(DateFormatter.formatTime(_dueDate)),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sub-tugas
              const Text('Pecah Jadi Sub-tugas (Anti-Prokrastinasi):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subTaskInputController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Baca Bab 1 / Buat Presentasi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSubtask,
                    child: const Text('Tambah'),
                  ),
                ],
              ),
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Column(
                  children: _subtasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final title = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () {
                              setState(() => _subtasks.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Lampiran Link (GDrive / LMS)
              const Text('Tautan Lampiran (Google Drive / LMS):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _attachmentController,
                      decoration: InputDecoration(
                        hintText: 'https://drive.google.com/...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: const Icon(Icons.link, size: 18),
                      ),
                      onSubmitted: (_) => _addAttachment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addAttachment,
                    child: const Text('+ Link'),
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _attachments.asMap().entries.map((entry) {
                    return Chip(
                      avatar: const Icon(Icons.link, size: 14),
                      label: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () {
                        setState(() => _attachments.removeAt(entry.key));
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Catatan
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Tambahan',
                  hintText: 'Syarat format pengumpulan, tips, dsb.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.initialTask != null ? 'Simpan Perubahan' : 'Buat Tugas',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(TaskType type, String label) {
    final isSelected = _taskType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _taskType = type);
      },
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, String label, Color color) {
    final isSelected = _priority == priority;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) setState(() => _priority = priority);
      },
    );
  }
}

