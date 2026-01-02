import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all students of a class
  Future<List<String>> _getAllStudents({
    required String year,
    required String semester, // ✅ ADDED
    required String branch,
    required String section,
  }) async {
    final query = await _db
        .collection('students')
        .where('year', isEqualTo: year)
        .where('semester', isEqualTo: semester) // ✅ ENFORCED
        .where('branch', isEqualTo: branch)
        .where('section', isEqualTo: section)
        .get();

    return query.docs.map((doc) => doc.id).toList();
  }

  /// Create attendance record
  Future<void> markAttendance({
    required String facultyId, // MUST be Firestore faculty doc ID
    required String subjectCode,
    required String year,
    required String semester, // ✅ ADDED
    required String branch,
    required String section,
    required int periodNumber,
    required List<String> presentStudentRollNos,
  }) async {
    final date = DateTime.now().toIso8601String().split('T').first;

    // Deterministic document ID (prevents duplicates)
    final docId = '${date}_${facultyId}_$year$semester$branch$section$periodNumber';

    debugPrint('📝 Writing attendance → $docId');

    final allStudents = await _getAllStudents(
      year: year,
      semester: semester,
      branch: branch,
      section: section,
    );

    final absentStudents =
        allStudents.where((r) => !presentStudentRollNos.contains(r)).toList();

    await _db.collection('attendance').doc(docId).set({
  'date': date,
  'facultyId': facultyId,
  'subjectCode': subjectCode,

  // 🔴 REQUIRED SNAPSHOT FIELDS
  'year': year,
  'semester': semester,
  'branch': branch,
  'section': section,

  'periodNumber': periodNumber,
  'presentStudentRollNos': presentStudentRollNos,
  'absentStudentRollNos': absentStudents,

  'timestamp': FieldValue.serverTimestamp(),
});

    debugPrint('✅ Attendance write SUCCESS');
  }

  // ---------------------------
  // Queries
  // ---------------------------

  Stream<QuerySnapshot> getAttendanceForFacultyByDate(
    String facultyId,
    DateTime date,
  ) {
    final dateString = date.toIso8601String().split('T').first;

    return _db
        .collection('attendance')
        .where('facultyId', isEqualTo: facultyId)
        .where('date', isEqualTo: dateString)
        .orderBy('periodNumber')
        .snapshots();
  }

  Stream<QuerySnapshot> getAttendanceForStudent(String rollNo) {
    return _db
        .collection('attendance')
        .where('presentStudentRollNos', arrayContains: rollNo)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
