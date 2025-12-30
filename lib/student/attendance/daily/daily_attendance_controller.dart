import 'package:flutter/material.dart';

class DailyAttendanceController extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  List<PeriodAttendance> periods = [];
  int presentCount = 0;
  int absentCount = 0;

  Future<void> loadDailyAttendance(String rollNo) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    periods = [
      PeriodAttendance("09:00", "Machine Learning", "Prof. Pavani", true),
      PeriodAttendance("10:00", "DBMS", "Prof. Pavani", true),
      PeriodAttendance("11:00", "P&S", "Prof. John", false),
      PeriodAttendance("12:00", "Machine Learning", "Prof. Pavani", true),
    ];

    presentCount = periods.where((p) => p.isPresent).length;
    absentCount = periods.length - presentCount;

    isLoading = false;
    notifyListeners();
  }
}

class PeriodAttendance {
  final String time;
  final String subject;
  final String faculty;
  final bool isPresent;

  PeriodAttendance(this.time, this.subject, this.faculty, this.isPresent);
}
