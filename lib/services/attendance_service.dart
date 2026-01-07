// lib/services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _db.collection('attendance').add({
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

  /// ✅ USED BY STUDENT DASHBOARD
  Future<List<Map<String, dynamic>>> getAttendanceForStudentRoll({
    required String rollNo,
  }) async {
    final snap = await _db
        .collection('attendance')
        .where('enrolledStudentIds', arrayContains: rollNo)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      final present =
          List<String>.from(data['presentStudentIds'] ?? []);

      return {
        'timestamp': data['timestamp'],
        'subjectName': data['subjectName'],
        'subjectCode': data['subjectCode'],
        'isPresent': present.contains(rollNo),
      };
    }).toList();
  }
}
