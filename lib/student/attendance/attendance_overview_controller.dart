import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/attendance_service.dart';

class AttendanceOverviewController extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  double overallPercentage = 0.0;
  String? rollNo;

  List<SubjectAttendance> subjects = [];

  Future<void> loadOverview() async {
    isLoading = true;
    notifyListeners();

    try {
      // Get roll number from current user
      if (rollNo == null) {
        final user = _auth.currentUser;
        if (user == null) {
          isLoading = false;
          notifyListeners();
          return;
        }

        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          isLoading = false;
          notifyListeners();
          return;
        }

        rollNo = doc.data()?['rollno'] ?? '';
      }

      if (rollNo!.isEmpty) {
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get subject-wise attendance
      final subjectStats = await _attendanceService.getSubjectWiseAttendance(
        rollNo: rollNo!,
      );

      // Convert to SubjectAttendance objects
      subjects = subjectStats.entries.map((entry) {
        return SubjectAttendance(
          entry.key,
          entry.value['attended'] as int,
          entry.value['total'] as int,
        );
      }).toList();

      // Sort by subject name
      subjects.sort((a, b) => a.subject.compareTo(b.subject));

      // Calculate overall percentage
      if (subjects.isNotEmpty) {
        overallPercentage = subjects.fold(0.0, (sum, s) => sum + s.percentage) /
            subjects.length;
      } else {
        overallPercentage = 0.0;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading attendance overview: $e');
      subjects = [];
      overallPercentage = 0.0;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadOverview();
  }
}

class SubjectAttendance {
  final String subject;
  final int attended;
  final int total;

  SubjectAttendance(this.subject, this.attended, this.total);

  double get percentage => total > 0 ? attended / total : 0.0;

  Color get color {
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.65) return Colors.orange;
    return Colors.red;
  }
}