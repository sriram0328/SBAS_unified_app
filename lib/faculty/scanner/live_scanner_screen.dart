import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_controller.dart';
import '../../core/session.dart';

class LiveScannerScreen extends StatefulWidget {
  final String facultyId;
  final String subjectName;

  // Class context
  final String branch;
  final String section;
  final int yearOfStudy;
  final int semester;
  final int periodNumber;

  const LiveScannerScreen({
    super.key,
    required this.facultyId,
    required this.subjectName,
    required this.branch,
    required this.section,
    required this.yearOfStudy,
    required this.semester,
    required this.periodNumber,
  });

  @override
  State<LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<LiveScannerScreen> {
  final ScannerController controller = ScannerController();
  late final MobileScannerController cameraController;

  @override
  void initState() {
    super.initState();

    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.itf,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.qrCode, // keep QR for testing
      ],
    );
  }

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
            /// 📷 CAMERA SCANNER
            MobileScanner(
              controller: cameraController,
              onDetect: (BarcodeCapture capture) {
                if (capture.barcodes.isEmpty) return;

                final barcode = capture.barcodes.first;
                final code = barcode.rawValue;

                if (code == null || code.trim().isEmpty) return;

                controller.onStudentScanned(
                  rollNo: code.trim(),
                  expectedBranch: widget.branch,
                  expectedSection: widget.section,
                  expectedYearOfStudy: widget.yearOfStudy,
                  expectedSemester: widget.semester,
                  refreshUI: _refresh,
                );
              },
            ),

            /// 🔝 HEADER
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

            /// 🎯 SCAN FRAME (WIDE FOR 1D BARCODE)
            Center(
              child: Container(
                height: 160,
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
              ),
            ),

            /// ✅ / ❌ RESULT POPUP
            if (controller.showSuccessPopup)
              Positioned(
                left: 16,
                right: 16,
                bottom: 140,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            controller.lastScannedRoll.contains('Present')
                                ? Colors.green
                                : Colors.red,
                        child: Icon(
                          controller.lastScannedRoll.contains('Present')
                              ? Icons.check
                              : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.lastScannedRoll,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /// 🚀 SUBMIT BUTTON
            Positioned(
              left: 16,
              right: 16,
              bottom: 40,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.scannedCount == 0
                      ? null
                      : () async {
                          await controller.submitAttendance(
                            facultyId: Session.facultyId,
                            subjectCode: widget.subjectName,
                            yearOfStudy: widget.yearOfStudy,
                            semester: widget.semester,
                            branch: widget.branch,
                            section: widget.section,
                            periodNumber: widget.periodNumber,
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                  child: Text(
                    "Submit Attendance (${controller.scannedCount})",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
