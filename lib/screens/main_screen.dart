import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart';
import 'subjects_screen.dart';
import 'calendar_screen.dart';
import 'finance_screen.dart';
import 'pomodoro_screen.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/add_transaction_modal.dart';
import '../utils/app_theme.dart';

/// Modern Editorial Bottom Navigation Shell
class MainScreen extends StatefulWidget {
  static const int tasksTabIndex = 0;
  static const int subjectsTabIndex = 1;
  static const int calendarTabIndex = 2;
  static const int financeTabIndex = 3;
  static const int focusTabIndex = 4;

  const MainScreen({super.key});

  /// Switches the active bottom navigation tab when [context] is inside [MainScreen].
  static bool switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    if (state == null) return false;
    state._switchToTab(index);
    return true;
  }

  /// Switches to the Pomodoro Focus tab and preselects [taskId] as the focus target.
  static bool focusTaskInPomodoro(BuildContext context, String taskId) {
    try {
      Provider.of<TaskProvider>(context, listen: false).requestFocusOnTask(taskId);
    } catch (_) {}
    return switchTab(context, focusTabIndex);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    if (index < 0 || index >= _screens.length || _currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SubjectsScreen(),
    CalendarScreen(),
    FinanceScreen(),
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
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Keuangan',
                  activeCol: activeCol,
                  inactiveCol: inactiveCol,
                ),
                _buildNavItem(
                  index: 4,
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
        heroTag: 'main_fab',
        elevation: 2,
        highlightElevation: 4,
        mini: false,
        backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () {
          if (_currentIndex == 3) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddTransactionModal(),
            );
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddTaskModal(),
            );
          }
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
