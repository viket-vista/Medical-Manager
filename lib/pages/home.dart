import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/pages/MedicalRecord.dart';
import 'package:medicalmanager/pages/AI.dart';
import 'package:medicalmanager/pages/Settings.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class AllMHpage extends StatefulWidget {
  const AllMHpage({Key? key}) : super(key: key);

  @override
  State<AllMHpage> createState() => _AllMHpageState();
}

class _AllMHpageState extends State<AllMHpage> {
  int _selectedIndex = 0;
  // 页面内容列表
  final List<Widget> _pages = [MedicalRecordPage(), AIPage(), SettingsPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex), // 显示当前选中页面
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '病历'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
