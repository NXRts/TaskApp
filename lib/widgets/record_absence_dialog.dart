import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_record.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';

class RecordAbsenceDialog extends StatefulWidget {
  final String subjectId;
  final int totalMeetings;
  final AttendanceRecord? initialRecord;
  final int? defaultMeetingNumber;

  const RecordAbsenceDialog({
    super.key,
    required this.subjectId,
    this.totalMeetings = 16,
    this.initialRecord,
    this.defaultMeetingNumber,
  });

  @override
  State<RecordAbsenceDialog> createState() => _RecordAbsenceDialogState();
}

class _RecordAbsenceDialogState extends State<RecordAbsenceDialog> {
  late int _meetingNumber;
  late DateTime _selectedDate;
  late String _type; // 'sakit', 'izin', 'alfa'
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;
    if (rec != null) {
      _meetingNumber = rec.meetingNumber;
      _selectedDate = rec.date;
      _type = rec.type;
      _noteController = TextEditingController(text: rec.note);
    } else {
      _meetingNumber = widget.defaultMeetingNumber ?? 1;
      _selectedDate = DateTime.now();
      _type = 'hadir';
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  void _submit() {
    final record = AttendanceRecord(
      id: widget.initialRecord?.id ?? const Uuid().v4(),
      meetingNumber: _meetingNumber,
      date: _selectedDate,
      type: _type,
      note: _noteController.text.trim(),
    );

    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    subjectProvider.recordAbsence(widget.subjectId, record);
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.initialRecord != null) {
      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
      subjectProvider.removeAbsence(widget.subjectId, widget.initialRecord!.id);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return AlertDialog(
      title: Text(
        widget.initialRecord != null ? 'Ubah Status Presensi Pertemuan' : 'Catat Presensi Perkuliahan',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pertemuan ke- & Tanggal
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      value: _meetingNumber,
                      decoration: InputDecoration(
                        labelText: 'Pertemuan',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: List.generate(widget.totalMeetings, (i) => i + 1).map((m) {
                        return DropdownMenuItem(value: m, child: Text('Ke-$m'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _meetingNumber = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: const Icon(Icons.calendar_today, size: 16),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: TextStyle(fontSize: 12.5, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Pilihan Status Presensi
              Text(
                'PILIH STATUS KEHADIRAN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildTypePill(
                    type: 'hadir',
                    label: 'Hadir',
                    icon: Icons.check_circle_outline,
                    activeColor: AppTheme.successSage,
                    borderCol: borderCol,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTypePill(
                    type: 'sakit',
                    label: 'Sakit',
                    icon: Icons.local_hospital_outlined,
                    activeColor: Colors.blue,
                    borderCol: borderCol,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTypePill(
                    type: 'izin',
                    label: 'Izin',
                    icon: Icons.assignment_outlined,
                    activeColor: AppTheme.warningOchre,
                    borderCol: borderCol,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTypePill(
                    type: 'alfa',
                    label: 'Alfa',
                    icon: Icons.cancel_outlined,
                    activeColor: AppTheme.urgentRose,
                    borderCol: borderCol,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Alasan / Keterangan
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Catatan / Materi / Alasan (Opsional)',
                  hintText: _type == 'hadir'
                      ? 'e.g. Masuk tatap muka / pembahasan materi'
                      : _type == 'sakit'
                          ? 'e.g. Demam, flu, surat dokter terlampir'
                          : _type == 'izin'
                              ? 'e.g. Urusan keluarga mendesak / lomba'
                              : 'e.g. Kesiangan / terkendala transportasi',
                  hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.initialRecord != null)
          TextButton(
            onPressed: _delete,
            child: const Text('Reset (Belum Kuliah)', style: TextStyle(color: AppTheme.urgentRose)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildTypePill({
    required String type,
    required String label,
    required IconData icon,
    required Color activeColor,
    required Color borderCol,
    required bool isDark,
  }) {
    final isSelected = _type == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : borderCol,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? activeColor : borderCol),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

