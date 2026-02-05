import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login/login_screen.dart';
import 'auth/role_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _navigateToLogin();
      return;
    }

    try {
      final userData = await _fetchUserData(currentUser.uid);
      
      if (userData != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleRouter(userData: userData),
          ),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        _navigateToLogin();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData(String authUid) async {
    try {
      final db = FirebaseFirestore.instance;

      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
      final role = token.claims?['role'];

      if (role != 'student' && role != 'faculty') {
        return null;
      }

      final collection = role == 'student' ? 'students' : 'faculty';
      final userDoc = await db.collection(collection).doc(authUid).get();

      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final currentUser = FirebaseAuth.instance.currentUser!;

      final result = <String, dynamic>{
        'authUid': authUid,
        'role': role,
        'name': data['name'] ?? '',
        'email': currentUser.email ?? '',
      };

      if (role == 'student') {
        result.addAll({
          'studentId': authUid,
          'rollNo': data['rollno'] ?? '',
          'branch': data['branch'] ?? '',
          'section': data['section'] ?? '',
          'phone': data['studentPhone'] ?? '',
          'parentPhone': data['parentPhone'] ?? '',
        });
      }

      if (role == 'faculty') {
        result.addAll({
          'facultyId': authUid,
          'department': data['department'] ?? '',
          'phone': data['facultyPhone'] ?? '',
          'subjects': data['subjects'] ?? [],
        });
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/splashicon.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 30),
              const Text(
                'SBAS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Barcode Based Attendance System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}