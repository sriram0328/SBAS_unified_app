import 'package:flutter/material.dart';
import '../student/student_shell.dart';
import '../faculty/faculty_shell.dart';

class RoleRouter extends StatelessWidget {
  final Map<String, dynamic> userData;

  const RoleRouter({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final role = userData['role'];

    if (role == 'student') {
      return StudentShell(userData: userData);
    } else if (role == 'faculty') {
      return FacultyShell(userData: userData);
    } else {
      // Fallback for an unknown role or error
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error: Unknown user role.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Go Back to Login"),
              )
            ],
          ),
        ),
      );
    }
  }
}