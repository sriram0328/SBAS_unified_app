import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  double attendancePercentage = 0.0;

  /// ----------------------------
  /// LOAD DASHBOARD DATA
  /// ----------------------------
  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      /// 1️⃣ Fetch student document
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

      /// 2️⃣ Fetch academic record (year)
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

      /// 3️⃣ Calculate attendance %
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
  /// ATTENDANCE CALCULATION (FIXED)
  /// ----------------------------
  Future<void> _calculateAttendance() async {
    if (rollNo.isEmpty) {
      attendancePercentage = 0;
      return;
    }

    try {
      // Query only attendance records where this student is enrolled
      final attendanceSnap = await _firestore
          .collection('attendance')
          .where('enrolledStudentIds', arrayContains: rollNo)
          .get();

      int totalClasses = 0;
      int presentCount = 0;

      for (var doc in attendanceSnap.docs) {
        final data = doc.data();
        
        // Get the enrolled and present lists
        final List<dynamic> enrolledList = data['enrolledStudentIds'] ?? [];
        final List<dynamic> presentList = data['presentStudentIds'] ?? [];

        // Only count classes where student is enrolled
        if (enrolledList.contains(rollNo)) {
          totalClasses++;
          
          // Check if student was present
          if (presentList.contains(rollNo)) {
            presentCount++;
          }
        }
      }

      // Calculate percentage
      attendancePercentage =
          totalClasses == 0 ? 0 : (presentCount / totalClasses) * 100;
    } catch (e) {
      print('Error calculating attendance: $e');
      attendancePercentage = 0;
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