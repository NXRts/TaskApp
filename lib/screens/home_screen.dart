import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import 'profile_settings_screen.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();
  final Map<TaskFilterStatus, GlobalKey> _filterChipKeys = {
    for (final status in TaskFilterStatus.values) status: GlobalKey(),
  };

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final profile = settingsProvider.profile;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final filteredTasks = taskProvider.filteredTasks;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Editorial Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Date & Action Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formattedDate.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                settingsProvider.isDarkMode
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 19,
                                color: textSecondary,
                              ),
                              tooltip: 'Ganti Tema',
                              onPressed: () => settingsProvider.toggleTheme(),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileSettingsScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorder,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'M',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Greeting
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semester ${profile.semester} • ${profile.studyProgram}',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),

                    const SizedBox(height: 16),

                    // Daily Overview
                    const SummaryCard(),

                    const SizedBox(height: 16),

                    // Sleek Minimalist Search Bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderCol, width: 0.8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Cari tugas, praktikum, matkul...',
                          hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                          prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    taskProvider.setSearchQuery('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          taskProvider.setSearchQuery(val);
                          setState(() {});
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Segmented Category Tabs & Sort Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightBorderSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderCol, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                _buildSegmentItem(
                                  label: 'Semua',
                                  isSelected: taskProvider.filterCategory == null,
                                  onTap: () => taskProvider.setFilterCategory(null),
                                ),
                                _buildSegmentItem(
                                  label: 'Kuliah',
                                  isSelected: taskProvider.filterCategory == TaskCategory.academic,
                                  onTap: () => taskProvider.setFilterCategory(TaskCategory.academic),
                                ),
                                _buildSegmentItem(
                                  label: 'Pribadi',
                                  isSelected: taskProvider.filterCategory == TaskCategory.personal,
                                  onTap: () => taskProvider.setFilterCategory(TaskCategory.personal),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Sort Menu
                        PopupMenuButton<TaskSortOption>(
                          tooltip: 'Urutkan',
                          icon: Icon(Icons.swap_vert, size: 20, color: textSecondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (sort) => taskProvider.setSortOption(sort),
                          itemBuilder: (ctx) => [
                            _buildSortMenuItem(
                              TaskSortOption.deadlineAsc,
                              'Tenggat Terdekat',
                              taskProvider.sortOption == TaskSortOption.deadlineAsc,
                            ),
                            _buildSortMenuItem(
                              TaskSortOption.priorityDesc,
                              'Prioritas Tertinggi',
                              taskProvider.sortOption == TaskSortOption.priorityDesc,
                            ),
                            _buildSortMenuItem(
                              TaskSortOption.newest,
                              'Terbaru Dibuat',
                              taskProvider.sortOption == TaskSortOption.newest,
                            ),
                            _buildSortMenuItem(
                              TaskSortOption.titleAsc,
                              'Nama (A - Z)',
                              taskProvider.sortOption == TaskSortOption.titleAsc,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Horizontal Status Filters
                    SingleChildScrollView(
                      controller: _filterScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: Row(
                        children: [
                          _buildFilterChip('Semua', TaskFilterStatus.all),
                          const SizedBox(width: 6),
                          _buildFilterChip('Hari Ini', TaskFilterStatus.today),
                          const SizedBox(width: 6),
                          _buildFilterChip('Mendatang', TaskFilterStatus.upcoming),
                          const SizedBox(width: 6),
                          _buildFilterChip('Terlewat', TaskFilterStatus.overdue),
                          const SizedBox(width: 6),
                          _buildFilterChip('Selesai', TaskFilterStatus.completed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Task List Feed
            if (filteredTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada tugas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semua tugas telah diselesaikan atau sesuaikan filter Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderCol),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const AddTaskModal(),
                            );
                          },
                          child: const Text('Buat Tugas Baru', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(task: task);
                    },
                    childCount: filteredTasks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentItem({
    required String label,
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
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
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

  Widget _buildFilterChip(String label, TaskFilterStatus status) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final isSelected = taskProvider.filterStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      key: _filterChipKeys[status],
      onTap: () {
        taskProvider.setFilterStatus(status);
        final chipContext = _filterChipKeys[status]?.currentContext;
        if (chipContext != null) {
          Scrollable.ensureVisible(
            chipContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkAccent.withValues(alpha: 0.15) : AppTheme.lightAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? AppTheme.darkAccent : Colors.white)
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<TaskSortOption> _buildSortMenuItem(
    TaskSortOption value,
    String title,
    bool isSelected,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          if (isSelected) const Icon(Icons.check, size: 16, color: AppTheme.brandCobalt),
        ],
      ),
    );
  }
}
