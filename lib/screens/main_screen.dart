import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'subjects_screen.dart';
import 'calendar_screen.dart';
import 'pomodoro_screen.dart';
import '../widgets/add_task_modal.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Bottom Navigation Shell
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SubjectsScreen(),
    CalendarScreen(),
    PomodoroScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final activeCol = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final inactiveCol = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgCol,
          border: Border(
            top: BorderSide(color: borderCol, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.format_list_bulleted,
                  label: 'Tugas',
                  activeCol: activeCol,
                  inactiveCol: inactiveCol,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.menu_book_outlined,
                  label: 'Matkul',
                  activeCol: activeCol,
                  inactiveCol: inactiveCol,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.calendar_today_outlined,
                  label: 'Kalender',
                  activeCol: activeCol,
                  inactiveCol: inactiveCol,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.hourglass_empty_outlined,
                  label: 'Fokus',
                  activeCol: activeCol,
                  inactiveCol: inactiveCol,
                ),
              ],
            ),
          ),
        ),
      ),
      // Tactile, Non-Obtrusive Floating Add Button
      floatingActionButton: FloatingActionButton(
        elevation: 2,
        highlightElevation: 4,
        mini: false,
        backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTaskModal(),
          );
        },
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeCol,
    required Color inactiveCol,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeCol : inactiveCol,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeCol : inactiveCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
