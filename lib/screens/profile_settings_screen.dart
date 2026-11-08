import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Profile & Settings Screen
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _campusController;
  late TextEditingController _prodiController;
  late int _semester;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<SettingsProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.name);
    _campusController = TextEditingController(text: profile.campus);
    _prodiController = TextEditingController(text: profile.studyProgram);
    _semester = profile.semester;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _campusController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  void _save() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.updateProfile(
      name: _nameController.text.trim(),
      campus: _campusController.text.trim(),
      studyProgram: _prodiController.text.trim(),
      semester: _semester,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal Avatar Block
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderCol, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'M',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Identitas Akademik',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tersimpan secara lokal (offline-first) di perangkat Anda.',
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Fields
            _buildFieldLabel('Nama Lengkap', textSecondary),
            const SizedBox(height: 5),
            TextFormField(
              controller: _nameController,
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: _inputDecoration(borderCol, textSecondary, 'Nama Anda'),
            ),

            const SizedBox(height: 14),

            _buildFieldLabel('Kampus / Universitas / Sekolah', textSecondary),
            const SizedBox(height: 5),
            TextFormField(
              controller: _campusController,
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: _inputDecoration(borderCol, textSecondary, 'Nama Universitas/Kampus'),
            ),

            const SizedBox(height: 14),

            _buildFieldLabel('Program Studi / Jurusan', textSecondary),
            const SizedBox(height: 5),
            TextFormField(
              controller: _prodiController,
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: _inputDecoration(borderCol, textSecondary, 'Teknik Informatika / dsb.'),
            ),

            const SizedBox(height: 14),

            _buildFieldLabel('Semester Saat Ini', textSecondary),
            const SizedBox(height: 5),
            DropdownButtonFormField<int>(
              initialValue: _semester,
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: _inputDecoration(borderCol, textSecondary, ''),
              items: List.generate(14, (i) => i + 1).map((s) {
                return DropdownMenuItem(value: s, child: Text('Semester $s'));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _semester = val);
              },
            ),

            const SizedBox(height: 20),

            // Save Action
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _save,
                child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 28),
            Divider(color: borderCol),
            const SizedBox(height: 16),

            // Backup & Restore
            Text(
              'CADANGAN & KEDAULATAN DATA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Simpan salinan data tugas dan mata kuliah Anda ke teks JSON agar tidak hilang saat beralih perangkat.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: borderCol),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final storage = StorageService();
                      final jsonStr = storage.exportBackupJson();
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cadangan Disalin! 🎉'),
                          content: const Text(
                            'Teks data JSON cadangan Anda telah disalin ke clipboard. Anda bisa menyimpannya di aplikasi catatan.',
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Ekspor JSON', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: borderCol),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final controller = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Pulihkan Data Cadangan'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Tempelkan (paste) teks JSON cadangan di bawah:',
                                style: TextStyle(fontSize: 12.5),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: controller,
                                maxLines: 4,
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: '{"version": 1, ...}',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final text = controller.text.trim();
                                if (text.isNotEmpty) {
                                  final storage = StorageService();
                                  final success = await storage.importBackupJson(text);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (success) {
                                    if (context.mounted) {
                                      Provider.of<TaskProvider>(context, listen: false).loadTasks();
                                      Provider.of<SubjectProvider>(context, listen: false).loadSubjects();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Data berhasil dipulihkan!')),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('❌ Format JSON cadangan tidak valid.')),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Text('Pulihkan'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Impor JSON', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: borderCol),
            const SizedBox(height: 14),

            // About App
            Text(
              'TENTANG TASKAPP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TaskApp v2.0 • Modern Editorial Edition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    'Dibangun dengan arsitektur offline-first, desain minimalis intensional tanpa slop, dan fitur terfokus untuk mahasiswa.',
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    );
  }

  InputDecoration _inputDecoration(Color borderCol, Color hintCol, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: hintCol),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderCol, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderCol, width: 0.8),
      ),
    );
  }
}
