import 'package:flutter/material.dart';

class WeeklyAttendanceController extends ChangeNotifier {
  bool isLoading = false;

  double weeklyPercentage = 0.0;
  int attendedClasses = 0;
  int totalClasses = 0;

  List<DayAttendance> days = [];

  Future<void> loadWeeklyAttendance(String rollNo) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    // Mock data with detailed subject information
    days = [
      DayAttendance(
        "Mon",
        5,
        6,
        [
          SubjectAttendanceRecord("Machine Learning", "09:00 AM", "Theory", true),
          SubjectAttendanceRecord("Software Eng.", "10:00 AM", "Theory", true),
          SubjectAttendanceRecord("Big Data", "11:00 AM", "Theory", true),
          SubjectAttendanceRecord("P&S", "12:00 PM", "Theory", false),
          SubjectAttendanceRecord("ML Lab", "02:00 PM", "Lab", true),
          SubjectAttendanceRecord("SE Lab", "03:00 PM", "Lab", true),
        ],
      ),
      DayAttendance(
        "Tue",
        6,
        6,
        [
          SubjectAttendanceRecord("Machine Learning", "09:00 AM", "Theory", true),
          SubjectAttendanceRecord("Big Data", "10:00 AM", "Theory", true),
          SubjectAttendanceRecord("P&S", "11:00 AM", "Theory", true),
          SubjectAttendanceRecord("Software Eng.", "01:00 PM", "Theory", true),
          SubjectAttendanceRecord("ML Lab", "02:00 PM", "Lab", true),
          SubjectAttendanceRecord("BD Lab", "03:00 PM", "Lab", true),
        ],
      ),
      DayAttendance(
        "Wed",
        4,
        6,
        [
          SubjectAttendanceRecord("P&S", "09:00 AM", "Theory", true),
          SubjectAttendanceRecord("Machine Learning", "10:00 AM", "Theory", false),
          SubjectAttendanceRecord("Software Eng.", "11:00 AM", "Theory", true),
          SubjectAttendanceRecord("Big Data", "12:00 PM", "Theory", false),
          SubjectAttendanceRecord("ML Lab", "02:00 PM", "Lab", true),
          SubjectAttendanceRecord("Free Period", "03:00 PM", "Free", true),
        ],
      ),
      DayAttendance(
        "Thu",
        2,
        5,
        [
          SubjectAttendanceRecord("Machine Learning", "09:00 AM", "Theory", false),
          SubjectAttendanceRecord("Big Data", "10:00 AM", "Theory", true),
          SubjectAttendanceRecord("P&S", "11:00 AM", "Theory", false),
          SubjectAttendanceRecord("Software Eng.", "01:00 PM", "Theory", false),
          SubjectAttendanceRecord("BD Lab", "02:00 PM", "Lab", true),
        ],
      ),
      DayAttendance(
        "Fri",
        3,
        5,
        [
          SubjectAttendanceRecord("Software Eng.", "09:00 AM", "Theory", true),
          SubjectAttendanceRecord("Machine Learning", "10:00 AM", "Theory", false),
          SubjectAttendanceRecord("Big Data", "11:00 AM", "Theory", true),
          SubjectAttendanceRecord("P&S", "12:00 PM", "Theory", false),
          SubjectAttendanceRecord("ML Lab", "02:00 PM", "Lab", true),
        ],
      ),
      DayAttendance(
        "Sat",
        2,
        5,
        [
          SubjectAttendanceRecord("Machine Learning", "09:00 AM", "Theory", false),
          SubjectAttendanceRecord("P&S", "10:00 AM", "Theory", true),
          SubjectAttendanceRecord("Software Eng.", "11:00 AM", "Theory", false),
          SubjectAttendanceRecord("Big Data", "12:00 PM", "Theory", false),
          SubjectAttendanceRecord("SE Lab", "02:00 PM", "Lab", true),
        ],
      ),
    ];

    attendedClasses = days.fold(0, (s, d) => s + d.attended);
    totalClasses = days.fold(0, (s, d) => s + d.total);
    weeklyPercentage = attendedClasses / totalClasses;

    isLoading = false;
    notifyListeners();
  }
}

class DayAttendance {
  final String day;
  final int attended;
  final int total;
  final List<SubjectAttendanceRecord> subjects;

  DayAttendance(this.day, this.attended, this.total, this.subjects);

  double get percentage => attended / total;

  Color get color {
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class SubjectAttendanceRecord {
  final String subjectName;
  final String time;
  final String type; // Theory, Lab, Tutorial
  final bool isPresent;

  SubjectAttendanceRecord(
    this.subjectName,
    this.time,
    this.type,
    this.isPresent,
  );
}