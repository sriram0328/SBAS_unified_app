import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// ===============================================================
/// REPORT RANGE
/// ===============================================================
enum ReportRange {
  fullMonth,
  firstHalf,  // 1–15 (excluding Sundays)
  secondHalf, // 16–end (excluding Sundays)
}

class LongReportsController extends ChangeNotifier {
  final String facultyId;
  LongReportsController({required this.facultyId});

  String? _year, _branch, _section, _subject, _month;

  String? get year => _year;
  set year(String? value) {
    _year = value;
    _subject = null;
    _month = null;
    notifyListeners();
  }

  String? get branch => _branch;
  set branch(String? value) {
    _branch = value;
    _subject = null;
    _month = null;
    notifyListeners();
  }

  String? get section => _section;
  set section(String? value) {
    _section = value;
    _subject = null;
    _month = null;
    notifyListeners();
  }

  String? get subject => _subject;
  set subject(String? value) {
    _subject = value;
    _month = null;
    fetchAvailableMonths();
    notifyListeners();
  }

  String? get month => _month;
  set month(String? value) {
    _month = value;
    notifyListeners();
  }

  /// ===============================================================
  /// REPORT RANGE
  /// ===============================================================
  ReportRange _range = ReportRange.fullMonth;

  ReportRange get range => _range;
  set range(ReportRange value) {
    _range = value;
    notifyListeners();
  }

  bool loading = false;
  bool loadingSubjects = false;
  bool loadingMonths = false;

  Map<String, dynamic> classData = {};
  List<String> students = [];
  List<String> availableSubjects = [];
  List<String> availableMonths = [];

  /// ===============================================================
  /// FORMAT MONTH (yyyy-MM → Feb 2026)
  /// ===============================================================
  String formatMonthLabel(String ym) {
    final parts = ym.split('-');
    if (parts.length != 2) return ym;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${names[month - 1]} $year';
  }

  /// ===============================================================
  /// FETCH SUBJECTS
  /// ===============================================================
  Future<void> fetchSubjects() async {
    if ([_year, _branch, _section].any((e) => e == null)) {
      availableSubjects = [];
      notifyListeners();
      return;
    }

    loadingSubjects = true;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('faculty_timetables')
          .doc(facultyId)
          .get();

      if (!snap.exists) {
        availableSubjects = [];
        return;
      }

      final data = snap.data()!;
      final Set<String> subjects = {};

      for (final dayData in data.values) {
        if (dayData is! List) continue;

        for (final period in dayData) {
          if (period is Map &&
              period['year']?.toString() == _year &&
              period['branch']?.toString() == _branch &&
              period['section']?.toString() == _section) {
            final code = period['subjectCode']?.toString().trim();
            if (code != null && code.isNotEmpty) {
              subjects.add(code);
            }
          }
        }
      }

      availableSubjects = subjects.toList()..sort();
    } finally {
      loadingSubjects = false;
      notifyListeners();
    }
  }

  /// ===============================================================
  /// FETCH AVAILABLE MONTHS (AUTO-SELECT LATEST)
  /// ===============================================================
  Future<void> fetchAvailableMonths() async {
    if ([_year, _branch, _section, _subject].any((e) => e == null)) {
      availableMonths = [];
      notifyListeners();
      return;
    }

    loadingMonths = true;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('class_attendance_summaries')
          .get();

      final Set<String> months = {};

      for (final doc in snap.docs) {
        final parts = doc.id.split('_');
        if (parts.length != 5) continue;

        if (parts[0] == _year &&
            parts[1] == _branch &&
            parts[2] == _section &&
            parts[3] == _subject) {
          months.add(parts[4]); // yyyy-MM
        }
      }

      availableMonths = months.toList()..sort();

      // ✅ AUTO-SELECT LATEST MONTH
      if (availableMonths.isNotEmpty) {
        _month ??= availableMonths.last;
      }
    } finally {
      loadingMonths = false;
      notifyListeners();
    }
  }

  /// ===============================================================
  /// LOAD REPORT
  /// ===============================================================
  Future<bool> loadReport() async {
    if ([_year, _branch, _section, _subject, _month].any((e) => e == null)) {
      return false;
    }

    loading = true;
    notifyListeners();

    try {
      final key = '${_year}_${_branch}_${_section}_${_subject}_$_month';

      final snap = await FirebaseFirestore.instance
          .collection('class_attendance_summaries')
          .doc(key)
          .get();

      if (!snap.exists) return false;

      classData = snap.data()!;
      final byDate = Map<String, dynamic>.from(classData['byDate'] ?? {});
      if (byDate.isEmpty) return false;

      final firstDay = Map<String, dynamic>.from(byDate.values.first);
      final present = Map<String, dynamic>.from(firstDay['present'] ?? {});
      students = present.keys.toList()..sort();

      return true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// ===============================================================
  /// DAYS (HALVES + SUNDAYS EXCLUDED)
  /// ===============================================================
  List<String> days() {
    final y = int.parse(_month!.split('-')[0]);
    final m = int.parse(_month!.split('-')[1]);
    final totalDays = DateTime(y, m + 1, 0).day;

    int start = 1;
    int end = totalDays;

    switch (_range) {
      case ReportRange.firstHalf:
        end = totalDays >= 15 ? 15 : totalDays;
        break;
      case ReportRange.secondHalf:
        start = totalDays >= 16 ? 16 : totalDays + 1;
        break;
      case ReportRange.fullMonth:
        break;
    }

    final result = <String>[];

    for (int day = start; day <= end; day++) {
      final date = DateTime(y, m, day);
      if (date.weekday == DateTime.sunday) continue;

      result.add(
        '$_month-${day.toString().padLeft(2, '0')}',
      );
    }

    return result;
  }

  /// ===============================================================
  /// STUDENT STATS
  /// ===============================================================
  ({List<String> daily, String total}) studentStats(String roll) {
    final d = days();
    final byDate = Map<String, dynamic>.from(classData['byDate'] ?? {});
    int present = 0, held = 0;
    final daily = <String>[];

    for (final day in d) {
      final data = byDate[day];
      if (data == null) {
        daily.add('-');
        continue;
      }

      final h = data['held'] ?? 0;
      final p = (data['present'] ?? {})[roll] ?? 0;

      present += p as int;
      held += h as int;

      daily.add(h > 0 ? '$p/$h' : '-');
    }

    return (
      daily: daily,
      total: held > 0 ? '$present/$held' : '-',
    );
  }

  /// ===============================================================
  /// EXCEL EXPORT
  /// ===============================================================
  Future<void> exportExcel() async {
    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Attendance'];
    
    // Remove default sheet if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final daysList = days();

    // ===============================================================
    // TITLE & METADATA
    // ===============================================================
    sheet.cell(excel_pkg.CellIndex.indexByString('A1')).value = 
        excel_pkg.TextCellValue('Monthly Attendance Report');
    sheet.cell(excel_pkg.CellIndex.indexByString('A1')).cellStyle = excel_pkg.CellStyle(
      bold: true,
      fontSize: 16,
    );

    final rangeLabel = _range == ReportRange.fullMonth
        ? 'Full Month'
        : _range == ReportRange.firstHalf
            ? 'Days 1-15'
            : 'Days 16-End';

    sheet.cell(excel_pkg.CellIndex.indexByString('A2')).value = 
        excel_pkg.TextCellValue(
            'Year: $_year | Branch: $_branch | Section: $_section | Subject: $_subject | Month: ${formatMonthLabel(_month!)} | Range: $rangeLabel (Sundays excluded)'
        );

    // ===============================================================
    // HEADER ROW (Row 4)
    // ===============================================================
    int col = 0;
    final headerStyle = excel_pkg.CellStyle(
      bold: true,
      backgroundColorHex: excel_pkg.ExcelColor.blue200,
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
      verticalAlign: excel_pkg.VerticalAlign.Center,
    );

    // Roll Number column
    sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 3)).value = 
        excel_pkg.TextCellValue('Roll No');
    sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: 3)).cellStyle = headerStyle;

    // Date columns
    for (final day in daysList) {
      final dayNum = day.split('-').last;
      sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 3)).value = 
          excel_pkg.TextCellValue(dayNum);
      sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: 3)).cellStyle = headerStyle;
    }

    // Total column
    sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3)).value = 
        excel_pkg.TextCellValue('Total');
    sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3)).cellStyle = headerStyle;

    // ===============================================================
    // DATA ROWS
    // ===============================================================
    int rowIndex = 4;
    final dataStyle = excel_pkg.CellStyle(
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
      verticalAlign: excel_pkg.VerticalAlign.Center,
    );

    final altRowStyle = excel_pkg.CellStyle(
      backgroundColorHex: excel_pkg.ExcelColor.blue50,
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
      verticalAlign: excel_pkg.VerticalAlign.Center,
    );

    for (int i = 0; i < students.length; i++) {
      final roll = students[i];
      final stats = studentStats(roll);
      final isAlt = i % 2 == 1;
      final rowStyle = isAlt ? altRowStyle : dataStyle;

      col = 0;

      // Roll number
      sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: rowIndex)).value = 
          excel_pkg.TextCellValue(roll);
      sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: rowIndex)).cellStyle = rowStyle;

      // Daily attendance
      for (final daily in stats.daily) {
        sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: rowIndex)).value = 
            excel_pkg.TextCellValue(daily);
        sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: rowIndex)).cellStyle = rowStyle;
      }

      // Total
      final totalStyle = excel_pkg.CellStyle(
        bold: true,
        backgroundColorHex: isAlt ? excel_pkg.ExcelColor.blue100 : excel_pkg.ExcelColor.blue50,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );
      sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex)).value = 
          excel_pkg.TextCellValue(stats.total);
      sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex)).cellStyle = totalStyle;

      rowIndex++;
    }

    // ===============================================================
    // COLUMN WIDTHS
    // ===============================================================
    sheet.setColumnWidth(0, 12); // Roll column
    for (int i = 1; i <= daysList.length + 1; i++) {
      sheet.setColumnWidth(i, 8); // Date and Total columns
    }

    // ===============================================================
    // SAVE & SHARE
    // ===============================================================
    final bytes = excel.encode();
    if (bytes == null) return;

    final fileName = 'Attendance_${_year}_${_branch}_${_section}_${_subject}_${_month}_$rangeLabel.xlsx';
    
    if (kIsWeb) {
      // Web: trigger download
      // Note: You'll need to add appropriate web download handling here
      // For example using html package or similar
      return;
    } else {
      // Mobile/Desktop: save and share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report',
      );
    }
  }
}