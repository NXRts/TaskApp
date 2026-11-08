import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/storage_service.dart';

enum TaskFilterStatus { all, today, upcoming, overdue, completed }

enum TaskSortOption { deadlineAsc, priorityDesc, titleAsc, newest }

class TaskProvider with ChangeNotifier {
  final StorageService _storageService;
  List<TaskItem> _tasks = [];
  
  TaskFilterStatus _filterStatus = TaskFilterStatus.all;
  TaskSortOption _sortOption = TaskSortOption.deadlineAsc;
  TaskCategory? _filterCategory; // null = all
  String? _selectedSubjectId;
  String _searchQuery = '';

  TaskProvider(this._storageService) {
    loadTasks();
  }

  List<TaskItem> get allTasks => _tasks;
  TaskFilterStatus get filterStatus => _filterStatus;
  TaskSortOption get sortOption => _sortOption;
  TaskCategory? get filterCategory => _filterCategory;
  String? get selectedSubjectId => _selectedSubjectId;
  String get searchQuery => _searchQuery;

  void loadTasks() {
    _tasks = _storageService.getTasks();
    notifyListeners();
  }

  // --- FILTERS & SEARCH ---
  void setFilterStatus(TaskFilterStatus status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSortOption(TaskSortOption sort) {
    _sortOption = sort;
    notifyListeners();
  }

  void setFilterCategory(TaskCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setSelectedSubjectId(String? subjectId) {
    _selectedSubjectId = subjectId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  List<TaskItem> get filteredTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filtered = _tasks.where((task) {
      // Category filter
      if (_filterCategory != null && task.category != _filterCategory) {
        return false;
      }

      // Subject filter
      if (_selectedSubjectId != null && task.subjectId != _selectedSubjectId) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final titleMatch = task.title.toLowerCase().contains(_searchQuery);
        final descMatch = task.description.toLowerCase().contains(_searchQuery);
        if (!titleMatch && !descMatch) return false;
      }

      // Status filter
      switch (_filterStatus) {
        case TaskFilterStatus.all:
          return true;
        case TaskFilterStatus.today:
          return !task.isCompleted &&
              task.dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              task.dueDate.isBefore(todayEnd.add(const Duration(seconds: 1)));
        case TaskFilterStatus.upcoming:
          return !task.isCompleted && task.dueDate.isAfter(todayEnd);
        case TaskFilterStatus.overdue:
          return task.isOverdue;
        case TaskFilterStatus.completed:
          return task.isCompleted;
      }
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      switch (_sortOption) {
        case TaskSortOption.deadlineAsc:
          return a.dueDate.compareTo(b.dueDate);
        case TaskSortOption.priorityDesc:
          return b.priority.index.compareTo(a.priority.index);
        case TaskSortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case TaskSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

  // --- METRICS / STATS ---
  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  int get dueTodayCount => _tasks.where((t) => t.isDueToday).length;

  double get completionRate {
    if (_tasks.isEmpty) return 0.0;
    return completedCount / totalCount;
  }

  List<TaskItem> get criticalDeadlines {
    final now = DateTime.now();
    final threshold = now.add(const Duration(hours: 24));
    return _tasks.where((t) => !t.isCompleted && t.dueDate.isBefore(threshold)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<TaskItem> getTasksForSubject(String subjectId) {
    return _tasks.where((t) => t.subjectId == subjectId).toList();
  }

  List<TaskItem> getTasksForDate(DateTime date) {
    return _tasks.where((t) {
      return t.dueDate.year == date.year &&
          t.dueDate.month == date.month &&
          t.dueDate.day == date.day;
    }).toList();
  }

  // --- CRUD ACTIONS ---
  Future<void> addTask(TaskItem task) async {
    _tasks.add(task);
    await _storageService.saveTask(task);
    loadTasks();
  }

  Future<void> updateTask(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _storageService.saveTask(task);
      loadTasks();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _storageService.deleteTask(id);
    notifyListeners();
  }

  Future<void> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final newStatus = !task.isCompleted;
      task.isCompleted = newStatus;
      task.completedAt = newStatus ? DateTime.now() : null;
      
      // If completed, mark all subtasks completed too
      if (newStatus) {
        for (var sub in task.subtasks) {
          sub.isCompleted = true;
        }
      }

      await _storageService.saveTask(task);
      loadTasks();
    }
  }

  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final subIndex = task.subtasks.indexWhere((s) => s.id == subTaskId);
      if (subIndex != -1) {
        task.subtasks[subIndex].isCompleted = !task.subtasks[subIndex].isCompleted;
        
        // Auto mark parent task completed if all subtasks are checked
        if (task.subtasks.isNotEmpty &&
            task.subtasks.every((s) => s.isCompleted)) {
          task.isCompleted = true;
          task.completedAt = DateTime.now();
        } else if (task.isCompleted &&
            task.subtasks.any((s) => !s.isCompleted)) {
          task.isCompleted = false;
          task.completedAt = null;
        }

        await _storageService.saveTask(task);
        loadTasks();
      }
    }
  }

  Future<void> addSubTask(String taskId, String title) async {
    if (title.trim().isEmpty) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final newSub = SubTask(
        id: const Uuid().v4(),
        title: title.trim(),
        isCompleted: false,
      );
      task.subtasks.add(newSub);
      task.isCompleted = false;
      await _storageService.saveTask(task);
      loadTasks();
    }
  }

  Future<void> deleteSubTask(String taskId, String subTaskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      task.subtasks.removeWhere((s) => s.id == subTaskId);
      await _storageService.saveTask(task);
      loadTasks();
    }
  }
}

