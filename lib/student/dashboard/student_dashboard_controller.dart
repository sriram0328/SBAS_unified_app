import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/attendance_service.dart';
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

  // Constructor can receive rollNo from login
  StudentDashboardController({this.rollNo = ""});

  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Query by rollno field (not document ID)
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

      // Calculate attendance percentage
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
      // Get all attendance records for this student
      final snapshot = await _attendanceService
          .getAttendanceForStudent(rollNo)
          .first;

      if (snapshot.docs.isEmpty) {
        attendancePercentage = 0.0;
        return;
      }

      int totalClasses = snapshot.docs.length;
      int attendedClasses = snapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['presentStudentRollNos']
              .contains(rollNo))
          .length;

      attendancePercentage = (attendedClasses / totalClasses) * 100;
    } catch (e) {
      debugPrint("Error calculating attendance: $e");
      attendancePercentage = 0.0;
    }
  }

  Future<void> refresh() async {
    await loadStudentData();
  }
}