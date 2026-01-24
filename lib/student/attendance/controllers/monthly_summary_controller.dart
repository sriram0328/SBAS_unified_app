// lib/student/attendance/controllers/monthly_summary_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_summary_reader.dart';

class MonthlySummaryController extends ChangeNotifier {
  final _summaryService = AttendanceSummaryReader();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  Map<int, AttendanceDay> attendanceData = {};
  String? rollNo;

  Future<void> loadMonthlyAttendance() async {
    isLoading = true;
    notifyListeners();

    try {
      // Get roll number
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

      // Clear existing data
      attendanceData = {};

      // Get summary for selected month
      final month = DateFormat('yyyy-MM').format(selectedMonth);
      final summary = await _summaryService.getStudentSummary(
        rollNo: rollNo!,
        month: month,
      );

      if (summary == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get byDate data
      final byDate = Map<String, dynamic>.from(summary['byDate'] ?? {});
      
      // Get days in month
      final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
      final daysInMonth = lastDay.day;

      // Process each day
      for (int day = 1; day <= daysInMonth; day++) {
        final currentDate = DateTime(selectedMonth.year, selectedMonth.month, day);
        
        // Skip future dates
        if (currentDate.isAfter(DateTime.now())) {
          continue;
        }

        final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
        final dayData = byDate[dateStr];

        if (dayData != null) {
          final dayMap = Map<String, dynamic>.from(dayData);
          final attended = dayMap['present'] ?? 0;
          final total = dayMap['total'] ?? 0;
          
          attendanceData[day] = AttendanceDay(attended: attended, total: total);
        } else {
          // No classes scheduled
          attendanceData[day] = AttendanceDay(attended: 0, total: 0);
        }
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading monthly attendance: $e');
      attendanceData = {};
      isLoading = false;
      notifyListeners();
    }
  }

  void previousMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    loadMonthlyAttendance();
  }

  void nextMonth() {
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    if (nextMonth.isAfter(DateTime.now())) {
      return;
    }
    selectedMonth = nextMonth;
    loadMonthlyAttendance();
  }

  int getTotalAttended() {
    return attendanceData.values.fold(0, (sum, day) => sum + day.attended);
  }

  int getTotalClasses() {
    return attendanceData.values.fold(0, (sum, day) => sum + day.total);
  }

  double getMonthlyPercentage() {
    final total = getTotalClasses();
    if (total == 0) return 0;
    return getTotalAttended() / total;
  }

  String getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> refresh() async {
    await loadMonthlyAttendance();
  }
}

class AttendanceDay {
  final int attended;
  final int total;

  AttendanceDay({required this.attended, required this.total});

  double get percentage => total > 0 ? attended / total : 0.0;

  Color get color {
    if (total == 0) return Colors.grey;
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}