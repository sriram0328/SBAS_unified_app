// lib/faculty/scanner/live_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_controller.dart';
import '../../services/attendance_service.dart';

class LiveScannerScreen extends StatefulWidget {
  final String facultyId;
  final int periodNumber;
  final int periodCount;     // ✅ KEEP - needed for submission
  final bool isLab;          // ✅ KEEP - needed for submission & UI
  final String year;
  final String branch;
  final String section;
  final String subjectCode;
  final String subjectName;
  final List<String> enrolledStudentIds;

  const LiveScannerScreen({
    super.key,
    required this.facultyId,
    required this.periodNumber,
    required this.periodCount,
    required this.isLab,
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
      formats: [BarcodeFormat.all],
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showAttendanceReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final presentList = controller.presentStudentIds.toList()..sort();
        final absentList = widget.enrolledStudentIds
            .where((id) => !controller.presentStudentIds.contains(id))
            .toList()..sort();
        
        return _AttendanceReportSheet(
          presentList: presentList,
          absentList: absentList,
          isLab: widget.isLab,
          onSubmit: () {
            Navigator.pop(context);
            _handleSubmit();
          },
        );
      },
    );
  }

  // OPTIMIZED SUBMISSION logic to cut down wait time
  Future<void> _handleSubmit() async {
    setState(() { 
      controller.isProcessing = true; 
    });

    // ✅ Pass periodCount and isLab to the service
    _attendanceService.createAttendance(
      facultyId: widget.facultyId,
      periodNumber: widget.periodNumber,
      periodCount: widget.periodCount,    // ✅ NOW PASSED
      isLab: widget.isLab,                // ✅ NOW PASSED
      year: widget.year,
      branch: widget.branch,
      section: widget.section,
      subjectCode: widget.subjectCode,
      subjectName: widget.subjectName,
      enrolledStudentIds: widget.enrolledStudentIds,
      presentStudentIds: controller.presentStudentIds.toList(),
    );

    cameraController.stop();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isLab ? 'Lab Attendance Saved (Syncing...)' : 'Attendance Saved (Syncing...)'),
          backgroundColor: widget.isLab ? Colors.purple : Colors.blueAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(); 
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use purple for labs, blue for classes
    final accentColor = widget.isLab ? Colors.purple : const Color(0xFF2962FF);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final uid = capture.barcodes.first.rawValue;
              if (uid == null || uid.isEmpty) return;
              
              if (!controller.presentStudentIds.contains(uid)) {
                 HapticFeedback.lightImpact();
              }

              controller.onStudentScanned(
                studentUid: uid, 
                refreshUI: _refresh, 
                onInvalidStudent: () => HapticFeedback.vibrate()
              );
            },
          ),
          
          Positioned.fill(child: _ScannerOverlayPainter()),

          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent]
                )
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isLab) ...[
                            const Icon(Icons.science_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(widget.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(
                        widget.periodCount > 1
                            ? '${widget.branch}-${widget.section} • P${widget.periodNumber}-P${widget.periodNumber + widget.periodCount - 1}'
                            : '${widget.branch}-${widget.section} • P${widget.periodNumber}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(controller.isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                    onPressed: () { controller.toggleFlash(); cameraController.toggleTorch(); _refresh(); }
                  ),
                ],
              ),
            ),
          ),

          // Success popup - green
          if (controller.showSuccessPopup)
            Positioned(
              left: 40, right: 40, bottom: 200,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.9), 
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  controller.lastScannedText, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),

          // Error popup - red
          if (controller.showErrorPopup)
            Positioned(
              left: 40, right: 40, bottom: 200,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9), 
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  controller.lastScannedText, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),

          Positioned(
            left: 24, right: 24, bottom: 40,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: controller.scannedCount == 0 || controller.isProcessing ? null : _showAttendanceReport,
                child: controller.isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Review & Submit (${controller.scannedCount})', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: Stateful widget for the attendance report with filter tabs
class _AttendanceReportSheet extends StatefulWidget {
  final List<String> presentList;
  final List<String> absentList;
  final bool isLab;
  final VoidCallback onSubmit;

  const _AttendanceReportSheet({
    required this.presentList,
    required this.absentList,
    required this.isLab,
    required this.onSubmit,
  });

  @override
  State<_AttendanceReportSheet> createState() => _AttendanceReportSheetState();
}

class _AttendanceReportSheetState extends State<_AttendanceReportSheet> {
  int _selectedFilter = 0; // 0: All, 1: Present, 2: Absent

  @override
  Widget build(BuildContext context) {
    List<String> filteredList;
    switch (_selectedFilter) {
      case 1: // Present only
        filteredList = widget.presentList;
        break;
      case 2: // Absent only
        filteredList = widget.absentList;
        break;
      default: // All
        filteredList = [...widget.presentList, ...widget.absentList];
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  "Attendance Report",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${widget.presentList.length} Present",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${widget.absentList.length} Absent",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All (${widget.presentList.length + widget.absentList.length})',
                  isSelected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Present (${widget.presentList.length})',
                  isSelected: _selectedFilter == 1,
                  color: Colors.green,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Absent (${widget.absentList.length})',
                  isSelected: _selectedFilter == 2,
                  color: Colors.red,
                  onTap: () => setState(() => _selectedFilter = 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Student List
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filteredList.length,
              itemBuilder: (context, i) {
                final studentId = filteredList[i];
                final isPresent = widget.presentList.contains(studentId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPresent ? Colors.green[50] : Colors.red[50],
                    child: Icon(
                      isPresent ? Icons.person : Icons.person_outline,
                      color: isPresent ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    studentId,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPresent ? Colors.black : Colors.grey[700],
                    ),
                  ),
                  trailing: Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green : Colors.red,
                    size: 20,
                  ),
                );
              },
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Rescan More"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isLab ? Colors.purple : const Color(0xFF2962FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.onSubmit,
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.blue;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? chipColor.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? chipColor : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.7;
    return Stack(
      children: [
        ColorFiltered(                                                                                   
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
              Align(alignment: Alignment.center, child: Container(width: size, height: size * 0.6, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
        ),
        Align(alignment: Alignment.center, child: Container(width: size, height: size * 0.6, decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2), borderRadius: BorderRadius.circular(20)))),
      ],
    );
  }
}