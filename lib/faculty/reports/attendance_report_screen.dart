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
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  late final AttendanceReportController controller;

  @override
  void initState() {
    super.initState();
    controller = AttendanceReportController(facultyId: widget.facultyId);
    controller.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.initialize();
    });
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = picked.toIso8601String().substring(0, 10);
      controller.updateFilter(dateValue: formatted);
    }
  }

  Future<void> _downloadCSV() async {
    try {
      final csv = controller.generateCSV();
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv';
      await File(filePath).writeAsString(csv);
      await Share.shareXFiles([XFile(filePath)], subject: 'Attendance Report');
      _showSnackBar('CSV Shared successfully');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _downloadPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(controller.getReportHeading(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(controller.getSubjectInfo()),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: ['Roll Number', 'Name', 'Status'],
            data: controller.visibleRolls.map((r) => [r.roll, r.name, r.present ? 'Present' : 'Absent']).toList(),
          ),
        ],
      ));
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(filePath).writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(filePath)], subject: 'Attendance Report');
      _showSnackBar('PDF Shared successfully');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('CSV'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadCSV();
                  }),
              ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadPDF();
                  }),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attendance Report', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: controller.isLoading || controller.totalCount == 0 ? null : _showDownloadOptions),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.isLoading ? null : controller.refresh),
        ],
      ),
      body: controller.isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                _buildStatsCard(),
                _buildSmoothScrollPills(),
                _buildSearchBar(),
                const Divider(height: 1),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: _dropdownField(controller.dates, controller.date, 'Date', (v) {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _dropdownField(controller.subjects, controller.subject, 'Subject', (v) => controller.updateFilter(subjectValue: v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _dropdownField(controller.years, controller.year, 'Yr', (v) => controller.updateFilter(yearValue: v)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _dropdownField(controller.branches, controller.branch, 'Branch', (v) => controller.updateFilter(branchValue: v))),
              const SizedBox(width: 8),
              Expanded(child: _dropdownField(controller.sections, controller.section, 'Section', (v) => controller.updateFilter(sectionValue: v))),
              const SizedBox(width: 8),
              Expanded(child: _dropdownField(controller.periods.map((e) => e.toString()).toList(), controller.period?.toString(), 'Period', (v) => controller.updateFilter(periodValue: int.tryParse(v)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(List<String> items, String? value, String label, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: (items.contains(value)) ? value : null,
      isExpanded: true,
      menuMaxHeight: 250,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: Colors.blueGrey[50]?.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      items: items
          .map((e) => DropdownMenuItem(
              value: e, 
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(e, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              )))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', controller.totalCount.toString(), Colors.black),
          _statItem('Present', controller.presentCount.toString(), Colors.green),
          _statItem('Absent', controller.absentCount.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSmoothScrollPills() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pillItem('all', 'All'),
          const SizedBox(width: 8),
          _pillItem('present', 'Present'),
          const SizedBox(width: 8),
          _pillItem('absent', 'Absent'),
        ],
      ),
    );
  }

  Widget _pillItem(String key, String label) {
    bool isSelected = controller.activeFilter == key;
    return GestureDetector(
      onTap: () => controller.updateFilter(pill: key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: TextField(
        onChanged: (value) => controller.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search roll number or name...',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (controller.isLoading) return const Center(child: CircularProgressIndicator());

    final rows = controller.visibleRolls;
    if (rows.isEmpty) return const Center(child: Text('No records found', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: r.present ? Colors.green[50] : Colors.red[50],
              child: Text(
                r.roll.substring(r.roll.length - 2),
                style: TextStyle(color: r.present ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(r.roll, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: r.present ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.present ? 'PRESENT' : 'ABSENT',
                style: TextStyle(color: r.present ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
        );
      },
    );
  }
}