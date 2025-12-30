import 'package:flutter/material.dart';

import 'dashboard/student_dashboard_screen.dart';
import 'id_card/student_id_screen.dart';
import 'attendance/attendance_overview_screen.dart';
import 'profile/student_profile_screen.dart';

class StudentShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  const StudentShell({super.key, required this.userData});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StudentDashboardScreen(userData: widget.userData),
      const StudentIdScreen(),
      const AttendanceOverviewScreen(),
      const StudentProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: "Home",
                index: 0,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.badge,
                label: "ID",
                index: 1,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.event_available,
                label: "Attendance",
                index: 2,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.person,
                label: "Profile",
                index: 3,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
