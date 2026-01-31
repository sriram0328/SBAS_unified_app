import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LongReportsController extends ChangeNotifier {
  final String facultyId;
  LongReportsController({required this.facultyId});

  String? year, branch, section, subject, month;

  bool loading = false;
  Map<String, dynamic> classData = {};
  List<String> students = [];

  // =========================
  // FETCH CLASS SUMMARY
  // =========================
  Future<bool> loadReport() async {
    if ([year, branch, section, subject, month].any((e) => e == null)) {
      return false;
    }

    loading = true;
    notifyListeners();

    try {
      final key = '${year}_${branch}_${section}_${subject}_$month';
      debugPrint('🔑 CLASS SUMMARY KEY: $key');

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

  // =========================
  // DAYS IN MONTH
  // =========================
  List<String> days() {
    final y = int.parse(month!.split('-')[0]);
    final m = int.parse(month!.split('-')[1]);
    final count = DateTime(y, m + 1, 0).day;

    return List.generate(
      count,
      (i) => '$month-${(i + 1).toString().padLeft(2, '0')}',
    );
  }

  // =========================
  // STUDENT STATS
  // =========================
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

  // =========================
  // PDF EXPORT
  // =========================
  Future<void> exportPdf() async {
    final pdf = pw.Document();
    final daysList = days();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          pw.Text(
            'Monthly Attendance Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Year: $year | Branch: $branch | Section: $section | '
            'Subject: $subject | Month: $month',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pw.TableRow(
                children: [
                  _pdfCell('Roll'),
                  ...daysList.map((d) => _pdfCell(d.split('-').last)),
                  _pdfCell('Total'),
                ],
              ),
              ...students.map((roll) {
                final stats = studentStats(roll);
                return pw.TableRow(
                  children: [
                    _pdfCell(roll),
                    ...stats.daily.map(_pdfCell),
                    _pdfCell(stats.total),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }
}
