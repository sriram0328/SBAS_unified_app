import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DailyAttendanceController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<PeriodAttendance> periods = [];
  int presentCount = 0;
  int absentCount = 0;
  String? rollNo;
  String? studentBranch;

  Future<void> loadDailyAttendance() async {
    isLoading = true;
    notifyListeners();

    try {
      // Get current user's roll number and branch
      if (rollNo == null) {
        final user = _auth.currentUser;
        if (user == null) {
          print('❌ No user logged in');
          isLoading = false;
          notifyListeners();
          return;
        }

        print('✅ User ID: ${user.uid}');

        final studentDoc = await _firestore
            .collection('students')
            .doc(user.uid)
            .get();

        if (!studentDoc.exists) {
          print('❌ Student document not found');
          isLoading = false;
          notifyListeners();
          return;
        }

        rollNo = studentDoc.data()?['rollno'] ?? '';
        studentBranch = studentDoc.data()?['branch'] ?? '';
        
        print('✅ Roll No: $rollNo');
        print('✅ Branch: $studentBranch');
      }

      if (rollNo!.isEmpty || studentBranch == null) {
        print('❌ Roll number or branch is empty');
        isLoading = false;
        notifyListeners();
        return;
      }

      // Format date as YYYY-MM-DD to match your Firestore structure
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      print('🔍 Querying for date: $dateStr');
      print('🔍 Querying for branch: $studentBranch');

      // Query attendance records for the selected date and student's branch
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .where('branch', isEqualTo: studentBranch)
          .get();

      print('📊 Found ${attendanceQuery.docs.length} attendance records');

      periods = [];

      // Process each attendance record (each period)
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        print('📄 Document ID: ${doc.id}');
        
        final enrolledStudents = List<String>.from(data['enrolledStudentIds'] ?? []);
        final presentStudents = List<String>.from(data['presentStudentIds'] ?? []);
        final periodNumber = data['periodNumber'] ?? 0;
        final facultyId = data['facultyId'] ?? '';

        print('  Period: $periodNumber');
        print('  Enrolled count: ${enrolledStudents.length}');
        print('  Present count: ${presentStudents.length}');
        print('  Student enrolled: ${enrolledStudents.contains(rollNo)}');

        // Check if student is enrolled in this period
        if (enrolledStudents.contains(rollNo)) {
          print('  ✅ Student is enrolled in period $periodNumber');
          
          // Get faculty name
          String facultyName = 'Unknown';
          if (facultyId.isNotEmpty) {
            try {
              final facultyDoc = await _firestore
                  .collection('faculty')
                  .doc(facultyId)
                  .get();
              if (facultyDoc.exists) {
                facultyName = facultyDoc.data()?['name'] ?? 'Unknown';
              }
            } catch (e) {
              print('⚠️ Error fetching faculty: $e');
            }
          }

          // Get subject name (using period number for now)
          String subjectName = 'Period $periodNumber';

          // Determine time based on period number
          String time = _getPeriodTime(periodNumber);

          // Check if student was present
          bool isPresent = presentStudents.contains(rollNo);
          print('  Attendance: ${isPresent ? "PRESENT" : "ABSENT"}');

          periods.add(PeriodAttendance(
            time,
            subjectName,
            facultyName,
            isPresent,
            periodNumber,
          ));
        } else {
          print('  ⚠️ Student NOT enrolled in period $periodNumber');
        }
      }

      // Sort by period number
      periods.sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

      presentCount = periods.where((p) => p.isPresent).length;
      absentCount = periods.length - presentCount;

      print('📈 Total periods: ${periods.length}');
      print('📈 Present: $presentCount');
      print('📈 Absent: $absentCount');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading daily attendance: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      periods = [];
      presentCount = 0;
      absentCount = 0;
      isLoading = false;
      notifyListeners();
    }
  }

  String _getPeriodTime(int periodNumber) {
    // Customize this according to your institution's timetable
    const Map<int, String> periodTimes = {
      1: '09:00',
      2: '10:00',
      3: '11:00',
      4: '12:00',
      5: '01:00',
      6: '02:00',
      7: '03:00',
      8: '04:00',
    };
    return periodTimes[periodNumber] ?? '${periodNumber}:00';
  }

  void changeDate(DateTime newDate) {
    selectedDate = newDate;
    loadDailyAttendance();
  }

  Future<void> refresh() async {
    await loadDailyAttendance();
  }
}

class PeriodAttendance {
  final String time;
  final String subject;
  final String faculty;
  final bool isPresent;
  final int periodNumber;

  PeriodAttendance(
    this.time,
    this.subject,
    this.faculty,
    this.isPresent,
    this.periodNumber,
  );
}