// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'firebase_options.dart';
import 'app_colors.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      // MainScreen
      home: const MainScreen(), 
    );
  }
}

// ========================================================
// Firebase 测试代码 (FirebaseTestScreen)
// if需要测试，只要把上面的 home: const MainScreen() 
// 改成 home: const FirebaseTestScreen() 就可以了
// ========================================================
class FirebaseTestScreen extends StatelessWidget {
  const FirebaseTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warung Wise Connection Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // This is the test write
              await FirebaseFirestore.instance
                  .collection('test_connection')
                  .add({
                    'message': 'Hello from Warung Wise!',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
              print("✅ Success: Data sent to Firebase!");
            } catch (e) {
              print("❌ Error: $e");
            }
          },
          child: const Text('Test Firebase Connection'),
        ),
      ),
    );
  }
}