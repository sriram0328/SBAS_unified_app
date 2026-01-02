// attendance_report_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'attendance_report_controller.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final controller = AttendanceReportController();
  String filter = "All";

  @override
  void initState() {
    super.initState();
    // Controller initializes itself, just trigger UI update
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadData() async {
    setState(() {});
    await controller.refreshAllData();
    setState(() {});
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Export Attendance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue),
                title: const Text("Share as Text"),
                subtitle: const Text("Share via messaging apps"),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsText();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text("Export as CSV"),
                subtitle: const Text("Download spreadsheet file"),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsCSV();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareAsText() {
    final textReport = controller.generateTextReport();
    Share.share(
      textReport,
      subject: 'Attendance Report - ${controller.selectedDate}',
    );
  }

  void _exportAsCSV() {
    final csvContent = controller.generateCSV();
    Share.share(
      csvContent,
      subject: 'Attendance_${controller.selectedDate}.csv',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV file ready to share'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = filter == "Present"
        ? controller.presentStudents
        : filter == "Absent"
            ? controller.absentStudents
            : controller.students;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Attendance Records"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FilterSection(
              controller: controller,
              onFilterChanged: () async {
                setState(() {});
                await controller.updateFilters();
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
            
            // Show error message if any
            if (controller.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            _ToggleBar(
              selected: filter,
              onChanged: (v) => setState(() => filter = v),
            ),
            const SizedBox(height: 12),
            _SummaryRow(controller),
            const SizedBox(height: 12),
            
            // Show initializing, loading, or content
            Expanded(
              child: controller.isInitializing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading attendance records...'),
                        ],
                      ),
                    )
                  : controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : students.isEmpty
                          ? _EmptyState()
                          : ListView.builder(
                              itemCount: students.length,
                              itemBuilder: (_, i) =>
                                  _StudentTile(student: students[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- EMPTY STATE ---------------- */

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting the filters above',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- FILTER SECTION ---------------- */

class _FilterSection extends StatelessWidget {
  final AttendanceReportController controller;
  final VoidCallback onFilterChanged;

  const _FilterSection({
    required this.controller,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                label: "Date",
                value: controller.selectedDate,
                items: controller.availableDates,
                onChanged: (value) {
                  controller.updateFilters(date: value);
                  onFilterChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                label: "Subject",
                value: controller.subject,
                items: controller.availableSubjects,
                onChanged: (value) {
                  controller.updateFilters(subjectValue: value);
                  onFilterChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                label: "Year",
                value: controller.year,
                items: controller.availableYears,
                onChanged: (value) {
                  controller.updateFilters(yearValue: value);
                  onFilterChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                label: "Branch",
                value: controller.branch,
                items: controller.availableBranches,
                onChanged: (value) {
                  controller.updateFilters(branchValue: value);
                  onFilterChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                label: "Section",
                value: controller.section,
                items: controller.availableSections,
                onChanged: (value) {
                  controller.updateFilters(sectionValue: value);
                  onFilterChanged();
                },
              ),
            ),
            Expanded(
  child: _DropdownField(
    label: "Period",
    value: controller.periodNumber?.toString() ?? "",
    items: controller.availablePeriods.map((e) => e.toString()).toList(),
    onChanged: (v) {
      controller.updateFilters(periodValue: int.parse(v));
      onFilterChanged();
    },
  ),
),

          ],
        ),
      ],
    );
  }
}

/* ---------------- DROPDOWN FIELD ---------------- */

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- TOGGLE BAR ---------------- */

class _ToggleBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ToggleBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ["All", "Present", "Absent"].map((e) {
          final active = selected == e;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  e,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/* ---------------- SUMMARY ROW ---------------- */

class _SummaryRow extends StatelessWidget {
  final AttendanceReportController controller;

  const _SummaryRow(this.controller);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Total: ${controller.totalStudents} Students"),
        Row(
          children: [
            Text(
              "P: ${controller.presentCount}",
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(width: 10),
            Text(
              "A: ${controller.absentCount}",
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}

/* ---------------- STUDENT TILE ---------------- */

class _StudentTile extends StatelessWidget {
  final AttendanceStudent student;

  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final color = student.isPresent ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: student.isPresent
            ? null
            : Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              student.name[0],
              style: TextStyle(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.rollNo,
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              student.isPresent ? "Present" : "Absent",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}