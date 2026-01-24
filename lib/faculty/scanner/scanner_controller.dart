// lib/faculty/scanner/scanner_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';

class ScannerController {
  final Set<String> enrolledStudentIds;
  final Set<String> _presentStudentIds = {};

  bool isProcessing = false;
  bool showSuccessPopup = false;
  String lastScanned = '';
  bool isFlashOn = false; 

  ScannerController({
    required Set<String> enrolledStudentIds,
  }) : enrolledStudentIds = enrolledStudentIds;

  int get scannedCount => _presentStudentIds.length;
  Set<String> get presentStudentIds => _presentStudentIds;
  String get lastScannedText => lastScanned;

  void toggleFlash() {
    isFlashOn = !isFlashOn;
  }

  /// 🔥 SCAN LOGIC - Stays initialized to accept new IDs
  Future<void> onStudentScanned({
    required String studentUid,
    required VoidCallback refreshUI,
    required VoidCallback onInvalidStudent,
  }) async {
    if (isProcessing) return;
    
    // If already scanned, just show the popup again to confirm they are present
    if (_presentStudentIds.contains(studentUid)) {
       lastScanned = "Already Scanned: $studentUid";
       showSuccessPopup = true;
       refreshUI();
       Timer(const Duration(seconds: 2), () {
          showSuccessPopup = false;
          refreshUI();
       });
       return;
    }

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
}