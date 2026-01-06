import 'dart:async';
import 'package:flutter/material.dart';

class ScannerController {
  final Set<String> enrolledStudentIds;
  final Set<String> _presentStudentIds = {};

  bool isProcessing = false;
  bool showSuccessPopup = false;
  String lastScanned = '';
  bool isFlashOn = false; // ✅ Added

  ScannerController({
    required Set<String> enrolledStudentIds,
  }) : enrolledStudentIds = enrolledStudentIds;

  int get presentCount => _presentStudentIds.length;
  Set<String> get presentStudentIds => _presentStudentIds;
  
  // ✅ Added getters
  int get scannedCount => _presentStudentIds.length;
  String get lastScannedText => lastScanned;

  // ✅ Added flash toggle
  void toggleFlash() {
    isFlashOn = !isFlashOn;
  }

  /// 🔥 SCAN LOGIC
  Future<void> onStudentScanned({
    required String studentUid,
    required VoidCallback refreshUI,
    required VoidCallback onInvalidStudent,
  }) async {
    if (isProcessing) return;
    if (_presentStudentIds.contains(studentUid)) return;

    // ❌ NOT ENROLLED
    if (!enrolledStudentIds.contains(studentUid)) {
      onInvalidStudent();
      return;
    }

    isProcessing = true;
    _presentStudentIds.add(studentUid);

    lastScanned = "Scanned: $studentUid";
    showSuccessPopup = true;
    refreshUI();

    Timer(const Duration(seconds: 2), () {
      showSuccessPopup = false;
      isProcessing = false;
      refreshUI();
    });
  }

  void reset() {
    _presentStudentIds.clear();
    showSuccessPopup = false;
    lastScanned = '';
    isProcessing = false;
  }
}