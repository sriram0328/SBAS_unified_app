import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase Core
import 'firebase_options.dart'; // 2. Import the options file from FlutterFire
import 'auth/login/login_screen.dart'; // Your login screen

// 3. Make your main function async
Future<void> main() async {
  // 4. Ensure Flutter is ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 5. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 6. Run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Powerhouse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Start with the login screen
      // Add named routes for navigation
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}