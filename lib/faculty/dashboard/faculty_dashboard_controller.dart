// lib/faculty/dashboard/faculty_dashboard_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FacultyDashboardController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId;

  FacultyDashboardController({required this.facultyId}) {
    _initSyncListener(); 
  }

  bool isLoading = true;
  bool isSyncing = false; 
  String? errorMessage;

  String facultyName = '';
  String facultyCode = ''; 
  String department = '';
  String todayLabel = '';

  int classesToday = 0;
  List<TodayClass> todayClasses = [];

  // Listen for background sync status
  void _initSyncListener() {
    _db.snapshotsInSync().listen((_) async {
      // Check for pending writes in any collection (e.g., attendance)
      final snap = await _db.collection('attendance').snapshots().first;
      isSyncing = snap.metadata.hasPendingWrites;
      notifyListeners();
    });
  }

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
      if (!snap.exists) throw Exception("Profile not found");
      final data = snap.data()!;
      facultyName = data['name'] ?? 'Unknown Faculty';
      facultyCode = data['facultyId'] ?? facultyId;
      department = data['department'] ?? '';
    } catch (e) {
      debugPrint("❌ Profile error: $e");
      rethrow;
    }
  }

  Future<void> _loadTodayClasses() async {
    try {
      final day = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
      final snap = await _db.collection('faculty_timetables').doc(facultyId).get();
      if (!snap.exists) return;
      final List? list = snap.data()?[day] as List?;
      if (list == null) return;

      todayClasses = list.map((e) {
        final m = Map<String, dynamic>.from(e);
        return TodayClass(
          subject: m['subjectName'] ?? 'Unknown',
          branch: m['branch'] ?? '',
          year: m['year'] ?? '',
          section: m['section'] ?? '',
          period: m['periodNumber'] ?? 0,
          start: m['startTime'] ?? '',
          end: m['endTime'] ?? '',
        );
      }).toList();
      classesToday = todayClasses.length;
    } catch (e) {
      todayClasses = [];
      classesToday = 0;
    }
  }

  void refresh() => load();
}

class TodayClass {
  final String subject, branch, year, section, start, end;
  final int period;
  TodayClass({required this.subject, required this.branch, required this.year, required this.section, required this.period, required this.start, required this.end});
}