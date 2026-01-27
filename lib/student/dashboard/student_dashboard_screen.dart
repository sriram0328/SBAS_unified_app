import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
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
          )
        ],
      ),
      drawer: _buildDrawer(context),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
              ? Center(child: Text(controller.errorMessage!))
              : RefreshIndicator(
                  // ✅ ADDED: Pull-to-refresh
                  onRefresh: () => controller.loadStudentData(),
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
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          controller.classInfo,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          controller.rollNo,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),

                        /// 🔥 REAL ATTENDANCE CARD
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceOverviewScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
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
                                  style: TextStyle(color: AppColors.textSecondary),
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
                                    builder: (_) => const StudentIdScreen(),
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
                                    builder: (_) => const AttendanceHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        // ✅ ADDED: Extra space for pull-to-refresh
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// ================= DRAWER =================
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F6BED), Color(0xFF2196F3)],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF4F6BED)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.studentName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          controller.classInfo,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          controller.rollNo,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _DrawerItem(
            icon: Icons.home,
            title: "Dashboard",
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.badge,
            title: "My ID Card",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentIdScreen()),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.event_available,
            title: "Attendance",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceOverviewScreen()),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.person,
            title: "Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
              );
            },
          ),
          const Divider(),
          
          // ✅ FIXED: Logout with Firebase Auth
          _DrawerItem(
            icon: Icons.logout,
            title: "Logout",
            textColor: Colors.red,
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logout failed. Please try again.')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// ================= DRAWER ITEM =================
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.black87),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black87)),
      onTap: onTap,
    );
  }
}

/// ================= QUICK ACTION CARD =================
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
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}