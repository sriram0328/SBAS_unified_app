import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'attendance_report_controller.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String facultyId;
  const AttendanceReportScreen({super.key, required this.facultyId});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  late final AttendanceReportController controller;

  @override
  void initState() {
    super.initState();
    controller = AttendanceReportController(facultyId: widget.facultyId);
    controller.addListener(_rebuild);
    controller.initialize();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_rebuild);
    controller.dispose();
    super.dispose();
  }

  Future<void> _downloadCSV() async {
    try {
      final csv = controller.generateCSV();
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'attendance_report_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csv);
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Attendance Report',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV Report downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading CSV: $e')),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    try {
      final pdf = pw.Document();
      
      // Get filtered rows
      final List rows;
      if (controller.activeFilter == 'present') {
        rows = controller.visibleRolls.where((e) => e.present).toList();
      } else if (controller.activeFilter == 'absent') {
        rows = controller.visibleRolls.where((e) => !e.present).toList();
      } else {
        rows = controller.visibleRolls;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Main Heading
              pw.Text(
                controller.getReportHeading(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                controller.getSubjectInfo(),
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total: ${controller.totalCount}'),
                  pw.Text('Present: ${controller.presentCount}'),
                  pw.Text('Absent: ${controller.absentCount}'),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Roll Number',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...rows.map((row) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row.roll),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            row.present ? 'Present' : 'Absent',
                            style: pw.TextStyle(
                              color: row.present ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'attendance_report_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Attendance Report',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF Report downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading PDF: $e')),
        );
      }
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Download as CSV'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadCSV();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Download as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadPDF();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: controller.isLoading || controller.totalCount == 0
                ? null
                : _showDownloadOptions,
            tooltip: 'Download Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading ? null : controller.refresh,
          ),
        ],
      ),
      body: controller.isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _filters(),
                _counts(),
                const Divider(),
                _pills(),
                const Divider(),
                Expanded(child: _list()),
              ],
            ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _dd(controller.dates, controller.date, 'Date',
              (v) => controller.updateFilter(dateValue: v)),
          _dd(controller.subjects, controller.subject, 'Subject',
              (v) => controller.updateFilter(subjectValue: v)),
          _dd(controller.years, controller.year, 'Year',
              (v) => controller.updateFilter(yearValue: v)),
          _dd(controller.branches, controller.branch, 'Branch',
              (v) => controller.updateFilter(branchValue: v)),
          _dd(controller.sections, controller.section, 'Section',
              (v) => controller.updateFilter(sectionValue: v)),
          _dd(
            controller.periods.map((e) => e.toString()).toList(),
            controller.period?.toString(),
            'Period',
            (v) => controller.updateFilter(
                periodValue: int.parse(v)),
          ),
        ],
      ),
    );
  }

  Widget _dd(
    List<String> items,
    String? value,
    String label,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e) =>
                DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: value == null ? null : (v) => onChanged(v!),
      ),
    );
  }

  Widget _counts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Total: ${controller.totalCount}'),
          const Spacer(),
          Text('P: ${controller.presentCount}',
              style: const TextStyle(color: Colors.green)),
          const SizedBox(width: 12),
          Text('A: ${controller.absentCount}',
              style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _pills() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill('all', 'All'),
        _pill('present', 'Present'),
        _pill('absent', 'Absent'),
      ],
    );
  }

  Widget _pill(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: controller.activeFilter == key,
        onSelected: (_) =>
            controller.updateFilter(pill: key),
      ),
    );
  }

  Widget _list() {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = controller.visibleRolls;

    if (rows.isEmpty) {
      return const Center(child: Text('No records'));
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: r.present ? Colors.green.shade100 : Colors.red.shade100,
            child: Text(
              r.roll.substring(r.roll.length > 2 ? r.roll.length - 2 : 0),
              style: TextStyle(
                color: r.present ? Colors.green.shade900 : Colors.red.shade900,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(r.name),
          subtitle: Text(r.roll),
          trailing: Text(
            r.present ? 'Present' : 'Absent',
            style: TextStyle(
              color: r.present ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}