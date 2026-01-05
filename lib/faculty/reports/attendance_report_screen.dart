import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'attendance_report_controller.dart';
import '../../core/session.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  late final AttendanceReportController controller;

  String filter = "All";

  @override
  void initState() {
    super.initState();

    // ✅ FIXED: use debugPrint instead of print
    debugPrint("🚀 AttendanceReportScreen initialized");
    debugPrint("👤 Faculty ID from Session: ${Session.facultyId}");

    controller = AttendanceReportController(
      facultyId: Session.facultyId,
    );

    controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose(); // ✅ FIXED: properly dispose ChangeNotifier
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    debugPrint("🔄 Refreshing attendance report...");
    await controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "🎨 Building UI - isInitializing: ${controller.isInitializing}, "
      "isLoading: ${controller.isLoading}",
    );

    final students = filter == "Present"
        ? controller.students.where((s) => s.isPresent).toList()
        : filter == "Absent"
            ? controller.students.where((s) => !s.isPresent).toList()
            : controller.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Records"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading ? null : _refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (controller.students.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No data to export")),
                );
                return;
              }

              if (v == "text") {
                Share.share(controller.generateTextReport());
              } else {
                Share.share(controller.generateCSV());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "text", child: Text("Share Text Report")),
              PopupMenuItem(value: "csv", child: Text("Export as CSV")),
            ],
          ),
        ],
      ),
      body: controller.isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading attendance records..."),
                ],
              ),
            )
          : controller.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Error: ${controller.errorMessage}",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row([
                        _dropdown(
                          "Year",
                          controller.year,
                          controller.availableYears,
                          (v) =>
                              controller.updateFilters(yearValue: v),
                        ),
                        _dropdown(
                          "Semester",
                          controller.semester,
                          controller.availableSemesters,
                          (v) =>
                              controller.updateFilters(semesterValue: v),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _row([
                        _dropdown(
                          "Branch",
                          controller.branch,
                          controller.availableBranches,
                          (v) =>
                              controller.updateFilters(branchValue: v),
                        ),
                        _dropdown(
                          "Section",
                          controller.section,
                          controller.availableSections,
                          (v) =>
                              controller.updateFilters(sectionValue: v),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      if (controller.availableDates.isNotEmpty)
                        _row([
                          _dropdown(
                            "Date",
                            controller.selectedDate,
                            controller.availableDates,
                            (v) =>
                                controller.updateFilters(date: v),
                          ),
                          _dropdown(
                            "Subject",
                            controller.subject,
                            controller.availableSubjects,
                            (v) =>
                                controller.updateFilters(subjectValue: v),
                          ),
                        ]),
                      const SizedBox(height: 12),
                      if (controller.students.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (_, i) {
                              final s = students[i];
                              return ListTile(
                                title: Text(s.name),
                                subtitle: Text(s.rollNo),
                                trailing: Text(
                                  s.isPresent ? "Present" : "Absent",
                                  style: TextStyle(
                                    color: s.isPresent
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _row(List<Widget> children) =>
      Row(children: children.map((e) => Expanded(child: e)).toList());

  Widget _dropdown<T>(
    String label,
    T? value,
    List<T> items,
    Function(T) onChanged,
  ) {
    final isDisabled =
        controller.isLoading || (value == null && items.isEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          DropdownButton<T>(
            isExpanded: true,
            value: items.contains(value) ? value : null,
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.toString()),
                  ),
                )
                .toList(),
            onChanged: isDisabled
                ? null
                : (v) {
                    if (v != null) onChanged(v);
                  },
          ),
        ],
      ),
    );
  }
}
