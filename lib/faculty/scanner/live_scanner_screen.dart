import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/session.dart';
import 'scanner_controller.dart';
import '../../services/attendance_service.dart';

class LiveScannerScreen extends StatefulWidget {
  final String facultyId;
  final int periodNumber; // ✅ FIXED
  final String year;
  final String branch;
  final String section;
  final String subjectCode;
  final String subjectName;
  final List<String> enrolledStudentIds;

  const LiveScannerScreen({
    super.key,
    required this.facultyId,
    required this.periodNumber, // ✅ FIXED
    required this.year,
    required this.branch,
    required this.section,
    required this.subjectCode,
    required this.subjectName,
    required this.enrolledStudentIds,
  });

  @override
  State<LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<LiveScannerScreen> {
  late final ScannerController controller;
  final AttendanceService _attendanceService = AttendanceService();
  late final MobileScannerController cameraController;

  @override
  void initState() {
    super.initState();

    controller = ScannerController(
      enrolledStudentIds: widget.enrolledStudentIds.toSet(),
    );

    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      torchEnabled: false,
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showInvalidStudentPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student not enrolled in this class'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
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
            Positioned.fill(
              child: MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final uid = capture.barcodes.first.rawValue;
                  if (uid == null || uid.isEmpty) return;

                  controller.onStudentScanned(
                    studentUid: uid,
                    refreshUI: _refresh,
                    onInvalidStudent: _showInvalidStudentPopup,
                  );
                },
              ),
            ),

            /// HEADER
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        style: const TextStyle(color: Colors.white),
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

            /// SUCCESS POPUP
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
                  child: Text(
                    controller.lastScannedText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            /// SUBMIT
            Positioned(
              left: 16,
              right: 16,
              bottom: 40,
              child: ElevatedButton(
                onPressed: controller.scannedCount == 0
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);

                        await _attendanceService.createAttendance(
                          facultyId: Session.facultyId,
                          periodNumber: widget.periodNumber, // ✅ FIXED
                          year: widget.year,
                          branch: widget.branch,
                          section: widget.section,
                          subjectCode: widget.subjectCode,
                          subjectName: widget.subjectName,
                          enrolledStudentIds: widget.enrolledStudentIds,
                          presentStudentIds:
                              controller.presentStudentIds.toList(),
                        );

                        navigator.pop();
                      },
                child: Text(
                  'Submit Attendance (${controller.scannedCount})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
