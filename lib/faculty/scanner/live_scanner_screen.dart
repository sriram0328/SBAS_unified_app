import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_controller.dart';
import '../../core/session.dart';

class LiveScannerScreen extends StatefulWidget {
  final String facultyId;
  final String subjectName;
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
        BarcodeFormat.qrCode,
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
    return GestureDetector(
      onTap: () {
        if (controller.showSuccessPopup) {
          controller.hidePopup();
          _refresh();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Stack(
            children: [
              /// 📷 CAMERA (full screen)
              Positioned.fill(
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (capture.barcodes.isEmpty) return;
                    final code = capture.barcodes.first.rawValue;
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
              ),

              /// 🔝 HEADER BAR
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          controller.isFlashOn ? Icons.flash_on : Icons.flash_off,
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

              /// 🎯 SCAN TARGET FRAME
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

              /// ✅ SUCCESS/ERROR POPUP
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
                          backgroundColor: controller.lastScannedRoll.contains('Present')
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              /// 🚀 SUBMIT BUTTON (Final Production Version)
              Positioned(
                left: 16,
                right: 16,
                bottom: 40,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.scannedCount == 0
                        ? null
                        : () async {
                            // ✅ Exact match for Firestore rules
                            final facultyId = Session.facultyId;
                            
                            debugPrint('🔑 Submitting with facultyId="$facultyId"');
                            debugPrint('📊 Scanned ${controller.scannedCount} students');
                            
                            try {
                              await controller.submitAttendance(
                                facultyId: facultyId,           // Must be "FAC123" 
                                subjectCode: widget.subjectName,
                                yearOfStudy: widget.yearOfStudy,
                                semester: widget.semester,
                                branch: widget.branch,
                                section: widget.section,
                                periodNumber: widget.periodNumber,
                              );

                              debugPrint('✅ Attendance SUBMITTED SUCCESSFULLY');
                              
                              if (!mounted) return;
                              Navigator.pop(context);
                            } catch (e, st) {
                              debugPrint('❌ Submit failed: $e');
                              debugPrint('Stack: $st');
                              
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Submit failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: Text(
                      "Submit Attendance (${controller.scannedCount})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
