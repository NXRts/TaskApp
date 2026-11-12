import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/add_subject_dialog.dart';
import '../widgets/record_absence_dialog.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Subject Detail Screen with Attendance Sentinel & Task Tabs
class SubjectDetailScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  int _selectedTab = 0; // 0: Tugas, 1: Presensi & Batas Bolos

  String _formatDate(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    final currentSubject = subjectProvider.getSubjectById(widget.subject.id) ?? widget.subject;
    final subjectTasks = taskProvider.getTasksForSubject(currentSubject.id);
    final pendingCount = subjectTasks.where((t) => !t.isCompleted).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSubject.name),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 20, color: textSecondary),
            tooltip: 'Edit Matkul',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddSubjectDialog(initialSubject: currentSubject),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.urgentRose),
            tooltip: 'Hapus Matkul',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Mata Kuliah?'),
                  content: Text('Anda yakin ingin menghapus "${currentSubject.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentRose),
                      onPressed: () {
                        subjectProvider.deleteSubject(currentSubject.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Block
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: currentSubject.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentSubject.code.isNotEmpty ? currentSubject.code : 'MATKUL',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text('• ${currentSubject.creditHours} SKS', style: TextStyle(fontSize: 12, color: textSecondary)),
                      Text(' • ${currentSubject.totalMeetings} Pertemuan', style: TextStyle(fontSize: 12, color: textSecondary)),
                      const Spacer(),
                      _buildAttendanceStatusPill(currentSubject),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (currentSubject.lecturer.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Dosen: ${currentSubject.lecturer}', style: TextStyle(fontSize: 12.5, color: textSecondary)),
                    ),
                  if (currentSubject.room.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Ruangan: ${currentSubject.room}', style: TextStyle(fontSize: 12.5, color: textSecondary)),
                    ),
                  if (currentSubject.dayOfWeek != null)
                    Text(
                      'Jadwal: ${currentSubject.dayName} ${currentSubject.timeRange ?? ''}',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Segmented Tab Selector (Tugas vs Presensi & Batas Bolos)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      label: 'Daftar Tugas (${subjectTasks.length})',
                      icon: Icons.checklist_rounded,
                      tabIndex: 0,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      label: 'Presensi & Bolos (${currentSubject.totalAbsences})',
                      icon: Icons.fact_check_outlined,
                      tabIndex: 1,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            if (_selectedTab == 0)
              _buildTasksTab(subjectTasks, pendingCount, isDark, borderCol, textPrimary, textSecondary)
            else
              _buildAttendanceSentinelTab(currentSubject, isDark, borderCol, textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusPill(Subject subject) {
    Color color;
    String label;
    switch (subject.attendanceStatus) {
      case AttendanceStatus.critical:
        color = AppTheme.urgentRose;
        label = '🔴 ${subject.totalAbsences}x Absen';
        break;
      case AttendanceStatus.warning:
        color = AppTheme.warningOchre;
        label = '🟡 ${subject.totalAbsences}x Absen';
        break;
      case AttendanceStatus.safe:
        color = AppTheme.successSage;
        label = subject.totalAbsences == 0 ? '🟢 100% Hadir' : '🟢 ${subject.totalAbsences}x Absen';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int tabIndex,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isSelected = _selectedTab == tabIndex;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tabIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? (isDark ? AppTheme.darkAccent : AppTheme.brandCobalt)
                  : textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: TUGAS MATKUL ---
  Widget _buildTasksTab(
    List subjectTasks,
    int pendingCount,
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAFTAR TUGAS MATKUL INI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddTaskModal(),
                );
              },
              child: Text(
                '+ Tugas Baru',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (subjectTasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 36, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'Tidak ada tugas untuk mata kuliah ini',
                    style: TextStyle(fontSize: 13.5, color: textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: subjectTasks.map((t) => TaskCard(task: t)).toList(),
          ),
      ],
    );
  }

  // --- TAB 2: ATTENDANCE SENTINEL (MONITOR PRESENSI & BATAS BOLOS) ---
  Widget _buildAttendanceSentinelTab(
    Subject currentSubject,
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    Color statusColor;
    String statusTitle;
    String statusBadgeText;
    String statusDescription;
    IconData statusIcon;

    switch (currentSubject.attendanceStatus) {
      case AttendanceStatus.critical:
        statusColor = AppTheme.urgentRose;
        statusIcon = Icons.error_outline_rounded;
        statusTitle = 'Peringatan Kritis! (${currentSubject.attendancePercentage.toStringAsFixed(0)}% Hadir)';
        statusBadgeText = '≥4 Kali Alfa (Kritis)';
        statusDescription =
            'Batas minimal 75% kehadiran terlampaui! Anda berisiko dilarang mengikuti Ujian Akhir Semester (UAS).';
        break;

      case AttendanceStatus.warning:
        statusColor = AppTheme.warningOchre;
        statusIcon = Icons.warning_amber_rounded;
        statusTitle = 'Waspada Kuota Absen (${currentSubject.attendancePercentage.toStringAsFixed(0)}% Hadir)';
        statusBadgeText = '2–3 Kali Alfa (Waspada)';
        statusDescription =
            'Perhatian: Sisa kuota izin Anda tinggal ${currentSubject.remainingAbsenceQuota} kali lagi! Segera hadir di pertemuan berikutnya.';
        break;

      case AttendanceStatus.safe:
        statusColor = AppTheme.successSage;
        statusIcon = Icons.check_circle_outline_rounded;
        statusTitle = 'Kehadiran Aman (${currentSubject.attendancePercentage.toStringAsFixed(0)}% Hadir)';
        statusBadgeText = '0–1 Kali Alfa (Aman)';
        statusDescription = currentSubject.totalAbsences == 0
            ? 'Kehadiran Anda 100% sempurna! Sisa kuota izin: ${currentSubject.remainingAbsenceQuota} kali lagi sebelum batas 75%.'
            : 'Kehadiran Anda sangat baik. Sisa kuota izin: ${currentSubject.remainingAbsenceQuota} kali lagi sebelum batas 75%.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Attendance Sentinel Alert Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(statusIcon, color: statusColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                statusTitle,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusBadgeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusDescription,
                          style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Progress Bar Kehadiran dengan Penanda 75%
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tingkat Kehadiran: ${currentSubject.attendedMeetings}/${currentSubject.totalMeetings} Pertemuan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                      Text(
                        'Batas Minimal UAS: 75%',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      // Background bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          color: isDark ? AppTheme.darkBorder : Colors.black12,
                        ),
                      ),
                      // Progress fill
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: FractionallySizedBox(
                          widthFactor: (currentSubject.attendancePercentage / 100).clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            color: statusColor,
                          ),
                        ),
                      ),
                      // 75% threshold indicator mark
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment(-1.0 + (0.75 * 2.0), 0.0),
                              child: Container(
                                width: 2,
                                height: 8,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: statusColor.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 10),

              // Metric Mini Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell('Hadir', '${currentSubject.attendedMeetings}x', statusColor),
                  _buildMetricCell('Tidak Hadir', '${currentSubject.totalAbsences}x', statusColor),
                  _buildMetricCell(
                    'Sisa Kuota Izin',
                    '${currentSubject.remainingAbsenceQuota}x lagi',
                    currentSubject.remainingAbsenceQuota <= 1 ? AppTheme.urgentRose : textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Interactive Meeting Matrix (1 s/d totalMeetings)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MATRIKS PERTEMUAN (1 - ${currentSubject.totalMeetings})',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            Text(
              'Klik untuk catat',
              style: TextStyle(fontSize: 10.5, color: textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Color Legend
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLegendDot(AppTheme.successSage, 'Hadir (Hijau)'),
              const SizedBox(width: 12),
              _buildLegendDot(Colors.blue, 'Sakit (Biru)'),
              const SizedBox(width: 12),
              _buildLegendDot(AppTheme.warningOchre, 'Izin (Kuning)'),
              const SizedBox(width: 12),
              _buildLegendDot(AppTheme.urgentRose, 'Alfa (Merah)'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(currentSubject.totalMeetings, (index) {
            final meetingNum = index + 1;
            final record = currentSubject.getAttendanceForMeeting(meetingNum);

            Color chipBorder;
            Color chipBg;
            Color chipText;
            String chipLabel;
            IconData? chipIcon;

            if (record != null) {
              switch (record.type.toLowerCase()) {
                case 'hadir':
                  chipBorder = AppTheme.successSage;
                  chipBg = AppTheme.successSage.withValues(alpha: 0.16);
                  chipText = AppTheme.successSage;
                  chipLabel = 'P$meetingNum (H)';
                  chipIcon = Icons.check_circle_rounded;
                  break;
                case 'sakit':
                  chipBorder = Colors.blue;
                  chipBg = Colors.blue.withValues(alpha: 0.16);
                  chipText = Colors.blue;
                  chipLabel = 'P$meetingNum (S)';
                  chipIcon = Icons.local_hospital_outlined;
                  break;
                case 'izin':
                  chipBorder = AppTheme.warningOchre;
                  chipBg = AppTheme.warningOchre.withValues(alpha: 0.16);
                  chipText = AppTheme.warningOchre;
                  chipLabel = 'P$meetingNum (I)';
                  chipIcon = Icons.assignment_outlined;
                  break;
                case 'alfa':
                default:
                  chipBorder = AppTheme.urgentRose;
                  chipBg = AppTheme.urgentRose.withValues(alpha: 0.16);
                  chipText = AppTheme.urgentRose;
                  chipLabel = 'P$meetingNum (A)';
                  chipIcon = Icons.cancel_outlined;
                  break;
              }
            } else {
              chipBorder = borderCol;
              chipBg = isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle;
              chipText = textSecondary;
              chipLabel = 'P$meetingNum';
              chipIcon = Icons.radio_button_unchecked;
            }

            return InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => RecordAbsenceDialog(
                    subjectId: currentSubject.id,
                    totalMeetings: currentSubject.totalMeetings,
                    defaultMeetingNumber: meetingNum,
                    initialRecord: record,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: chipBorder, width: record != null ? 1.4 : 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, size: 14, color: chipText),
                    const SizedBox(height: 2),
                    Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: record != null ? FontWeight.w700 : FontWeight.w500,
                        color: chipText,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // 3. Attendance Log (Catatan Riwayat Presensi)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CATATAN RIWAYAT PRESENSI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: textSecondary),
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => RecordAbsenceDialog(
                    subjectId: currentSubject.id,
                    totalMeetings: currentSubject.totalMeetings,
                  ),
                );
              },
              child: Text(
                '+ Catat Presensi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkAccent : AppTheme.brandCobalt,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (currentSubject.absences.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_outlined, size: 36, color: AppTheme.successSage),
                const SizedBox(height: 8),
                Text(
                  'Belum ada catatan presensi',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klik salah satu nomor pertemuan di atas (P1 - ${currentSubject.totalMeetings}) untuk mencatat kehadiran Anda.',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: currentSubject.absences.map((rec) {
              Color badgeColor;
              IconData badgeIcon;
              switch (rec.type.toLowerCase()) {
                case 'hadir':
                  badgeColor = AppTheme.successSage;
                  badgeIcon = Icons.check_circle_rounded;
                  break;
                case 'sakit':
                  badgeColor = Colors.blue;
                  badgeIcon = Icons.local_hospital_outlined;
                  break;
                case 'izin':
                  badgeColor = AppTheme.warningOchre;
                  badgeIcon = Icons.assignment_outlined;
                  break;
                case 'alfa':
                default:
                  badgeColor = AppTheme.urgentRose;
                  badgeIcon = Icons.cancel_outlined;
                  break;
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            rec.typeLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pertemuan Ke-${rec.meetingNumber} • ${_formatDate(rec.date)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rec.note.isNotEmpty
                                ? rec.note
                                : (rec.type.toLowerCase() == 'hadir'
                                    ? 'Hadir perkuliahan'
                                    : 'Tanpa catatan alasan'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: rec.note.isNotEmpty ? textSecondary : textSecondary.withValues(alpha: 0.6),
                              fontStyle: rec.note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                      tooltip: 'Edit Catatan',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => RecordAbsenceDialog(
                            subjectId: currentSubject.id,
                            totalMeetings: currentSubject.totalMeetings,
                            initialRecord: rec,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMetricCell(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
        ),
      ],
    );
  }
}
