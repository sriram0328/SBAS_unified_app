import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/attendance_service.dart';

class StudentDashboardController extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? errorMessage;

  String studentName = "";
  String department = "";
  String classInfo = "";
  String rollNo = "";
  double attendancePercentage = 0.0;

  /// ----------------------------
  /// LOAD STUDENT DASHBOARD
  /// ----------------------------
  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw Exception("Student data not found");
      }

      final data = doc.data()!;

      studentName = data['name'] ?? '';
      rollNo = data['rollno'] ?? '';

      final branch = data['branch'] ?? '';
      final year = data['year'] ?? '';
      final section = data['section'] ?? '';

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

  /// ----------------------------
  /// ATTENDANCE %
  /// ----------------------------
  Future<void> _calculateAttendancePercentage() async {
    try {
      if (rollNo.isEmpty) {
        attendancePercentage = 0.0;
        return;
      }

      final records =
          await _attendanceService.getAttendanceForStudentRoll(
        rollNo: rollNo,
      );

      if (records.isEmpty) {
        attendancePercentage = 0.0;
        return;
      }

      final presentCount =
          records.where((r) => r['isPresent'] == true).length;

      attendancePercentage =
          (presentCount / records.length) * 100.0;
    } catch (_) {
      attendancePercentage = 0.0;
    }
  }

  /// ----------------------------
  /// REFRESH
  /// ----------------------------
  Future<void> refresh() async {
    await loadStudentData();
  }

  /// ----------------------------
  /// HELPERS
  /// ----------------------------
  String _getDepartmentName(String branch) {
    const departments = {
      'AIML': 'Artificial Intelligence & Machine Learning',
      'CSE': 'Computer Science & Engineering',
      'ECE': 'Electronics & Communication Engineering',
      'EEE': 'Electrical & Electronics Engineering',
    };
    return departments[branch] ?? branch;
  }
}
