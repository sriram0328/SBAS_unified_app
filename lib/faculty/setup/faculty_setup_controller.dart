import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// FacultySetupController - Manages the attendance setup flow
/// 
/// DEBUG LOGGING:
/// This controller includes comprehensive debug logging to track all Firestore operations.
/// Each Firestore read/query is logged with the following format:
/// 
/// 📖 [FIRESTORE READ] - Starting a Firestore operation
/// 📄 [FIRESTORE READ] - Reading a specific document
/// 📄 [FIRESTORE QUERY] - Executing a query
/// ✅ [FIRESTORE READ/QUERY] - Operation completed successfully
/// ❌ [FIRESTORE ERROR] - Operation failed
/// 📊 [FIRESTORE DATA] - Data structure information
/// 📊 [DATA LOADED] - Summary of loaded data
/// 🔒 [LOCKED PERIODS] - Period lock information
/// ⚠️ [WARNING] - Warning messages
/// ⚠️ [SKIP] - Skipped operation (missing prerequisites)
/// ⚠️ [CONFLICT] - Attendance conflict detected
/// 🎯 [TARGET] - Target class/subject information
/// 👥 [STUDENTS] - Student data information
/// 📦 [BATCHING] - Batch operation information
/// 📋 [ROLL NUMBERS] - Roll number data
/// 📚 [SUBJECT] - Subject information
/// 
/// To view these logs in your IDE/console, search for "[FIRESTORE" to see all database operations.

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
  // ✅ FIX: Store complete subject display strings (e.g., "ML (Theory)", "ML (Lab - 3 hrs)")
  Set<String> availableSubjectDisplayNames = {};

  String? selectedYear;
  String? selectedBranch;
  String? selectedSection;
  String? selectedSubjectDisplay; // Display name like "ML (Lab - 3 hrs)"
  int selectedPeriodNumber = 1;

  String subjectCode = '';
  String subjectName = '';
  int periodCount = 1;
  bool isLab = false;
  
  final List<int> periods = [1,2,3,4,5,6,7];
  List<String> enrolledStudentRollNos = [];
  
  // Track locked periods
  Set<int> lockedPeriods = {};

  /// ✅ COST-EFFICIENT: Load from a single lightweight metadata document
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
      debugPrint('📖 [FIRESTORE READ] Starting loadInitialData()');
      debugPrint('📄 [FIRESTORE READ] Reading: system_metadata/class_structure');
      
      // ✅ SINGLE READ from metadata document (tiny ~1KB document)
      final metadataDoc = await _db
          .collection('system_metadata')
          .doc('class_structure')
          .get();

      debugPrint('✅ [FIRESTORE READ] Completed: system_metadata/class_structure (exists: ${metadataDoc.exists})');

      if (!metadataDoc.exists || metadataDoc.data() == null) {
        debugPrint('❌ [FIRESTORE ERROR] system_metadata/class_structure not found');
        errorMessage = "System metadata not found. Please contact admin.";
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = metadataDoc.data()!;
      debugPrint('📊 [FIRESTORE DATA] Metadata loaded: ${data.keys.join(", ")}');
      
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

      debugPrint('📊 [DATA LOADED] Years: ${availableYears.length} items - $availableYears');
      debugPrint('📊 [DATA LOADED] Branches: ${availableBranches.length} items - $availableBranches');
      debugPrint('📊 [DATA LOADED] Sections: ${availableSections.length} items - $availableSections');

      if (availableYears.isEmpty) {
        debugPrint('⚠️ [WARNING] No years loaded from metadata');
        errorMessage = "No class data available";
      }
    } catch (e) {
      debugPrint('❌ [FIRESTORE ERROR] loadInitialData failed: $e');
      errorMessage = "Failed to load initial data: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get available branches (from metadata - already loaded)
  Set<String> getAvailableBranches() {
    return availableBranches;
  }

  /// Get available sections (from metadata - already loaded)
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

  // ✅ NEW: Select class in one go (Year-Branch-Section)
  void selectClass(String year, String branch, String section) {
    selectedYear = year;
    selectedBranch = branch;
    selectedSection = section;
    selectedSubjectDisplay = null;
    loadBranchSubjects();
    notifyListeners();
  }

  /// ✅ IMPROVED: Create unique display names for subjects
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

  /// ✅ COST-EFFICIENT: Single read from branch_subjects
  Future<void> loadBranchSubjects() async {
    if (selectedYear == null || selectedBranch == null || selectedSection == null) {
      debugPrint('⚠️ [SKIP] loadBranchSubjects - missing selection (year: $selectedYear, branch: $selectedBranch, section: $selectedSection)');
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      branchSubjects.clear();
      availableSubjectDisplayNames.clear();

      // ✅ SINGLE READ: Document ID format: "branch_year" (e.g., "AIML_4")
      final docId = '${selectedBranch}_$selectedYear';
      debugPrint('📖 [FIRESTORE READ] Starting loadBranchSubjects()');
      debugPrint('📄 [FIRESTORE READ] Reading: branch_subjects/$docId');
      
      final doc = await _db
          .collection('branch_subjects')
          .doc(docId)
          .get();

      debugPrint('✅ [FIRESTORE READ] Completed: branch_subjects/$docId (exists: ${doc.exists})');

      if (!doc.exists || doc.data() == null) {
        debugPrint('❌ [FIRESTORE ERROR] branch_subjects/$docId not found');
        errorMessage = "No subjects found for $selectedYear-$selectedBranch";
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = doc.data()!;
      final List<dynamic>? subjects = data['subjects'];

      debugPrint('📊 [FIRESTORE DATA] Found ${subjects?.length ?? 0} subjects in document');

      if (subjects == null || subjects.isEmpty) {
        debugPrint('⚠️ [WARNING] No subjects array found in document');
        errorMessage = "No subjects configured for this class";
        isLoading = false;
        notifyListeners();
        return;
      }

      for (final subjectData in subjects) {
        final subject = Map<String, dynamic>.from(subjectData);
        branchSubjects.add(subject);
        
        // ✅ FIX: Create unique display name for each subject
        final displayName = _createSubjectDisplayName(subject);
        availableSubjectDisplayNames.add(displayName);
        debugPrint('📚 [SUBJECT] Added: $displayName (code: ${subject['subjectCode']}, isLab: ${subject['isLab']}, periods: ${subject['periodCount']})');
      }
      
      debugPrint('✅ [DATA LOADED] Total subjects loaded: ${branchSubjects.length}');
    } catch (e) {
      debugPrint('❌ [FIRESTORE ERROR] loadBranchSubjects failed: $e');
      errorMessage = "Failed to load subjects: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ FIX: Find subject by display name (not just subject name)
  void selectSubject(String displayName) {
    selectedSubjectDisplay = displayName;
    
    // Find the matching subject by comparing display names
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
    
    // Check for locked periods
    _checkLockedPeriods();
    
    notifyListeners();
  }

  /// ✅ COST-EFFICIENT: Single filtered query - GLOBAL CLASS LOCK
  /// Checks if any period is locked for the entire class, regardless of subject
  Future<void> _checkLockedPeriods() async {
    lockedPeriods.clear();
    
    if (selectedYear == null || selectedBranch == null || selectedSection == null) {
      debugPrint('⚠️ [SKIP] _checkLockedPeriods - missing selection');
      return;
    }

    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      
      debugPrint('📖 [FIRESTORE READ] Starting _checkLockedPeriods() - GLOBAL CLASS LOCK');
      debugPrint('📄 [FIRESTORE QUERY] attendance where date=$today, year=$selectedYear, branch=$selectedBranch, section=$selectedSection (ALL SUBJECTS)');
      
      // ✅ GLOBAL LOCK: Query ALL subjects for this class
      // Remove subjectCode filter to check entire class
      final existingAttendance = await _db
          .collection('attendance')
          .where('date', isEqualTo: today)
          .where('year', isEqualTo: selectedYear)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .get();

      debugPrint('✅ [FIRESTORE QUERY] Completed: Found ${existingAttendance.docs.length} existing attendance records for entire class');

      for (final doc in existingAttendance.docs) {
        final data = doc.data();
        final startPeriod = data['periodNumber'] as int? ?? 0;
        final count = (data['periodCount'] as num?)?.toInt() ?? 1;
        final subjectCode = data['subjectCode'] as String? ?? '';
        final facultyId = data['facultyId'] as String? ?? '';
        
        // Mark all covered periods as locked
        for (int i = 0; i < count; i++) {
          lockedPeriods.add(startPeriod + i);
        }
        debugPrint('🔒 [LOCKED PERIODS] Periods ${startPeriod} to ${startPeriod + count - 1} locked by $facultyId for subject $subjectCode');
      }
      
      debugPrint('📊 [LOCKED PERIODS] Total locked: ${lockedPeriods.length} periods - $lockedPeriods');
    } catch (e) {
      debugPrint('❌ [FIRESTORE ERROR] _checkLockedPeriods failed: $e');
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

  /// ✅ VALIDATED: Loads only students for the EXACT year-branch-section
  Future<void> loadEnrolledStudents() async {
    try {
      debugPrint('📖 [FIRESTORE READ] Starting loadEnrolledStudents()');
      debugPrint('🎯 [TARGET] Year: $selectedYear, Branch: $selectedBranch, Section: $selectedSection, Subject: $subjectCode');
      
      errorMessage = null;
      enrolledStudentRollNos.clear();
      notifyListeners();

      // ✅ GLOBAL LOCK CHECK: Check if attendance already exists for ANY subject in this class
      final today = DateTime.now().toIso8601String().split('T').first;
      
      debugPrint('📄 [FIRESTORE QUERY] Checking existing attendance for date=$today (ALL SUBJECTS for class)');
      
      // Query ALL subjects for this class to check for period conflicts
      final existingAttendance = await _db
          .collection('attendance')
          .where('date', isEqualTo: today)
          .where('year', isEqualTo: selectedYear)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .get();

      debugPrint('✅ [FIRESTORE QUERY] Found ${existingAttendance.docs.length} existing attendance records for entire class');

      // Check if selected period is already covered by ANY attendance record
      for (final doc in existingAttendance.docs) {
        final data = doc.data();
        final startPeriod = data['periodNumber'] as int? ?? 0;
        final periodCount = (data['periodCount'] as num?)?.toInt() ?? 1;
        final endPeriod = startPeriod + periodCount;
        final existingSubject = data['subjectCode'] as String? ?? '';
        final existingFacultyId = data['facultyId'] as String? ?? '';
        
        // If selected period falls within an existing record
        if (selectedPeriodNumber >= startPeriod && selectedPeriodNumber < endPeriod) {
          debugPrint('⚠️ [CONFLICT] Period $selectedPeriodNumber already taken by faculty: $existingFacultyId for subject: $existingSubject');
          
          if (existingFacultyId == facultyId) {
            errorMessage = 'You have already taken attendance for Period $selectedPeriodNumber (Subject: $existingSubject)';
          } else {
            errorMessage = 'Period $selectedPeriodNumber already occupied by another faculty for $existingSubject';
          }
          notifyListeners();
          return;
        }
      }

      // ✅ VALIDATED: Fetch students for EXACT year-branch-section
      final int year = int.parse(selectedYear!);
      
      debugPrint('📄 [FIRESTORE QUERY] Fetching academic_records where yearOfStudy=$year, branch=$selectedBranch, section=$selectedSection, status=active');
      
      final academicSnap = await _db
          .collection('academic_records')
          .where('yearOfStudy', isEqualTo: year)
          .where('branch', isEqualTo: selectedBranch)
          .where('section', isEqualTo: selectedSection)
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('✅ [FIRESTORE QUERY] Found ${academicSnap.docs.length} academic records');

      if (academicSnap.docs.isEmpty) {
        debugPrint('❌ [ERROR] No active students found');
        errorMessage = 'No active students found for $selectedYear-$selectedBranch-$selectedSection';
        notifyListeners();
        return;
      }

      final studentIds = academicSnap.docs
          .map((d) => d['studentId'] as String)
          .toList();

      debugPrint('👥 [STUDENTS] Extracted ${studentIds.length} student IDs');

      // Fetch student roll numbers in batches
      const int chunkSize = 30;
      int totalBatches = (studentIds.length / chunkSize).ceil();
      
      debugPrint('📦 [BATCHING] Processing ${studentIds.length} students in $totalBatches batches of max $chunkSize');
      
      for (int i = 0; i < studentIds.length; i += chunkSize) {
        final chunk = studentIds.sublist(
          i,
          i + chunkSize > studentIds.length ? studentIds.length : i + chunkSize,
        );

        int batchNum = (i ~/ chunkSize) + 1;
        debugPrint('📄 [FIRESTORE QUERY] Batch $batchNum/$totalBatches - Fetching ${chunk.length} students from students collection');
        
        final snap = await _db
            .collection('students')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        debugPrint('✅ [FIRESTORE QUERY] Batch $batchNum/$totalBatches - Retrieved ${snap.docs.length} student documents');

        for (final doc in snap.docs) {
          final roll = doc['rollno']?.toString();
          if (roll != null && roll.isNotEmpty) {
            enrolledStudentRollNos.add(roll);
          }
        }
      }
      
      debugPrint('✅ [DATA LOADED] Total roll numbers loaded: ${enrolledStudentRollNos.length}');
      debugPrint('📋 [ROLL NUMBERS] ${enrolledStudentRollNos.take(10).join(", ")}${enrolledStudentRollNos.length > 10 ? "..." : ""}');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [FIRESTORE ERROR] loadEnrolledStudents failed: $e');
      errorMessage = 'Failed to load students: $e';
      notifyListeners();
    }
  }
}