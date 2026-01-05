import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/services/attendance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboardController extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? errorMessage;

  // Student data
  String studentName = "";
  String department = "";
  String classInfo = "";
  String rollNo = "";
  double attendancePercentage = 0.0;

  StudentDashboardController({this.rollNo = ""});

  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('rollno', isEqualTo: rollNo)
          .limit(1)
          .get();

      if (studentsQuery.docs.isEmpty) {
        throw Exception("Student data not found");
      }

      final userData = studentsQuery.docs.first.data();

      studentName = userData['name'] ?? '';
      rollNo = userData['rollno'] ?? '';

      final branch = userData['branch'] ?? '';
      final year = userData['year'] ?? '';
      final section = userData['section'] ?? '';

      classInfo = "$year - $branch - $section";
      department = _getDepartmentName(branch);

      await _calculateAttendancePercentage();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  String _getDepartmentName(String branch) {
    const departments = {
      'AIML': 'Artificial Intelligence & Machine Learning',
      'CSE': 'Computer Science & Engineering',
      'ECE': 'Electronics & Communication Engineering',
      'EEE': 'Electrical & Electronics Engineering',
    };
    return departments[branch] ?? branch;
  }

  Future<void> _calculateAttendancePercentage() async {
    try {
      // ✅ FIX: correct method name
      final snapshot = await _attendanceService
          .getAttendanceForStudent(rollNo)
          .first;

      if (snapshot.docs.isEmpty) {
        attendancePercentage = 0.0;
        return;
      }

      final totalClasses = snapshot.docs.length;
      final attendedClasses = snapshot.docs.length; 
      // 👆 already filtered by arrayContains in service

      attendancePercentage =
          ((attendedClasses / totalClasses) * 100).clamp(0, 100);
    } catch (e) {
      attendancePercentage = 0.0;
    }
  }

  Future<void> refresh() async {
    await loadStudentData();
  }
}
