import 'package:flutter/material.dart';
import 'dashboard/faculty_dashboard_screen.dart';
import 'timetable/timetable_screen.dart';
import 'reports/attendance_report_screen.dart';

class FacultyShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FacultyShell({super.key, required this.userData});

  @override
  State<FacultyShell> createState() => _FacultyShellState();
}

class _FacultyShellState extends State<FacultyShell> {
  int _currentIndex = 0;
  late final String facultyId;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    facultyId = widget.userData['facultyId'];

    _screens = [
      FacultyDashboardScreen(facultyId: facultyId),
      TimetableScreen(facultyId: facultyId),
      AttendanceReportScreen(facultyId: facultyId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each screen
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Timetable"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_rounded), label: "Reports"),
        ],
      ),
    );
  }
}