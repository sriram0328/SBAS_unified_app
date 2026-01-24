// lib/student/attendance/controllers/weekly_summary_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_summary_reader.dart';

class WeeklySummaryController extends ChangeNotifier {
  final _summaryService = AttendanceSummaryReader();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool isLoading = false;
  double weeklyPercentage = 0.0;
  int attendedClasses = 0;
  int totalClasses = 0;
  List<DayAttendance> days = [];
  String? rollNo;
  
  // Week selection
  DateTime selectedWeekStart = _getMondayOfWeek(DateTime.now());
  
  static DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> loadWeeklyAttendance() async {
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

      // Get month summary for selected week
      final month = DateFormat('yyyy-MM').format(selectedWeekStart);
      final summary = await _summaryService.getStudentSummary(
        rollNo: rollNo!,
        month: month,
      );

      if (summary == null) {
        days = _generateEmptyWeek();
        attendedClasses = 0;
        totalClasses = 0;
        weeklyPercentage = 0.0;
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get byDate data
      final byDate = Map<String, dynamic>.from(summary['byDate'] ?? {});
      
      // Generate days for the week (Monday to Saturday)
      days = [];
      for (int i = 0; i < 6; i++) {
        final currentDay = selectedWeekStart.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(currentDay);
        final dayName = DateFormat('EEE').format(currentDay);

        final dayData = byDate[dateStr];
        int attended = 0;
        int total = 0;
        List<PeriodAttendance> periods = [];

        if (dayData != null) {
          final dayMap = Map<String, dynamic>.from(dayData);
          attended = dayMap['present'] ?? 0;
          total = dayMap['total'] ?? 0;
          
          // ✅ Parse period data
          final periodsMap = Map<String, dynamic>.from(dayMap['periods'] ?? {});
          final sortedKeys = periodsMap.keys.toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          
          for (final periodKey in sortedKeys) {
            final periodData = Map<String, dynamic>.from(periodsMap[periodKey]);
            periods.add(PeriodAttendance(
              periodNumber: int.parse(periodKey),
              subject: periodData['subject'] ?? 'Unknown',
              subjectCode: periodData['subjectCode'] ?? '',
              isPresent: periodData['isPresent'] ?? false,
            ));
          }
        }

        days.add(DayAttendance(
          dayName,
          attended,
          total,
          periods, // ✅ Add periods
        ));
      }

      // Calculate overall weekly stats
      attendedClasses = days.fold(0, (sum, day) => sum + day.attended);
      totalClasses = days.fold(0, (sum, day) => sum + day.total);
      weeklyPercentage = totalClasses > 0 ? (attendedClasses / totalClasses * 100) : 0.0;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading weekly attendance: $e');
      days = _generateEmptyWeek();
      attendedClasses = 0;
      totalClasses = 0;
      weeklyPercentage = 0.0;
      isLoading = false;
      notifyListeners();
    }
  }

  List<DayAttendance> _generateEmptyWeek() {
    return List.generate(6, (i) {
      final currentDay = selectedWeekStart.add(Duration(days: i));
      final dayName = DateFormat('EEE').format(currentDay);
      return DayAttendance(dayName, 0, 0, []);
    });
  }

  void previousWeek() {
    selectedWeekStart = selectedWeekStart.subtract(const Duration(days: 7));
    loadWeeklyAttendance();
  }

  void nextWeek() {
    final nextWeekStart = selectedWeekStart.add(const Duration(days: 7));
    if (nextWeekStart.isAfter(_getMondayOfWeek(DateTime.now()))) {
      return;
    }
    selectedWeekStart = nextWeekStart;
    loadWeeklyAttendance();
  }

  String getWeekLabel() {
    final endOfWeek = selectedWeekStart.add(const Duration(days: 5));
    final startStr = DateFormat('MMM d').format(selectedWeekStart);
    final endStr = DateFormat('MMM d, yyyy').format(endOfWeek);
    return '$startStr - $endStr';
  }

  bool canGoNext() {
    final nextWeekStart = selectedWeekStart.add(const Duration(days: 7));
    return !nextWeekStart.isAfter(_getMondayOfWeek(DateTime.now()));
  }

  Future<void> refresh() async {
    await loadWeeklyAttendance();
  }
}

// ✅ Updated DayAttendance with periods
class DayAttendance {
  final String day;
  final int attended;
  final int total;
  final List<PeriodAttendance> periods; // ✅ NEW

  DayAttendance(this.day, this.attended, this.total, this.periods);

  double get percentage => total > 0 ? attended / total : 0.0;

  Color get color {
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

// ✅ NEW: Period attendance model (same as Daily)
class PeriodAttendance {
  final int periodNumber;
  final String subject;
  final String subjectCode;
  final bool isPresent;

  PeriodAttendance({
    required this.periodNumber,
    required this.subject,
    required this.subjectCode,
    required this.isPresent,
  });

  String get time {
    const timings = {
      1: '09:00 AM',
      2: '10:00 AM',
      3: '11:00 AM',
      4: '12:00 PM',
      5: '01:00 PM',
      6: '02:00 PM',
      7: '03:00 PM',
      8: '04:00 PM',
    };
    return timings[periodNumber] ?? '$periodNumber:00';
  }
  
  Color get statusColor => isPresent ? Colors.green : Colors.red;
  String get statusText => isPresent ? 'Present' : 'Absent';
}