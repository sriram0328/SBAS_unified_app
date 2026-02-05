// lib/student/attendance/controllers/daily_summary_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_summary_reader.dart';

class DailySummaryController extends ChangeNotifier {
  final _summaryService = AttendanceSummaryReader();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String? rollNo;
  
  int presentCount = 0;
  int absentCount = 0;
  int totalCount = 0;
  
  // ✅ NEW: Period-level data
  List<PeriodAttendance> periods = [];

  Future<void> loadDailyAttendance() async {
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

      // Get month summary
      final month = DateFormat('yyyy-MM').format(selectedDate);
      final summary = await _summaryService.getStudentSummary(
        rollNo: rollNo!,
        month: month,
      );

      if (summary == null) {
        presentCount = 0;
        absentCount = 0;
        totalCount = 0;
        periods = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get specific day data
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final byDate = Map<String, dynamic>.from(summary['byDate'] ?? {});
      final dayData = byDate[dateStr];

      if (dayData != null) {
        final dayMap = Map<String, dynamic>.from(dayData);
        totalCount = dayMap['total'] ?? 0;
        presentCount = dayMap['present'] ?? 0;
        absentCount = totalCount - presentCount;
        
        // ✅ Parse period data
        final periodsMap = Map<String, dynamic>.from(dayMap['periods'] ?? {});
        periods = [];
        
        // Sort by period number
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
      } else {
        presentCount = 0;
        absentCount = 0;
        totalCount = 0;
        periods = [];
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading daily: $e');
      presentCount = 0;
      absentCount = 0;
      totalCount = 0;
      periods = [];
      isLoading = false;
      notifyListeners();
    }
  }

  void changeDate(DateTime newDate) {
    selectedDate = newDate;
    loadDailyAttendance();
  }

  Future<void> refresh() async {
    await loadDailyAttendance();
  }
}

// ✅ NEW: Period attendance model
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