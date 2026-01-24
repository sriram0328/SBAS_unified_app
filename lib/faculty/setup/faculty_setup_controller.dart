import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/session.dart';

class FacultySetupController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FacultySetupController() {
    _loadFacultySubjects();
  }

  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> facultySubjects = [];

  Set<String> availableSubjects = {};
  Set<String> availableYears = {};
  Set<String> availableBranches = {};
  Set<String> availableSections = {};

  String? selectedSubjectName;
  String? selectedYear;
  String? selectedBranch;
  String? selectedSection;
  int selectedPeriodNumber = 1;

  String subjectCode = '';
  String subjectName = '';

  final List<int> periods = [1,2,3,4,5,6,7];

  /// ✅ Roll numbers only
  List<String> enrolledStudentRollNos = [];

  // ---------------- LOAD TIMETABLE ----------------
  Future<void> _loadFacultySubjects() async {
    isLoading = true;
    notifyListeners();

    try {
      final doc = await _db
          .collection('faculty_timetables')
          .doc(Session.facultyId)
          .get();

      if (!doc.exists || doc.data() == null) {
        errorMessage = "No timetable found";
        return;
      }

      final data = doc.data()!;
      final days = [
        'monday','tuesday','wednesday',
        'thursday','friday','saturday'
      ];

      facultySubjects.clear();
      availableSubjects.clear();
      availableYears.clear();
      availableBranches.clear();
      availableSections.clear();

      for (final day in days) {
        final List<dynamic>? schedule = data[day];
        if (schedule == null) continue;

        for (final raw in schedule) {
          final c = Map<String, dynamic>.from(raw);
          facultySubjects.add(c);

          if (c['subjectName'] != null) {
            availableSubjects.add(c['subjectName']);
          }
          if (c['year'] != null) {
            availableYears.add(c['year'].toString());
          }
          if (c['branch'] != null) {
            availableBranches.add(c['branch']);
          }
          if (c['section'] != null) {
            availableSections.add(c['section']);
          }
        }
      }
    } catch (e) {
      errorMessage = "Failed to load timetable: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- FILTERS ----------------
  Set<String> getAvailableYears() =>
      facultySubjects
          .where((c) => c['subjectName'] == selectedSubjectName)
          .map((c) => c['year']?.toString())
          .whereType<String>()
          .toSet();

  Set<String> getAvailableBranches() =>
      facultySubjects
          .where((c) =>
              c['subjectName'] == selectedSubjectName &&
              c['year']?.toString() == selectedYear)
          .map((c) => c['branch'] as String?)
          .whereType<String>()
          .toSet();

  Set<String> getAvailableSections() =>
      facultySubjects
          .where((c) =>
              c['subjectName'] == selectedSubjectName &&
              c['year']?.toString() == selectedYear &&
              c['branch'] == selectedBranch)
          .map((c) => c['section'] as String?)
          .whereType<String>()
          .toSet();

  // ---------------- SELECTIONS ----------------
  void selectSubject(String v) {
    selectedSubjectName = v;
    selectedYear = selectedBranch = selectedSection = null;
    notifyListeners();
  }

  void selectYear(String v) {
    selectedYear = v;
    selectedBranch = selectedSection = null;
    notifyListeners();
  }

  void selectBranch(String v) {
    selectedBranch = v;
    selectedSection = null;
    notifyListeners();
  }

  void selectSection(String v) {
    selectedSection = v;

    final match = facultySubjects.firstWhere(
      (c) =>
          c['subjectName'] == selectedSubjectName &&
          c['year']?.toString() == selectedYear &&
          c['branch'] == selectedBranch &&
          c['section'] == selectedSection,
      orElse: () => {},
    );

    subjectCode = match['subjectCode'] ?? '';
    subjectName = match['subjectName'] ?? '';

    notifyListeners();
  }

  void setPeriodNumber(int v) {
    selectedPeriodNumber = v;
    notifyListeners();
  }

  bool get canProceed =>
      selectedSubjectName != null &&
      selectedYear != null &&
      selectedBranch != null &&
      selectedSection != null;

  // ---------------- LOAD STUDENTS (FIXED) ----------------
  Future<void> loadEnrolledStudents() async {
  try {
    errorMessage = null;
    enrolledStudentRollNos.clear();
    notifyListeners();

    final int year = int.parse(selectedYear!);

    debugPrint('--- LOAD STUDENTS ---');
    debugPrint('Branch: $selectedBranch');
    debugPrint('Section: $selectedSection');
    debugPrint('YearOfStudy: $year');

    // 1️⃣ Academic records
    final academicSnap = await _db
        .collection('academic_records')
        .where('yearOfStudy', isEqualTo: year)
        .where('status', isEqualTo: 'active')
        .get();

    if (academicSnap.docs.isEmpty) {
      errorMessage = 'No academic records found';
      notifyListeners();
      return;
    }

    final studentIds =
        academicSnap.docs.map((d) => d['studentId'] as String).toList();

    debugPrint('Academic students count: ${studentIds.length}');

    // 2️⃣ Chunk studentIds (Firestore limit = 30)
    const int chunkSize = 30;
    final List<List<String>> chunks = [];

    for (int i = 0; i < studentIds.length; i += chunkSize) {
      chunks.add(
        studentIds.sublist(
          i,
          i + chunkSize > studentIds.length
              ? studentIds.length
              : i + chunkSize,
        ),
      );
    }

    // 3️⃣ Query each chunk
    for (final chunk in chunks) {
      final snap = await _db
          .collection('students')
          .where(FieldPath.documentId, whereIn: chunk)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .get();

      for (final doc in snap.docs) {
        final roll = doc['rollno']?.toString();
        if (roll != null && roll.isNotEmpty) {
          enrolledStudentRollNos.add(roll);
        }
      }
    }

    debugPrint('Final enrolled students: ${enrolledStudentRollNos.length}');
    notifyListeners();
  } catch (e, s) {
    debugPrint('LOAD STUDENTS ERROR: $e');
    debugPrint('$s');
    errorMessage = 'Failed to load students';
    notifyListeners();
  }
}
}