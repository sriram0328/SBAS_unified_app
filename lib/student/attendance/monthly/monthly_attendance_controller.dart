import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MonthlyAttendanceController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  Map<int, AttendanceDay> attendanceData = {};
  String? rollNo;
  String? studentBranch;

  Future<void> loadMonthlyAttendance() async {
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

      // Clear existing data
      attendanceData = {};

      // Get first and last day of the selected month
      final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
      final daysInMonth = lastDay.day;

      // Format date range for query
      final startDateStr = DateFormat('yyyy-MM-dd').format(firstDay);
      final endDateStr = DateFormat('yyyy-MM-dd').format(lastDay);

      print('🔍 Querying from: $startDateStr to $endDateStr');
      print('🔍 Querying for branch: $studentBranch');

      // Query all attendance for the month
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .where('branch', isEqualTo: studentBranch)
          .get();

      print('📊 Found ${attendanceQuery.docs.length} attendance records for the month');

      // Group attendance by date
      Map<String, List<AttendanceRecord>> attendanceByDate = {};

      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final date = data['date'] as String;
        final enrolledStudents = List<String>.from(data['enrolledStudentIds'] ?? []);
        final presentStudents = List<String>.from(data['presentStudentIds'] ?? []);
        final periodNumber = data['periodNumber'] ?? 0;

        // Only process if student is enrolled
        if (enrolledStudents.contains(rollNo)) {
          if (!attendanceByDate.containsKey(date)) {
            attendanceByDate[date] = [];
          }

          attendanceByDate[date]!.add(AttendanceRecord(
            isPresent: presentStudents.contains(rollNo),
            periodNumber: periodNumber,
          ));
        }
      }

      // Process each day of the month
      for (int day = 1; day <= daysInMonth; day++) {
        final currentDate = DateTime(selectedMonth.year, selectedMonth.month, day);
        final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

        // Skip future dates
        if (currentDate.isAfter(DateTime.now())) {
          continue;
        }

        // Get records for this day
        final records = attendanceByDate[dateStr] ?? [];
        
        if (records.isEmpty) {
          // No classes scheduled (weekend/holiday)
          attendanceData[day] = AttendanceDay(attended: 0, total: 0);
          print('📅 Day $day: No classes');
        } else {
          final attended = records.where((r) => r.isPresent).length;
          final total = records.length;
          attendanceData[day] = AttendanceDay(attended: attended, total: total);
          print('📅 Day $day: $attended/$total');
        }
      }

      print('📈 Monthly Total - Attended: ${getTotalAttended()}/${getTotalClasses()} (${(getMonthlyPercentage() * 100).toInt()}%)');

      isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error loading monthly attendance: $e');
      print('❌ Stack trace: $stackTrace');
      attendanceData = {};
      isLoading = false;
      notifyListeners();
    }
  }

  void previousMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    loadMonthlyAttendance();
  }

  void nextMonth() {
    // Don't go beyond current month
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    if (nextMonth.isAfter(DateTime.now())) {
      return;
    }
    selectedMonth = nextMonth;
    loadMonthlyAttendance();
  }

  void changeMonth(DateTime newMonth) {
    selectedMonth = newMonth;
    loadMonthlyAttendance();
  }

  int getTotalAttended() {
    return attendanceData.values.fold(0, (sum, day) => sum + day.attended);
  }

  int getTotalClasses() {
    return attendanceData.values.fold(0, (sum, day) => sum + day.total);
  }

  double getMonthlyPercentage() {
    final total = getTotalClasses();
    if (total == 0) return 0;
    return getTotalAttended() / total;
  }

  String getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> refresh() async {
    await loadMonthlyAttendance();
  }
}

class AttendanceDay {
  final int attended;
  final int total;

  AttendanceDay({required this.attended, required this.total});

  double get percentage => total > 0 ? attended / total : 0.0;

  Color get color {
    if (total == 0) return Colors.grey;
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class AttendanceRecord {
  final bool isPresent;
  final int periodNumber;

  AttendanceRecord({
    required this.isPresent,
    required this.periodNumber,
  });
}