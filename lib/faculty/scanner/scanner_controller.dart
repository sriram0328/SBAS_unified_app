import 'dart:async';
import 'package:flutter/foundation.dart';

class ScannerController {
  bool isFlashOn = false;
  bool showSuccessPopup = false;
  String lastScannedRoll = "";

  bool _isProcessing = false; // prevent duplicate scans

  void toggleFlash() {
    isFlashOn = !isFlashOn;
  }

  void onStudentScanned(String rollNo, VoidCallback refreshUI) {
    if (_isProcessing) return;

    _isProcessing = true;
    lastScannedRoll = rollNo;
    showSuccessPopup = true;
    refreshUI();

    Timer(const Duration(seconds: 2), () {
      showSuccessPopup = false;
      _isProcessing = false;
      refreshUI();
    });
  }
}
