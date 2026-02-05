import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'student_id_controller.dart';

class StudentIdScreen extends StatefulWidget {
  const StudentIdScreen({super.key});

  @override
  State<StudentIdScreen> createState() => _StudentIdScreenState();
}

class _StudentIdScreenState extends State<StudentIdScreen> {
  late final StudentIdController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudentIdController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.loadStudentData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: const Text(
          "Digital ID",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Institution Name
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _controller.institutionName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Profile Icon
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            Colors.teal.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.person,
                          size: 36,
                          color: Colors.teal,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// Name & Role
                      Text(
                        _controller.studentName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _controller.role,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),

                      const SizedBox(height: 16),

                      /// Student Info
                      _InfoRow("Roll No", _controller.rollNo),
                      _InfoRow("Branch & Section",
                          _controller.branchDisplay),
                      _InfoRow("Year", _controller.year),

                      const SizedBox(height: 20),

                      /// Barcode (Code128 – same as React)
                      if (_controller.rollNo.isNotEmpty)
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: _controller.barcodeData,
                          height: 70,
                          drawText: false,
                        ),

                      const SizedBox(height: 8),

                      Text(
                        _controller.barcodeData,
                        style: const TextStyle(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// ================= INFO ROW =================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}