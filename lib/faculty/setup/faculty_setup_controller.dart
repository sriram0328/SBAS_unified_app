import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FacultySetupController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? errorMessage;

  String branch = "";
  String year = "";
  String section = "";
  String subject = "";
  String period = "";

  List<String> branches = [];
  List<String> years = ["1", "2", "3", "4"];
  List<String> sections = ["A", "B", "C"];
  List<String> subjects = [];
  List<String> periods = [
    "Period 1",
    "Period 2",
    "Period 3",
    "Period 4",
    "Period 5",
    "Period 6",
    "Period 7",
  ];

  Future<void> loadSetupData() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Load branches from settings
      await _loadBranches();

      // Load faculty's subjects
      await _loadFacultySubjects(user.uid);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _loadBranches() async {
    try {
      final branchesDoc = await _db.collection('settings').doc('branches').get();
      if (branchesDoc.exists) {
        final data = branchesDoc.data();
        branches = List<String>.from(data?['list'] ?? ['AIML', 'CSE', 'ECE', 'EEE']);
      } else {
        branches = ['AIML', 'CSE', 'ECE', 'EEE'];
      }
      
      if (branches.isNotEmpty && branch.isEmpty) {
        branch = branches.first;
      }
    } catch (e) {
      print("Error loading branches: $e");
      branches = ['AIML', 'CSE', 'ECE', 'EEE'];
      branch = branches.first;
    }
  }

  Future<void> _loadFacultySubjects(String facultyId) async {
    try {
      final facultyDoc = await _db.collection('faculty').doc(facultyId).get();
      if (facultyDoc.exists) {
        final data = facultyDoc.data();
        final subjectsList = List<String>.from(data?['subjects'] ?? []);
        
        // Get subject names
        subjects = [];
        for (String subjectCode in subjectsList) {
          subjects.add(subjectCode);
        }
        
        if (subjects.isNotEmpty && subject.isEmpty) {
          subject = subjects.first;
        }
      }
    } catch (e) {
      print("Error loading faculty subjects: $e");
      subjects = [];
    }
  }

  void updateBranch(String value) {
    branch = value;
    notifyListeners();
  }

  void updateYear(String value) {
    year = value;
    notifyListeners();
  }

  void updateSection(String value) {
    section = value;
    notifyListeners();
  }

  void updateSubject(String value) {
    subject = value;
    notifyListeners();
  }

  void updatePeriod(String value) {
    period = value;
    notifyListeners();
  }

  bool canStartScanner() {
    return branch.isNotEmpty &&
        year.isNotEmpty &&
        section.isNotEmpty &&
        subject.isNotEmpty &&
        period.isNotEmpty;
  }

  void startScanner(BuildContext context) {
    if (!canStartScanner()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final periodNumber = int.tryParse(period.replaceAll('Period ', '')) ?? 0;

    Navigator.pushNamed(
      context,
      '/faculty/scanner',
      arguments: {
        'branch': branch,
        'year': year,
        'section': section,
        'subject': subject,
        'periodNumber': periodNumber,
      },
    );
  }
}