import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Marks attendance for a specific class period.
  ///
  /// This creates or updates an attendance record for a given date and period.
  /// It stores which students were present.
  Future<void> markAttendance({
    required String facultyId,
    required String subjectCode,
    required String year,
    required String branch,
    required String section,
    required int periodNumber,
    required List<String> presentStudentRollNos,
  }) async {
    try {
      // Use YYYY-MM-DD format for consistent date-based queries.
      final date = DateTime.now().toIso8601String().split('T').first;
      
      // The document ID is a composite key to ensure uniqueness for each class on a given day.
      final docId = '${date}_${facultyId}_${subjectCode}_$periodNumber';

      final attendanceRef = _db.collection('attendance').doc(docId);

      await attendanceRef.set({
        'date': date,
        'facultyId': facultyId,
        'subjectCode': subjectCode,
        'year': year,
        'branch': branch,
        'section': section,
        'periodNumber': periodNumber,
        'presentStudentRollNos': presentStudentRollNos,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking attendance: $e');
      // Rethrowing allows the UI layer to handle the error, e.g., show a snackbar.
      rethrow;
    }
  }

  /// Retrieves attendance records for a specific faculty member on a given date.
  Stream<QuerySnapshot> getAttendanceForFacultyByDate(String facultyId, DateTime date) {
    final dateString = date.toIso8601String().split('T').first;
    return _db
        .collection('attendance')
        .where('facultyId', isEqualTo: facultyId)
        .where('date', isEqualTo: dateString)
        .orderBy('periodNumber')
        .snapshots();
  }
  
  /// Retrieves all attendance records for a specific student.
  Stream<QuerySnapshot> getAttendanceForStudent(String rollNo) {
    return _db
        .collection('attendance')
        .where('presentStudentRollNos', arrayContains: rollNo)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}