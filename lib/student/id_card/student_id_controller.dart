import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentIdController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? errorMessage;

  String institutionName = "INSTITUTION NAME";
  String studentName = "";
  String role = "Student";
  String rollNo = "";
  String branch = "";
  String year = "";
  String section = "";

  String get barcodeData => rollNo;

  Future<void> loadStudentData() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Query by rollno field
      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('rollno', isEqualTo: rollNo)
          .limit(1)
          .get();

      if (studentsQuery.docs.isEmpty) {
        throw Exception("Student data not found");
      }

      final userData = studentsQuery.docs.first.data();

      studentName = userData['name'] ?? '';
      rollNo = userData['rollno'] ?? '';
      branch = userData['branch'] ?? '';
      year = userData['year'] ?? '';
      section = userData['section'] ?? '';
      
      // Get institution name from settings collection (optional)
      try {
        final settingsDoc = await _firestoreService.getDocument('settings', 'institution');
        if (settingsDoc.exists) {
          final settingsData = settingsDoc.data() as Map<String, dynamic>?;
          institutionName = settingsData?['name'] ?? institutionName;
        }
      } catch (e) {
        debugPrint("Could not fetch institution name: $e");
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}