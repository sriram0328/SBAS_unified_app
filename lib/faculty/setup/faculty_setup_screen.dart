import 'package:flutter/material.dart';
import '../scanner/live_scanner_screen.dart';

class FacultySetupScreen extends StatefulWidget {
  const FacultySetupScreen({super.key});

  @override
  State<FacultySetupScreen> createState() => _FacultySetupScreenState();
}

class _FacultySetupScreenState extends State<FacultySetupScreen> {
  String branch = "AIML";
  String year = "II";
  String section = "A";
  String subject = "Machine Learning";
  String period = "Period 4";

  final branches = ["AIML", "AIDS", "CSE", "ECE"];
  final years = ["I", "II", "III", "IV"];
  final sections = ["A", "B", "C"];
  final subjects = ["Machine Learning", "ML LAB", "BDA", "BDA LAB"];
  final periods = [
    "Period 1",
    "Period 2",
    "Period 3",
    "Period 4",
    "Period 5",
    "Period 6"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Setup Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _Dropdown("Branch", branch, branches,
                (v) => setState(() => branch = v)),
            _Dropdown("Year", year, years,
                (v) => setState(() => year = v)),
            _Dropdown("Section", section, sections,
                (v) => setState(() => section = v)),
            _Dropdown("Subject", subject, subjects,
                (v) => setState(() => subject = v)),
            _Dropdown("Period", period, periods,
                (v) => setState(() => period = v)),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LiveScannerScreen(subjectName: subject),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,),
                child: const Text("Start Scanner", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
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
