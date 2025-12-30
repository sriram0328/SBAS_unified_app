import 'package:flutter/material.dart';

class AttendanceOverviewController extends ChangeNotifier {
  bool isLoading = false;
  double overallPercentage = 0.0;

  List<SubjectAttendance> subjects = [];

  Future<void> loadOverview(String rollNo) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    subjects = [
      SubjectAttendance("Machine Learning", 23, 25),
      SubjectAttendance("Software Eng.", 21, 25),
      SubjectAttendance("Big Data Analytics", 20, 25),
      SubjectAttendance("P&S", 18, 25),
    ];

    overallPercentage =
        subjects.fold(0.0, (sum, s) => sum + s.percentage) /
            subjects.length;

    isLoading = false;
    notifyListeners();
  }
}

class SubjectAttendance {
  final String subject;
  final int attended;
  final int total;

  SubjectAttendance(this.subject, this.attended, this.total);

  double get percentage => attended / total;
}
