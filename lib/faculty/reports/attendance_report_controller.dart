import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportController {
  // ---------------------------
  // Filters (ALL REQUIRED)
  // ---------------------------
  String selectedDate = "";
  String subject = "";
  String section = "A";
  String year = "4";
  String branch = "AIML";
  int? periodNumber;

  // ---------------------------
  // Dropdown data (DEPENDENT)
  // ---------------------------
  List<String> availableDates = [];
  List<String> availableSubjects = [];
  List<int> availablePeriods = [];

  final List<String> availableSections = ["A", "B", "C"];
  final List<String> availableYears = ["1", "2", "3", "4"];
  final List<String> availableBranches = ["AIML", "CSE", "ECE"];

  // ---------------------------
  // Stats
  // ---------------------------
  int totalStudents = 0;
  int presentCount = 0;
  int absentCount = 0;

  // ---------------------------
  // Students
  // ---------------------------
  List<AttendanceStudent> students = [];

  // ---------------------------
// Computed lists (REQUIRED BY UI)
// ---------------------------
List<AttendanceStudent> get presentStudents =>
    students.where((s) => s.isPresent).toList();

List<AttendanceStudent> get absentStudents =>
    students.where((s) => !s.isPresent).toList();

  // ---------------------------
  // UI state
  // ---------------------------
  bool isInitializing = true;
  bool isLoading = false;
  String? errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 prevents race-condition overwrites
  int _requestToken = 0;

  AttendanceReportController() {
    refreshAllData();
  }

  // ---------------------------
  Future<void> refreshAllData() async {
    try {
      isInitializing = true;
      errorMessage = null;

      await _loadDates();
    } catch (_) {
      errorMessage = "Failed to load attendance data";
    } finally {
      isInitializing = false;
    }
  }

  // ---------------------------
  // Load available dates
  // ---------------------------
  Future<void> _loadDates() async {
    final snap = await _firestore.collection('attendance').get();

    availableDates = snap.docs
        .map((d) => d['date'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    if (availableDates.isNotEmpty) {
      selectedDate = availableDates.first;
      await _loadSubjects();
    }
  }

  // ---------------------------
  // Load subjects for selected date
  // ---------------------------
  Future<void> _loadSubjects() async {
    final snap = await _firestore
        .collection('attendance')
        .where('date', isEqualTo: selectedDate)
        .get();

    availableSubjects = snap.docs
        .map((d) => d['subjectCode'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    if (availableSubjects.isNotEmpty) {
      subject = availableSubjects.first;
      await _loadPeriods();
    }
  }

  // ---------------------------
  // Load periods (CRITICAL FIX)
  // ---------------------------
  Future<void> _loadPeriods() async {
    final snap = await _firestore
        .collection('attendance')
        .where('date', isEqualTo: selectedDate)
        .where('subjectCode', isEqualTo: subject)
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    availablePeriods = snap.docs
        .map((d) => d['periodNumber'] as int?)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();

    periodNumber =
        availablePeriods.isNotEmpty ? availablePeriods.first : null;

    await _reloadAttendanceData();
  }

  // ---------------------------
  // Update filters safely
  // ---------------------------
  Future<void> updateFilters({
    String? date,
    String? subjectValue,
    String? sectionValue,
    String? yearValue,
    String? branchValue,
    int? periodValue,
  }) async {
    if (date != null && date != selectedDate) {
      selectedDate = date;
      await _loadSubjects();
      return;
    }

    if (subjectValue != null && subjectValue != subject) {
      subject = subjectValue;
      await _loadPeriods();
      return;
    }

    if (sectionValue != null) section = sectionValue;
    if (yearValue != null) year = yearValue;
    if (branchValue != null) branch = branchValue;
    if (periodValue != null) periodNumber = periodValue;

    await _reloadAttendanceData();
  }

  // ---------------------------
  // FINAL SAFE QUERY
  // ---------------------------
  Future<void> _reloadAttendanceData() async {
    if (periodNumber == null) return;

    final token = ++_requestToken;

    try {
      isLoading = true;
      errorMessage = null;
      students.clear();

      final query = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: selectedDate)
          .where('subjectCode', isEqualTo: subject)
          .where('branch', isEqualTo: branch)
          .where('year', isEqualTo: year)
          .where('section', isEqualTo: section)
          .where('periodNumber', isEqualTo: periodNumber)
          .limit(1)
          .get();

      if (token != _requestToken) return;

      if (query.docs.isEmpty) {
        totalStudents = presentCount = absentCount = 0;
        return;
      }

      final data = query.docs.first.data();

      final present =
          List<String>.from(data['presentStudentRollNos'] ?? []);
      final absent =
          List<String>.from(data['absentStudentRollNos'] ?? []);

      final allRolls = {...present, ...absent};

      for (final roll in allRolls) {
        students.add(
          AttendanceStudent(
            rollNo: roll,
            name: roll,
            isPresent: present.contains(roll),
          ),
        );
      }

      totalStudents = students.length;
      presentCount = present.length;
      absentCount = absent.length;
    } catch (_) {
      errorMessage = "Unable to fetch attendance";
    } finally {
      isLoading = false;
    }
  }

  // ---------------------------
  String generateCSV() {
    final b = StringBuffer();
    b.writeln("Roll No,Status");
    for (final s in students) {
      b.writeln("${s.rollNo},${s.isPresent ? "Present" : "Absent"}");
    }
    return b.toString();
  }

  String generateTextReport() {
    return '''
ATTENDANCE REPORT
Date: $selectedDate
Subject: $subject
Period: $periodNumber
Class: $branch $year-$section
Total: $totalStudents
Present: $presentCount
Absent: $absentCount
''';
  }
}

// ---------------------------
class AttendanceStudent {
  final String rollNo;
  final String name;
  final bool isPresent;

  AttendanceStudent({
    required this.rollNo,
    required this.name,
    required this.isPresent,
  });
}
