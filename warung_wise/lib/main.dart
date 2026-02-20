import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'firebase_options.dart';

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
      home: Scaffold(
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
      ),
    );
  }
}


/* origin from github clone

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Add this!
import 'firebase_options.dart'; // 2. Add this (after Step 1 is done)!
import 'app_colors.dart';
import 'screens/main_screen.dart';

/*void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // This line officially connects your app to your Firebase project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WarungWiseApp());
}
*/
Future<void> main() async {
  // 1. Added 'Future<void>' and 'async'
  WidgetsFlutterBinding.ensureInitialized();

  // 2. This will now work once the file in Step 2 is generated
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
      home: const MainScreen(), // 启动时进入导航框架
    );
  }
}
*/