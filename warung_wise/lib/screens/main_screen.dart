import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'dashboard_page.dart';
import 'ai_analysis_page.dart';
import 'report_page.dart';

class MainScreen extends StatefulWidget {  //ini navigation bar ya
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 引用我们刚才分开写的三个页面
  final List<Widget> _pages = [
    const DashboardPage(), 
    const AiAnalysisPage(),
    const ReportPage(),    
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 显示当前选中的页面
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