import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentIdController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = true;

  // Institution
  String institutionName = "INSTITUTION NAME";

  // Student Info
  String studentName = "";
  String role = "Student";
  String rollNo = "";
  String branch = "";
  String section = "";
  String year = "";

  /// Barcode value (same as React logic)
  String get barcodeData => rollNo;

  /// Branch & section display
  String get branchDisplay => "$branch - $section";

  /// ----------------------------
  /// LOAD STUDENT ID DATA
  /// ----------------------------
  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      /// 1️⃣ Fetch student document
      final studentDoc =
          await _db.collection('students').doc(user.uid).get();

      if (!studentDoc.exists) {
        throw Exception("Student record not found");
      }

      final studentData = studentDoc.data()!;
      studentName = studentData['name'] ?? '';
      rollNo = studentData['rollno'] ?? '';
      branch = studentData['branch'] ?? '';
      section = studentData['section'] ?? '';

      /// 2️⃣ Fetch academic record for YEAR
      final academicSnap = await _db
          .collection('academic_records')
          .where('studentId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (academicSnap.docs.isNotEmpty) {
        year = academicSnap.docs.first
            .data()['yearOfStudy']
            .toString();
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading ID data: $e");
      isLoading = false;
      notifyListeners();
    }
  }
}
