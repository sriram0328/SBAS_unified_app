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

      for (final id in enrolled) {
        _allRows.add(
          _Row(
            roll: id,
            name: id,
            present: present.contains(id),
          ),
        );
      }

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
