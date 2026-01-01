import 'package:flutter/material.dart';

class FacultySetupController extends ChangeNotifier {
  // Selected values
  String branch = "AIML";
  String year = "4";
  String section = "A";
  String subject = "Machine Learning";
  String period = "Period 1";

  // Static options (later replace with Firestore / timetable)
  final branches = ["AIML", "AIDS", "CSE", "ECE"];
  final years = ["1", "2", "3", "4"];
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

  // Update methods
  void updateBranch(String v) {
    branch = v;
    notifyListeners();
  }

  void updateYear(String v) {
    year = v;
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

  // Validation
  bool canStartScanner() {
    return branch.isNotEmpty &&
        year.isNotEmpty &&
        section.isNotEmpty &&
        subject.isNotEmpty &&
        period.isNotEmpty;
  }

  // Extract period number
  int get periodNumber =>
      int.tryParse(period.replaceAll("Period ", "")) ?? 0;

  // Prepare scanner arguments (single source of truth)
  Map<String, dynamic> get scannerArgs => {
        'branch': branch,
        'year': year,
        'section': section,
        'subject': subject,
        'periodNumber': periodNumber,
      };
}
