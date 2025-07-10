import 'package:flutter/material.dart';
import 'package:medicalmanager/pages/MedicalRecord.dart';
import 'package:medicalmanager/pages/AI.dart';
import 'package:medicalmanager/pages/Settings.dart';

class AllMHpage extends StatefulWidget {
  const AllMHpage({super.key});

  @override
  State<AllMHpage> createState() => _AllMHpageState();
}

class _AllMHpageState extends State<AllMHpage> {
  int _selectedIndex = 0;
  // 页面内容列表
  final List<Widget> _pages = [MedicalRecordPage(), AIPage(), SettingsPage()];
  
  // 添加PageController用于处理滑动切换
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 当点击导航项时，滑动到对应页面
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 释放PageController资源
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '病历'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
        currentIndex: _selectedIndex,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
