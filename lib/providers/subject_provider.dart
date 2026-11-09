import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';

class SubjectProvider with ChangeNotifier {
  final StorageService _storageService;
  List<Subject> _subjects = [];

  SubjectProvider(this._storageService) {
    loadSubjects();
  }

  List<Subject> get subjects => _subjects;

  void _sortSubjects() {
    _subjects.sort();
  }

  void loadSubjects() {
    _subjects = _storageService.getSubjects();
    _sortSubjects();
    notifyListeners();
  }

  int get totalCreditHours {
    return _subjects.fold<int>(0, (sum, sub) => sum + sub.creditHours);
  }

  Subject? getSubjectById(String? id) {
    if (id == null) return null;
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addSubject(Subject subject) async {
    _subjects.add(subject);
    _sortSubjects();
    await _storageService.saveSubject(subject);
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      _sortSubjects();
      await _storageService.saveSubject(subject);
      notifyListeners();
    }
  }

  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    await _storageService.deleteSubject(id);
    notifyListeners();
  }
}

