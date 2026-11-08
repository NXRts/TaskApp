import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_modal.dart';
import 'profile_settings_screen.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final profile = settingsProvider.profile;

    final filteredTasks = taskProvider.filteredTasks;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Greeting Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${profile.name}! 👋',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Semester ${profile.semester} • ${profile.studyProgram}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        // Action buttons: Dark mode & Profile
                        Row(
                          children: [
                            IconButton.filledTonal(
                              icon: Icon(
                                settingsProvider.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                size: 20,
                              ),
                              onPressed: () => settingsProvider.toggleTheme(),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.person, size: 20),
                              tooltip: 'Profil & Pengaturan',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Summary Card
                    const SummaryCard(),

                    const SizedBox(height: 18),

                    // Search Input
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari tugas, praktikum, materi...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ),
                      onChanged: (val) => taskProvider.setSearchQuery(val),
                    ),

                    const SizedBox(height: 14),

                    // Category Filter Tabs (Semua | Kuliah | Pribadi)
                    Row(
                      children: [
                        _buildCategoryChip(
                          context,
                          label: 'Semua',
                          isSelected: taskProvider.filterCategory == null,
                          onTap: () => taskProvider.setFilterCategory(null),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          context,
                          label: '🎓 Kuliah',
                          isSelected: taskProvider.filterCategory == TaskCategory.academic,
                          onTap: () => taskProvider.setFilterCategory(TaskCategory.academic),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          context,
                          label: '👤 Pribadi',
                          isSelected: taskProvider.filterCategory == TaskCategory.personal,
                          onTap: () => taskProvider.setFilterCategory(TaskCategory.personal),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Status Filter Chips (All | Today | Upcoming | Overdue | Completed)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip(
                            context,
                            label: 'Semua Status',
                            status: TaskFilterStatus.all,
                          ),
                          const SizedBox(width: 6),
                          _buildStatusChip(
                            context,
                            label: '🔴 Hari Ini',
                            status: TaskFilterStatus.today,
                          ),
                          const SizedBox(width: 6),
                          _buildStatusChip(
                            context,
                            label: '🟡 Mendatang',
                            status: TaskFilterStatus.upcoming,
                          ),
                          const SizedBox(width: 6),
                          _buildStatusChip(
                            context,
                            label: '⏰ Terlewat',
                            status: TaskFilterStatus.overdue,
                          ),
                          const SizedBox(width: 6),
                          _buildStatusChip(
                            context,
                            label: '✅ Selesai',
                            status: TaskFilterStatus.completed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tasks List
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
                          Icons.task_alt,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada tugas yang sesuai',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Semua tugas telah diselesaikan atau gunakan filter lain.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Tugas Baru'),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const AddTaskModal(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 80),
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

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required TaskFilterStatus status,
  }) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final isSelected = taskProvider.filterStatus == status;

    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (_) {
        taskProvider.setFilterStatus(status);
      },
    );
  }
}
