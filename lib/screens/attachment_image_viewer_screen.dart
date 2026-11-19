import 'dart:io';
import 'package:flutter/material.dart';
import '../services/task_attachment_service.dart';
import '../utils/app_theme.dart';

/// Layar penampil pratinjau gambar internal dengan dukungan interaktif Zoom & Pan.
class AttachmentImageViewerScreen extends StatefulWidget {
  final String imagePath;
  final String? title;

  const AttachmentImageViewerScreen({
    super.key,
    required this.imagePath,
    this.title,
  });

  @override
  State<AttachmentImageViewerScreen> createState() => _AttachmentImageViewerScreenState();
}

class _AttachmentImageViewerScreenState extends State<AttachmentImageViewerScreen>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  TaskAttachmentInfo? _attachmentInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });

    _loadAttachmentInfo();
  }

  Future<void> _loadAttachmentInfo() async {
    try {
      final info = await TaskAttachmentService.getAttachmentInfo(widget.imagePath);
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
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    Matrix4 targetMatrix;
    if (currentScale > 1.2) {
      // Reset zoom
      targetMatrix = Matrix4.identity();
    } else {
      // Zoom 2.5x ke arah titik ketukan
      targetMatrix = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090A0D) : const Color(0xFF141519);
    final textPrimary = Colors.white;
    final textSecondary = Colors.white70;

    final displayName = widget.title ??
        (_attachmentInfo?.displayName ?? TaskAttachmentService.getDisplayName(widget.imagePath));
    final formattedSize = _attachmentInfo?.formattedSize ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (formattedSize.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Foto Catatan • $formattedSize',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bagikan Foto',
            icon: const Icon(Icons.share_outlined, size: 19, color: Colors.white),
            onPressed: () {
              TaskAttachmentService.shareAttachment(
                widget.imagePath,
                subject: displayName,
              );
            },
          ),
          IconButton(
            tooltip: 'Reset Skala',
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
            onPressed: () {
              _animation = Matrix4Tween(
                begin: _transformationController.value,
                end: Matrix4.identity(),
              ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
              _animationController.forward(from: 0);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.darkAccent, strokeWidth: 2),
            )
          : GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(40),
                  child: _buildImageContent(),
                ),
              ),
            ),
    );
  }

  Widget _buildImageContent() {
    final path = _attachmentInfo?.resolvedPath ?? widget.imagePath;
    final file = File(path);

    if (TaskAttachmentService.isLocalFile(path)) {
      if (!file.existsSync()) {
        return Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2026),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, size: 48, color: Colors.amber),
              const SizedBox(height: 12),
              const Text(
                'Berkas Foto Tidak Ditemukan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Berkas lokal mungkin telah dipindahkan atau dihapus dari perangkat:\n$path',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 8),
                Text('Gagal memuat gambar: $error', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        },
      );
    }

    // Tautan web fallback
    return Image.network(
      path,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(color: AppTheme.darkAccent, strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
        );
      },
    );
  }
}
