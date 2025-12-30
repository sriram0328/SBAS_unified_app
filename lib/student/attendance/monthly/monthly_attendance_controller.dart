import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { full, partial, absent }

class MonthlyAttendanceController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  DateTime currentMonth = DateTime.now();
  Map<int, AttendanceStatus> monthlyStatus = {};

  Future<void> loadMonthlyAttendance(String rollNo) async {
    isLoading = true;
    notifyListeners();

    try {
      monthlyStatus = {};

      // Get last day of current month
      final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);

      // Query attendance for the entire month
      for (int day = 1; day <= lastDay.day; day++) {
        final currentDate = DateTime(currentMonth.year, currentMonth.month, day);
        
        // Skip future dates
        if (currentDate.isAfter(DateTime.now())) continue;
        
        // Skip Sundays
        if (currentDate.weekday == 7) continue;

        final dateString = currentDate.toIso8601String().split('T').first;

        final querySnapshot = await _db
            .collection('attendance')
            .where('date', isEqualTo: dateString)
            .get();

        if (querySnapshot.docs.isEmpty) continue;

        int attended = 0;
        int total = querySnapshot.docs.length;

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final presentList = List<String>.from(data['presentStudentRollNos'] ?? []);
          if (presentList.contains(rollNo)) {
            attended++;
          }
        }

        // Determine status
        if (attended == total) {
          monthlyStatus[day] = AttendanceStatus.full;
        } else if (attended > 0) {
          monthlyStatus[day] = AttendanceStatus.partial;
        } else {
          monthlyStatus[day] = AttendanceStatus.absent;
        }
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading monthly attendance: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  void changeMonth(DateTime newMonth) {
    currentMonth = newMonth;
    notifyListeners();
  }

  void nextMonth() {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    notifyListeners();
  }
}