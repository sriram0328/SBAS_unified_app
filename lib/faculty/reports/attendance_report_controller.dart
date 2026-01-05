import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceReportController extends ChangeNotifier {
  // ---------------- FILTERS ----------------
  String year = "4";
  String branch = "AIML";
  String section = "A";
  String semester = "1";

  String? selectedDate;
  String? subject;
  int? periodNumber;

  final String? facultyId;

  // ---------------- OPTIONS ----------------
  List<String> availableDates = [];
  List<String> availableSubjects = [];
  List<int> availablePeriods = [];

  final List<String> availableYears = ["1", "2", "3", "4"];
  final List<String> availableBranches = ["AIML", "CSE", "ECE", "AIDS"];
  final List<String> availableSections = ["A", "B", "C"];
  final List<String> availableSemesters = ["1", "2"];

  // ---------------- DATA ----------------
  List<AttendanceStudent> students = [];

  int totalStudents = 0;
  int presentCount = 0;
  int absentCount = 0;

  bool isInitializing = true;
  bool isLoading = false;
  String? errorMessage;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AttendanceReportController({this.facultyId}) {
    initialize();
  }

  // ---------------- INIT ----------------
  Future<void> initialize() async {
    isInitializing = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint("🚀 Initializing AttendanceReportController");
      debugPrint("👤 facultyId: $facultyId");

      await _loadFilterOptions();
      await loadAttendance();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Initialization error: $e");
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  // ---------------- LOAD FILTER OPTIONS ----------------
  Future<void> _loadFilterOptions() async {
    debugPrint(
        "📋 Loading filters: year=$year sem=$semester branch=$branch section=$section");

    Query query = _db.collection('attendance');

    if (facultyId != null && facultyId!.isNotEmpty) {
      query = query.where('facultyId', isEqualTo: facultyId);
    }

    query = query
        .where('year', isEqualTo: year)
        .where('semester', isEqualTo: semester)
        .where('branch', isEqualTo: branch)
        .where('section', isEqualTo: section);

    final snap = await query.get();

    final dates = <String>{};
    final subjects = <String>{};
    final periods = <int>{};

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['date'] != null) dates.add(d['date']);
      if (d['subjectCode'] != null) subjects.add(d['subjectCode']);
      if (d['periodNumber'] != null) periods.add(d['periodNumber']);
    }

    availableDates = dates.toList()..sort((a, b) => b.compareTo(a));
    availableSubjects = subjects.toList()..sort();
    availablePeriods = periods.toList()..sort();

    selectedDate ??= availableDates.isNotEmpty ? availableDates.first : null;
    subject ??= availableSubjects.isNotEmpty ? availableSubjects.first : null;
    periodNumber ??= availablePeriods.isNotEmpty ? availablePeriods.first : null;

    notifyListeners();
  }

  // ---------------- UPDATE FILTERS ----------------
  Future<void> updateFilters({
    String? date,
    String? subjectValue,
    int? periodValue,
    String? yearValue,
    String? branchValue,
    String? sectionValue,
    String? semesterValue,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (yearValue != null ||
          branchValue != null ||
          sectionValue != null ||
          semesterValue != null) {
        selectedDate = null;
        subject = null;
        periodNumber = null;
      }

      year = yearValue ?? year;
      branch = branchValue ?? branch;
      section = sectionValue ?? section;
      semester = semesterValue ?? semester;

      selectedDate = date ?? selectedDate;
      subject = subjectValue ?? subject;
      periodNumber = periodValue ?? periodNumber;

      await _loadFilterOptions();
      await loadAttendance();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ updateFilters error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- LOAD ATTENDANCE ----------------
  Future<void> loadAttendance() async {
    students.clear();
    _resetCounts();

    if (selectedDate == null || subject == null || periodNumber == null) {
      debugPrint("⚠️ Missing filters, skipping attendance load");
      notifyListeners();
      return;
    }

    try {
      final docId =
          '${selectedDate}_${facultyId}_${year}_${semester}_${branch}_${section}_$periodNumber';

      final docSnap =
          await _db.collection('attendance').doc(docId).get();

      if (!docSnap.exists) {
        debugPrint("⚠️ Attendance document not found");
        notifyListeners();
        return;
      }

      await _processAttendanceDocument(docSnap);
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ loadAttendance error: $e");
    }

    notifyListeners(); // 🔥 THIS WAS MISSING
  }

  // ---------------- PROCESS DOC ----------------
  Future<void> _processAttendanceDocument(
      DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final present =
        List<String>.from(data['presentStudentRollNos'] ?? []);
    final absent =
        List<String>.from(data['absentStudentRollNos'] ?? []);
    final allRolls = [...present, ...absent];

    if (allRolls.isEmpty) return;

    final studentMap = <String, String>{};

    for (int i = 0; i < allRolls.length; i += 30) {
      final batch = allRolls.skip(i).take(30).toList();
      if (batch.isEmpty) continue;

      final snap = await _db
          .collection('students')
          .where('rollno', whereIn: batch)
          .get();

      for (final d in snap.docs) {
        studentMap[d['rollno']] = d['name'] ?? d['rollno'];
      }
    }

    for (final roll in allRolls) {
      students.add(
        AttendanceStudent(
          rollNo: roll,
          name: studentMap[roll] ?? roll,
          isPresent: present.contains(roll),
        ),
      );
    }

    students.sort((a, b) => a.rollNo.compareTo(b.rollNo));

    totalStudents = students.length;
    presentCount = present.length;
    absentCount = absent.length;
  }

  void _resetCounts() {
    totalStudents = 0;
    presentCount = 0;
    absentCount = 0;
  }

  // ---------------- EXPORT ----------------
  String generateCSV() {
    final b = StringBuffer("Roll No,Name,Status\n");
    for (final s in students) {
      b.writeln(
          "${s.rollNo},${s.name},${s.isPresent ? "Present" : "Absent"}");
    }
    return b.toString();
  }

  String generateTextReport() {
    return '''
ATTENDANCE REPORT

Date     : ${selectedDate ?? "N/A"}
Subject  : ${subject ?? "N/A"}
Period   : ${periodNumber ?? "N/A"}
Year     : $year
Semester : $semester
Class    : $branch-$section

Total    : $totalStudents
Present  : $presentCount
Absent   : $absentCount
''';
  }
}

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
