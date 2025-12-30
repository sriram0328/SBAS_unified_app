import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';

class FacultyDashboardController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? errorMessage;

  String facultyName = "";
  String dateLabel = "";
  int classesToday = 0;
  String facultyId = "";
  String department = "";

  // Allow injecting facultyId (document id) from login flow
  FacultyDashboardController({this.facultyId = ""});

  List<TodayClass> todayClasses = [];

  Future<void> loadDashboard() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      facultyId = user.uid;

      // Get faculty data
      final userData = await _firestoreService.getUserData(facultyId, 'faculty');
      
      if (userData == null) {
        throw Exception("Faculty data not found");
      }

      facultyName = userData['name'] ?? '';
      department = userData['department'] ?? '';

      // Format date
      final now = DateTime.now();
      dateLabel = DateFormat('EEEE, d MMM').format(now);

      // Get today's timetable
      await _loadTodayClasses();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _loadTodayClasses() async {
    try {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);

      // Get faculty timetable
      final timetableDoc = await _firestoreService
          .getDocument('faculty_timetables', facultyId);

      if (!timetableDoc.exists) {
        classesToday = 0;
        todayClasses = [];
        return;
      }

      final data = timetableDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        classesToday = 0;
        todayClasses = [];
        return;
      }

      final timetable = data['timetable'] as Map<String, dynamic>?;
      if (timetable == null) {
        classesToday = 0;
        todayClasses = [];
        return;
      }

      final todaySchedule = timetable[dayName] as List<dynamic>?;
      if (todaySchedule == null) {
        classesToday = 0;
        todayClasses = [];
        return;
      }

      todayClasses = todaySchedule.map((item) {
        final classData = item as Map<String, dynamic>;
        return TodayClass(
          subjectName: classData['subjectName'] ?? '',
          subjectCode: classData['subjectCode'] ?? '',
          periodNumber: classData['periodNumber'] ?? 0,
          startTime: classData['startTime'] ?? '',
          endTime: classData['endTime'] ?? '',
          branch: classData['branch'] ?? '',
          year: classData['year'] ?? '',
          section: classData['section'] ?? '',
        );
      }).toList();

      classesToday = todayClasses.length;
    } catch (e) {
      print("Error loading today's classes: $e");
      classesToday = 0;
      todayClasses = [];
    }
  }

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