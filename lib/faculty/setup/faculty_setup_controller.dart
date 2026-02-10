// added academic year filter to remove detained 
// added theory period count dropdown for consecutive theory classes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FacultySetupController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId;

  FacultySetupController({required this.facultyId}) {
    loadInitialData();
  }

  bool isLoading = false;
  String? errorMessage;

  // Available options - loaded from lightweight metadata
  Set<String> availableYears = {};
  Set<String> availableBranches = {};
  Set<String> availableSections = {};
  
  // Subjects fetched from branch_subjects collection
  List<Map<String, dynamic>> branchSubjects = [];
  Set<String> availableSubjectDisplayNames = {};

  String? selectedYear;
  String? selectedBranch;
  String? selectedSection;
  String? selectedSubjectDisplay;
  int selectedPeriodNumber = 1;
  int selectedTheoryPeriodCount = 1; // For theory classes: 1 or 2 hours

  String subjectCode = '';
  String subjectName = '';
  int periodCount = 1;
  bool isLab = false;
  
  final List<int> periods = [1,2,3,4,5,6,7];
  final List<int> theoryPeriodOptions = [1, 2]; // Theory can be 1 or 2 hours
  List<String> enrolledStudentRollNos = [];
  
  // Track locked periods
  Set<int> lockedPeriods = {};

  // Helper function to get current academic year
  String _getAcademicYearFromDate(DateTime date) {
    final year = date.year;
    final month = date.month;
    // Assumes academic year starts in June
    if (month < 6) {
      return '${year - 1}-$year';
    } else {
      return '$year-${year + 1}';
    }
  }

  Future<void> loadInitialData() async {
    if (facultyId.isEmpty) {
      errorMessage = "Invalid Faculty ID";
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final metadataDoc = await _db
          .collection('system_metadata')
          .doc('class_structure')
          .get();

      if (!metadataDoc.exists || metadataDoc.data() == null) {
        errorMessage = "System metadata not found. Please contact admin.";
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = metadataDoc.data()!;
      
      availableYears.clear();
      availableBranches.clear();
      availableSections.clear();

      // Load from metadata arrays
      final years = data['years'] as List<dynamic>?;
      final branches = data['branches'] as List<dynamic>?;
      final sections = data['sections'] as List<dynamic>?;

      if (years != null) {
        availableYears = years.map((e) => e.toString()).toSet();
      }
      if (branches != null) {
        availableBranches = branches.map((e) => e.toString()).toSet();
      }
      if (sections != null) {
        availableSections = sections.map((e) => e.toString()).toSet();
      }

      if (availableYears.isEmpty) {
        errorMessage = "No class data available";
      }
    } catch (e) {
      errorMessage = "Failed to load initial data: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Set<String> getAvailableBranches() {
    return availableBranches;
  }

  Set<String> getAvailableSections() {
    return availableSections;
  }

  void selectYear(String v) {
    selectedYear = v;
    selectedBranch = null;
    selectedSection = null;
    selectedSubjectDisplay = null;
    availableSubjectDisplayNames.clear();
    branchSubjects.clear();
    notifyListeners();
  }

  void selectBranch(String v) {
    selectedBranch = v;
    selectedSection = null;
    selectedSubjectDisplay = null;
    availableSubjectDisplayNames.clear();
    branchSubjects.clear();
    notifyListeners();
  }

  void selectSection(String v) {
    selectedSection = v;
    selectedSubjectDisplay = null;
    loadBranchSubjects();
    notifyListeners();
  }

  void selectClass(String year, String branch, String section) {
    selectedYear = year;
    selectedBranch = branch;
    selectedSection = section;
    selectedSubjectDisplay = null;
    loadBranchSubjects();
    notifyListeners();
  }

  String _createSubjectDisplayName(Map<String, dynamic> subject) {
    final name = subject['subjectName'] ?? '';
    final isLab = subject['isLab'] ?? false;
    final periodCount = subject['periodCount'] ?? 1;
    
    if (isLab) {
      return '$name (Lab - $periodCount ${periodCount == 1 ? "hr" : "hrs"})';
    } else {
      return '$name (Theory)';
    }
  }

  Future<void> loadBranchSubjects() async {
    if (selectedYear == null || selectedBranch == null || selectedSection == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      branchSubjects.clear();
      availableSubjectDisplayNames.clear();

      final docId = '${selectedBranch}_$selectedYear';
      
      final doc = await _db
          .collection('branch_subjects')
          .doc(docId)
          .get();

      if (!doc.exists || doc.data() == null) {
        errorMessage = "No subjects found for $selectedYear-$selectedBranch";
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = doc.data()!;
      final List<dynamic>? subjects = data['subjects'];

      if (subjects == null || subjects.isEmpty) {
        errorMessage = "No subjects configured for this class";
        isLoading = false;
        notifyListeners();
        return;
      }

      for (final subjectData in subjects) {
        final subject = Map<String, dynamic>.from(subjectData);
        branchSubjects.add(subject);
        
        final displayName = _createSubjectDisplayName(subject);
        availableSubjectDisplayNames.add(displayName);
      }
    } catch (e) {
      errorMessage = "Failed to load subjects: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectSubject(String displayName) {
    selectedSubjectDisplay = displayName;
    
    final match = branchSubjects.firstWhere(
      (s) => _createSubjectDisplayName(s) == displayName,
      orElse: () => {},
    );
    
    if (match.isEmpty) {
      errorMessage = "Subject not found";
      notifyListeners();
      return;
    }
    
    subjectCode = match['subjectCode'] ?? '';
    subjectName = match['subjectName'] ?? '';
    periodCount = match['periodCount'] ?? 1;
    isLab = match['isLab'] ?? false;
    
    // Reset theory period count when subject changes
    selectedTheoryPeriodCount = 1;
    
    _checkLockedPeriods();
    
    notifyListeners();
  }

  void selectTheoryPeriodCount(int count) {
    selectedTheoryPeriodCount = count;
    _checkLockedPeriods();
    notifyListeners();
  }

  Future<void> _checkLockedPeriods() async {
    lockedPeriods.clear();
    
    if (selectedYear == null || selectedBranch == null || selectedSection == null) {
      return;
    }

    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      
      final existingAttendance = await _db
          .collection('attendance')
          .where('date', isEqualTo: today)
          .where('year', isEqualTo: selectedYear)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .get();

      for (final doc in existingAttendance.docs) {
        final data = doc.data();
        final startPeriod = data['periodNumber'] as int? ?? 0;
        final count = (data['periodCount'] as num?)?.toInt() ?? 1;
        
        for (int i = 0; i < count; i++) {
          lockedPeriods.add(startPeriod + i);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  void setPeriodNumber(int v) {
    selectedPeriodNumber = v;
    notifyListeners();
  }

  bool get canProceed =>
      selectedYear != null &&
      selectedBranch != null &&
      selectedSection != null &&
      selectedSubjectDisplay != null;

  // Get the actual period count to use (for labs: from subject config, for theory: from dropdown)
  int get effectivePeriodCount => isLab ? periodCount : selectedTheoryPeriodCount;

  // Check if selecting this period would cause overflow
  bool isPeriodOverflow(int startPeriod) {
    final maxPeriod = periods.isNotEmpty ? periods.last : 7;
    return startPeriod + effectivePeriodCount - 1 > maxPeriod;
  }

  Future<void> loadEnrolledStudents() async {
    try {
      errorMessage = null;
      enrolledStudentRollNos.clear();
      notifyListeners();

      final today = DateTime.now().toIso8601String().split('T').first;
      
      final existingAttendance = await _db
          .collection('attendance')
          .where('date', isEqualTo: today)
          .where('year', isEqualTo: selectedYear)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .get();

      // Check for conflicts using the effective period count
      final effectiveCount = effectivePeriodCount;
      
      for (final doc in existingAttendance.docs) {
        final data = doc.data();
        final startPeriod = data['periodNumber'] as int? ?? 0;
        final periodCount = (data['periodCount'] as num?)?.toInt() ?? 1;
        final endPeriod = startPeriod + periodCount;
        final existingSubject = data['subjectCode'] as String? ?? '';
        final existingFacultyId = data['facultyId'] as String? ?? '';
        
        // Check if any of our periods overlap with existing attendance
        for (int i = 0; i < effectiveCount; i++) {
          final ourPeriod = selectedPeriodNumber + i;
          if (ourPeriod >= startPeriod && ourPeriod < endPeriod) {
            if (existingFacultyId == facultyId) {
              errorMessage = 'You have already taken attendance for Period $ourPeriod (Subject: $existingSubject)';
            } else {
              errorMessage = 'Period $ourPeriod already occupied by another faculty for $existingSubject';
            }
            notifyListeners();
            return;
          }
        }
      }

      final int year = int.parse(selectedYear!);
      
      // Get current academic year
      final currentAcademicYear = _getAcademicYearFromDate(DateTime.now());
      
      final academicSnap = await _db
          .collection('academic_records')
          .where('yearOfStudy', isEqualTo: year)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .where('status', isEqualTo: 'active')
          .where('academicYear', isEqualTo: currentAcademicYear)
          .get();

      if (academicSnap.docs.isEmpty) {
        errorMessage = 'No active students found for $selectedYear-$selectedBranch-$selectedSection';
        notifyListeners();
        return;
      }

      final studentIds = academicSnap.docs
          .map((d) => d['studentId'] as String)
          .toList();

      const int chunkSize = 30;
      
      for (int i = 0; i < studentIds.length; i += chunkSize) {
        final chunk = studentIds.sublist(
          i,
          i + chunkSize > studentIds.length ? studentIds.length : i + chunkSize,
        );

        final snap = await _db
            .collection('students')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final roll = doc['rollno']?.toString();
          if (roll != null && roll.isNotEmpty) {
            enrolledStudentRollNos.add(roll);
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load students: $e';
      notifyListeners();
    }
  }
}