import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

/// Zen Minimalist Focus (Pomodoro) Screen
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int focusDuration = 25 * 60; // 25 min
  static const int breakDuration = 5 * 60;  // 5 min

  int _remainingSeconds = focusDuration;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;

  String? _selectedTaskId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        if (!_isBreak && mounted) {
          Provider.of<SettingsProvider>(context, listen: false)
              .recordCompletedSession();
        }
        setState(() {
          _isRunning = false;
          if (!_isBreak) {
            _isBreak = true;
            _remainingSeconds = breakDuration;
          } else {
            _isBreak = false;
            _remainingSeconds = focusDuration;
          }
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isBreak ? breakDuration : focusDuration;
    });
  }

  void _switchMode(bool isBreakMode) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = isBreakMode;
      _remainingSeconds = isBreakMode ? breakDuration : focusDuration;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _isBreak ? breakDuration : focusDuration;
    return (total - _remainingSeconds) / total;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final completedSessions = settingsProvider.completedPomodoroSessions;
    final pendingTasks = taskProvider.allTasks.where((t) => !t.isCompleted).toList();
    if (_selectedTaskId != null && !pendingTasks.any((t) => t.id == _selectedTaskId)) {
      _selectedTaskId = null;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fokus Belajar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Mode Selector (Fokus 25m vs Rehat 5m)
            Container(
              height: 34,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightBorderSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Row(
                children: [
                  _buildModeSegment(
                    title: 'Fokus (25m)',
                    isSelected: !_isBreak,
                    onTap: () => _switchMode(false),
                  ),
                  _buildModeSegment(
                    title: 'Rehat (5m)',
                    isSelected: _isBreak,
                    onTap: () => _switchMode(true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Target Task Selector Dropdown
            if (pendingTasks.isNotEmpty) ...[
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(
                      'Pilih tugas yang ingin difokuskan...',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                    value: _selectedTaskId,
                    items: pendingTasks.map((t) {
                      return DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTaskId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Minimalist Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    backgroundColor: isDark ? const Color(0xFF242731) : const Color(0xFFEAEAEC),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isBreak ? AppTheme.successSage : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBreak ? 'WAKTU REHAT' : 'SESI FOKUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Controls (Start / Pause / Reset)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderCol),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  ),
                  onPressed: _resetTimer,
                  child: Text('Reset', style: TextStyle(fontSize: 13, color: textSecondary)),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  child: Text(
                    _isRunning ? 'Jeda' : 'Mulai',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Completed Sessions tracker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AppTheme.successSage, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedSessions sesi fokus terselesaikan (${settingsProvider.totalFocusMinutes} menit)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegment({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppTheme.darkSurfaceElevated : Colors.white;
    final activeText = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final inactiveText = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeText : inactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
