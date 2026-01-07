import 'package:flutter/material.dart';
import 'student_profile_controller.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final StudentProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = StudentProfileController();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("My Profile"),
        actions: [
          if (!controller.isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => controller.editProfile(context),
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    child: const Icon(Icons.person,
                        size: 44, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _SectionCard(
                    title: "Academic Details",
                    children: [
                      _InfoRow("Roll No", controller.rollNo),
                      _InfoRow("Branch", controller.branch),
                      _InfoRow("Section", controller.section),
                      _InfoRow("Year", controller.year),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "Contact Information",
                    children: [
                      _InfoRow("Phone", controller.phone.isNotEmpty
                          ? controller.phone
                          : 'Not provided'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "Settings",
                    children: [
                      _ActionRow(
                        title: "Logout",
                        onTap: () => controller.logout(context),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionRow({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.black,
                fontWeight:
                    isDestructive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}