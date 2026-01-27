// attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
          'periodCount': data['periodCount'] ?? 1, // ✅ NEW
          'isLab': data['isLab'] ?? false, // ✅ NEW
          'isPresent': presentList.contains(rollNo),
          'branch': data['branch'] ?? '',
          'section': data['section'] ?? '',
          'year': data['year'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
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
          'periodCount': data['periodCount'] ?? 1,
          'isLab': data['isLab'] ?? false,
          'isPresent': presentList.contains(rollNo),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching attendance by date: $e');
      return [];
    }
  }

  /// Get attendance records for a date range
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
          'periodCount': data['periodCount'] ?? 1,
          'isLab': data['isLab'] ?? false,
          'isPresent': presentList.contains(rollNo),
          'branch': data['branch'] ?? '',
          'section': data['section'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching attendance range: $e');
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
        final periodCount = record['periodCount'] as int; // ✅ Count hours, not just sessions

        if (!subjectStats.containsKey(subject)) {
          subjectStats[subject] = {
            'attended': 0,
            'total': 0,
            'subjectCode': record['subjectCode'],
            'isLab': record['isLab'],
          };
        }

        // ✅ Add periodCount (so a 3-hour lab counts as 3 classes)
        subjectStats[subject]!['total'] = (subjectStats[subject]!['total'] as int) + periodCount;
        if (isPresent) {
          subjectStats[subject]!['attended'] = (subjectStats[subject]!['attended'] as int) + periodCount;
        }
      }

      return subjectStats;
    } catch (e) {
      debugPrint('Error calculating subject-wise attendance: $e');
      return {};
    }
  }

  /// ✅ UPDATED: Create attendance with LAB support
  /// For labs: periodNumber = starting period, periodCount = 2 or 3
  /// For regular classes: periodCount = 1
  Future<void> createAttendance({
    required String facultyId,
    required int periodNumber,
    required int periodCount, // ✅ NEW: 1 for class, 2-3 for lab
    required bool isLab, // ✅ NEW: true for labs
    required String subjectCode,
    required String subjectName,
    required String year,
    required String branch,
    required String section,
    required List<String> enrolledStudentIds,
    required List<String> presentStudentIds,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T').first;
      final month = dateStr.substring(0, 7);

      // 1️⃣ Create ONE attendance record that covers multiple periods
      await _db.collection('attendance').add({
        'date': dateStr,
        'facultyId': facultyId,
        'periodNumber': periodNumber, // Starting period (e.g., 4 for P4-P5-P6)
        'periodCount': periodCount, // ✅ How many periods (1, 2, or 3)
        'isLab': isLab, // ✅ Flag for UI differentiation
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'year': year,
        'branch': branch,
        'section': section,
        'enrolledStudentIds': enrolledStudentIds,
        'presentStudentIds': presentStudentIds,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update summaries (count each period separately for percentage calculation)
      final sanitizedSubject = subjectName.replaceAll(RegExp(r'[.\[\]*/]'), '_');
      
      for (final rollNo in enrolledStudentIds) {
        final summaryRef = _db
            .collection('attendance_summaries')
            .doc('${rollNo}_$month');
        
        final isPresent = presentStudentIds.contains(rollNo);
        
        await _db.runTransaction((transaction) async {
          final snapshot = await transaction.get(summaryRef);
          
          Map<String, dynamic> summaryData;
          
          if (!snapshot.exists) {
            // Create new summary
            summaryData = {
              'rollNo': rollNo,
              'month': month,
              'overall': {
                'totalClasses': periodCount, // ✅ 3-hour lab = 3 classes
                'present': isPresent ? periodCount : 0,
              },
              'bySubject': {
                sanitizedSubject: {
                  'total': periodCount,
                  'present': isPresent ? periodCount : 0,
                }
              },
              'byDate': {
                dateStr: {
                  'total': periodCount,
                  'present': isPresent ? periodCount : 0,
                  'periods': _buildPeriodData(periodNumber, periodCount, subjectName, subjectCode, isPresent, isLab),
                }
              },
              'updatedAt': FieldValue.serverTimestamp(),
            };
          } else {
            // Update existing summary
            final existingData = snapshot.data() as Map<String, dynamic>;
            
            final overall = Map<String, dynamic>.from(existingData['overall'] ?? {});
            final bySubject = Map<String, dynamic>.from(existingData['bySubject'] ?? {});
            final byDate = Map<String, dynamic>.from(existingData['byDate'] ?? {});
            
            // Update overall (add periodCount)
            overall['totalClasses'] = (overall['totalClasses'] ?? 0) + periodCount;
            overall['present'] = (overall['present'] ?? 0) + (isPresent ? periodCount : 0);
            
            // Update bySubject
            final subjectData = Map<String, dynamic>.from(bySubject[sanitizedSubject] ?? {});
            subjectData['total'] = (subjectData['total'] ?? 0) + periodCount;
            subjectData['present'] = (subjectData['present'] ?? 0) + (isPresent ? periodCount : 0);
            bySubject[sanitizedSubject] = subjectData;
            
            // Update byDate with ALL periods covered by the lab
            final dateData = Map<String, dynamic>.from(byDate[dateStr] ?? {});
            dateData['total'] = (dateData['total'] ?? 0) + periodCount;
            dateData['present'] = (dateData['present'] ?? 0) + (isPresent ? periodCount : 0);
            
            final periods = Map<String, dynamic>.from(dateData['periods'] ?? {});
            final newPeriods = _buildPeriodData(periodNumber, periodCount, subjectName, subjectCode, isPresent, isLab);
            periods.addAll(newPeriods);
            dateData['periods'] = periods;
            
            byDate[dateStr] = dateData;
            
            summaryData = {
              'rollNo': rollNo,
              'month': month,
              'overall': overall,
              'bySubject': bySubject,
              'byDate': byDate,
              'updatedAt': FieldValue.serverTimestamp(),
            };
          }
          
          transaction.set(summaryRef, summaryData);
        });
      }

      debugPrint('✅ ${isLab ? "Lab" : "Class"} attendance submitted for ${enrolledStudentIds.length} students ($periodCount periods)');
    } catch (e) {
      debugPrint('❌ Error submitting attendance: $e');
      rethrow;
    }
  }

  /// ✅ Helper: Build period data for all periods in a lab session
  /// Example: Lab from P4-P6 creates entries for periods 4, 5, and 6
  Map<String, dynamic> _buildPeriodData(
    int startPeriod,
    int periodCount,
    String subjectName,
    String subjectCode,
    bool isPresent,
    bool isLab,
  ) {
    final Map<String, dynamic> periods = {};
    
    for (int i = 0; i < periodCount; i++) {
      final periodNum = startPeriod + i;
      periods[periodNum.toString()] = {
        'subject': subjectName,
        'subjectCode': subjectCode,
        'isPresent': isPresent,
        'isLab': isLab, // ✅ Mark as lab for UI display
      };
    }
    
    return periods;
  }

  /// Get faculty name by ID
  Future<String> getFacultyName(String facultyId) async {
    if (facultyId.isEmpty) return 'Unknown';
    
    try {
      final doc = await _db.collection('faculty').doc(facultyId).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Unknown';
      }
    } catch (e) {
      debugPrint('Error fetching faculty: $e');
    }
    return 'Unknown';
  }

  /// Get student info by user ID
  Future<Map<String, dynamic>?> getStudentInfo(String userId) async {
    try {
      final doc = await _db.collection('students').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching student info: $e');
    }
    return null;
  }

  /// Get overall attendance percentage for a student
  Future<double> getOverallAttendancePercentage(String rollNo) async {
    try {
      int totalClasses = 0;
      int attendedClasses = 0;

      final snapshot = await _db
          .collection('attendance')
          .where('enrolledStudentIds', arrayContains: rollNo)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final enrolledStudents = List<String>.from(data['enrolledStudentIds'] ?? []);
        final presentStudents = List<String>.from(data['presentStudentIds'] ?? []);
        final periodCount = (data['periodCount'] as num?)?.toInt() ?? 1; // ✅ Fix type conversion

        if (enrolledStudents.contains(rollNo)) {
          totalClasses += periodCount;
          if (presentStudents.contains(rollNo)) {
            attendedClasses += periodCount;
          }
        }
      }

      return totalClasses > 0 ? attendedClasses / totalClasses : 0.0;
    } catch (e) {
      debugPrint('Error calculating overall attendance: $e');
      return 0.0;
    }
  }
}

/// Helper class for period time mapping
class PeriodTimeHelper {
  static const Map<int, String> periodTimings = {
    1: '09:00 AM',
    2: '10:00 AM',
    3: '11:00 AM',
    4: '12:00 PM',
    5: '01:00 PM',
    6: '02:00 PM',
    7: '03:00 PM',
    8: '04:00 PM',
  };

  static String getTime(int periodNumber) {
    return periodTimings[periodNumber] ?? '$periodNumber:00 AM';
  }

  static String getTimeShort(int periodNumber) {
    final time = getTime(periodNumber);
    return time.replaceAll(' AM', '').replaceAll(' PM', '');
  }

  /// ✅ Get time range for labs
  /// Example: getPeriodRange(4, 3) → "12:00 PM - 03:00 PM"
  static String getPeriodRange(int startPeriod, int periodCount) {
    if (periodCount == 1) {
      return getTime(startPeriod);
    }
    
    final startTime = getTime(startPeriod);
    final endPeriod = startPeriod + periodCount - 1;
    final endTime = getTime(endPeriod + 1); // Next period's start time
    
    return '$startTime - $endTime';
  }

  /// ✅ Get compact period label
  /// Example: getPeriodLabel(4, 3, true) → "Lab P4-P6"
  /// Example: getPeriodLabel(2, 1, false) → "P2"
  static String getPeriodLabel(int startPeriod, int periodCount, bool isLab) {
    if (periodCount == 1) {
      return 'P$startPeriod';
    }
    
    final endPeriod = startPeriod + periodCount - 1;
    return '${isLab ? "Lab " : ""}P$startPeriod-P$endPeriod';
  }
}