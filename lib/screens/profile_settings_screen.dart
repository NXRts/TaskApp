import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../services/storage_service.dart';
import '../services/task_reminder_service.dart';
import 'schedule_export_screen.dart';
import '../widgets/support_creator_card.dart';
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
    final settingsProvider = Provider.of<SettingsProvider>(context);

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

            // Visual Export Section
            Text(
              'EKSPOR VISUAL & DOKUMEN CETAK',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Buat Wallpaper Jadwal Kuliah HP (9:16) beresolusi tinggi atau unduh Dokumen Ringkasan Studi (PDF A4) lengkap dengan checklist tugas.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  side: BorderSide(color: borderCol),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Buka Studio Ekspor Jadwal (Wallpaper & PDF)', style: TextStyle(fontSize: 12.5)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScheduleExportScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: borderCol),
            const SizedBox(height: 16),

            // Notification & Smart Reminders Section
            Text(
              'NOTIFIKASI & PENGINGAT DEADLINE CERDAS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Jadwalkan alarm pengingat otomatis di ponsel agar tidak melewatkan batas pengumpulan tugas akademik.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
            ),
            const SizedBox(height: 10),
            Material(
              color: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: borderCol, width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Aktifkan Pengingat Deadline',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    subtitle: Text(
                      'Bunyikan alarm dan notifikasi sistem untuk tugas yang belum selesai',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                    value: settingsProvider.taskRemindersEnabled,
                    activeColor: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                    onChanged: (val) async {
                      await settingsProvider.setTaskRemindersEnabled(val);
                      if (context.mounted) {
                        final taskProv = Provider.of<TaskProvider>(context, listen: false);
                        await taskProv.syncReminders();
                      }
                    },
                  ),
                  if (settingsProvider.taskRemindersEnabled) ...[
                    Divider(color: borderCol.withValues(alpha: 0.5), height: 1),
                    CheckboxListTile(
                      title: Text(
                        '🔔 Pengingat H-1 Hari (Pukul 19:00)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      subtitle: Text(
                        'Pengingat malam hari sebelum hari H batas pengumpulan tugas',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      value: settingsProvider.reminderH1Enabled,
                      activeColor: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (val) async {
                        if (val != null) {
                          await settingsProvider.setReminderH1Enabled(val);
                          if (context.mounted) {
                            final taskProv = Provider.of<TaskProvider>(context, listen: false);
                            await taskProv.syncReminders();
                          }
                        }
                      },
                    ),
                    Divider(color: borderCol.withValues(alpha: 0.5), height: 1),
                    CheckboxListTile(
                      title: Text(
                        '⚠️ Pengingat Darurat H-3 Jam',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      subtitle: Text(
                        'Peringatan mendesak tepat 3 jam sebelum batas akhir pengumpulan',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      value: settingsProvider.reminderH3HoursEnabled,
                      activeColor: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (val) async {
                        if (val != null) {
                          await settingsProvider.setReminderH3HoursEnabled(val);
                          if (context.mounted) {
                            final taskProv = Provider.of<TaskProvider>(context, listen: false);
                            await taskProv.syncReminders();
                          }
                        }
                      },
                    ),
                    Divider(color: borderCol.withValues(alpha: 0.5), height: 1),
                    CheckboxListTile(
                      title: Text(
                        '🚨 Pengingat Kritis H-30 Menit',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      subtitle: Text(
                        'Peringatan darurat terakhir tepat 30 menit sebelum batas akhir pengumpulan',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      value: settingsProvider.reminderH30MinutesEnabled,
                      activeColor: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (val) async {
                        if (val != null) {
                          await settingsProvider.setReminderH30MinutesEnabled(val);
                          if (context.mounted) {
                            final taskProv = Provider.of<TaskProvider>(context, listen: false);
                            await taskProv.syncReminders();
                          }
                        }
                      },
                    ),
                    Divider(color: borderCol.withValues(alpha: 0.5), height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                size: 14,
                                color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Uji Coba Suara & Notifikasi Alarm:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTestAlarmChip(
                                  context: context,
                                  label: 'Tes H-1',
                                  icon: Icons.notifications_active_outlined,
                                  type: 0,
                                  isDark: isDark,
                                  borderCol: borderCol,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildTestAlarmChip(
                                  context: context,
                                  label: 'Tes H-3 Jam',
                                  icon: Icons.warning_amber_rounded,
                                  type: 1,
                                  isDark: isDark,
                                  borderCol: borderCol,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildTestAlarmChip(
                                  context: context,
                                  label: 'Tes H-30m',
                                  icon: Icons.alarm_on_rounded,
                                  type: 2,
                                  isDark: isDark,
                                  borderCol: borderCol,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 15,
                                  color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Panduan Alarm & Layar Mati (Lock Screen):',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Agar alarm berdering nyaring saat HP mati/terkunci dan aplikasi ditutup (terutama di Xiaomi MIUI/HyperOS, Samsung, & Oppo):\n• Notifikasi: aktifkan "Notifikasi Layar Kunci", "Notifikasi Mengambang", & "Suara".\n• Penghemat Baterai: pilih "Tidak ada pembatasan" agar sistem tidak menghentikan alarm.',
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.45,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      side: BorderSide(
                                        color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.open_in_new_rounded,
                                      size: 13,
                                      color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                    ),
                                    label: Text(
                                      'Setelan Notifikasi',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await TaskReminderService.openAppNotificationSettings();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      side: BorderSide(
                                        color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.battery_charging_full_rounded,
                                      size: 13,
                                      color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                    ),
                                    label: Text(
                                      'Hemat Baterai',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await TaskReminderService.openBatteryOptimizationSettings();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: borderCol),
            const SizedBox(height: 16),

            // Backup & Restore
            Text(
              'CADANGAN & KEDAULATAN DATA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Simpan atau pulihkan seluruh data aplikasi (Tugas, Sub-tugas, Mata Kuliah, Profil, Tema, & Sesi Fokus) dalam format teks JSON.',
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
                      // Simpan dulu perubahan form profil yang sedang diketik jika ada
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);

                      final storage = StorageService();
                      final jsonStr = storage.exportBackupJson(pretty: true);
                      Clipboard.setData(ClipboardData(text: jsonStr));

                      final totalSubtasks = taskProvider.allTasks.fold<int>(
                        0,
                        (sum, t) => sum + t.subtasks.length,
                      );

                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cadangan Lengkap Disalin! 🎉'),
                          content: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Seluruh data aplikasi telah disalin ke clipboard dalam format JSON:',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : AppTheme.lightBorderSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderCol, width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• Profil: ${settingsProvider.profile.name} (Sem. ${settingsProvider.profile.semester})',
                                        style: TextStyle(fontSize: 11.5, color: textPrimary),
                                      ),
                                      Text(
                                        '• Mata Kuliah: ${subjectProvider.subjects.length} matkul (${subjectProvider.totalCreditHours} SKS)',
                                        style: TextStyle(fontSize: 11.5, color: textPrimary),
                                      ),
                                      Text(
                                        '• Tugas: ${taskProvider.totalCount} tugas ($totalSubtasks sub-tugas)',
                                        style: TextStyle(fontSize: 11.5, color: textPrimary),
                                      ),
                                      Text(
                                        '• Fokus Pomodoro: ${settingsProvider.completedPomodoroSessions} sesi (${settingsProvider.totalFocusMinutes} menit)',
                                        style: TextStyle(fontSize: 11.5, color: textPrimary),
                                      ),
                                      Text(
                                        '• Pengaturan Tema: ${settingsProvider.isDarkMode ? "Dark Mode" : "Light Mode"}',
                                        style: TextStyle(fontSize: 11.5, color: textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 140),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurface : AppTheme.lightBorderSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: borderCol, width: 0.8),
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        jsonStr,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: jsonStr));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('📋 Teks JSON disalin ulang ke clipboard!')),
                                );
                              },
                              child: const Text('Salin Ulang'),
                            ),
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
                          title: const Text('Pulihkan Seluruh Data'),
                          content: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tempelkan (paste) teks JSON cadangan untuk memulihkan seluruh tugas, mata kuliah, profil, tema, dan sesi fokus:',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final clip = await Clipboard.getData(Clipboard.kTextPlain);
                                      if (clip?.text != null && clip!.text!.trim().isNotEmpty) {
                                        controller.text = clip.text!.trim();
                                      }
                                    },
                                    icon: const Icon(Icons.content_paste, size: 15),
                                    label: const Text(
                                      'Tempel dari Clipboard',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller: controller,
                                  maxLines: 6,
                                  style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                                  decoration: InputDecoration(
                                    hintText: '{"app": "TaskApp", "version": 2, ...}',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
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
                                      final taskProv = Provider.of<TaskProvider>(context, listen: false);
                                      final subProv = Provider.of<SubjectProvider>(context, listen: false);
                                      final settingsProv = Provider.of<SettingsProvider>(context, listen: false);

                                      taskProv.loadTasks();
                                      subProv.loadSubjects();
                                      settingsProv.reloadSettings();

                                      final restoredProfile = settingsProv.profile;
                                      setState(() {
                                        _nameController.text = restoredProfile.name;
                                        _campusController.text = restoredProfile.campus;
                                        _prodiController.text = restoredProfile.studyProgram;
                                        _semester = restoredProfile.semester.clamp(1, 14);
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '✅ Seluruh data berhasil dipulihkan (${subProv.subjects.length} matkul, ${taskProv.totalCount} tugas, profil & pengaturan)!',
                                          ),
                                        ),
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

            // Support Me / Creator Section
            Text(
              'DUKUNG PENGEMBANG',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            const SizedBox(height: 8),
            const SupportCreatorCard(),

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
                  Text('TaskApp v2.6.0 • Academic & Financial Student Hub', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    'Platform terintegrasi produktivitas akademik, presensi kuliah, jadwal wallpaper, deadline alarm, dan buku kas finansial mahasiswa. 100% Offline-First & Zero-Ad.',
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

  Widget _buildTestAlarmChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int type,
    required bool isDark,
    required Color borderCol,
  }) {
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: borderCol.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final result = await TaskReminderService.instance.showTestNotification(type: type);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: result.success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: result.success ? 4 : 6),
                action: result.isPermissionDenied
                    ? SnackBarAction(
                        label: 'Setelan',
                        textColor: Colors.white,
                        onPressed: () {
                          TaskReminderService.openAppNotificationSettings();
                        },
                      )
                    : null,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: accentCol),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
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
