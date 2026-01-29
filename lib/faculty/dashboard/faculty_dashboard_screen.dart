import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'faculty_dashboard_controller.dart';
import '../setup/faculty_setup_screen.dart';
import '../reports/attendance_report_screen.dart';
import '../long_reports/long_reports_screen.dart';

class FacultyDashboardScreen extends StatelessWidget {
  final String facultyId;
  const FacultyDashboardScreen({super.key, required this.facultyId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FacultyDashboardController(facultyId: facultyId),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  void _showProfile(BuildContext context, FacultyDashboardController c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFF1F4F9),
                child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
              ),
              const SizedBox(height: 16),
              Text(c.facultyName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('ID: ${c.facultyCode}',
                  style: const TextStyle(color: Colors.grey)),
              Text('Dept: ${c.department}',
                  style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      debugPrint('❌ Logout error: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FacultyDashboardController>();

    if (c.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FD),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        onRefresh: () => c.load(),
        color: Colors.blueAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(c, context),
              const SizedBox(height: 20),
              _statusCard(c),
              const SizedBox(height: 20),
              _heroCard(context, c),
              const SizedBox(height: 24),
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _quickActions(context, c),
              const SizedBox(height: 24),
              if (c.todayClasses.isNotEmpty) ...[
                const Text("Today's Classes",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...c.todayClasses.map(_classTile),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(FacultyDashboardController c, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Text('WELCOME BACK',
                  style: TextStyle(
                      color: Colors.grey, fontSize: 11, letterSpacing: 1.1)),
              const SizedBox(width: 8),
              _SyncIcon(
                isSyncing: c.isSyncing,
                isCloudSynced: c.isCloudSynced,
              ),
            ],
          ),
          Text(c.facultyName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text('ID : ${c.facultyCode}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text('Dept : ${c.department}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        GestureDetector(
          onTap: () => _showProfile(context, c),
          child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blueAccent)),
        ),
      ],
    );
  }

  Widget _statusCard(FacultyDashboardController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 8),
        Row(children: [
          Text(c.classesToday.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Text('Classes Today', style: TextStyle(color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _heroCard(BuildContext context, FacultyDashboardController c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2962FF), Color(0xFF0039CB)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.shade700, width: 1.5),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => FacultySetupScreen(facultyId: c.facultyId))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
            const SizedBox(height: 16),
            const Text('Start Attendance',
                style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Scan Barcodes',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ]),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, FacultyDashboardController c) {
    return Row(children: [
      Expanded(
          child: _actionCard(
              icon: Icons.assignment_outlined,
              label: 'Class Reports',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LongReportsScreen(facultyId: c.facultyId))))),
      const SizedBox(width: 16),
      Expanded(
          child: _actionCard(
              icon: Icons.fact_check_outlined,
              label: 'View Reports',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AttendanceReportScreen(facultyId: c.facultyId))))),
    ]);
  }

  Widget _actionCard(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Column(children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
          ]),
        ),
      ),
    );
  }

  Widget _classTile(TodayClass c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: c.isLab 
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_outlined, color: Colors.purple, size: 20),
              )
            : null,
        title: Text(c.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${c.year} ${c.branch} ${c.section}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: c.isLab ? Colors.purple.withValues(alpha: 0.1) : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            c.periodCount > 1 ? 'P${c.period}-P${c.period + c.periodCount - 1}' : 'P${c.period}',
            style: TextStyle(
                color: c.isLab ? Colors.purple : Colors.blueAccent, 
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _SyncIcon extends StatefulWidget {
  final bool isSyncing;
  final bool isCloudSynced;
  
  const _SyncIcon({
    required this.isSyncing,
    required this.isCloudSynced,
  });

  @override
  State<_SyncIcon> createState() => _SyncIconState();
}

class _SyncIconState extends State<_SyncIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSyncing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSyncing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show orange when: syncing, not synced, or no network
    // ✅ Show green when: synced AND connected to network
    final showOrange = widget.isSyncing || !widget.isCloudSynced;
    
    return FadeTransition(
      opacity: widget.isSyncing ? _opacityAnimation : const AlwaysStoppedAnimation(1.0),
      child: Icon(
        widget.isSyncing 
            ? Icons.cloud_upload_rounded 
            : (widget.isCloudSynced 
                ? Icons.cloud_done_rounded 
                : Icons.cloud_off_rounded),
        size: 14,
        color: showOrange ? Colors.orange : Colors.green,
      ),
    );
  }
}