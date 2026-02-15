import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const WarungWiseApp());
}

class WarungWiseApp extends StatelessWidget {
  const WarungWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warung Wise',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.offWhite,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.jungleGreen),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(), // 启动时进入导航框架
    );
  }
}