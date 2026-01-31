import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ======================================================
  /// MAIN ENTRY POINT
  /// ======================================================
  Future<void> createAttendance({
    required String facultyId,
    required int periodNumber,
    required int periodCount,
    required bool isLab,
    required String subjectCode,
    required String subjectName,
    required String year,
    required String branch,
    required String section,
    required List<String> enrolledStudentIds,
    required List<String> presentStudentIds,
  }) async {
    final now = DateTime.now();
    final date = now.toIso8601String().split('T').first;
    final month = date.substring(0, 7);

    final attendanceData = {
      'date': date,
      'month': month,
      'year': year,
      'branch': branch,
      'section': section,
      'facultyId': facultyId,
      'subjectCode': subjectCode.trim(),
      'subjectName': subjectName.trim(),
      'periodNumber': periodNumber,
      'periodCount': periodCount,
      'isLab': isLab,
      'enrolledStudentIds': enrolledStudentIds,
      'presentStudentIds': presentStudentIds,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // 1️⃣ Raw attendance
      await _db.collection('attendance').add(attendanceData);

      // 2️⃣ Student summaries (batch-safe)
      await _updateStudentSummaries(attendanceData);

      // 3️⃣ Class summary (transaction-safe)
      await _updateClassSummary(attendanceData);

      debugPrint('✅ Attendance + summaries updated correctly');
    } catch (e) {
      debugPrint('❌ Attendance failed: $e');
      rethrow;
    }
  }

  /// ======================================================
  /// STUDENT SUMMARIES (BATCH IS SAFE HERE)
  /// ======================================================
  Future<void> _updateStudentSummaries(Map<String, dynamic> a) async {
    final batch = _db.batch();

    final String date = a['date'];
    final String month = a['month'];
    final String year = a['year'];
    final String branch = a['branch'];
    final String section = a['section'];
    final String subjectCode = a['subjectCode'];
    final String subjectName = a['subjectName'];
    final int periodNumber = a['periodNumber'];
    final int periodCount = a['periodCount'];
    final bool isLab = a['isLab'];

    final List<String> enrolled = List<String>.from(a['enrolledStudentIds']);
    final Set<String> present = Set<String>.from(a['presentStudentIds']);

    for (final rollNo in enrolled) {
      final isPresent = present.contains(rollNo);

      final ref = _db
          .collection('attendance_summaries')
          .doc('${rollNo}_$month');

      batch.set(
        ref,
        {
          'rollNo': rollNo,
          'month': month,
          'year': year,
          'branch': branch,
          'section': section,

          'overall.totalClasses': FieldValue.increment(periodCount),
          'overall.present':
              FieldValue.increment(isPresent ? periodCount : 0),

          'bySubject.$subjectCode.total':
              FieldValue.increment(periodCount),
          'bySubject.$subjectCode.present':
              FieldValue.increment(isPresent ? periodCount : 0),

          'byDate.$date.total': FieldValue.increment(periodCount),
          'byDate.$date.present':
              FieldValue.increment(isPresent ? periodCount : 0),

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (int i = 0; i < periodCount; i++) {
        batch.set(
          ref,
          {
            'byDate.$date.periods.${periodNumber + i}': {
              'subject': subjectName,
              'subjectCode': subjectCode,
              'isPresent': isPresent,
              'isLab': isLab,
            }
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  /// ======================================================
  /// CLASS SUMMARY (TRANSACTION — CRITICAL FIX)
  /// ======================================================
  Future<void> _updateClassSummary(Map<String, dynamic> a) async {
    final String date = a['date'];
    final String month = a['month'];
    final String year = a['year'];
    final String branch = a['branch'];
    final String section = a['section'];
    final String subjectCode = a['subjectCode'];
    final String subjectName = a['subjectName'];
    final int periodCount = a['periodCount'];

    final List<String> enrolled = List<String>.from(a['enrolledStudentIds']);
    final Set<String> present = Set<String>.from(a['presentStudentIds']);

    final classKey =
        '${year}_${branch}_${section}_${subjectCode}_$month';

    final classRef =
        _db.collection('class_attendance_summaries').doc(classKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(classRef);
      final data = snap.exists ? snap.data()! : {};

      final byDate = Map<String, dynamic>.from(data['byDate'] ?? {});
      final day = Map<String, dynamic>.from(byDate[date] ?? {
        'held': 0,
        'present': <String, int>{},
      });

      day['held'] = (day['held'] ?? 0) + periodCount;

      final Map<String, dynamic> presentMap =
          Map<String, dynamic>.from(day['present'] ?? {});

      for (final rollNo in enrolled) {
        final wasPresent = present.contains(rollNo);
        presentMap[rollNo] =
            (presentMap[rollNo] ?? 0) + (wasPresent ? periodCount : 0);
      }

      day['present'] = presentMap;
      byDate[date] = day;

      tx.set(
        classRef,
        {
          'year': year,
          'branch': branch,
          'section': section,
          'subjectCode': subjectCode,
          'subjectName': subjectName,
          'month': month,
          'byDate': byDate,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
