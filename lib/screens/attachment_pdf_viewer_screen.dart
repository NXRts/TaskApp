import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/task_attachment_service.dart';
import '../utils/app_theme.dart';

/// Layar pembaca dokumen PDF tersemat dengan dukungan zoom, navigasi halaman, cetak, dan bagikan.
class AttachmentPdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String? title;

  const AttachmentPdfViewerScreen({
    super.key,
    required this.pdfPath,
    this.title,
  });

  @override
  State<AttachmentPdfViewerScreen> createState() => _AttachmentPdfViewerScreenState();
}

class _AttachmentPdfViewerScreenState extends State<AttachmentPdfViewerScreen> {
  TaskAttachmentInfo? _attachmentInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttachmentInfo();
  }

  Future<void> _loadAttachmentInfo() async {
    try {
      final info = await TaskAttachmentService.getAttachmentInfo(widget.pdfPath);
      if (mounted) {
        setState(() {
          _attachmentInfo = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final surfaceCol = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final displayName = widget.title ??
        (_attachmentInfo?.displayName ?? TaskAttachmentService.getDisplayName(widget.pdfPath));
    final formattedSize = _attachmentInfo?.formattedSize ?? '';

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: surfaceCol,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (formattedSize.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                'Dokumen PDF • $formattedSize',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bagikan Berkas PDF',
            icon: Icon(Icons.share_outlined, size: 19, color: textPrimary),
            onPressed: () {
              TaskAttachmentService.shareAttachment(
                widget.pdfPath,
                subject: displayName,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.darkAccent, strokeWidth: 2),
            )
          : _buildPdfViewer(context, textPrimary, textSecondary),
    );
  }

  Widget _buildPdfViewer(BuildContext context, Color textPrimary, Color textSecondary) {
    final resolvedPath = _attachmentInfo?.resolvedPath ?? widget.pdfPath;
    final file = File(resolvedPath);

    if (!file.existsSync()) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurfaceElevated
                : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 48, color: Colors.amber),
              const SizedBox(height: 12),
              Text(
                'Berkas PDF Tidak Ditemukan',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Berkas PDF lokal mungkin telah dipindahkan atau dihapus:\n$resolvedPath',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = widget.title ??
        (_attachmentInfo?.displayName ?? TaskAttachmentService.getDisplayName(widget.pdfPath));

    return PdfPreview(
      build: (format) async => await file.readAsBytes(),
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      maxPageWidth: 700,
      pdfFileName: displayName.endsWith('.pdf') ? displayName : '$displayName.pdf',
      previewPageMargin: const EdgeInsets.all(12),
    );
  }
}
