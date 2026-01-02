import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/attendance_service.dart';

class ScannerController {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isFlashOn = false;
  bool showSuccessPopup = false;
  String lastScannedRoll = "";

  final Set<String> _scannedRolls = {};
  bool _isProcessing = false;

  // ---------------------------
  void toggleFlash() {
    isFlashOn = !isFlashOn;
  }

  // ---------------------------
  Future<void> onStudentScanned({
    required String rollNo,
    required String expectedBranch,
    required String expectedSection,
    required int expectedYearOfStudy,
    required int expectedSemester,
    required VoidCallback refreshUI,
  }) async {
    if (_isProcessing) return;
    if (_scannedRolls.contains(rollNo)) return;

    _isProcessing = true;

    try {
      // 1️⃣ STUDENT (static data)
      final studentQuery = await _db
          .collection('students')
          .where('rollno', isEqualTo: rollNo)
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        throw "Invalid ID card";
      }

      final student = studentQuery.docs.first.data();

      if (student['branch'] != expectedBranch ||
          student['section'] != expectedSection) {
        throw "Student not from this class";
      }

      // 2️⃣ ACADEMIC RECORD (dynamic data)
      final academicQuery = await _db
          .collection('academic_records')
          .where('studentId', isEqualTo: rollNo)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (academicQuery.docs.isEmpty) {
        throw "Academic record inactive";
      }

      final academic = academicQuery.docs.first.data();

      if (academic['yearOfStudy'] != expectedYearOfStudy ||
          academic['semester'] != expectedSemester) {
        throw "Wrong year / semester";
      }

      // 3️⃣ MARK PRESENT
      _scannedRolls.add(rollNo);
      lastScannedRoll = "$rollNo - Present";
    } catch (e) {
      lastScannedRoll = e.toString();
    }
_scannedRolls.add(rollNo);
debugPrint("✅ SCANNED: $rollNo");

    showSuccessPopup = true;
    refreshUI();

    Timer(const Duration(seconds: 2), () {
      showSuccessPopup = false;
      _isProcessing = false;
      refreshUI();
    });
  }

  // ---------------------------
  /// ✅ FINAL, CORRECT SUBMIT LOGIC
  Future<void> submitAttendance({
    required String facultyId,
    required String subjectCode,
    required int yearOfStudy,
    required int semester,
    required String branch,
    required String section,
    required int periodNumber,
  }) async {
    if (_scannedRolls.isEmpty) {
      throw "No students scanned";
    }

    await _attendanceService.markAttendance(
      facultyId: facultyId,
      subjectCode: subjectCode,
      year: yearOfStudy.toString(),
      semester: semester.toString(),
      branch: branch,
      section: section,
      periodNumber: periodNumber,
      presentStudentRollNos: _scannedRolls.toList(),
    );
  }

  // ---------------------------
  void reset() {
    _scannedRolls.clear();
  }

  int get scannedCount => _scannedRolls.length;
}
