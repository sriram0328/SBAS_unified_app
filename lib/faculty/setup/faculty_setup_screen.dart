import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../setup/faculty_setup_controller.dart';
import '../scanner/live_scanner_screen.dart';
import '../../core/session.dart';

class FacultySetupScreen extends StatelessWidget {
  const FacultySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FacultySetupController(),
      child: const _FacultySetupView(),
    );
  }
}

class _FacultySetupView extends StatelessWidget {
  const _FacultySetupView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FacultySetupController>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Setup Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _Dropdown("Branch", c.branch, c.branches, c.updateBranch),
            _Dropdown("Year", c.year, c.years, c.updateYear),
            _Dropdown("Semester", c.semester, c.semesters, c.updateSemester),
            _Dropdown("Section", c.section, c.sections, c.updateSection),
            _Dropdown("Subject", c.subject, c.subjects, c.updateSubject),
            _Dropdown("Period", c.period, c.periods, c.updatePeriod),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: c.canStartScanner()
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveScannerScreen(
                              facultyId: Session.facultyId,
                              subjectName: c.subject,
                              branch: c.branch,
                              section: c.section,
                              yearOfStudy: int.parse(c.year),
                              semester: int.parse(c.semester),
                              periodNumber: c.periodNumber,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text("Start Scanner"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Dropdown(this.label, this.value, this.items, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (v) => onChanged(v!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
