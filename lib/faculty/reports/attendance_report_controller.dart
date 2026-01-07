import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId;

  AttendanceReportController({required this.facultyId});

  bool isInitializing = true;
  bool isLoading = false;
  String? errorMessage;

  // Filters
  String? date; // yyyy-MM-dd
  String? subject;
  String? branch;
  String? year;
  String? section;
  int? period;

  // Options
  final List<String> dates = [];
  final List<String> subjects = [];
  final List<String> branches = [];
  final List<String> years = [];
  final List<String> sections = [];
  final List<int> periods = [];

  // Data
  final List<_Row> _allRows = [];

  // Pills
  String activeFilter = 'all';

  int totalCount = 0;
  int presentCount = 0;
  int absentCount = 0;

  List<_Row> get visibleRolls {
    if (activeFilter == 'present') {
      return _allRows.where((e) => e.present).toList();
    }
    if (activeFilter == 'absent') {
      return _allRows.where((e) => !e.present).toList();
    }
    return _allRows;
  }

  // ---------------- INIT ----------------
  Future<void> initialize() async {
    try {
      isInitializing = true;
      notifyListeners();

      final snap = await _db
          .collection('attendance')
          .where('facultyId', isEqualTo: facultyId)
          .get();

      if (snap.docs.isEmpty) {
        isInitializing = false;
        notifyListeners();
        return;
      }

      for (final d in snap.docs) {
        final m = d.data();

        final ts = m['timestamp'];
        if (ts is Timestamp) {
          final d =
              ts.toDate().toIso8601String().substring(0, 10);
          _addIfNew(dates, d);
        }

        final code = m['subjectCode'];
        final name = m['subjectName'];
        if (code != null && name != null) {
          _addIfNew(subjects, '$name ($code)');
        }

        _addIfNew(branches, m['branch']);
        _addIfNew(years, m['year']);
        _addIfNew(sections, m['section']);

        final p = m['periodNumber'];
        if (p is int && !periods.contains(p)) periods.add(p);
      }

      dates.sort();
      subjects.sort();
      branches.sort();
      years.sort();
      sections.sort();
      periods.sort();

      date = dates.first;
      subject = subjects.first;
      branch = branches.first;
      year = years.first;
      section = sections.first;
      period = periods.first;

      await refresh();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  void _addIfNew(List<String> list, dynamic v) {
    if (v != null && v is String && !list.contains(v)) {
      list.add(v);
    }
  }

  String _extractSubjectCode(String label) {
    final match = RegExp(r'\((.*?)\)').firstMatch(label);
    return match?.group(1) ?? label;
  }

  // ---------------- REFRESH (FIXED) ----------------
  Future<void> refresh() async {
    if (date == null ||
        subject == null ||
        branch == null ||
        year == null ||
        section == null ||
        period == null) return;

    try {
      isLoading = true;
      _allRows.clear();
      notifyListeners();

      final startUtc =
          DateTime.parse(date!).toUtc();
      final endUtc =
          startUtc.add(const Duration(days: 1));

      final q = await _db
          .collection('attendance')
          .where('facultyId', isEqualTo: facultyId)
          .where('branch', isEqualTo: branch)
          .where('year', isEqualTo: year)
          .where('section', isEqualTo: section)
          .where('periodNumber', isEqualTo: period)
          .where(
            'subjectCode',
            isEqualTo: _extractSubjectCode(subject!),
          )
          .where(
            'timestamp',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(startUtc),
          )
          .where(
            'timestamp',
            isLessThan:
                Timestamp.fromDate(endUtc),
          )
          .get();

      if (q.docs.isEmpty) {
        _resetCounts();
        return;
      }

      final Set<String> enrolled = {};
      final Set<String> present = {};

      for (final d in q.docs) {
        final m = d.data();

        enrolled.addAll(
          List<String>.from(m['enrolledStudentIds'] ?? []),
        );

        present.addAll(
          List<String>.from(m['presentStudentIds'] ?? []),
        );
      }

      // Fetch student details from students collection
      final Map<String, String> studentNames = {};
      
      for (final id in enrolled) {
        try {
          // Query by rollno field instead of document ID
          final studentQuery = await _db
              .collection('students')
              .where('rollno', isEqualTo: id)
              .limit(1)
              .get();
          
          if (studentQuery.docs.isNotEmpty) {
            final data = studentQuery.docs.first.data();
            final studentName = data['name'];
            
            if (studentName != null && studentName.isNotEmpty) {
              studentNames[id] = studentName;
            } else {
              studentNames[id] = id;
            }
          } else {
            studentNames[id] = id;
          }
        } catch (e) {
          print('Error fetching student $id: $e');
          studentNames[id] = id;
        }
      }

      for (final id in enrolled) {
        _allRows.add(
          _Row(
            roll: id,
            name: studentNames[id] ?? id,
            present: present.contains(id),
          ),
        );
      }

      // Sort by roll number in ascending order
      _allRows.sort((a, b) => a.roll.compareTo(b.roll));

      totalCount = enrolled.length;
      presentCount = present.length;
      absentCount = totalCount - presentCount;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetCounts() {
    totalCount = 0;
    presentCount = 0;
    absentCount = 0;
  }

  // ---------------- FILTER UPDATE ----------------
  void updateFilter({
    String? dateValue,
    String? subjectValue,
    String? branchValue,
    String? yearValue,
    String? sectionValue,
    int? periodValue,
    String? pill,
  }) {
    if (dateValue != null) date = dateValue;
    if (subjectValue != null) subject = subjectValue;
    if (branchValue != null) branch = branchValue;
    if (yearValue != null) year = yearValue;
    if (sectionValue != null) section = sectionValue;
    if (periodValue != null) period = periodValue;
    if (pill != null) activeFilter = pill;

    refresh();
  }

  // ---------------- DOWNLOAD CSV ----------------
  String generateCSV() {
    final buffer = StringBuffer();
    
    // Main Heading
    final dateFormatted = date != null 
        ? DateTime.parse(date!).toLocal().toString().split(' ')[0].split('-').reversed.join('-')
        : '';
    buffer.writeln('$year $branch-$section $dateFormatted');
    buffer.writeln('Subject: $subject');
    buffer.writeln('Period: $period');
    buffer.writeln('');
    
    // Header
    buffer.writeln('Roll Number,Name,Status');
    
    // Get the rows based on active filter
    final List<_Row> rowsToExport;
    if (activeFilter == 'present') {
      rowsToExport = _allRows.where((e) => e.present).toList();
    } else if (activeFilter == 'absent') {
      rowsToExport = _allRows.where((e) => !e.present).toList();
    } else {
      rowsToExport = _allRows;
    }
    
    // Data rows
    for (final row in rowsToExport) {
      buffer.writeln('${row.roll},${row.name},${row.present ? 'Present' : 'Absent'}');
    }
    
    buffer.writeln('');
    buffer.writeln('Total: $totalCount, Present: $presentCount, Absent: $absentCount');
    
    return buffer.toString();
  }

  // ---------------- DOWNLOAD PDF ----------------
  String getReportHeading() {
    final dateFormatted = date != null 
        ? DateTime.parse(date!).toLocal().toString().split(' ')[0].split('-').reversed.join('-')
        : '';
    return '$year $branch-$section $dateFormatted';
  }

  String getSubjectInfo() {
    return 'Subject: $subject | Period: $period';
  }
}

// ---------------- MODEL ----------------
class _Row {
  final String roll;
  final String name;
  final bool present;

  _Row({
    required this.roll,
    required this.name,
    required this.present,
  });
}