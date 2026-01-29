//import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class LongReportsController extends ChangeNotifier {
  final String facultyId;
  
  String? selectedYear, selectedBranch, selectedSection, selectedSubject, selectedMonth;
  List<String> years = [], branches = [], sections = [], months = [], classStudents = [];
  List<Map<String, dynamic>> subjects = [], attendanceData = [];
  
  bool isLoading = false;
  bool isGenerating = false;

  LongReportsController({required this.facultyId}) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance.collection('faculty_timetables').doc(facultyId).get();
      months = List.generate(12, (i) => DateFormat('yyyy-MM').format(DateTime(DateTime.now().year, DateTime.now().month - i, 1)));
      
      if (doc.exists) {
        final data = doc.data()!;
        final Set<String> y = {}, b = {}, s = {};
        for (var day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']) {
          if (data[day] is List) {
            for (var entry in data[day]) {
              y.add(entry['year'].toString());
              b.add(entry['branch'].toString());
              s.add(entry['section'].toString());
            }
          }
        }
        years = y.toList()..sort();
        branches = b.toList()..sort();
        sections = s.toList()..sort();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchReportData() async {
    isGenerating = true;
    attendanceData = [];
    notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance.collection('attendance')
          .where('year', isEqualTo: selectedYear)
          .where('branch', isEqualTo: selectedBranch)
          .limit(1).get();
      if (snap.docs.isEmpty) return false;
      classStudents = List<String>.from(snap.docs.first.data()['enrolledStudentIds'] ?? []);

      for (int i = 0; i < classStudents.length; i += 10) {
        final batch = classStudents.skip(i).take(10).toList();
        final summarySnap = await FirebaseFirestore.instance.collection('attendance_summaries')
            .where('month', isEqualTo: selectedMonth)
            .where('rollNo', whereIn: batch).get();
        attendanceData.addAll(summarySnap.docs.map((d) => d.data()));
      }
      attendanceData.sort((a, b) => a['rollNo'].compareTo(b['rollNo']));
      return attendanceData.isNotEmpty;
    } catch (e) { return false; } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  List<String> getDaysInMonth() {
    final year = int.parse(selectedMonth!.split('-')[0]);
    final month = int.parse(selectedMonth!.split('-')[1]);
    final totalDays = DateTime(year, month + 1, 0).day;
    return List.generate(totalDays, (i) => '$selectedMonth-${(i + 1).toString().padLeft(2, '0')}');
  }

  ({List<String> dailyStrings, String totalString}) calculateStudentStats(Map<String, dynamic> student) {
    final byDate = student['byDate'] as Map<String, dynamic>? ?? {};
    final days = getDaysInMonth();
    List<String> daily = [];
    int pTotal = 0, hTotal = 0;
    for (var date in days) {
      int dP = 0, dH = 0;
      final periods = byDate[date]?['periods'] as Map<String, dynamic>?;
      if (periods != null) {
        for (var p in periods.values) {
          if (p['subjectCode'] == selectedSubject) {
            dH++; if (p['isPresent'] == true) dP++;
          }
        }
      }
      daily.add(dH > 0 ? '$dP/$dH' : '-');
      pTotal += dP; hTotal += dH;
    }
    return (dailyStrings: daily, totalString: '$pTotal/$hTotal');
  }

  Map<String, String> calculateDailyClassTotals() {
    final days = getDaysInMonth();
    Map<String, String> totals = {};
    for (var date in days) {
      int dayPresent = 0, dayHeld = 0;
      for (var student in attendanceData) {
        final periods = (student['byDate'] as Map? ?? {})[date]?['periods'] as Map?;
        if (periods != null) {
          for (var p in periods.values) {
            if (p['subjectCode'] == selectedSubject) {
              dayHeld++; if (p['isPresent'] == true) dayPresent++;
            }
          }
        }
      }
      totals[date] = dayHeld > 0 ? '$dayPresent/$dayHeld' : '-';
    }
    return totals;
  }

  Future<void> printReport() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final days = getDaysInMonth();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      theme: pw.ThemeData.withFont(base: font),
      build: (context) => [
        pw.Text('Attendance: $selectedYear-$selectedBranch-$selectedSection | $selectedSubject', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Roll No', ...days.map((d) => d.split('-').last), 'Total'],
          data: attendanceData.map((s) {
            final stats = calculateStudentStats(s);
            return [s['rollNo'], ...stats.dailyStrings, stats.totalString];
          }).toList(),
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void setYear(String? v) { selectedYear = v; subjects = []; notifyListeners(); }
  void setBranch(String? v) { selectedBranch = v; notifyListeners(); }
  void setSection(String? v) { selectedSection = v; _loadSubjects(); notifyListeners(); }
  void setSubject(String? v) { selectedSubject = v; notifyListeners(); }
  void setMonth(String? v) { selectedMonth = v; notifyListeners(); }

  Future<void> _loadSubjects() async {
    isLoading = true; notifyListeners();
    final doc = await FirebaseFirestore.instance.collection('faculty_timetables').doc(facultyId).get();
    final data = doc.data()!;
    final Map<String, Map<String, dynamic>> subs = {};
    for (var d in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']) {
      if (data[d] is List) {
        for (var e in data[d]) {
          if (e['year'] == selectedYear && e['branch'] == selectedBranch && e['section'] == selectedSection) {
            subs[e['subjectCode']] = {'code': e['subjectCode'], 'name': e['subjectName'] ?? e['subjectCode']};
          }
        }
      }
    }
    subjects = subs.values.toList();
    isLoading = false; notifyListeners();
  }

  bool get canGenerate => selectedYear != null && selectedBranch != null && selectedSection != null && selectedSubject != null && selectedMonth != null;
}