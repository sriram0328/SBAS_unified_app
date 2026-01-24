import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId;

  AttendanceReportController({required this.facultyId});

  bool isInitializing = true;
  bool isLoading = false;
  String? errorMessage;

  String? date; 
  String? subject;
  String? branch;
  String? year;
  String? section;
  int? period;
  String searchQuery = ""; 

  final List<String> dates = [];
  final List<String> subjects = [];
  final List<String> branches = [];
  final List<String> years = [];
  final List<String> sections = [];
  final List<int> periods = [];

  final List<_Row> _allRows = [];
  final Map<String, String> _studentNameCache = {}; 
  String activeFilter = 'all';

  int totalCount = 0;
  int presentCount = 0;
  int absentCount = 0;

  List<_Row> get visibleRolls {
    List<_Row> filtered = _allRows;
    if (activeFilter == 'present') filtered = filtered.where((e) => e.present).toList();
    else if (activeFilter == 'absent') filtered = filtered.where((e) => !e.present).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
        e.roll.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    return filtered;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      isInitializing = true;
      notifyListeners();
      final snap = await _db.collection('attendance').where('facultyId', isEqualTo: facultyId).get();
      if (snap.docs.isEmpty) { isInitializing = false; notifyListeners(); return; }

      for (final d in snap.docs) {
        final m = d.data();
        final ts = m['timestamp'];
        if (ts is Timestamp) _addIfNew(dates, ts.toDate().toIso8601String().substring(0, 10));
        final code = m['subjectCode'];
        final name = m['subjectName'];
        if (code != null && name != null) _addIfNew(subjects, '$name ($code)');
        _addIfNew(branches, m['branch']);
        _addIfNew(years, m['year']);
        _addIfNew(sections, m['section']);
        final p = m['periodNumber'];
        if (p is int && !periods.contains(p)) periods.add(p);
      }

      for (var list in [dates, subjects, branches, years, sections]) { list.sort(); }
      periods.sort();

      date = dates.isNotEmpty ? dates.first : null;
      subject = subjects.isNotEmpty ? subjects.first : null;
      branch = branches.isNotEmpty ? branches.first : null;
      year = years.isNotEmpty ? years.first : null;
      section = sections.isNotEmpty ? sections.first : null;
      period = periods.isNotEmpty ? periods.first : null;

      await refresh();
    } catch (e) { errorMessage = e.toString(); } 
    finally { isInitializing = false; notifyListeners(); }
  }

  void _addIfNew(List<String> list, dynamic v) {
    if (v != null && v is String && !list.contains(v)) list.add(v);
  }

  String _extractSubjectCode(String label) {
    final match = RegExp(r'\((.*?)\)').firstMatch(label);
    return match?.group(1) ?? label;
  }

  Future<void> refresh() async {
    if (date == null || subject == null || branch == null || year == null || section == null || period == null) return;
    try {
      isLoading = true; _allRows.clear(); notifyListeners();
      final startUtc = DateTime.parse(date!).toUtc();
      final endUtc = startUtc.add(const Duration(days: 1));

      final q = await _db.collection('attendance')
          .where('facultyId', isEqualTo: facultyId)
          .where('branch', isEqualTo: branch)
          .where('year', isEqualTo: year)
          .where('section', isEqualTo: section)
          .where('periodNumber', isEqualTo: period)
          .where('subjectCode', isEqualTo: _extractSubjectCode(subject!))
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
          .where('timestamp', isLessThan: Timestamp.fromDate(endUtc))
          .get();

      if (q.docs.isEmpty) { _resetCounts(); return; }

      final Set<String> enrolled = {};
      final Set<String> present = {};

      for (final d in q.docs) {
        final m = d.data();
        enrolled.addAll(List<String>.from(m['enrolledStudentIds'] ?? []));
        present.addAll(List<String>.from(m['presentStudentIds'] ?? []));
      }

      final List<String> enrolledList = enrolled.toList();
      final List<String> rollsToFetch = enrolledList.where((id) => !_studentNameCache.containsKey(id)).toList();
      
      for (var i = 0; i < rollsToFetch.length; i += 30) {
        final end = (i + 30 < rollsToFetch.length) ? i + 30 : rollsToFetch.length;
        final batch = rollsToFetch.sublist(i, end);
        final studentSnap = await _db.collection('students').where('rollno', whereIn: batch).get();
        for (final doc in studentSnap.docs) {
          final data = doc.data();
          _studentNameCache[data['rollno']] = data['name'] ?? data['rollno'];
        }
      }

      for (final id in enrolledList) {
        _allRows.add(_Row(roll: id, name: _studentNameCache[id] ?? id, present: present.contains(id)));
      }

      _allRows.sort((a, b) => a.roll.compareTo(b.roll));
      totalCount = enrolled.length;
      presentCount = present.length;
      absentCount = totalCount - presentCount;
    } catch (e) { errorMessage = e.toString(); } 
    finally { isLoading = false; notifyListeners(); }
  }

  void _resetCounts() { totalCount = 0; presentCount = 0; absentCount = 0; }

  void updateFilter({String? dateValue, String? subjectValue, String? branchValue, String? yearValue, String? sectionValue, int? periodValue, String? pill}) {
    if (dateValue != null) {
      date = dateValue;
      if (!dates.contains(dateValue)) { dates.add(dateValue); dates.sort(); }
    }
    if (subjectValue != null) subject = subjectValue;
    if (branchValue != null) branch = branchValue;
    if (yearValue != null) year = yearValue;
    if (sectionValue != null) section = sectionValue;
    if (periodValue != null) period = periodValue;
    if (pill != null) activeFilter = pill;
    refresh();
  }

  String generateCSV() {
    final buffer = StringBuffer();
    final dFmt = date?.split('-').reversed.join('-') ?? '';
    buffer.writeln('$year $branch-$section $dFmt\nSubject: $subject\nPeriod: $period\n');
    buffer.writeln('Roll Number,Name,Status');
    for (final row in visibleRolls) { buffer.writeln('${row.roll},${row.name},${row.present ? 'Present' : 'Absent'}'); }
    buffer.writeln('\nTotal: $totalCount, Present: $presentCount, Absent: $absentCount');
    return buffer.toString();
  }

  String getReportHeading() => '$year $branch-$section ${date?.split('-').reversed.join('-') ?? ''}';
  String getSubjectInfo() => 'Subject: $subject | Period: $period';
}

class _Row {
  final String roll;
  final String name;
  final bool present;
  _Row({required this.roll, required this.name, required this.present});
}