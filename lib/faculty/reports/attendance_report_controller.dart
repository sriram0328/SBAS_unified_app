import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportController {
  // ---------------------------
  // Filters
  // ---------------------------
  String selectedDate = "";
  String subject = "";
  String section = "A";
  String year = "4";
  String branch = "AIML";
  int periodNumber = 1;

  // ---------------------------
  // Dropdown data
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
  // UI state
  // ---------------------------
  bool isInitializing = true;
  bool isLoading = false;
  String? errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AttendanceReportController() {
    refreshAllData();
  }

  // ---------------------------
  Future<void> refreshAllData() async {
    try {
      errorMessage = null;
      isInitializing = true;

      await _loadFilters();
      await _reloadAttendanceData();
    } catch (_) {
      errorMessage = "Failed to load attendance data";
    } finally {
      isInitializing = false;
    }
  }

  // ---------------------------
  Future<void> _loadFilters() async {
    final snapshot = await _firestore.collection('attendance').get();

    final dateSet = <String>{};
    final subjectSet = <String>{};
    final periodSet = <int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['date'] != null) dateSet.add(data['date']);
      if (data['subjectCode'] != null) subjectSet.add(data['subjectCode']);
      if (data['periodNumber'] != null) {
        periodSet.add(data['periodNumber']);
      }
    }

    availableDates = dateSet.toList()..sort();
    availableSubjects = subjectSet.toList()..sort();
    availablePeriods = periodSet.toList()..sort();

    if (availableDates.isNotEmpty) selectedDate = availableDates.first;
    if (availableSubjects.isNotEmpty) subject = availableSubjects.first;
    if (availablePeriods.isNotEmpty) periodNumber = availablePeriods.first;
  }

  // ---------------------------
  List<AttendanceStudent> get presentStudents =>
      students.where((s) => s.isPresent).toList();

  List<AttendanceStudent> get absentStudents =>
      students.where((s) => !s.isPresent).toList();

  // ---------------------------
  Future<void> updateFilters({
    String? date,
    String? subjectValue,
    String? sectionValue,
    String? yearValue,
    String? branchValue,
    int? periodValue,
  }) async {
    if (date != null) selectedDate = date;
    if (subjectValue != null) subject = subjectValue;
    if (sectionValue != null) section = sectionValue;
    if (yearValue != null) year = yearValue;
    if (branchValue != null) branch = branchValue;
    if (periodValue != null) periodNumber = periodValue;

    await _reloadAttendanceData();
  }

  // ---------------------------
  // 🔴 FIXED HERE (NO DUPLICATES)
  // ---------------------------
  Future<void> _reloadAttendanceData() async {
    try {
      isLoading = true;
      errorMessage = null;
      students = [];

      final query = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: selectedDate)
          .where('subjectCode', isEqualTo: subject)
          .where('section', isEqualTo: section)
          .where('year', isEqualTo: year)
          .where('branch', isEqualTo: branch)
          .where('periodNumber', isEqualTo: periodNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        totalStudents = 0;
        presentCount = 0;
        absentCount = 0;
        return;
      }

      final data = query.docs.first.data();

      final presentRolls =
          List<String>.from(data['presentStudentRollNos'] ?? []);
      final absentRolls =
          List<String>.from(data['absentStudentRollNos'] ?? []);

      // ✅ DEDUPLICATION (CRITICAL FIX)
      final uniqueRolls = <String>{
        ...presentRolls,
        ...absentRolls,
      };

      for (final roll in uniqueRolls) {
        final studentSnap =
            await _firestore.collection('students').doc(roll).get();

        final studentData = studentSnap.data();

        students.add(
          AttendanceStudent(
            rollNo: roll,
            name: studentData?['name'] ?? roll,
            isPresent: presentRolls.contains(roll),
          ),
        );
      }

      totalStudents = students.length;
      presentCount = presentStudents.length;
      absentCount = absentStudents.length;
    } catch (_) {
      errorMessage = "Unable to fetch attendance";
      students = [];
    } finally {
      isLoading = false;
    }
  }

  // ---------------------------
  String generateCSV() {
    final buffer = StringBuffer();
    buffer.writeln("Roll No,Name,Status");

    for (final s in students) {
      buffer.writeln(
          "${s.rollNo},${s.name},${s.isPresent ? "Present" : "Absent"}");
    }

    return buffer.toString();
  }

  String generateTextReport() {
    return '''
ATTENDANCE REPORT
Date: $selectedDate
Subject: $subject
Period: $periodNumber
Class: $branch $year Section $section
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
