import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storageService;
  late bool _isDarkMode;
  late UserProfile _profile;

  SettingsProvider(this._storageService) {
    _isDarkMode = _storageService.isDarkMode();
    _profile = _storageService.getUserProfile();
  }

  void reloadSettings() {
    _isDarkMode = _storageService.isDarkMode();
    _profile = _storageService.getUserProfile();
    notifyListeners();
  }

  bool get isDarkMode => _isDarkMode;
  UserProfile get profile => _profile;
  int get completedPomodoroSessions => _storageService.getCompletedPomodoroSessions();
  int get totalFocusMinutes => completedPomodoroSessions * 25;

  Future<void> recordCompletedSession() async {
    await _storageService.incrementPomodoroSession();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? campus,
    String? studyProgram,
    int? semester,
  }) async {
    if (name != null) _profile.name = name;
    if (campus != null) _profile.campus = campus;
    if (studyProgram != null) _profile.studyProgram = studyProgram;
    if (semester != null) _profile.semester = semester;

    await _storageService.saveUserProfile(_profile);
    notifyListeners();
  }
}

