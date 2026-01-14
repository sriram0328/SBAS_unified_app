import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WeeklyAttendanceController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  double weeklyPercentage = 0.0;
  int attendedClasses = 0;
  int totalClasses = 0;
  List<DayAttendance> days = [];
  String? rollNo;
  String? studentBranch;
  
  // Week selection
  DateTime selectedWeekStart = _getMondayOfWeek(DateTime.now());
  
  // Get Monday of the current week
  static DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> loadWeeklyAttendance() async {
    print('🔄 ========== LOADING WEEKLY ATTENDANCE ==========');
    isLoading = true;
    notifyListeners();

    try {
      // Get current user's roll number and branch
      if (rollNo == null) {
        final user = _auth.currentUser;
        if (user == null) {
          print('❌ CRITICAL: No user logged in');
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
          print('❌ CRITICAL: Student document does not exist');
          isLoading = false;
          notifyListeners();
          return;
        }

        final studentData = studentDoc.data();
        rollNo = studentData?['rollno'] ?? '';
        studentBranch = studentData?['branch'] ?? '';
        
        print('✅ Roll No: "$rollNo"');
        print('✅ Branch: "$studentBranch"');
      }

      if (rollNo == null || rollNo!.isEmpty) {
        print('❌ CRITICAL: Roll number is null or empty');
        isLoading = false;
        notifyListeners();
        return;
      }

      if (studentBranch == null || studentBranch!.isEmpty) {
        print('❌ CRITICAL: Branch is null or empty');
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get the selected week's date range (Monday to Saturday)
      final startOfWeek = selectedWeekStart;
      final endOfWeek = startOfWeek.add(const Duration(days: 5)); // Monday to Saturday (6 days)

      // Format dates
      final startDateStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endOfWeek);

      print('📅 Week range: $startDateStr to $endDateStr');
      print('🔍 Querying for branch: $studentBranch');

      // Query attendance for the week - use branch as first condition
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('branch', isEqualTo: studentBranch)
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();

      print('📊 QUERY RESULT: Found ${attendanceQuery.docs.length} total documents');

      // Group attendance by date
      Map<String, List<AttendanceRecord>> attendanceByDate = {};
      int enrolledCount = 0;

      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final date = data['date'] as String;
        final enrolledStudents = List<String>.from(data['enrolledStudentIds'] ?? []);
        final presentStudents = List<String>.from(data['presentStudentIds'] ?? []);
        final periodNumber = data['periodNumber'] ?? 0;
        final facultyId = data['facultyId'] ?? '';

        // Only process if student is enrolled
        if (enrolledStudents.contains(rollNo)) {
          enrolledCount++;
          
          if (!attendanceByDate.containsKey(date)) {
            attendanceByDate[date] = [];
          }

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
              print('   ⚠️ Error fetching faculty: $e');
            }
          }

          final isPresent = presentStudents.contains(rollNo);

          attendanceByDate[date]!.add(AttendanceRecord(
            periodNumber: periodNumber,
            isPresent: isPresent,
            facultyName: facultyName,
          ));
        }
      }

      print('📊 Classes student is enrolled in: $enrolledCount');

      // Create DayAttendance objects for Monday to Saturday (6 days)
      days = [];
      for (int i = 0; i < 6; i++) {
        final currentDay = startOfWeek.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(currentDay);
        final dayName = DateFormat('EEE').format(currentDay);

        final records = attendanceByDate[dateStr] ?? [];
        final attended = records.where((r) => r.isPresent).length;
        final total = records.length;

        print('📅 $dayName ($dateStr): $attended/$total');

        // Create subject records
        final subjects = records.map((record) {
          return SubjectAttendanceRecord(
            'Period ${record.periodNumber}',
            _getPeriodTime(record.periodNumber),
            'Theory',
            record.isPresent,
          );
        }).toList();

        // Sort by time
        subjects.sort((a, b) => a.time.compareTo(b.time));

        days.add(DayAttendance(
          dayName,
          attended,
          total,
          subjects,
        ));
      }

      // Calculate overall weekly stats
      attendedClasses = days.fold(0, (sum, day) => sum + day.attended);
      totalClasses = days.fold(0, (sum, day) => sum + day.total);
      weeklyPercentage = totalClasses > 0 ? attendedClasses / totalClasses : 0.0;

      print('📈 WEEKLY SUMMARY: $attendedClasses/$totalClasses (${(weeklyPercentage * 100).toStringAsFixed(1)}%)');

      isLoading = false;
      notifyListeners();
      
      print('✅ ========== WEEKLY ATTENDANCE LOADED ==========');
    } catch (e, stackTrace) {
      print('❌ ========== ERROR LOADING WEEKLY ATTENDANCE ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      days = [];
      attendedClasses = 0;
      totalClasses = 0;
      weeklyPercentage = 0.0;
      isLoading = false;
      notifyListeners();
    }
  }

  String _getPeriodTime(int periodNumber) {
    const Map<int, String> periodTimes = {
      1: '09:00 AM',
      2: '10:00 AM',
      3: '11:00 AM',
      4: '12:00 PM',
      5: '01:00 PM',
      6: '02:00 PM',
      7: '03:00 PM',
      8: '04:00 PM',
    };
    return periodTimes[periodNumber] ?? '${periodNumber}:00 AM';
  }

  // Week navigation
  void previousWeek() {
    selectedWeekStart = selectedWeekStart.subtract(const Duration(days: 7));
    loadWeeklyAttendance();
  }

  void nextWeek() {
    final nextWeekStart = selectedWeekStart.add(const Duration(days: 7));
    // Don't go beyond current week
    if (nextWeekStart.isAfter(_getMondayOfWeek(DateTime.now()))) {
      return;
    }
    selectedWeekStart = nextWeekStart;
    loadWeeklyAttendance();
  }

  // Get week label
  String getWeekLabel() {
    final endOfWeek = selectedWeekStart.add(const Duration(days: 5));
    final startStr = DateFormat('MMM d').format(selectedWeekStart);
    final endStr = DateFormat('MMM d, yyyy').format(endOfWeek);
    return '$startStr - $endStr';
  }

  // Check if we can go to next week
  bool canGoNext() {
    final nextWeekStart = selectedWeekStart.add(const Duration(days: 7));
    return !nextWeekStart.isAfter(_getMondayOfWeek(DateTime.now()));
  }

  Future<void> refresh() async {
    await loadWeeklyAttendance();
  }
}

class AttendanceRecord {
  final int periodNumber;
  final bool isPresent;
  final String facultyName;

  AttendanceRecord({
    required this.periodNumber,
    required this.isPresent,
    required this.facultyName,
  });
}

class DayAttendance {
  final String day;
  final int attended;
  final int total;
  final List<SubjectAttendanceRecord> subjects;

  DayAttendance(this.day, this.attended, this.total, this.subjects);

  double get percentage => total > 0 ? attended / total : 0.0;

  Color get color {
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class SubjectAttendanceRecord {
  final String subjectName;
  final String time;
  final String type;
  final bool isPresent;

  SubjectAttendanceRecord(
    this.subjectName,
    this.time,
    this.type,
    this.isPresent,
  );
}