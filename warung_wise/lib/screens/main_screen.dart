// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'dart:async'; // 👈 必须加这行，为了用 Timer
import '../app_colors.dart';
import 'dashboard_page.dart';
import 'ai_analysis_page.dart';
import 'report_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 1. 普通的底部 Tab 切换
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 🔥 2. 高级版：模拟 AI 扫描过程 (Loading -> 跳转)
  void _startScanProcess() {
    // A. 弹出 Loading 对话框
    showDialog(
      context: context,
      barrierDismissible: false, // 用户不能点背景关闭
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 旋转的圈圈
                const CircularProgressIndicator(
                  color: AppColors.jungleGreen, 
                  strokeWidth: 6,
                ),
                const SizedBox(height: 25),
                // 提示文字
                const Text(
                  "Gemini sedang menganalisa...", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.jungleGreen),
                ),
                const SizedBox(height: 10),
                Text(
                  "Mengira kos telur & ayam...", 
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );

    // B. 延迟 2秒 后跳转
    Timer(const Duration(seconds: 2), () {
      // 1. 关掉弹窗
      Navigator.of(context).pop();
      
      // 2. 切换到 AI 页面
      setState(() {
        _selectedIndex = 1; 
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. 把 _startScanProcess 传给 Dashboard
    final List<Widget> pages = [
      DashboardPage(onScanTap: _startScanProcess), // <--- 这里用新的函数
      const AiAnalysisPage(),
      const ReportPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          height: 80,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.lightOrange,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 30),
              selectedIcon: Icon(Icons.home, size: 30, color: AppColors.jungleGreen),
              label: 'Utama',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined, size: 30),
              selectedIcon: Icon(Icons.document_scanner, size: 30, color: AppColors.jungleGreen),
              label: 'AI Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined, size: 30),
              selectedIcon: Icon(Icons.assignment, size: 30, color: AppColors.jungleGreen),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}