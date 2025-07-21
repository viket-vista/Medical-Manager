import 'package:flutter/material.dart';

class DiscoveryState with ChangeNotifier {
  List<Map<String, dynamic>> _devices = [];
  bool _isInitializing = true;
  String? _error;

  List<Map<String, dynamic>> get devices => _devices;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  void addDevice(Map<String, dynamic> device) {
    _devices.add(device);
    notifyListeners(); // 通知所有监听者
  }

  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }

  void setInitializing(bool value) {
    _isInitializing = value;
    notifyListeners();
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }
}