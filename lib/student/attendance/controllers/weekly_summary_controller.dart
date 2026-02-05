import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_summary_reader.dart';

class WeeklySummaryController extends ChangeNotifier {
  final AttendanceSummaryReader _summaryService = AttendanceSummaryReader();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  double weeklyPercentage = 0.0;
  int attendedClasses = 0;
  int totalClasses = 0;
  List<DayAttendance> days = [];
  String? rollNo;

  /// Week starts on Monday
  DateTime selectedWeekStart = _getMondayOfWeek(DateTime.now());

  static DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> loadWeeklyAttendance() async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch roll number once
      if (rollNo == null) {
        final user = _auth.currentUser;
        if (user == null) {
          _resetAndStop();
          return;
        }

        final doc = await _db.collection('students').doc(user.uid).get();
        if (!doc.exists) {
          _resetAndStop();
          return;
        }

        rollNo = doc.data()?['rollno'] as String? ?? '';
      }

      if (rollNo!.isEmpty) {
        _resetAndStop();
        return;
      }

      // Fetch monthly summary (week lives inside a month)
      final monthKey = DateFormat('yyyy-MM').format(selectedWeekStart);
      final summary = await _summaryService.getStudentSummary(
        rollNo: rollNo!,
        month: monthKey,
      );

      if (summary == null) {
        _resetAndStop();
        return;
      }

      final Map<String, dynamic> byDate =
          Map<String, dynamic>.from(summary['byDate'] ?? {});

      days.clear();

      // Monday → Saturday (6 days)
      for (int i = 0; i < 6; i++) {
        final currentDay = selectedWeekStart.add(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDay);
        final dayName = DateFormat('EEE').format(currentDay);

        int attended = 0;
        int total = 0;
        final List<PeriodAttendance> periods = [];

        final dynamic dayData = byDate[dateKey];
        if (dayData != null) {
          final Map<String, dynamic> dayMap =
              Map<String, dynamic>.from(dayData);

          attended = (dayMap['present'] ?? 0) as int;
          total = (dayMap['total'] ?? 0) as int;

          final Map<String, dynamic> periodsMap =
              Map<String, dynamic>.from(dayMap['periods'] ?? {});

          final sortedKeys = periodsMap.keys.toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          for (final key in sortedKeys) {
            final Map<String, dynamic> periodData =
                Map<String, dynamic>.from(periodsMap[key]);

            periods.add(
              PeriodAttendance(
                periodNumber: int.parse(key),
                subject: periodData['subject'] ?? 'Unknown',
                subjectCode: periodData['subjectCode'] ?? '',
                isPresent: periodData['isPresent'] ?? false,
              ),
            );
          }
        }

        days.add(
          DayAttendance(dayName, attended, total, periods),
        );
      }

      // Weekly totals
      attendedClasses =
          days.fold<int>(0, (acc, day) => acc + day.attended);
      totalClasses =
          days.fold<int>(0, (acc, day) => acc + day.total);

      weeklyPercentage =
          totalClasses > 0 ? (attendedClasses / totalClasses * 100) : 0.0;

      _stopLoading();
    } catch (e, stack) {
      debugPrint(
        'WeeklySummaryController.loadWeeklyAttendance error: $e\n$stack',
      );
      _resetAndStop();
    }
  }

  List<DayAttendance> _generateEmptyWeek() {
    return List.generate(6, (i) {
      final currentDay = selectedWeekStart.add(Duration(days: i));
      final dayName = DateFormat('EEE').format(currentDay);
      return DayAttendance(dayName, 0, 0, const []);
    });
  }

  void previousWeek() {
    selectedWeekStart =
        selectedWeekStart.subtract(const Duration(days: 7));
    loadWeeklyAttendance();
  }

  void nextWeek() {
    final nextWeekStart =
        selectedWeekStart.add(const Duration(days: 7));

    if (nextWeekStart.isAfter(_getMondayOfWeek(DateTime.now()))) return;

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
    final nextWeekStart =
        selectedWeekStart.add(const Duration(days: 7));
    return !nextWeekStart.isAfter(_getMondayOfWeek(DateTime.now()));
  }

  Future<void> refresh() => loadWeeklyAttendance();

  void _resetAndStop() {
    days = _generateEmptyWeek();
    attendedClasses = 0;
    totalClasses = 0;
    weeklyPercentage = 0.0;
    _stopLoading();
  }

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }
}

/// =======================
/// Models
/// =======================

class DayAttendance {
  final String day;
  final int attended;
  final int total;
  final List<PeriodAttendance> periods;

  const DayAttendance(
    this.day,
    this.attended,
    this.total,
    this.periods,
  );

  double get percentage => total > 0 ? attended / total : 0.0;

  Color get color {
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class PeriodAttendance {
  final int periodNumber;
  final String subject;
  final String subjectCode;
  final bool isPresent;

  const PeriodAttendance({
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
