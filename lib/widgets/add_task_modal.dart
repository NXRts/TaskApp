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

/// Modern Editorial Add/Edit Task Bottom Sheet
class AddTaskModal extends StatefulWidget {
  final TaskItem? initialTask;
  final DateTime? initialDueDate;

  const AddTaskModal({super.key, this.initialTask, this.initialDueDate});

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

  bool _showAdvanced = false;

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
      _showAdvanced = task.attachments.isNotEmpty || (task.notes != null && task.notes!.isNotEmpty);
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _attachmentController = TextEditingController();
      _notesController = TextEditingController();
      _category = TaskCategory.academic;
      _priority = TaskPriority.medium;
      _taskType = TaskType.individual;
      _dueDate = widget.initialDueDate ?? DateTime.now().add(const Duration(days: 1));
      _dueTime = widget.initialDueDate != null
          ? TimeOfDay(hour: widget.initialDueDate!.hour, minute: widget.initialDueDate!.minute)
          : const TimeOfDay(hour: 23, minute: 59);
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
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
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
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      taskProvider.addTask(newTask);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final subjects = subjectProvider.subjects;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    if (_category == TaskCategory.academic &&
        _selectedSubjectId == null &&
        subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTask != null ? 'Edit Tugas' : 'Tugas Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, size: 20, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Segmented Category Switch (Kuliah vs Pribadi)
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: Row(
                  children: [
                    _buildCategorySegment(
                      title: '🎓 Tugas Kuliah',
                      isSelected: _category == TaskCategory.academic,
                      onTap: () => setState(() => _category = TaskCategory.academic),
                    ),
                    _buildCategorySegment(
                      title: '👤 Tugas Pribadi',
                      isSelected: _category == TaskCategory.personal,
                      onTap: () => setState(() => _category = TaskCategory.personal),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Title input
              TextFormField(
                controller: _titleController,
                autofocus: widget.initialTask == null,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Judul tugas atau aktivitas...',
                  hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderCol, width: 0.8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderCol, width: 0.8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Description input
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Deskripsi / catatan instruksi singkat...',
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderCol, width: 0.8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderCol, width: 0.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                ),
              ),

              const SizedBox(height: 14),

              // Academic Details (Subject Dropdown + Task Type)
              if (_category == TaskCategory.academic) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mata Kuliah',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AddSubjectDialog(),
                        );
                      },
                      child: Text(
                        '+ Matkul Baru',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                    ),
                    items: subjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub.id,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: sub.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(sub.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                  ),
                const SizedBox(height: 10),

                // Task Type Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildTaskTypeChip(TaskType.individual, 'Individu'),
                    _buildTaskTypeChip(TaskType.group, 'Kelompok'),
                    _buildTaskTypeChip(TaskType.practice, 'Praktikum'),
                    _buildTaskTypeChip(TaskType.quiz, 'Kuis'),
                    _buildTaskTypeChip(TaskType.exam, 'UTS/UAS'),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Deadline & Priority
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      ),
                      icon: Icon(Icons.calendar_today, size: 14, color: textSecondary),
                      label: Text(
                        DateFormatter.formatShortDate(_dueDate),
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      ),
                      icon: Icon(Icons.access_time, size: 14, color: textSecondary),
                      label: Text(
                        DateFormatter.formatTime(_dueDate),
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority selector chip
                  PopupMenuButton<TaskPriority>(
                    tooltip: 'Prioritas',
                    onSelected: (p) => setState(() => _priority = p),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderCol, width: 0.8),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _priority == TaskPriority.high
                                  ? AppTheme.urgentRose
                                  : (_priority == TaskPriority.medium
                                      ? AppTheme.warningOchre
                                      : AppTheme.infoSlate),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _priority == TaskPriority.high
                                ? 'Tinggi'
                                : (_priority == TaskPriority.medium ? 'Sedang' : 'Rendah'),
                            style: TextStyle(fontSize: 12, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: TaskPriority.low, child: Text('Rendah')),
                      PopupMenuItem(value: TaskPriority.medium, child: Text('Sedang')),
                      PopupMenuItem(value: TaskPriority.high, child: Text('Tinggi (Urgent)')),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Sub-tugas Section with Quick Templates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sub-tugas (Langkah Pengerjaan)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  // Quick Template Trigger
                  if (_subtasks.isEmpty)
                    PopupMenuButton<String>(
                      tooltip: 'Pilih Template Langkah',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 13, color: AppTheme.warningOchre),
                          const SizedBox(width: 3),
                          Text(
                            'Template Cepat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningOchre,
                            ),
                          ),
                        ],
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val == 'praktikum') {
                            _taskType = TaskType.practice;
                            _subtasks.addAll([
                              'Dasar Teori & Abstrak',
                              'Hasil Percobaan & Screenshot/Kode',
                              'Analisis Hasil & Jawaban Soal',
                              'Kesimpulan & Format PDF',
                            ]);
                          } else if (val == 'kelompok') {
                            _taskType = TaskType.group;
                            _subtasks.addAll([
                              'Diskusi Pembagian Bab',
                              'Penyusunan Makalah',
                              'Slide Presentasi Canva',
                              'Latihan Presentasi Kelompok',
                            ]);
                          } else if (val == 'resume') {
                            _subtasks.addAll([
                              'Membaca Paper & Highlight Poin',
                              'Tulis Ringkasan Masalah & Solusi',
                              'Format Sitasi Referensi (APA/IEEE)',
                            ]);
                          }
                        });
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'praktikum', child: Text('📑 Laporan Praktikum')),
                        PopupMenuItem(value: 'kelompok', child: Text('👥 Tugas Kelompok')),
                        PopupMenuItem(value: 'resume', child: Text('📝 Resume Jurnal / Buku')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Subtasks input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subTaskInputController,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: '+ Tambah langkah...',
                        hintStyle: TextStyle(fontSize: 13, color: textSecondary),
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
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: _addSubtask,
                  ),
                ],
              ),

              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: 6),
                Column(
                  children: _subtasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final title = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.crop_square, size: 14, color: textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(fontSize: 12.5, color: textPrimary),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _subtasks.removeAt(idx)),
                            child: Icon(Icons.close, size: 14, color: textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 10),

              // Progressive Disclosure Toggle for Secondary Details (Attachments / Notes)
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showAdvanced ? 'Sembunyikan Opsi Tambahan' : 'Tambah Lampiran & Catatan Dosen',
                        style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showAdvanced) ...[
                const SizedBox(height: 10),
                // Attachment field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _attachmentController,
                        style: TextStyle(fontSize: 12.5, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tautan Google Drive / LMS / Dokumen...',
                          hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                          prefixIcon: Icon(Icons.link, size: 16, color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: borderCol, width: 0.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: borderCol, width: 0.8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        ),
                        onSubmitted: (_) => _addAttachment(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _addAttachment,
                    ),
                  ],
                ),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: _attachments.asMap().entries.map((entry) {
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                        onDeleted: () => setState(() => _attachments.removeAt(entry.key)),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),

                // Notes field
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Catatan penting / syarat pengumpulan...',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(color: borderCol, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(color: borderCol, width: 0.8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.initialTask != null ? 'Simpan Perubahan' : 'Buat Tugas',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySegment({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppTheme.darkSurface : Colors.white;
    final activeText = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final inactiveText = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeText : inactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTypeChip(TaskType type, String label) {
    final isSelected = _taskType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _taskType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkAccent.withValues(alpha: 0.2) : AppTheme.lightAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? AppTheme.darkAccent : Colors.white)
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
