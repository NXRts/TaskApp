import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                    child: const Icon(Icons.school, size: 44, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Identitas Akademik',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Data ini disimpan aman secara offline di perangkat Anda.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nama
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Kampus
            TextFormField(
              controller: _campusController,
              decoration: InputDecoration(
                labelText: 'Kampus / Universitas / Sekolah',
                prefixIcon: const Icon(Icons.account_balance_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Prodi
            TextFormField(
              controller: _prodiController,
              decoration: InputDecoration(
                labelText: 'Program Studi / Jurusan',
                prefixIcon: const Icon(Icons.menu_book_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Semester
            DropdownButtonFormField<int>(
              value: _semester,
              decoration: InputDecoration(
                labelText: 'Semester Saat Ini',
                prefixIcon: const Icon(Icons.layers_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: List.generate(14, (i) => i + 1).map((s) {
                return DropdownMenuItem(value: s, child: Text('Semester $s'));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _semester = val);
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // About App
            const Text('Tentang TaskApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TaskApp v1.0.0 (Offline-First Edition)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Aplikasi manajemen tugas kuliah dan to-do list harian dengan arsitektur penyimpanan lokal cepat, fitur anti-prokrastinasi, dan manajemen mata kuliah.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

