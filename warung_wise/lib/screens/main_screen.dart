import 'package:flutter/material.dart';
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

  // 1. 标准的点击底部 Tab 切换
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 2. 🔥 新增：专门给 Dashboard 用的“跳转到 AI 页”函数
  void _goToAiPage() {
    setState(() {
      _selectedIndex = 1; // 1 代表第二个页面 (AI Scan)
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. 🔥 把页面列表搬到 build 里面来
    // 这样我们才能把 _goToAiPage 这个函数传给 DashboardPage
    final List<Widget> pages = [
      DashboardPage(onScanTap: _goToAiPage), // <--- 这里把“钥匙”传给 Dashboard
      const AiAnalysisPage(),
      const ReportPage(),
    ];

    return Scaffold(
      // 使用上面的局部变量 pages
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