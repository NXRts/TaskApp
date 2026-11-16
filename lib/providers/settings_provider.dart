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

  bool get taskRemindersEnabled => _storageService.getTaskRemindersEnabled();
  bool get reminderH1Enabled => _storageService.getReminderH1Enabled();
  bool get reminderH3HoursEnabled => _storageService.getReminderH3HoursEnabled();
  bool get reminderH30MinutesEnabled => _storageService.getReminderH30MinutesEnabled();

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    await _storageService.setTaskRemindersEnabled(enabled);
    notifyListeners();
  }

  Future<void> setReminderH1Enabled(bool enabled) async {
    await _storageService.setReminderH1Enabled(enabled);
    notifyListeners();
  }

  Future<void> setReminderH3HoursEnabled(bool enabled) async {
    await _storageService.setReminderH3HoursEnabled(enabled);
    notifyListeners();
  }

  Future<void> setReminderH30MinutesEnabled(bool enabled) async {
    await _storageService.setReminderH30MinutesEnabled(enabled);
    notifyListeners();
  }

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

