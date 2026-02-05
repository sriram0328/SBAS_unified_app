import 'package:flutter/material.dart';
import '/core/colors.dart';
import '/student/attendance/attendance_history_screen.dart';
import '/student/attendance/attendance_overview_screen.dart';
import '/student/dashboard/student_dashboard_controller.dart';
import '/student/id_card/student_id_screen.dart';
import '/student/profile/student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late final StudentDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = StudentDashboardController();

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    controller.loadStudentData();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentProfileScreen(),
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                child: Icon(Icons.person),
              ),
            ),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
              ? Center(child: Text(controller.errorMessage!))
              : RefreshIndicator(
                  onRefresh: controller.loadStudentData,
                  color: Colors.blue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, ${controller.studentName}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.department,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                        Text(
                          controller.classInfo,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                        Text(
                          controller.rollNo,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 24),

                        /// Attendance Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AttendanceOverviewScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "${controller.attendancePercentage.toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Attendance",
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            _QuickActionCard(
                              icon: Icons.badge,
                              title: "My ID Card",
                              subtitle: "View Digital ID",
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentIdScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 14),
                            _QuickActionCard(
                              icon: Icons.event_available,
                              title: "Attendance",
                              subtitle: "Check History",
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AttendanceHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
