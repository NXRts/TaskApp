import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/task_attachment_service.dart';
import '../screens/attachment_image_viewer_screen.dart';
import '../screens/attachment_pdf_viewer_screen.dart';
import '../utils/app_theme.dart';

/// Kartu visual untuk menampilkan item lampiran (Foto, Dokumen PDF, atau Tautan URL).
class TaskAttachmentTile extends StatefulWidget {
  final String pathOrUrl;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  final bool compact;

  const TaskAttachmentTile({
    super.key,
    required this.pathOrUrl,
    this.onDelete,
    this.showDeleteButton = true,
    this.compact = false,
  });

  @override
  State<TaskAttachmentTile> createState() => _TaskAttachmentTileState();
}

class _TaskAttachmentTileState extends State<TaskAttachmentTile> {
  TaskAttachmentInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void didUpdateWidget(covariant TaskAttachmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathOrUrl != widget.pathOrUrl) {
      _loadInfo();
    }
  }

  Future<void> _loadInfo() async {
    try {
      final info = await TaskAttachmentService.getAttachmentInfo(widget.pathOrUrl);
      if (mounted) {
        setState(() {
          _info = info;
        });
      }
    } catch (_) {}
  }

  void _handleTap(BuildContext context) {
    final type = _info?.type ?? TaskAttachmentService.getAttachmentType(widget.pathOrUrl);

    if (type == AttachmentType.image) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AttachmentImageViewerScreen(imagePath: widget.pathOrUrl),
        ),
      );
    } else if (type == AttachmentType.pdf) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AttachmentPdfViewerScreen(pdfPath: widget.pathOrUrl),
        ),
      );
    } else {
      Clipboard.setData(ClipboardData(text: widget.pathOrUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan disalin ke clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final type = _info?.type ?? TaskAttachmentService.getAttachmentType(widget.pathOrUrl);
    final displayName = _info?.displayName ?? TaskAttachmentService.getDisplayName(widget.pathOrUrl);
    final formattedSize = _info?.formattedSize ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: widget.compact ? 6 : 8),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => _handleTap(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: widget.compact ? 6 : 8,
            ),
            child: Row(
              children: [
                // Thumbnail / Leading Icon
                _buildLeading(type, isDark),
                const SizedBox(width: 10),

                // Title & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: widget.compact ? 12 : 12.5,
                          fontWeight: FontWeight.w600,
                          color: type == AttachmentType.link ? AppTheme.brandCobalt : textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _getTypeSubtitle(type, formattedSize),
                        style: TextStyle(
                          fontSize: widget.compact ? 10.5 : 11,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share button for local files
                    if (TaskAttachmentService.isLocalFile(widget.pathOrUrl)) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 17,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(Icons.share_outlined, color: textSecondary),
                        tooltip: 'Bagikan',
                        onPressed: () {
                          TaskAttachmentService.shareAttachment(widget.pathOrUrl);
                        },
                      ),
                    ],

                    // Delete button
                    if (widget.showDeleteButton && widget.onDelete != null) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 17,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                        tooltip: 'Hapus Lampiran',
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(AttachmentType type, bool isDark) {
    final size = widget.compact ? 36.0 : 42.0;

    if (type == AttachmentType.image && _info != null && _info!.exists) {
      final file = File(_info!.resolvedPath);
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackBox(
              Icons.image_outlined,
              Colors.teal,
              size,
              isDark,
            ),
          ),
        ),
      );
    }

    switch (type) {
      case AttachmentType.image:
        return _buildFallbackBox(Icons.image_outlined, Colors.teal, size, isDark);
      case AttachmentType.pdf:
        return _buildFallbackBox(Icons.picture_as_pdf_rounded, Colors.redAccent, size, isDark);
      case AttachmentType.link:
        return _buildFallbackBox(Icons.link_rounded, AppTheme.brandCobalt, size, isDark);
      case AttachmentType.file:
        return _buildFallbackBox(Icons.insert_drive_file_outlined, Colors.amber, size, isDark);
    }
  }

  Widget _buildFallbackBox(IconData icon, Color color, double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }

  String _getTypeSubtitle(AttachmentType type, String sizeText) {
    final sizePart = sizeText.isNotEmpty ? ' • $sizeText' : '';
    switch (type) {
      case AttachmentType.image:
        return 'Foto Catatan Papan Tulis$sizePart';
      case AttachmentType.pdf:
        return 'Dokumen PDF Soal$sizePart';
      case AttachmentType.link:
        return 'Tautan Eksternal • Ketuk untuk salin';
      case AttachmentType.file:
        return 'Berkas Dokumen$sizePart';
    }
  }
}
