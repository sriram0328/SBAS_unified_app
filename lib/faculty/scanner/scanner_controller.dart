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

  Future<void> onStudentScanned({
    required String rollNo,
    required String expectedYear,
    required String expectedBranch,
    required String expectedSection,
    required VoidCallback refreshUI,
  }) async {
    if (_isProcessing) return;
    if (_scannedRolls.contains(rollNo)) return;

    _isProcessing = true;

    try {
      final studentDoc =
          await _db.collection('students').doc(rollNo).get();

      if (!studentDoc.exists) {
        throw "Invalid ID card";
      }

      final data = studentDoc.data()!;

      if (data['year'] != expectedYear ||
          data['branch'] != expectedBranch ||
          data['section'] != expectedSection) {
        throw "Student not from this class";
      }

      _scannedRolls.add(rollNo);
      lastScannedRoll = "$rollNo - Present";
    } catch (e) {
      lastScannedRoll = e.toString();
    }

    showSuccessPopup = true;
    refreshUI();

    Timer(const Duration(seconds: 2), () {
      showSuccessPopup = false;
      _isProcessing = false;
      refreshUI();
    });
  }

  /// IMPORTANT: facultyId MUST be Firestore doc ID (e.g., F1352)
  Future<void> submitAttendance({
    required String facultyId,
    required String subjectCode,
    required String year,
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
      year: year,
      branch: branch,
      section: section,
      periodNumber: periodNumber,
      presentStudentRollNos: _scannedRolls.toList(),
    );
  }

  void reset() {
    _scannedRolls.clear();
  }

  int get scannedCount => _scannedRolls.length;
}
