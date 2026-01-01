import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_controller.dart';

class LiveScannerScreen extends StatefulWidget {
  final String subjectName;
  final String branch;
  final String year;
  final String section;
  final int periodNumber;

  const LiveScannerScreen({
    super.key,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.section,
    required this.periodNumber,
  });

  @override
  State<LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<LiveScannerScreen> {
  final ScannerController controller = ScannerController();
  final MobileScannerController cameraController =
      MobileScannerController();

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: (barcode) {
                final code = barcode.barcodes.first.rawValue;
                if (code != null) {
                  controller.onStudentScanned(
                    rollNo: code,
                    expectedYear: widget.year,
                    expectedBranch: widget.branch,
                    expectedSection: widget.section,
                    refreshUI: _refresh,
                  );
                }
              },
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black45,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.subjectName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        controller.isFlashOn
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        controller.toggleFlash();
                        cameraController.toggleTorch();
                        _refresh();
                      },
                    ),
                  ],
                ),
              ),
            ),

            Center(
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                ),
              ),
            ),

            if (controller.showSuccessPopup)
              Positioned(
                left: 16,
                right: 16,
                bottom: 150,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    controller.lastScannedRoll,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 40,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await controller.submitAttendance(
                      facultyId: FirebaseAuth.instance.currentUser!.uid,
                      subjectCode: widget.subjectName,
                      year: widget.year,
                      branch: widget.branch,
                      section: widget.section,
                      periodNumber: widget.periodNumber,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Attendance submitted")),
                    );

                    controller.reset();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: Text(
                    "Submit Attendance (${controller.scannedCount})"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
