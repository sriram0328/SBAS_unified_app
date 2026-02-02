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

    // ✅ Check if user is already logged in
    _checkAuthState();
  }

  /// ✅ Check Firebase Auth state and route accordingly
  Future<void> _checkAuthState() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // ✅ No user logged in → Go to login
      _navigateToLogin();
      return;
    }

    // ✅ User is logged in → Fetch their data
    try {
      final userData = await _fetchUserData(currentUser.uid);
      
      if (userData != null && mounted) {
        // ✅ Route to appropriate screen based on role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleRouter(userData: userData),
          ),
        );
      } else {
        // ✅ User data not found → Force logout
        await FirebaseAuth.instance.signOut();
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('❌ Error checking auth state: $e');
      // ✅ Error occurred → Go to login
      _navigateToLogin();
    }
  }

  /// ✅ Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserData(String authUid) async {
    try {
      final db = FirebaseFirestore.instance;

      // Get role from custom claims
      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
      final role = token.claims?['role'];

      debugPrint('🔍 Checking auth state for user: $authUid');
      debugPrint('🔍 Role from claims: $role');

      if (role != 'student' && role != 'faculty') {
        debugPrint('❌ Invalid role: $role');
        return null;
      }

      // Fetch user document
      final collection = role == 'student' ? 'students' : 'faculty';
      final userDoc = await db.collection(collection).doc(authUid).get();

      if (!userDoc.exists) {
        debugPrint('❌ User document not found in $collection');
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Build userData map
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
        debugPrint('✅ Student data loaded: ${data['name']} (${data['rollno']})');
      }

      if (role == 'faculty') {
        result.addAll({
          'facultyId': authUid,
          'department': data['department'] ?? '',
          'phone': data['facultyPhone'] ?? '',
          'subjects': data['subjects'] ?? [],
        });
        debugPrint('✅ Faculty data loaded: ${data['name']} (${data['department']})');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
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
                'assets/icon/app_icon.png',
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
              // ✅ Loading indicator
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