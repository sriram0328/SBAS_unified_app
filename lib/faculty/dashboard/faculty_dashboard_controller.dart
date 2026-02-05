import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FacultyDashboardController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId;
  final Connectivity _connectivity = Connectivity();

  FacultyDashboardController({required this.facultyId}) {
    _initConnectivity();
    load();
  }

  bool isLoading = true;
  bool _isSyncing = false;
  bool _isConnected = true;
  DateTime? _lastSyncTime;
  String? errorMessage;

  String facultyName = '';
  String facultyCode = ''; 
  String department = '';
  String todayLabel = '';

  int classesToday = 0;
  List<TodayClass> todayClasses = [];

  bool get isSyncing => _isSyncing;
  bool get isCloudSynced => _lastSyncTime != null && _isConnected;

  void _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result.first != ConnectivityResult.none;
    
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final wasConnected = _isConnected;
      _isConnected = results.first != ConnectivityResult.none;
      
      if (_isConnected != wasConnected) {
        notifyListeners();
        
        if (_isConnected && !wasConnected) {
          load();
        }
      }
    });
  }

  Future<void> load() async {
    if (facultyName.isEmpty) {
      isLoading = true;
    } else {
      _isSyncing = true;
    }
    
    errorMessage = null;
    notifyListeners();

    try {
      await _loadFacultyProfile();
      await _loadTodayClasses();
      todayLabel = DateFormat('EEEE, d MMM').format(DateTime.now());
      
      _lastSyncTime = DateTime.now();
    } catch (e) {
      errorMessage = "Failed to load dashboard: ${e.toString()}";
      _lastSyncTime = null;
    } finally {
      isLoading = false;
      _isSyncing = false;
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
      rethrow;
    }
  }

  Future<void> _loadTodayClasses() async {
    try {
      final day = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
      
      final snap = await _db
          .collection('faculty_timetables')
          .doc(facultyId)
          .get();
          
      if (!snap.exists) {
        todayClasses = [];
        classesToday = 0;
        return;
      }

      final List? list = snap.data()?[day] as List?;
      if (list == null) {
        todayClasses = [];
        classesToday = 0;
        return;
      }

      todayClasses = list.map((e) {
        final m = Map<String, dynamic>.from(e);
        return TodayClass(
          subject: m['subjectName'] ?? 'Unknown',
          branch: m['branch'] ?? '',
          year: m['year'] ?? '',
          section: m['section'] ?? '',
          period: m['periodNumber'] ?? 0,
          periodCount: m['periodCount'] ?? 1,
          isLab: m['isLab'] ?? false,
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
  final int periodCount;
  final bool isLab;
  
  TodayClass({
    required this.subject,
    required this.branch,
    required this.year,
    required this.section,
    required this.period,
    required this.periodCount,
    required this.isLab,
    required this.start,
    required this.end,
  });
}