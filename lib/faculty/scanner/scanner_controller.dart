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

  void toggleFlash() {
    isFlashOn = !isFlashOn;
  }

  void hidePopup() {
    showSuccessPopup = false;
  }

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
      // 1️⃣ Validate student
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

      // 2️⃣ Validate academic record
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

      // 3️⃣ SUCCESS
      _scannedRolls.add(rollNo);
      lastScannedRoll = "$rollNo - Present";
      debugPrint("✅ SCANNED: $rollNo, total=${_scannedRolls.length}");
    } catch (e) {
      lastScannedRoll = e.toString();
      debugPrint('❌ Scan error for $rollNo: $e');
    }

    showSuccessPopup = true;
    refreshUI();

    Timer(const Duration(seconds: 2), () {
      showSuccessPopup = false;
      _isProcessing = false;
      refreshUI();
    });
  }

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

    debugPrint(
        'submitAttendance: faculty=$facultyId, subject=$subjectCode, year=$yearOfStudy, sem=$semester, '
        'branch=$branch, section=$section, period=$periodNumber, present=${_scannedRolls.length}');

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

  void reset() {
    _scannedRolls.clear();
    showSuccessPopup = false;
    lastScannedRoll = "";
    _isProcessing = false;
  }

  int get scannedCount => _scannedRolls.length;
}
