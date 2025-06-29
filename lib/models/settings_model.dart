// lib/models/settings_model.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  static const _keyDarkMode = 'darkMode';
  static const _keyDocPath = 'docPath';
  static const _keyNotifications = 'notificationsEnabled';
  // 示例设置项
  bool _darkMode = false;
  String _docPath = '';
  bool _notificationsEnabled = true;

  // Getter方法
  bool get darkMode => _darkMode;
  String get docPath => _docPath;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    await loadSettings();
    updateSettings(darkMode: darkMode,docPath: docPath,notificationsEnabled: notificationsEnabled);
  }

  // 加载设置的方法（可以从本地存储加载）
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? dir = Platform.isAndroid?(await getApplicationDocumentsDirectory()).path:await FilePicker.platform.getDirectoryPath();
    // 这里应该是从SharedPreferences或其他存储加载设置的逻辑
    //darkmode
    setState(
      darkMode: prefs.getBool(_keyDarkMode) ?? false,
      docPath:
          prefs.getString(_keyDocPath) ?? dir!,
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
    );
  }

  // 更新设置的方法
  Future<void> updateSettings({
    bool? darkMode,
    String? docPath,
    bool? notificationsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      if (darkMode != null) prefs.setBool(_keyDarkMode, darkMode),
      if (docPath != null) prefs.setString(_keyDocPath, docPath),
      if (notificationsEnabled != null)
        prefs.setBool(_keyNotifications, notificationsEnabled),
    ]);
    setState(
      darkMode: darkMode,
      docPath: docPath,
      notificationsEnabled: notificationsEnabled,
    );
  }

  void setState({bool? darkMode, String? docPath, bool? notificationsEnabled}) {
    _darkMode = darkMode ?? _darkMode;
    _docPath = docPath ?? _docPath;
    _notificationsEnabled = notificationsEnabled ?? _notificationsEnabled;
    notifyListeners();
  }
}
