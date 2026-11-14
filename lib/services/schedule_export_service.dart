import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

/// Service for exporting visual wallpapers (PNG) and study summary documents (PDF)
class ScheduleExportService {
  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String _formatTaskDate(DateTime dt) {
    try {
      return DateFormat('E, d MMM yyyy - HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('E, d MMM yyyy - HH:mm').format(dt);
    }
  }

  static String getDayName(int? day) {
    if (day == null || day < 1 || day > 7) return 'Lainnya';
    return _dayNames[day - 1];
  }

  /// Capture a widget wrapped in a RepaintBoundary into a PNG byte array
  static Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 3.0}) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing PNG: $e');
      return null;
    }
  }

  /// Save PNG bytes to a local file in application/cache directory
  static Future<File> savePngFile(Uint8List bytes, {String? filename}) async {
    final dir = await getTemporaryDirectory();
    final name = filename ?? 'TaskApp_Jadwal_Wallpaper_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Share PNG Wallpaper using system share sheet
  static Future<void> shareWallpaper(Uint8List bytes, {String? filename}) async {
    final file = await savePngFile(bytes, filename: filename);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: 'Jadwal Kuliah Wallpaper - TaskApp',
        text: 'Jadwal Kuliah Semester ini dibuat dengan TaskApp',
      ),
    );
  }

  /// Generate Study Summary PDF (A4 Format)
  static Future<Uint8List> generateStudySummaryPdf({
    required UserProfile profile,
    required List<Subject> subjects,
    required List<TaskItem> tasks,
  }) async {
    final pdf = pw.Document(
      title: 'Ringkasan Studi & Jadwal Kuliah - ${profile.name}',
      author: 'TaskApp Academic Planner',
    );

    // Sort subjects by day and start time
    final sortedSubjects = List<Subject>.from(subjects)..sort();

    // Sort tasks by due date
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final totalSks = subjects.fold<int>(0, (sum, s) => sum + s.creditHours);
    
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}

    String printDateFormatted;
    try {
      printDateFormatted = DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
    } catch (_) {
      printDateFormatted = DateFormat('d MMMM yyyy, HH:mm').format(DateTime.now());
    }

    // Styling constants
    final primaryColor = PdfColor.fromInt(0xFF1E293B);
    final accentCobalt = PdfColor.fromInt(0xFF2563EB);
    final darkCharcoal = PdfColor.fromInt(0xFF0F172A);
    final lightGrey = PdfColor.fromInt(0xFFF8FAFC);
    final borderGrey = PdfColor.fromInt(0xFFE2E8F0);
    final textMuted = PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TASKAPP - DOKUMEN RINGKASAN AKADEMIK',
                        style: pw.TextStyle(
                          color: accentCobalt,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Jadwal Perkuliahan & Target Mingguan',
                        style: pw.TextStyle(
                          color: darkCharcoal,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (profile.campus.isNotEmpty || profile.studyProgram.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${profile.studyProgram.isNotEmpty ? profile.studyProgram : ''}${profile.studyProgram.isNotEmpty && profile.campus.isNotEmpty ? ' - ' : ''}${profile.campus}',
                          style: pw.TextStyle(color: PdfColor.fromInt(0xFF334155), fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: lightGrey,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(color: borderGrey, width: 0.8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              profile.name,
                              style: pw.TextStyle(
                                color: darkCharcoal,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Semester ${profile.semester}',
                              style: pw.TextStyle(color: textMuted, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dicetak: $printDateFormatted',
                        style: pw.TextStyle(color: textMuted, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: borderGrey, thickness: 1),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TaskApp - Academic Operating System for Students',
                  style: pw.TextStyle(color: textMuted, fontSize: 8),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(color: textMuted, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // KPI Metric Summary Cards
          pw.Row(
            children: [
              _buildPdfKpiCard(
                title: 'TOTAL SKS',
                value: '$totalSks SKS',
                sub: '${subjects.length} Mata Kuliah Terdaftar',
                accentColor: accentCobalt,
                borderGrey: borderGrey,
                lightGrey: lightGrey,
              ),
              pw.SizedBox(width: 10),
              _buildPdfKpiCard(
                title: 'TUGAS AKTIF',
                value: '${pendingTasks.length}',
                sub: 'Tenggat Menanti Penyelesaian',
                accentColor: PdfColor.fromInt(0xFFE11D48),
                borderGrey: borderGrey,
                lightGrey: lightGrey,
              ),
              pw.SizedBox(width: 10),
              _buildPdfKpiCard(
                title: 'STATUS AKADEMIK',
                value: 'Aktif',
                sub: 'Semester ${profile.semester} Berjalan',
                accentColor: PdfColor.fromInt(0xFF059669),
                borderGrey: borderGrey,
                lightGrey: lightGrey,
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Section 1: Weekly Timetable Table
          pw.Text(
            '1. DAFTAR MATA KULIAH & JADWAL KULIAH MINGGUAN',
            style: pw.TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),

          if (sortedSubjects.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderGrey),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Belum ada mata kuliah yang didaftarkan pada semester ini.',
                  style: pw.TextStyle(color: textMuted, fontSize: 10),
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGrey, width: 0.6),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // Hari
                1: pw.FlexColumnWidth(1.4), // Jam
                2: pw.FlexColumnWidth(3.0), // Mata Kuliah
                3: pw.FlexColumnWidth(0.8), // SKS
                4: pw.FlexColumnWidth(1.5), // Ruangan
                5: pw.FlexColumnWidth(2.5), // Dosen
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGrey),
                  children: [
                    _buildTableCell('Hari', isHeader: true),
                    _buildTableCell('Waktu', isHeader: true),
                    _buildTableCell('Mata Kuliah', isHeader: true),
                    _buildTableCell('SKS', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Ruangan', isHeader: true),
                    _buildTableCell('Dosen Pengampu', isHeader: true),
                  ],
                ),
                // Table Rows
                for (int i = 0; i < sortedSubjects.length; i++) ...[
                  pw.TableRow(
                    decoration: i % 2 == 1 ? pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFBFD)) : null,
                    children: [
                      _buildTableCell(
                        sortedSubjects[i].dayOfWeek != null ? getDayName(sortedSubjects[i].dayOfWeek) : '-',
                        bold: true,
                        color: accentCobalt,
                      ),
                      _buildTableCell(
                        sortedSubjects[i].timeRange?.isNotEmpty == true ? sortedSubjects[i].timeRange! : '-',
                      ),
                      _buildTableCell(
                        sortedSubjects[i].name,
                        bold: true,
                      ),
                      _buildTableCell(
                        '${sortedSubjects[i].creditHours}',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        sortedSubjects[i].room.isNotEmpty ? sortedSubjects[i].room : '-',
                      ),
                      _buildTableCell(
                        sortedSubjects[i].lecturer.isNotEmpty ? sortedSubjects[i].lecturer : '-',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          pw.SizedBox(height: 20),

          // Section 2: Weekly Task & Project Checklist
          pw.Text(
            '2. CHECKLIST TUGAS, LAPORAN & PROYEK MINGGUAN',
            style: pw.TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),

          if (pendingTasks.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderGrey),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Semua tugas telah selesai dikerjakan! Tidak ada tenggat tertunda.',
                  style: pw.TextStyle(color: textMuted, fontSize: 10),
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGrey, width: 0.6),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // Checkbox box
                1: pw.FlexColumnWidth(4.0), // Judul Tugas
                2: pw.FlexColumnWidth(2.2), // Matkul Terkait
                3: pw.FlexColumnWidth(2.0), // Tenggat
                4: pw.FlexColumnWidth(1.2), // Prioritas
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGrey),
                  children: [
                    _buildTableCell('Done', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Nama Tugas / Proyek', isHeader: true),
                    _buildTableCell('Mata Kuliah', isHeader: true),
                    _buildTableCell('Tenggat Waktu', isHeader: true),
                    _buildTableCell('Prioritas', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                for (final task in pendingTasks.take(15)) ...[
                  pw.TableRow(
                    children: [
                      // Printable checkbox square
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        alignment: pw.Alignment.center,
                        child: pw.Container(
                          width: 10,
                          height: 10,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: darkCharcoal, width: 0.8),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                        ),
                      ),
                      _buildTableCell(task.title, bold: true),
                      _buildTableCell(
                        subjects.firstWhere((s) => s.id == task.subjectId, orElse: () => Subject(id: '', name: '-')).name,
                      ),
                      _buildTableCell(
                        _formatTaskDate(task.dueDate),
                      ),
                      _buildTableCell(
                        task.priority.name.toUpperCase(),
                        align: pw.TextAlign.center,
                        color: task.priority == TaskPriority.high
                            ? PdfColor.fromInt(0xFFE11D48)
                            : (task.priority == TaskPriority.medium ? PdfColor.fromInt(0xFFD97706) : textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          pw.SizedBox(height: 18),

          // Section 3: Notes / Lembar Catatan Belajar & Dosen
          pw.Text(
            '3. CATATAN AKADEMIK & TARGET BELAJAR MANDIRI',
            style: pw.TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 90,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderGrey, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Catatan penting / arahan dosen / target nilai semester:',
                  style: pw.TextStyle(color: textMuted, fontSize: 8.5),
                ),
                pw.Divider(color: borderGrey, thickness: 0.5),
                pw.Divider(color: borderGrey, thickness: 0.5),
                pw.Divider(color: borderGrey, thickness: 0.5),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfKpiCard({
    required String title,
    required String value,
    required String sub,
    required PdfColor accentColor,
    required PdfColor borderGrey,
    required PdfColor lightGrey,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: lightGrey,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: borderGrey, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: accentColor,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColor.fromInt(0xFF0F172A),
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              sub,
              style: pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? PdfColor.fromInt(0xFF1E293B)
              : (color ?? PdfColor.fromInt(0xFF334155)),
        ),
      ),
    );
  }

  /// Print or open native PDF layout sheet directly
  static Future<void> printPdf(Uint8List pdfBytes, {String name = 'Ringkasan_Studi_TaskApp.pdf'}) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: name,
    );
  }

  /// Share PDF bytes
  static Future<void> sharePdf(Uint8List pdfBytes, {String filename = 'Ringkasan_Studi_TaskApp.pdf'}) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
