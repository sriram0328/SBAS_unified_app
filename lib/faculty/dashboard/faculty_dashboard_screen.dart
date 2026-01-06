// lib/faculty/dashboard/faculty_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'faculty_dashboard_controller.dart';
import '../setup/faculty_setup_screen.dart';
import '../reports/attendance_report_screen.dart';

class FacultyDashboardScreen extends StatelessWidget {
  final String facultyId;

  const FacultyDashboardScreen({
    super.key,
    required this.facultyId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FacultyDashboardController(facultyId: facultyId)..load(),
      child: const _FacultyDashboardView(),
    );
  }
}

class _FacultyDashboardView extends StatelessWidget {
  const _FacultyDashboardView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FacultyDashboardController>();

    if (c.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (c.errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(c.errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(c),
            const SizedBox(height: 16),
            _todayCard(c),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _quickActions(context),
            const SizedBox(height: 24),
            if (c.todayClasses.isNotEmpty) ...[
              const Text(
                "Today's Classes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...c.todayClasses.map(_classTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(FacultyDashboardController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome', style: TextStyle(color: Colors.grey)),
        Text(
          c.facultyName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text('ID : ${c.facultyCode}',
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _todayCard(FacultyDashboardController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule),
          const SizedBox(width: 12),
          Text('${c.classesToday} classes today'),
        ],
      ),
    );
  }

  /// ✅ FIXED: Clickable Quick Actions
  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.qr_code_scanner,
            label: 'Start Attendance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FacultySetupScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.fact_check,
            label: 'View Reports',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceReportScreen(
                    facultyId:
                        context.read<FacultyDashboardController>().facultyId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ✅ IMPORTANT: InkWell + Material
  Widget _actionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classTile(TodayClass c) {
    return Card(
      child: ListTile(
        title: Text(c.subject),
        subtitle: Text('${c.year} ${c.branch} ${c.section}'),
        trailing: Text('P${c.period}'),
      ),
    );
  }
}
