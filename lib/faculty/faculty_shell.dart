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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      FacultyDashboardScreen(userData: widget.userData),
      TimetableScreen(),
      AttendanceReportScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: "Timetable",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: "Reports",
          ),
        ],
      ),
    );
  }
}
