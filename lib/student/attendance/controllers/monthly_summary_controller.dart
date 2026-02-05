import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_summary_reader.dart';

class MonthlySummaryController extends ChangeNotifier {
  final AttendanceSummaryReader _summaryService = AttendanceSummaryReader();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  Map<int, AttendanceDay> attendanceData = {};
  String? rollNo;

  Future<void> loadMonthlyAttendance() async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch roll number once
      if (rollNo == null) {
        final user = _auth.currentUser;
        if (user == null) {
          _stopLoading();
          return;
        }

        final doc = await _db.collection('students').doc(user.uid).get();
        if (!doc.exists) {
          _stopLoading();
          return;
        }

        rollNo = doc.data()?['rollno'] as String? ?? '';
      }

      if (rollNo!.isEmpty) {
        _stopLoading();
        return;
      }

      attendanceData.clear();

      final monthKey = DateFormat('yyyy-MM').format(selectedMonth);
      final summary = await _summaryService.getStudentSummary(
        rollNo: rollNo!,
        month: monthKey,
      );

      if (summary == null) {
        _stopLoading();
        return;
      }

      final Map<String, dynamic> byDate =
          Map<String, dynamic>.from(summary['byDate'] ?? {});

      final int daysInMonth =
          DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);

        if (date.isAfter(DateTime.now())) continue;

        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final dynamic dayData = byDate[dateKey];

        if (dayData != null) {
          final Map<String, dynamic> dayMap =
              Map<String, dynamic>.from(dayData);

          attendanceData[day] = AttendanceDay(
            attended: (dayMap['present'] ?? 0) as int,
            total: (dayMap['total'] ?? 0) as int,
          );
        } else {
          attendanceData[day] = AttendanceDay(attended: 0, total: 0);
        }
      }

      _stopLoading();
    } catch (e, stack) {
      debugPrint(
        'MonthlySummaryController.loadMonthlyAttendance error: $e\n$stack',
      );
      attendanceData.clear();
      _stopLoading();
    }
  }

  void previousMonth() {
    selectedMonth =
        DateTime(selectedMonth.year, selectedMonth.month - 1);
    loadMonthlyAttendance();
  }

  void nextMonth() {
    final DateTime next =
        DateTime(selectedMonth.year, selectedMonth.month + 1);

    if (next.isAfter(DateTime.now())) return;

    selectedMonth = next;
    loadMonthlyAttendance();
  }

  int getTotalAttended() {
    return attendanceData.values.fold<int>(
      0,
      (acc, day) => acc + day.attended,
    );
  }

  int getTotalClasses() {
    return attendanceData.values.fold<int>(
      0,
      (acc, day) => acc + day.total,
    );
  }

  double getMonthlyPercentage() {
    final totalClasses = getTotalClasses();
    if (totalClasses == 0) return 0;
    return getTotalAttended() / totalClasses;
  }

  String getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> refresh() => loadMonthlyAttendance();

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }
}

class AttendanceDay {
  final int attended;
  final int total;

  const AttendanceDay({
    required this.attended,
    required this.total,
  });

  double get percentage =>
      total > 0 ? attended / total : 0.0;

  Color get color {
    if (total == 0) return Colors.grey;
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
