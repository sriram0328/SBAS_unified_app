import 'package:flutter/material.dart';

class FacultySetupController extends ChangeNotifier {
  // ---------------------------
  // Selected values
  // ---------------------------
  String branch = "AIML";
  String year = "4";
  String semester = "1";
  String section = "A";
  String subject = "Machine Learning";
  String period = "Period 1";

  // ---------------------------
  // Options (match DB)
  // ---------------------------
  final branches = ["AIML", "AIDS", "CSE", "ECE"];
  final years = ["1", "2", "3", "4"];
  final semesters = ["1", "2"];
  final sections = ["A", "B", "C"];
  final subjects = ["Machine Learning", "ML LAB", "BDA", "BDA LAB"];
  final periods = [
    "Period 1",
    "Period 2",
    "Period 3",
    "Period 4",
    "Period 5",
    "Period 6"
  ];

  // ---------------------------
  // Update methods
  // ---------------------------
  void updateBranch(String v) {
    branch = v;
    notifyListeners();
  }

  void updateYear(String v) {
    year = v;
    notifyListeners();
  }

  void updateSemester(String v) {
    semester = v;
    notifyListeners();
  }

  void updateSection(String v) {
    section = v;
    notifyListeners();
  }

  void updateSubject(String v) {
    subject = v;
    notifyListeners();
  }

  void updatePeriod(String v) {
    period = v;
    notifyListeners();
  }

  // ---------------------------
  // Validation
  // ---------------------------
  bool canStartScanner() {
    return branch.isNotEmpty &&
        year.isNotEmpty &&
        semester.isNotEmpty &&
        section.isNotEmpty &&
        subject.isNotEmpty &&
        period.isNotEmpty;
  }

  // ---------------------------
  // Derived values
  // ---------------------------
  int get periodNumber =>
      int.tryParse(period.replaceAll("Period ", "")) ?? 0;

  // ---------------------------
  // Scanner payload (single truth)
  // ---------------------------
  Map<String, dynamic> get scannerArgs => {
        'branch': branch,
        'year': year,
        'semester': semester,
        'section': section,
        'subject': subject,
        'periodNumber': periodNumber,
      };
}
