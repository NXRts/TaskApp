import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Jenis lampiran yang didukung oleh TaskApp
enum AttachmentType {
  image,
  pdf,
  link,
  file,
}

/// Metadata terurai untuk lampiran tugas
class TaskAttachmentInfo {
  final String rawPath;
  final AttachmentType type;
  final String displayName;
  final String resolvedPath;
  final int? sizeInBytes;
  final bool exists;

  const TaskAttachmentInfo({
    required this.rawPath,
    required this.type,
    required this.displayName,
    required this.resolvedPath,
    this.sizeInBytes,
    this.exists = false,
  });

  String get formattedSize {
    if (sizeInBytes == null || sizeInBytes! <= 0) return '';
    final bytes = sizeInBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Service untuk mengelola berkas lampiran lokal (Kamera, Galeri, PDF)
/// dan tautan eksternal secara offline-first.
class TaskAttachmentService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Menentukan jenis lampiran berdasarkan ekstensi berkas atau pola URL
  static AttachmentType getAttachmentType(String pathOrUrl) {
    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return AttachmentType.link;
    }

    final lower = trimmed.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.heic')) {
      return AttachmentType.image;
    }

    if (lower.endsWith('.pdf')) {
      return AttachmentType.pdf;
    }

    return AttachmentType.file;
  }

  /// Mengecek apakah lampiran merupakan berkas lokal
  static bool isLocalFile(String pathOrUrl) {
    return getAttachmentType(pathOrUrl) != AttachmentType.link;
  }

  /// Mendapatkan nama bersih untuk tampilan pengguna
  static String getDisplayName(String pathOrUrl) {
    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.host.isNotEmpty) {
          final queryPart = uri.hasQuery ? '?${uri.query}' : '';
          return '${uri.host}${uri.path}$queryPart';
        }
        return trimmed;
      } catch (_) {
        return trimmed;
      }
    }

    // Ambil basename dari path
    final normalized = trimmed.replaceAll(r'\', '/');
    final segments = normalized.split('/');
    String fileName = segments.isNotEmpty ? segments.last : trimmed;

    // Bersihkan prefix unik yang digenerate sistem seperti 'att_1732000000000_'
    final prefixRegex = RegExp(r'^att_\d+_');
    if (prefixRegex.hasMatch(fileName)) {
      fileName = fileName.replaceFirst(prefixRegex, '');
    }

    return fileName.isNotEmpty ? fileName : 'Berkas Lampiran';
  }

  /// Mendapatkan direktori penyimpanan berkas lampiran tugas di `app_storage`
  static Future<Directory> getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${appDir.path}/task_attachments');
    if (!await attachDir.exists()) {
      await attachDir.create(recursive: true);
    }
    return attachDir;
  }

  /// Mengurai path berkas lokal secara absolut.
  /// Menangani kemungkinan perubahan prefix direktori aplikasi pada pembaruan OS/Sandbox.
  static Future<String> resolveLocalPath(String pathOrUrl) async {
    if (!isLocalFile(pathOrUrl)) return pathOrUrl;

    final trimmed = pathOrUrl.trim();
    final directFile = File(trimmed);
    if (await directFile.exists()) {
      return trimmed;
    }

    // Cek di subfolder task_attachments
    try {
      final attachDir = await getAttachmentsDirectory();
      final normalized = trimmed.replaceAll(r'\', '/');
      final fileName = normalized.split('/').last;
      final fallbackFile = File('${attachDir.path}/$fileName');
      if (await fallbackFile.exists()) {
        return fallbackFile.path;
      }
    } catch (e) {
      debugPrint('Error resolving attachment path: $e');
    }

    return trimmed;
  }

  /// Mendapatkan informasi lengkap lampiran tugas
  static Future<TaskAttachmentInfo> getAttachmentInfo(String pathOrUrl) async {
    final type = getAttachmentType(pathOrUrl);
    final displayName = getDisplayName(pathOrUrl);

    if (type == AttachmentType.link) {
      return TaskAttachmentInfo(
        rawPath: pathOrUrl,
        type: type,
        displayName: displayName,
        resolvedPath: pathOrUrl,
        exists: true,
      );
    }

    final resolved = await resolveLocalPath(pathOrUrl);
    final file = File(resolved);
    bool exists = false;
    int? size;

    try {
      exists = await file.exists();
      if (exists) {
        size = await file.length();
      }
    } catch (_) {}

    return TaskAttachmentInfo(
      rawPath: pathOrUrl,
      type: type,
      displayName: displayName,
      resolvedPath: resolved,
      sizeInBytes: size,
      exists: exists,
    );
  }

  /// Mengambil foto langsung dari Kamera perangkat dan menyalin ke `task_attachments`
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );
      if (photo == null) return null;
      return await _saveFileToLocalAttachments(File(photo.path), photo.name);
    } catch (e) {
      debugPrint('TaskAttachmentService: Gagal mengambil foto kamera: $e');
      rethrow;
    }
  }

  /// Memilih foto dari Galeri perangkat dan menyalin ke `task_attachments`
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (image == null) return null;
      return await _saveFileToLocalAttachments(File(image.path), image.name);
    } catch (e) {
      debugPrint('TaskAttachmentService: Gagal memilih foto galeri: $e');
      rethrow;
    }
  }

  /// Memilih satu atau beberapa foto dari Galeri perangkat
  static Future<List<String>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 88,
      );
      if (images.isEmpty) return [];

      final savedPaths = <String>[];
      for (final img in images) {
        final path = await _saveFileToLocalAttachments(File(img.path), img.name);
        savedPaths.add(path);
      }
      return savedPaths;
    } catch (e) {
      debugPrint('TaskAttachmentService: Gagal memilih banyak foto galeri: $e');
      rethrow;
    }
  }

  /// Memilih berkas dokumen PDF soal atau tugas dan menyalin ke `task_attachments`
  static Future<List<String>> pickPdfFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Pilih Dokumen PDF Tugas / Soal',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isEmpty) return [];

      final savedPaths = <String>[];
      final targetDir = await getAttachmentsDirectory();

      for (final file in files) {
        if (file.path != null) {
          final srcFile = File(file.path!);
          if (await srcFile.exists()) {
            final path = await _saveFileToLocalAttachments(srcFile, file.name);
            savedPaths.add(path);
            continue;
          }
        }

        // Fallback untuk byte buffer (misal di web / platform tertentu)
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final cleanName = _sanitizeFileName(file.name);
          final uniqueName = 'att_${DateTime.now().millisecondsSinceEpoch}_$cleanName';
          final destFile = File('${targetDir.path}/$uniqueName');
          await destFile.writeAsBytes(bytes);
          savedPaths.add(destFile.path);
        }
      }

      return savedPaths;
    } catch (e) {
      debugPrint('TaskAttachmentService: Gagal memilih dokumen PDF: $e');
      rethrow;
    }
  }

  /// Menyalin berkas lokal ke direktori aman aplikasi
  static Future<String> _saveFileToLocalAttachments(File sourceFile, String originalName) async {
    final targetDir = await getAttachmentsDirectory();
    final cleanName = _sanitizeFileName(originalName);
    final uniqueName = 'att_${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    final targetPath = '${targetDir.path}/$uniqueName';

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Membersihkan karakter berbahaya atau spasi pada nama berkas
  static String _sanitizeFileName(String name) {
    final normalized = name.replaceAll(r'\', '/');
    final baseName = normalized.split('/').last;
    return baseName.replaceAll(RegExp(r'[^a-zA-Z0-9._\-]'), '_');
  }

  /// Menghapus berkas lampiran lokal dari `task_attachments` jika ada
  static Future<void> deleteAttachment(String pathOrUrl) async {
    if (!isLocalFile(pathOrUrl)) return;
    try {
      final resolved = await resolveLocalPath(pathOrUrl);
      final file = File(resolved);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('TaskAttachmentService: Gagal menghapus berkas: $e');
    }
  }

  /// Membagikan berkas lampiran ke aplikasi lain (WhatsApp, Drive, dll)
  static Future<void> shareAttachment(String pathOrUrl, {String? subject}) async {
    if (!isLocalFile(pathOrUrl)) {
      await SharePlus.instance.share(
        ShareParams(
          text: pathOrUrl,
          subject: subject,
        ),
      );
      return;
    }

    final resolved = await resolveLocalPath(pathOrUrl);
    final file = File(resolved);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(resolved, name: getDisplayName(pathOrUrl))],
          subject: subject ?? 'Lampiran Tugas TaskApp',
          text: 'Lampiran Tugas: ${getDisplayName(pathOrUrl)}',
        ),
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: pathOrUrl,
          subject: subject,
        ),
      );
    }
  }
}
