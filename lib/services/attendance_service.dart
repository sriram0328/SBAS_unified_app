import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getAttendanceForStudent(String rollNo) {
    return _db
        .collection('attendance')
        .where('presentStudentRollNos', arrayContains: rollNo)
        .snapshots();
  }

  Future<void> markAttendance({
    required String facultyId,
    required String subjectCode,
    required String year,
    required String semester,
    required String branch,
    required String section,
    required int periodNumber,
    required List<String> presentStudentRollNos,
  }) async {
    final date = DateTime.now().toIso8601String().split('T').first;

    final docId =
        '${date}_${facultyId}_${year}_${semester}_${branch}_${section}_$periodNumber';

    print("📝 Creating attendance document: $docId");
    print(
        "📋 Parameters: year=$year, semester=$semester, branch=$branch, section=$section");

    // Step 1: Find active academic records for this year/semester/branch/section
    final academicRecordsSnap = await _db
        .collection('academic_records')
        .where('yearOfStudy', isEqualTo: int.parse(year))
        .where('semester', isEqualTo: int.parse(semester))
        .where('status', isEqualTo: 'active')
        .get();

    print(
        "📚 Found ${academicRecordsSnap.docs.length} active academic records for Year $year, Semester $semester");

    if (academicRecordsSnap.docs.isEmpty) {
      print("⚠️ No active students found for Year $year, Semester $semester");
      await _db.collection('attendance').doc(docId).set({
        'date': date,
        'facultyId': facultyId,
        'subjectCode': subjectCode,
        'year': year,
        'semester': semester,
        'branch': branch,
        'section': section,
        'periodNumber': periodNumber,
        'presentStudentRollNos': presentStudentRollNos,
        'absentStudentRollNos': [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Extract student IDs from academic records
    final studentIdsInYearSem = academicRecordsSnap.docs
        .map((doc) => doc.data()['studentId'] as String)
        .toSet();

    print(
        "👥 Student IDs in Year $year, Sem $semester: ${studentIdsInYearSem.length} students");

    // Step 2: Fetch actual student documents for these IDs to verify branch/section
    final allValidRollNos = <String>[];

    for (int i = 0; i < studentIdsInYearSem.length; i += 30) {
      final batch = studentIdsInYearSem.skip(i).take(30).toList();

      final studentsSnap = await _db
          .collection('students')
          .where('rollno', whereIn: batch)
          .where('branch', isEqualTo: branch)
          .where('section', isEqualTo: section)
          .get();

      final rollNos = studentsSnap.docs
          .map((doc) => doc.data()['rollno'] as String)
          .toList();

      allValidRollNos.addAll(rollNos);
    }

    print(
        "✅ Valid students in Year $year, Sem $semester, $branch-$section: ${allValidRollNos.length}");
    print("👥 Roll numbers: $allValidRollNos");

    // Calculate absent students
    final absentRolls = allValidRollNos
        .where((r) => !presentStudentRollNos.contains(r))
        .toList();

    print(
        "📊 Present: ${presentStudentRollNos.length}, Absent: ${absentRolls.length}, Total: ${allValidRollNos.length}");

    await _db.collection('attendance').doc(docId).set({
      'date': date,
      'facultyId': facultyId,
      'subjectCode': subjectCode,
      'year': year,
      'semester': semester,
      'branch': branch,
      'section': section,
      'periodNumber': periodNumber,
      'presentStudentRollNos': presentStudentRollNos,
      'absentStudentRollNos': absentRolls,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("✅ Attendance document created successfully");
  }
}
