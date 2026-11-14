import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../providers/settings_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../services/schedule_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/wallpaper_schedule_widget.dart';
import '../utils/app_theme.dart';

/// Screen for previewing and exporting Shareable Wallpaper (9:16 PNG) & Study Summary Document (PDF A4)
class ScheduleExportScreen extends StatefulWidget {
  const ScheduleExportScreen({super.key});

  @override
  State<ScheduleExportScreen> createState() => _ScheduleExportScreenState();
}

class _ScheduleExportScreenState extends State<ScheduleExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _wallpaperKey = GlobalKey();

  bool _showLecturerOnWallpaper = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleShareWallpaper() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ScheduleExportService.capturePng(_wallpaperKey, pixelRatio: 3.5);
      if (bytes != null && mounted) {
        await ScheduleExportService.shareWallpaper(bytes);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat gambar wallpaper')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat membagikan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleSaveWallpaper() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ScheduleExportService.capturePng(_wallpaperKey, pixelRatio: 3.5);
      if (bytes != null && mounted) {
        final file = await ScheduleExportService.savePngFile(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.successSage, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wallpaper tersimpan di: ${file.path}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan wallpaper: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentCol = isDark ? AppTheme.darkAccent : AppTheme.brandCobalt;

    final profile = settingsProvider.profile;
    final subjects = subjectProvider.subjects;
    final tasks = taskProvider.allTasks;
    final is24Hour = StorageService.instance.getIs24HourTimeFormat();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekspor Jadwal & Ringkasan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentCol,
          unselectedLabelColor: textSecondary,
          indicatorColor: accentCol,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              icon: Icon(Icons.wallpaper_rounded, size: 18),
              text: 'Wallpaper HP (9:16)',
            ),
            Tab(
              icon: Icon(Icons.picture_as_pdf_rounded, size: 18),
              text: 'Dokumen Cetak (PDF A4)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Wallpaper Lockscreen 9:16 Preview & Actions
          _buildWallpaperTab(
            context,
            profile,
            subjects,
            is24Hour,
            isDark,
            textPrimary,
            textSecondary,
            borderCol,
            accentCol,
          ),

          // Tab 2: PDF Study Summary Preview & Actions
          _buildPdfTab(
            context,
            profile,
            subjects,
            tasks,
            isDark,
            accentCol,
            borderCol,
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperTab(
    BuildContext context,
    UserProfile profile,
    List<Subject> subjects,
    bool is24Hour,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color accentCol,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final previewHeight = (screenHeight * 0.60).clamp(420.0, 560.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentCol.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentCol.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: accentCol),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gambar beresolusi tinggi (9:16) berlatar Obsidian Gelap dirancang presisi untuk wallpaper lockscreen ponsel.',
                    style: TextStyle(fontSize: 11.5, color: textPrimary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Options Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tampilkan Nama Dosen',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              Switch(
                value: _showLecturerOnWallpaper,
                activeColor: accentCol,
                onChanged: (val) {
                  setState(() => _showLecturerOnWallpaper = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Wallpaper Mockup Frame with RepaintBoundary
          Center(
            child: Container(
              height: previewHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF2A2E3D),
                  width: 3.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: RepaintBoundary(
                key: _wallpaperKey,
                child: WallpaperScheduleWidget(
                  profile: profile,
                  subjects: subjects,
                  is24HourFormat: is24Hour,
                  showLecturer: _showLecturerOnWallpaper,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Share & Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _handleSaveWallpaper,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: borderCol),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Simpan PNG', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _handleShareWallpaper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentCol,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Bagikan Wallpaper',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfTab(
    BuildContext context,
    UserProfile profile,
    List<Subject> subjects,
    List<TaskItem> tasks,
    bool isDark,
    Color accentCol,
    Color borderCol,
  ) {
    return Column(
      children: [
        // Action Bar for PDF
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.print_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Format Kertas A4 Standar Cetak',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final bytes = await ScheduleExportService.generateStudySummaryPdf(
                        profile: profile,
                        subjects: subjects,
                        tasks: tasks,
                      );
                      await ScheduleExportService.sharePdf(bytes);
                    },
                    icon: const Icon(Icons.share_rounded, size: 14),
                    label: const Text('Bagikan', style: TextStyle(fontSize: 11.5)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final bytes = await ScheduleExportService.generateStudySummaryPdf(
                        profile: profile,
                        subjects: subjects,
                        tasks: tasks,
                      );
                      await ScheduleExportService.printPdf(bytes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentCol,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Cetak / Simpan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Live PDF Interactive Viewer
        Expanded(
          child: PdfPreview(
            build: (format) => ScheduleExportService.generateStudySummaryPdf(
              profile: profile,
              subjects: subjects,
              tasks: tasks,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            maxPageWidth: 700,
            pdfFileName: 'Jadwal_Studi_${profile.name.replaceAll(' ', '_')}.pdf',
            previewPageMargin: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
