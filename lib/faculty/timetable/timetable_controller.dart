import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String facultyId;

  TimetableController({required this.facultyId});

  bool isLoading = true;
  String? errorMessage;

  /// day -> periods
  final Map<String, List<TimetablePeriod>> timetable = {};

  /// ordered for UI
  final List<String> orderedDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];

  Future<void> loadTimetable() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('faculty_timetables')
          .doc(facultyId)
          .get();

      timetable.clear();

      if (!snap.exists) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = snap.data()!;

      for (final day in orderedDays) {
        final rawList = data[day];
        if (rawList is! List) continue;

        timetable[day] = rawList.map((e) {
          final m = e as Map<String, dynamic>;
          return TimetablePeriod(
            subjectName: m['subjectName'] ?? '',
            subjectCode: m['subjectCode'] ?? '',
            periodNumber: m['periodNumber'] ?? 0,
            startTime: m['startTime'] ?? '',
            endTime: m['endTime'] ?? '',
            branch: m['branch'] ?? '',
            year: m['year'] ?? '',
            section: m['section'] ?? '',
          );
        }).toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}

class TimetablePeriod {
  final String subjectName;
  final String subjectCode;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String branch;
  final String year;
  final String section;

  TimetablePeriod({
    required this.subjectName,
    required this.subjectCode,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    required this.branch,
    required this.year,
    required this.section,
  });
}
