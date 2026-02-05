import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/firestore_unflatten_helper.dart';

class StudentDashboardController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  // Student Info
  String studentName = "";
  String rollNo = "";
  String branch = "";
  String section = "";
  String yearOfStudy = "";
  String department = "";

  // Attendance (CURRENT MONTH)
  double attendancePercentage = 0.0;
  int totalClasses = 0;
  int presentClasses = 0;
  int absentClasses = 0;

  /// ----------------------------
  /// LOAD DASHBOARD DATA
  /// ----------------------------
  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // 1️⃣ Fetch student document
      final studentDoc =
          await _firestore.collection('students').doc(user.uid).get();

      if (!studentDoc.exists) {
        throw Exception("Student record not found");
      }

      final studentData = studentDoc.data()!;
      studentName = studentData['name'] ?? '';
      rollNo = studentData['rollno'] ?? '';
      branch = studentData['branch'] ?? '';
      section = studentData['section'] ?? '';
      department = _getDepartmentName(branch);

      // 2️⃣ Fetch academic record
      final academicSnap = await _firestore
          .collection('academic_records')
          .where('studentId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (academicSnap.docs.isNotEmpty) {
        yearOfStudy =
            academicSnap.docs.first.data()['yearOfStudy'].toString();
      }

      // 3️⃣ Load CURRENT MONTH attendance
      await _calculateAttendance();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// ----------------------------
  /// CURRENT MONTH ATTENDANCE
  /// ----------------------------
  Future<void> _calculateAttendance() async {
    if (rollNo.isEmpty) {
      attendancePercentage = 0;
      totalClasses = 0;
      presentClasses = 0;
      absentClasses = 0;
      return;
    }

    try {
      final now = DateTime.now();
      final monthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final docId = '${rollNo}_$monthKey';

      final doc = await _firestore
          .collection('attendance_summaries')
          .doc(docId)
          .get();

      if (!doc.exists) {
        attendancePercentage = 0;
        totalClasses = 0;
        presentClasses = 0;
        absentClasses = 0;
        return;
      }

      // 🔥 CRITICAL FIX: UNFLATTEN FIRESTORE DATA
      final rawData = doc.data()!;
      final data = FirestoreUnflattenHelper.unflatten(rawData);

      final overall = Map<String, dynamic>.from(data['overall'] ?? {});
      totalClasses = overall['totalClasses'] ?? 0;
      presentClasses = overall['present'] ?? 0;
      absentClasses = totalClasses - presentClasses;

      attendancePercentage =
          totalClasses == 0 ? 0.0 : (presentClasses / totalClasses) * 100;
      
      debugPrint('✅ Dashboard Attendance: $presentClasses/$totalClasses = ${attendancePercentage.toStringAsFixed(2)}%');
    } catch (e) {
      debugPrint('Error loading dashboard attendance: $e');
      attendancePercentage = 0;
      totalClasses = 0;
      presentClasses = 0;
      absentClasses = 0;
    }
  }

  /// ----------------------------
  /// HELPERS
  /// ----------------------------
  String get classInfo => "$yearOfStudy - $branch - $section";

  String _getDepartmentName(String branch) {
    const departments = {
      'AIML': 'Artificial Intelligence & Machine Learning',
      'AIDS': 'Artificial Intelligence & Data Science',
      'CSE': 'Computer Science & Engineering',
      'ECE': 'Electronics & Communication Engineering',
      'EEE': 'Electrical & Electronics Engineering',
      'MECH': 'Mechanical Engineering',
      'CIVIL': 'Civil Engineering',
    };
    return departments[branch] ?? branch;
  }
}