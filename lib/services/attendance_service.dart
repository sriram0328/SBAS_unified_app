import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get attendance records for a student by roll number
  Future<List<Map<String, dynamic>>> getAttendanceForStudentRoll({
    required String rollNo,
  }) async {
    try {
      final snap = await _db
          .collection('attendance')
          .where('enrolledStudentIds', arrayContains: rollNo)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        final presentList = List<String>.from(data['presentStudentIds'] ?? []);

        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'date': data['date'] ?? '',
          'subjectName': data['subjectName'] ?? 'Unknown',
          'subjectCode': data['subjectCode'] ?? '',
          'periodNumber': data['periodNumber'] ?? 0,
          'isPresent': presentList.contains(rollNo),
          'branch': data['branch'] ?? '',
          'section': data['section'] ?? '',
          'year': data['year'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  /// Get attendance records for a specific date
  Future<List<Map<String, dynamic>>> getAttendanceByDate({
    required String rollNo,
    required String date,
  }) async {
    try {
      final snap = await _db
          .collection('attendance')
          .where('date', isEqualTo: date)
          .where('enrolledStudentIds', arrayContains: rollNo)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        final presentList = List<String>.from(data['presentStudentIds'] ?? []);

        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'date': data['date'] ?? '',
          'subjectName': data['subjectName'] ?? 'Unknown',
          'periodNumber': data['periodNumber'] ?? 0,
          'isPresent': presentList.contains(rollNo),
        };
      }).toList();
    } catch (e) {
      print('Error fetching attendance by date: $e');
      return [];
    }
  }

  /// Get attendance records for a date range (for weekly/monthly views)
  Future<List<Map<String, dynamic>>> getAttendanceInRange({
    required String rollNo,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = startDate.toIso8601String().split('T').first;
      final endStr = endDate.toIso8601String().split('T').first;

      final snap = await _db
          .collection('attendance')
          .where('enrolledStudentIds', arrayContains: rollNo)
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .orderBy('date')
          .orderBy('periodNumber')
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        final presentList = List<String>.from(data['presentStudentIds'] ?? []);

        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'date': data['date'] ?? '',
          'subjectName': data['subjectName'] ?? 'Unknown',
          'periodNumber': data['periodNumber'] ?? 0,
          'isPresent': presentList.contains(rollNo),
          'branch': data['branch'] ?? '',
          'section': data['section'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching attendance range: $e');
      return [];
    }
  }

  /// Get subject-wise attendance summary
  Future<Map<String, Map<String, dynamic>>> getSubjectWiseAttendance({
    required String rollNo,
  }) async {
    try {
      final records = await getAttendanceForStudentRoll(rollNo: rollNo);
      
      final Map<String, Map<String, dynamic>> subjectStats = {};

      for (var record in records) {
        final subject = record['subjectName'] as String;
        final isPresent = record['isPresent'] as bool;

        if (!subjectStats.containsKey(subject)) {
          subjectStats[subject] = {
            'attended': 0,
            'total': 0,
            'subjectCode': record['subjectCode'],
          };
        }

        subjectStats[subject]!['total'] = (subjectStats[subject]!['total'] as int) + 1;
        if (isPresent) {
          subjectStats[subject]!['attended'] = (subjectStats[subject]!['attended'] as int) + 1;
        }
      }

      return subjectStats;
    } catch (e) {
      print('Error calculating subject-wise attendance: $e');
      return {};
    }
  }

  /// Create attendance record (for faculty use)
  Future<void> createAttendance({
    required String facultyId,
    required int periodNumber,
    required String subjectCode,
    required String subjectName,
    required String year,
    required String branch,
    required String section,
    required List<String> enrolledStudentIds,
    required List<String> presentStudentIds,
  }) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T').first;

    await _db.collection('attendance').add({
      'date': dateStr,
      'facultyId': facultyId,
      'periodNumber': periodNumber,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'year': year,
      'branch': branch,
      'section': section,
      'enrolledStudentIds': enrolledStudentIds,
      'presentStudentIds': presentStudentIds,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}