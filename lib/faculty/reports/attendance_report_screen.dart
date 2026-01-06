import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
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
        initialValue: value,
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
          title: Text(r.roll),
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
