// lib/faculty/dashboard/faculty_dashboard_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FacultyDashboardController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId; // AUTH UID / doc id

  FacultyDashboardController({required this.facultyId});

  bool isLoading = true;
  String? errorMessage;

  String facultyName = '';
  String facultyCode = ''; // FAC123
  String department = '';
  String todayLabel = '';

  int classesToday = 0;
  List<TodayClass> todayClasses = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _loadFacultyProfile();
      await _loadTodayClasses();
      todayLabel = DateFormat('EEEE, d MMM').format(DateTime.now());
    } catch (e) {
      errorMessage = "Failed to load dashboard: ${e.toString()}";
      debugPrint("❌ Dashboard load error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFacultyProfile() async {
    try {
      final snap = await _db.collection('faculty').doc(facultyId).get();
      
      if (!snap.exists) {
        throw Exception("Faculty profile not found");
      }

      final data = snap.data();
      if (data == null) {
        throw Exception("Faculty data is null");
      }

      facultyName = data['name'] ?? 'Unknown Faculty';
      facultyCode = data['facultyId'] ?? facultyId;
      department = data['department'] ?? '';
      
      debugPrint("✅ Faculty profile loaded: $facultyName ($facultyCode)");
    } catch (e) {
      debugPrint("❌ Error loading faculty profile: $e");
      rethrow;
    }
  }

  Future<void> _loadTodayClasses() async {
    try {
      final day = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
      debugPrint("📅 Loading timetable for: $day");

      final snap = await _db
          .collection('faculty_timetables')
          .doc(facultyId)
          .get();

      if (!snap.exists) {
        debugPrint("ℹ️ No timetable document found for faculty: $facultyId");
        todayClasses = [];
        classesToday = 0;
        return;
      }

      final data = snap.data();
      if (data == null) {
        debugPrint("ℹ️ Timetable data is null");
        todayClasses = [];
        classesToday = 0;
        return;
      }

      final List? list = data[day] as List?;

      if (list == null || list.isEmpty) {
        debugPrint("ℹ️ No classes scheduled for $day");
        todayClasses = [];
        classesToday = 0;
        return;
      }

      todayClasses = list.map((e) {
        final m = Map<String, dynamic>.from(e);
        return TodayClass(
          subject: m['subjectName'] ?? 'Unknown Subject',
          branch: m['branch'] ?? '',
          year: m['year'] ?? '',
          section: m['section'] ?? '',
          period: m['periodNumber'] ?? 0,
          start: m['startTime'] ?? '',
          end: m['endTime'] ?? '',
        );
      }).toList();

      classesToday = todayClasses.length;
      debugPrint("✅ Loaded ${todayClasses.length} classes for today");
    } catch (e) {
      debugPrint("❌ Error loading today's classes: $e");
      // Don't throw - just set empty state
      todayClasses = [];
      classesToday = 0;
    }
  }

  void refresh() {
    load();
  }
}

class TodayClass {
  final String subject;
  final String branch;
  final String year;
  final String section;
  final int period;
  final String start;
  final String end;

  TodayClass({
    required this.subject,
    required this.branch,
    required this.year,
    required this.section,
    required this.period,
    required this.start,
    required this.end,
  });
}