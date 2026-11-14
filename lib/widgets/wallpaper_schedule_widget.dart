import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../services/schedule_export_service.dart';
import '../utils/app_theme.dart';

/// 9:16 Aspect Ratio Lockscreen Wallpaper Widget (Obsidian Minimalist Aesthetic)
class WallpaperScheduleWidget extends StatelessWidget {
  final UserProfile profile;
  final List<Subject> subjects;
  final bool is24HourFormat;
  final bool showLecturer;

  const WallpaperScheduleWidget({
    super.key,
    required this.profile,
    required this.subjects,
    this.is24HourFormat = true,
    this.showLecturer = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort subjects by day of week and start time
    final sortedSubjects = List<Subject>.from(subjects)..sort();
    final totalSks = subjects.fold<int>(0, (sum, s) => sum + s.creditHours);

    // Group subjects by day (1: Senin ... 7: Minggu)
    final Map<int, List<Subject>> dayMap = {};
    for (int day = 1; day <= 7; day++) {
      final list = sortedSubjects.where((s) => s.dayOfWeek == day).toList();
      if (list.isNotEmpty) {
        dayMap[day] = list;
      }
    }

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C0D12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090A0E),
              Color(0xFF0E1017),
              Color(0xFF0A0B10),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top safe breathing space for phone lockscreen clock widget (~50px)
            const SizedBox(height: 38),

            // Discreet Header Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandCobalt,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACADEMIC SCHEDULE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    'SMT ${profile.semester}',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Student Name & Profile Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141721),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile.studyProgram.isNotEmpty || profile.campus.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${profile.studyProgram.isNotEmpty ? profile.studyProgram : ''}${profile.studyProgram.isNotEmpty && profile.campus.isNotEmpty ? ' • ' : ''}${profile.campus}',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandCobalt.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.brandCobalt.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$totalSks SKS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Schedule Body (Grouped by Day)
            Expanded(
              child: dayMap.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada jadwal kuliah',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final entry in dayMap.entries) ...[
                          _buildDaySection(entry.key, entry.value),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
            ),

            // Minimalist Footer
            const SizedBox(height: 6),
            Center(
              child: Text(
                'TASKAPP • OFFLINE ACADEMIC OS',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(int day, List<Subject> daySubjects) {
    final dayName = ScheduleExportService.getDayName(day).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header chip
        Row(
          children: [
            Text(
              dayName,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF93C5FD),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '• ${daySubjects.length} KELAS',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Class items
        for (final subject in daySubjects) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 3.5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFF13151E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 0.6,
              ),
            ),
            child: Row(
              children: [
                // Subject color pill
                Container(
                  width: 3.5,
                  height: 24,
                  decoration: BoxDecoration(
                    color: subject.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),

                // Subject Name & Room/Lecturer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          if (subject.room.isNotEmpty) ...[
                            Text(
                              '📍 ${subject.room}',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            '${subject.creditHours} SKS',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: subject.color.withValues(alpha: 0.9),
                            ),
                          ),
                          if (showLecturer && subject.lecturer.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '• ${subject.lecturer}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Time Range
                if (subject.timeRange?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subject.timeRange!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
