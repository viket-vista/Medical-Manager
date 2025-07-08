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
  static const _keyApi = 'apiKey';
  static const _keyModel = 'model';
  static const _keyAutoDarkMode = 'autoDarkMode';
  // 示例设置项
  bool _darkMode = false;
  String _docPath = '';
  bool _notificationsEnabled = true;
  String _apiKey = '';
  String _model = 'deepseek-chat';
  bool _autoDarkMode = false;

  // Getter方法
  bool get darkMode => _darkMode;
  String get docPath => _docPath;
  bool get notificationsEnabled => _notificationsEnabled;
  String get apiKey => _apiKey;
  String get model => _model;
  bool get autoDarkMode => _autoDarkMode;

  Future<void> init() async {
    await loadSettings();
    updateSettings(
      darkMode: darkMode,
      docPath: docPath,
      notificationsEnabled: notificationsEnabled,
      apiKey: apiKey,
      model: model,
    );
  }

  // 加载设置的方法（可以从本地存储加载）
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? dir = Platform.isAndroid
        ? (await getApplicationDocumentsDirectory()).path
        : await FilePicker.platform.getDirectoryPath();
    // 这里应该是从SharedPreferences或其他存储加载设置的逻辑
    //darkmode
    setState(
      darkMode: prefs.getBool(_keyDarkMode) ?? false,
      docPath: prefs.getString(_keyDocPath) ?? dir!,
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
      apiKey: prefs.getString(_keyApi) ?? '',
      model: prefs.getString(_keyModel) ?? 'deepseek-chat',
      autoDarkMode: prefs.getBool(_keyAutoDarkMode) ?? false,
    );
  }

  // 更新设置的方法
  Future<void> updateSettings({
    bool? darkMode,
    String? docPath,
    bool? notificationsEnabled,
    String? apiKey,
    String? model,
    bool? autoDarkMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      if (darkMode != null) prefs.setBool(_keyDarkMode, darkMode),
      if (docPath != null) prefs.setString(_keyDocPath, docPath),
      if (notificationsEnabled != null)
        prefs.setBool(_keyNotifications, notificationsEnabled),
      if (apiKey != null) prefs.setString(_keyApi, apiKey),
      if (model != null) prefs.setString(_keyModel, model),
      if (autoDarkMode != null) prefs.setBool(_keyAutoDarkMode, autoDarkMode),
    ]);
    setState(
      darkMode: darkMode,
      docPath: docPath,
      notificationsEnabled: notificationsEnabled,
      apiKey: apiKey,
      model: model,
      autoDarkMode: autoDarkMode,
    );
  }

  void setState({
    bool? darkMode,
    String? docPath,
    bool? notificationsEnabled,
    String? apiKey,
    String? model,
    bool? autoDarkMode,
  }) {
    _darkMode = darkMode ?? _darkMode;
    _docPath = docPath ?? _docPath;
    _notificationsEnabled = notificationsEnabled ?? _notificationsEnabled;
    _apiKey = apiKey ?? _apiKey; // 保持原有的API Key
    _model = model ?? _model; // 保持原有的模型
    _autoDarkMode = autoDarkMode ?? _autoDarkMode;
    notifyListeners();
  }
}
