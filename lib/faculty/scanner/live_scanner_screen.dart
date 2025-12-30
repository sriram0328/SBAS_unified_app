import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_controller.dart';

class LiveScannerScreen extends StatefulWidget {
  final String subjectName;

  const LiveScannerScreen({
    super.key,
    required this.subjectName,
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
            // 📷 REAL CAMERA
            MobileScanner(
              controller: cameraController,
              onDetect: (barcode) {
                final code = barcode.barcodes.first.rawValue;
                if (code != null) {
                  controller.onStudentScanned(code, _refresh);
                }
              },
            ),

            // 🔝 Top Bar
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

            // 📐 Scanner Overlay
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

            // ✅ Success Popup
            if (controller.showSuccessPopup)
              Positioned(
                left: 16,
                right: 16,
                bottom: 30,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${controller.lastScannedRoll} - Present",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
