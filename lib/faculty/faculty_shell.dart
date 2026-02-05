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

  // ✅ single source of truth for primary blue
  static const Color primaryBlue = Color(0xFF2962FF);

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
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),

        // 🔥 Floating bottom navigation (labels visible)
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,

              // ✅ labels ON
              showSelectedLabels: true,
              showUnselectedLabels: true,

              selectedItemColor: primaryBlue,
              unselectedItemColor: Colors.grey.shade400,

              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),

              selectedIconTheme: const IconThemeData(size: 26),
              unselectedIconTheme: const IconThemeData(size: 24),

              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: "Timetable",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: "Reports",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}