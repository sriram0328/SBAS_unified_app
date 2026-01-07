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
        leading: const BackButton(color: Colors.white),
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
              child: Column(
                children: [
                  /// ================= ID CARD =================
                  Container(
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

                  const Spacer(),

                  /// ================= DOWNLOAD BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDownloadOptions(context),
                      icon: const Icon(Icons.download),
                      label: const Text("Download ID"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ================= DOWNLOAD OPTIONS =================
  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Download ID Card",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _DownloadOption(
              icon: Icons.image,
              title: "Save to Gallery",
              subtitle: "Save as image",
              color: Colors.blue,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),

            _DownloadOption(
              icon: Icons.share,
              title: "Share ID Card",
              subtitle: "Share via apps",
              color: Colors.orange,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),

            _DownloadOption(
              icon: Icons.picture_as_pdf,
              title: "Export as PDF",
              subtitle: "Save as document",
              color: Colors.red,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
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

/// ================= DOWNLOAD OPTION =================
class _DownloadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DownloadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
