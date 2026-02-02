// student_profile_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = true;
  String name = "";
  String email = "";
  String phone = "";
  String rollNo = "";
  String branch = "";
  String section = "";
  String year = "";

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  Future<void> loadStudentData() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await _db.collection('students').doc(user.uid).get();

      if (!doc.exists) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = doc.data()!;
      name = data['name'] ?? '';
      email = data['email'] ?? '';
      phone = data['studentPhone'] ?? '';
      rollNo = data['rollno'] ?? '';
      branch = data['branch'] ?? '';
      section = data['section'] ?? '';
      
      // Fetch year from academic_records collection
      try {
        final academicRecordsQuery = await _db
            .collection('academic_records')
            .where('studentId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (academicRecordsQuery.docs.isNotEmpty) {
          final academicData = academicRecordsQuery.docs.first.data();
          final yearOfStudy = academicData['yearOfStudy'];
          year = yearOfStudy?.toString() ?? '';
        } else {
          year = '';
        }
      } catch (e) {
        print('Error fetching academic records: $e');
        year = '';
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading student data: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void editProfile(BuildContext context) {
    nameController.text = name;
    phoneController.text = phone;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _saveProfile(context),
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.collection('students').doc(user.uid).update({
        'name': nameController.text,
        'studentPhone': phoneController.text,
      });

      name = nameController.text;
      phone = phoneController.text;
      
      notifyListeners();
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      await _auth.signOut();

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}