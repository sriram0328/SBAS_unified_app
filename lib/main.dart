import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sbas_attendance/auth/login/login_screen.dart';
import 'firebase_options.dart';

import 'splashscreen.dart'; // 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SBAS Attendance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      // START WITH SPLASH, NOT LOGIN
      home: const SplashScreen(),
      //home: const RoleRouter(),  if changed to role router after splash; if kept auto login 


      // Routes (optional but fine)
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
