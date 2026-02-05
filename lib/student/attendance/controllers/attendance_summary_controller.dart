// lib/student/attendance/controllers/attendance_summary_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_summary_reader.dart';

class AttendanceSummaryController extends ChangeNotifier {
  final _summaryService = AttendanceSummaryReader();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool isLoading = false;
  String? rollNo;
  
  // Overview data - Current Month
  double overallPercentage = 0.0;
  int totalClasses = 0;
  int presentClasses = 0;
  int absentClasses = 0;
  List<SubjectSummary> subjects = [];
  String currentMonth = '';

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

        final doc = await _db.collection('students').doc(user.uid).get();
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

      // Get current month summary
      final now = DateTime.now();
      final month = DateFormat('yyyy-MM').format(now);
      currentMonth = DateFormat('MMMM yyyy').format(now);

      final summary = await _summaryService.getStudentSummary(
        rollNo: rollNo!,
        month: month,
      );

      if (summary == null) {
        // No data yet
        overallPercentage = 0.0;
        totalClasses = 0;
        presentClasses = 0;
        absentClasses = 0;
        subjects = [];
        isLoading = false;
        notifyListeners();
        return;
      }

        // Parse overall stats
        final overall = Map<String, dynamic>.from(summary['overall'] ?? {});
        totalClasses = overall['totalClasses'] ?? 0;
        presentClasses = overall['present'] ?? 0;
        absentClasses = totalClasses - presentClasses;
        overallPercentage = totalClasses == 0 ? 0.0 : (presentClasses / totalClasses) * 100;

      // Parse subject stats
      final bySubject = Map<String, dynamic>.from(summary['bySubject'] ?? {});
      subjects = [];
      
      bySubject.forEach((subjectName, stats) {
        final subjectMap = Map<String, dynamic>.from(stats);
        final total = subjectMap['total'] ?? 0;
        final present = subjectMap['present'] ?? 0;
        final percentage = total > 0 ? (present / total * 100) : 0.0;

        subjects.add(SubjectSummary(
          name: subjectName,
          total: total,
          present: present,
          percentage: percentage,
        ));
      });

      // Sort subjects by name
      subjects.sort((a, b) => a.name.compareTo(b.name));

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading overview: $e');
      subjects = [];
      overallPercentage = 0.0;
      totalClasses = 0;
      presentClasses = 0;
      absentClasses = 0;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadOverview();
  }
}

class SubjectSummary {
  final String name;
  final int total;
  final int present;
  final double percentage;

  SubjectSummary({
    required this.name,
    required this.total,
    required this.present,
    required this.percentage,
  });

  int get absent => total - present;

  Color get color {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 65) return Colors.orange;
    return Colors.red;
  }
}