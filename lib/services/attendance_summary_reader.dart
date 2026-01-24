// lib/services/attendance_summary_reader.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Simple reader service for pre-computed attendance summaries
/// The backend handles all writes - this only reads
class AttendanceSummaryReader {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get student's attendance summary for a specific month
  /// Returns raw map data (backward compatible with old code)
  Future<Map<String, dynamic>?> getStudentSummary({
    required String rollNo,
    required String month, // Format: "YYYY-MM"
  }) async {
    try {
      final docId = '${rollNo}_$month';
      final doc = await _db
          .collection('attendance_summaries')
          .doc(docId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return doc.data();
    } catch (e) {
      debugPrint('Error fetching summary: $e');
      return null;
    }
  }

  /// Get student's attendance summary as typed object
  Future<AttendanceSummary?> getMonthSummary({
    required String rollNo,
    required String month,
  }) async {
    final data = await getStudentSummary(rollNo: rollNo, month: month);
    if (data == null) return null;
    return AttendanceSummary.fromFirestore(data);
  }

  /// Get student's current month summary
  Future<AttendanceSummary?> getCurrentMonthSummary({
    required String rollNo,
  }) async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return getMonthSummary(rollNo: rollNo, month: month);
  }

  /// Stream real-time updates for a student's month
  Stream<AttendanceSummary?> streamMonthSummary({
    required String rollNo,
    required String month,
  }) {
    final docId = '${rollNo}_$month';
    return _db
        .collection('attendance_summaries')
        .doc(docId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return AttendanceSummary.fromFirestore(doc.data()!);
        });
  }

  /// This method is NOT needed anymore - backend handles all updates
  /// Keeping it as a no-op to prevent breaking existing code
  @Deprecated('Backend now handles all summary updates automatically')
  Future<void> updateStudentSummaries({
    required String date,
    required String subjectName,
    required List<String> enrolledStudentIds,
    required List<String> presentStudentIds,
  }) async {
    debugPrint('⚠️ updateStudentSummaries called but is deprecated - backend handles this now');
    // Do nothing - backend handles updates via Cloud Functions or admin panel
  }
}

/// Model class for attendance summary data
class AttendanceSummary {
  final String studentId;
  final String month;
  final OverallStats overall;
  final Map<String, SubjectStats> bySubject;
  final Map<String, DateStats> byDate;
  final DateTime? updatedAt;

  AttendanceSummary({
    required this.studentId,
    required this.month,
    required this.overall,
    required this.bySubject,
    required this.byDate,
    this.updatedAt,
  });

  factory AttendanceSummary.fromFirestore(Map<String, dynamic> data) {
    return AttendanceSummary(
      studentId: data['studentId'] ?? '',
      month: data['month'] ?? '',
      overall: OverallStats.fromMap(data['overall'] ?? {}),
      bySubject: _parseSubjectStats(data['bySubject'] ?? {}),
      byDate: _parseDateStats(data['byDate'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, SubjectStats> _parseSubjectStats(Map<dynamic, dynamic> data) {
    return data.map((key, value) =>
        MapEntry(key.toString(), SubjectStats.fromMap(value as Map)));
  }

  static Map<String, DateStats> _parseDateStats(Map<dynamic, dynamic> data) {
    return data.map((key, value) =>
        MapEntry(key.toString(), DateStats.fromMap(value as Map)));
  }
}

/// Overall attendance statistics
class OverallStats {
  final int totalClasses;
  final int present;
  final int absent;
  final double percentage;

  OverallStats({
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  factory OverallStats.fromMap(Map<dynamic, dynamic> data) {
    final total = (data['totalClasses'] ?? 0) as int;
    final present = (data['present'] ?? 0) as int;
    final absent = (data['absent'] ?? 0) as int;
    
    // Backend should calculate this, but fallback just in case
    final percentage = total > 0 
        ? ((data['percentage'] ?? (present / total * 100)) as num).toDouble()
        : 0.0;

    return OverallStats(
      totalClasses: total,
      present: present,
      absent: absent,
      percentage: percentage,
    );
  }
}

/// Per-subject statistics
class SubjectStats {
  final int total;
  final int present;
  final double percentage;

  SubjectStats({
    required this.total,
    required this.present,
    required this.percentage,
  });

  factory SubjectStats.fromMap(Map<dynamic, dynamic> data) {
    final total = (data['total'] ?? 0) as int;
    final present = (data['present'] ?? 0) as int;
    
    final percentage = total > 0
        ? ((data['percentage'] ?? (present / total * 100)) as num).toDouble()
        : 0.0;

    return SubjectStats(
      total: total,
      present: present,
      percentage: percentage,
    );
  }

  int get absent => total - present;
}

/// Per-date statistics
class DateStats {
  final int total;
  final int present;

  DateStats({
    required this.total,
    required this.present,
  });

  factory DateStats.fromMap(Map<dynamic, dynamic> data) {
    return DateStats(
      total: (data['total'] ?? 0) as int,
      present: (data['present'] ?? 0) as int,
    );
  }

  int get absent => total - present;
}