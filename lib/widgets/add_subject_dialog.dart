import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';

class AddSubjectDialog extends StatefulWidget {
  final Subject? initialSubject;

  const AddSubjectDialog({super.key, this.initialSubject});

  @override
  State<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _lecturerController;
  late TextEditingController _roomController;
  late TextEditingController _timeController;

  late int _sks;
  int? _dayOfWeek;
  late int _colorValue;

  final List<int> _palette = [
    0xFF4F46E5, // Indigo
    0xFF059669, // Emerald
    0xFF7C3AED, // Violet
    0xFFD97706, // Amber
    0xFFE11D48, // Rose
    0xFF0284C7, // Sky
    0xFF0D9488, // Teal
    0xFFEA580C, // Orange
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.initialSubject;
    if (s != null) {
      _nameController = TextEditingController(text: s.name);
      _codeController = TextEditingController(text: s.code);
      _lecturerController = TextEditingController(text: s.lecturer);
      _roomController = TextEditingController(text: s.room);
      _timeController = TextEditingController(text: s.timeRange ?? '');
      _sks = s.creditHours;
      _dayOfWeek = s.dayOfWeek;
      _colorValue = s.colorValue;
    } else {
      _nameController = TextEditingController();
      _codeController = TextEditingController();
      _lecturerController = TextEditingController();
      _roomController = TextEditingController();
      _timeController = TextEditingController();
      _sks = 3;
      _dayOfWeek = 1;
      _colorValue = _palette.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _lecturerController.dispose();
    _roomController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);

    if (widget.initialSubject != null) {
      final updated = widget.initialSubject!.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        lecturer: _lecturerController.text.trim(),
        room: _roomController.text.trim(),
        creditHours: _sks,
        dayOfWeek: _dayOfWeek,
        timeRange: _timeController.text.trim().isNotEmpty
            ? _timeController.text.trim()
            : null,
        colorValue: _colorValue,
      );
      subjectProvider.updateSubject(updated);
    } else {
      final newSubject = Subject(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        lecturer: _lecturerController.text.trim(),
        room: _roomController.text.trim(),
        creditHours: _sks,
        dayOfWeek: _dayOfWeek,
        timeRange: _timeController.text.trim().isNotEmpty
            ? _timeController.text.trim()
            : null,
        colorValue: _colorValue,
      );
      subjectProvider.addSubject(newSubject);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialSubject != null ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Matkul
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Mata Kuliah *',
                    hintText: 'e.g. Pemrograman Web',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama mata kuliah tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Kode & SKS
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Kode Matkul',
                          hintText: 'e.g. IF301',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: _sks,
                        decoration: InputDecoration(
                          labelText: 'SKS',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [1, 2, 3, 4, 6].map((k) {
                          return DropdownMenuItem(value: k, child: Text('$k'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _sks = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dosen Pengampu
                TextFormField(
                  controller: _lecturerController,
                  decoration: InputDecoration(
                    labelText: 'Dosen Pengampu',
                    hintText: 'e.g. Dr. Irfan Hakim',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Ruangan / Link Kelas
                TextFormField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    labelText: 'Ruangan / Link Meet',
                    hintText: 'e.g. Lab Komputer 3 / Zoom',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Hari & Jam
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _dayOfWeek,
                        decoration: InputDecoration(
                          labelText: 'Hari',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Senin')),
                          DropdownMenuItem(value: 2, child: Text('Selasa')),
                          DropdownMenuItem(value: 3, child: Text('Rabu')),
                          DropdownMenuItem(value: 4, child: Text('Kamis')),
                          DropdownMenuItem(value: 5, child: Text('Jumat')),
                          DropdownMenuItem(value: 6, child: Text('Sabtu')),
                        ],
                        onChanged: (val) => setState(() => _dayOfWeek = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(
                          labelText: 'Jam Kuliah',
                          hintText: '08:00 - 10:30',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Warna Tema Matkul
                const Text('Pilih Warna Label:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _palette.map((colorInt) {
                    final isSelected = _colorValue == colorInt;
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = colorInt),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(colorInt),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Color(colorInt).withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

