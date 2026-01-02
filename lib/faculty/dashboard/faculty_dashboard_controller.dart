import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';

class FacultyDashboardController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  /// 🔑 REAL faculty document ID (e.g. FAC123)
  final String facultyId;

  FacultyDashboardController({required this.facultyId});

  bool isLoading = true;
  String? errorMessage;

  String facultyName = "";
  String department = "";
  String dateLabel = "";
  int classesToday = 0;

  List<TodayClass> todayClasses = [];

  /// ----------------------------
  /// LOAD DASHBOARD
  /// ----------------------------
  Future<void> loadDashboard() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (facultyId.isEmpty) {
        throw Exception("Faculty ID missing");
      }

      /// 🔹 Faculty profile
      final userData =
          await _firestoreService.getUserData(facultyId, 'faculty');

      if (userData == null) {
        throw Exception("Faculty data not found for ID: $facultyId");
      }

      facultyName = userData['name'] ?? '';
      department = userData['department'] ?? '';

      /// 🔹 Date label
      dateLabel = DateFormat('EEEE, d MMM').format(DateTime.now());

      /// 🔹 Timetable
      await _loadTodayClasses();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// ----------------------------
  /// LOAD TODAY CLASSES
  /// ----------------------------
  Future<void> _loadTodayClasses() async {
    try {
      final today = DateFormat('EEEE').format(DateTime.now());

      final doc = await _firestoreService
          .getDocument('faculty_timetables', facultyId);

      if (!doc.exists) {
        todayClasses = [];
        classesToday = 0;
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final timetable = data?['timetable'] as Map<String, dynamic>?;

      final schedule = timetable?[today] as List<dynamic>?;

      if (schedule == null || schedule.isEmpty) {
        todayClasses = [];
        classesToday = 0;
        return;
      }

      todayClasses = schedule.map((item) {
        final m = item as Map<String, dynamic>;
        return TodayClass(
          subjectName: m['subjectName'] ?? '',
          subjectCode: m['subjectCode'] ?? '',
          periodNumber: m['periodNumber'] ?? 0,
          startTime: m['startTime'] ?? '',
          endTime: m['endTime'] ?? '',
          branch: m['branch'] ?? '',
          year: m['year'] ?? '',
          section: m['section'] ?? '',
        );
      }).toList();

      classesToday = todayClasses.length;
    } catch (e) {
      todayClasses = [];
      classesToday = 0;
    }
  }

  /// ----------------------------
  /// NAVIGATION
  /// ----------------------------
  void startAttendance(BuildContext context) {
    Navigator.pushNamed(context, '/faculty/setup');
  }

  void openTimetable(BuildContext context) {
    Navigator.pushNamed(context, '/faculty/timetable');
  }

  void openAttendanceRecords(BuildContext context) {
    Navigator.pushNamed(context, '/faculty/reports');
  }
}

/// ----------------------------
/// MODEL
/// ----------------------------
class TodayClass {
  final String subjectName;
  final String subjectCode;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String branch;
  final String year;
  final String section;

  TodayClass({
    required this.subjectName,
    required this.subjectCode,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    required this.branch,
    required this.year,
    required this.section,
  });
}
