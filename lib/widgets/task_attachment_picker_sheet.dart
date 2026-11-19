import 'package:flutter/material.dart';
import '../services/task_attachment_service.dart';
import '../utils/app_theme.dart';

enum _AttachmentPickerOption {
  camera,
  gallery,
  pdf,
  link,
}

/// Modal bottom sheet untuk memilih metode penambahan lampiran:
/// Kamera (Foto Papan Tulis), Galeri (Foto), Dokumen PDF, atau Tautan URL.
class TaskAttachmentPickerSheet extends StatelessWidget {
  const TaskAttachmentPickerSheet({super.key});

  /// Menampilkan sheet pemilih lampiran dan mengembalikan daftar path/URL yang berhasil dipilih
  static Future<List<String>> show(BuildContext context) async {
    final option = await showModalBottomSheet<_AttachmentPickerOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TaskAttachmentPickerSheet(),
    );

    if (option == null || !context.mounted) return [];

    try {
      switch (option) {
        case _AttachmentPickerOption.camera:
          final path = await TaskAttachmentService.pickImageFromCamera();
          return path != null ? [path] : [];

        case _AttachmentPickerOption.gallery:
          return await TaskAttachmentService.pickMultipleImagesFromGallery();

        case _AttachmentPickerOption.pdf:
          return await TaskAttachmentService.pickPdfFiles();

        case _AttachmentPickerOption.link:
          final link = await _showLinkInputDialog(context);
          return (link != null && link.isNotEmpty) ? [link] : [];
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat melampirkan berkas: $e')),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: borderCol, width: 0.8),
          left: BorderSide(color: borderCol, width: 0.8),
          right: BorderSide(color: borderCol, width: 0.8),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'TAMBAH LAMPIRAN TUGAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Options
          _buildOptionTile(
            context: context,
            icon: Icons.camera_alt_outlined,
            iconColor: Colors.tealAccent.shade700,
            title: 'Kamera (Foto Papan Tulis)',
            subtitle: 'Ambil foto penjelasan dosen atau catatan papan tulis',
            onTap: () => Navigator.of(context).pop(_AttachmentPickerOption.camera),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderCol: borderCol,
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.photo_library_outlined,
            iconColor: Colors.blueAccent,
            title: 'Pilih Foto dari Galeri',
            subtitle: 'Foto kisi-kisi atau catatan tugas dari galeri HP',
            onTap: () => Navigator.of(context).pop(_AttachmentPickerOption.gallery),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderCol: borderCol,
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.picture_as_pdf_outlined,
            iconColor: Colors.redAccent,
            title: 'Dokumen PDF Soal / Tugas',
            subtitle: 'Lembar soal tugas kuliah, modul, atau kisi-kisi PDF',
            onTap: () => Navigator.of(context).pop(_AttachmentPickerOption.pdf),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderCol: borderCol,
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.link_rounded,
            iconColor: AppTheme.brandCobalt,
            title: 'Tautan URL Eksternal',
            subtitle: 'Link Google Drive, LMS Kampus, atau dokumen online',
            onTap: () => Navigator.of(context).pop(_AttachmentPickerOption.link),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderCol: borderCol,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderCol,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<String?> _showLinkInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Tambah Tautan URL',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'https://drive.google.com/...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              prefixIcon: const Icon(Icons.link, size: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.of(dialogCtx).pop(text.isNotEmpty ? text : null);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}
