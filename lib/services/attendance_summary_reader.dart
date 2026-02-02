import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_unflatten_helper.dart';

class AttendanceSummaryReader {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ ONE-TIME FETCH - No automatic updates
  Future<Map<String, dynamic>?> getStudentSummary({
    required String rollNo,
    required String month, // Format: "YYYY-MM"
  }) async {
    try {
      final docId = '${rollNo}_$month';

      final doc = await _db
          .collection('attendance_summaries')
          .doc(docId)
          .get(); // ✅ Single read

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final flatData = doc.data()!;

      // Check if data is already nested
      final hasNestedStructure =
          flatData.containsKey('overall') && flatData['overall'] is Map;

      if (hasNestedStructure) {
        return flatData;
      }

      // Unflatten flat Firestore data
      final unflattened = FirestoreUnflattenHelper.unflatten(flatData);
      return unflattened;
    } catch (_) {
      return null;
    }
  }

  Future<AttendanceSummary?> getMonthSummary({
    required String rollNo,
    required String month,
  }) async {
    final data = await getStudentSummary(rollNo: rollNo, month: month);
    if (data == null) return null;
    return AttendanceSummary.fromFirestore(data);
  }

  Future<AttendanceSummary?> getCurrentMonthSummary({
    required String rollNo,
  }) async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return getMonthSummary(rollNo: rollNo, month: month);
  }

  /// ✅ Manual refresh (after attendance submission)
  Future<void> refreshSummary({
    required String rollNo,
    required String month,
  }) async {
    await getStudentSummary(rollNo: rollNo, month: month);
  }

  @Deprecated('Backend now handles all summary updates automatically')
  Future<void> updateStudentSummaries({
    required String date,
    required String subjectName,
    required List<String> enrolledStudentIds,
    required List<String> presentStudentIds,
  }) async {
    return;
  }
}

// ===================== MODELS =====================

class AttendanceSummary {
  final String rollNo;
  final String month;
  final String? branch;
  final String? section;
  final String? year;
  final OverallStats overall;
  final Map<String, SubjectStats> bySubject;
  final Map<String, DateStats> byDate;
  final DateTime? updatedAt;

  AttendanceSummary({
    required this.rollNo,
    required this.month,
    this.branch,
    this.section,
    this.year,
    required this.overall,
    required this.bySubject,
    required this.byDate,
    this.updatedAt,
  });

  factory AttendanceSummary.fromFirestore(Map<String, dynamic> data) {
    return AttendanceSummary(
      rollNo: data['rollNo'] ?? '',
      month: data['month'] ?? '',
      branch: data['branch'],
      section: data['section'],
      year: data['year']?.toString(),
      overall: OverallStats.fromMap(data['overall'] ?? {}),
      bySubject: _parseSubjectStats(data['bySubject'] ?? {}),
      byDate: _parseDateStats(data['byDate'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, SubjectStats> _parseSubjectStats(
      Map<dynamic, dynamic> data) {
    return data.map((key, value) =>
        MapEntry(key.toString(), SubjectStats.fromMap(value as Map)));
  }

  static Map<String, DateStats> _parseDateStats(
      Map<dynamic, dynamic> data) {
    return data.map((key, value) =>
        MapEntry(key.toString(), DateStats.fromMap(value as Map)));
  }
}

class OverallStats {
  final int totalClasses;
  final int present;
  final double percentage;

  OverallStats({
    required this.totalClasses,
    required this.present,
    required this.percentage,
  });

  factory OverallStats.fromMap(Map<dynamic, dynamic> data) {
    final total = (data['totalClasses'] ?? 0) as int;
    final present = (data['present'] ?? 0) as int;

    final percentage = total > 0
        ? ((data['percentage'] ?? (present / total * 100)) as num).toDouble()
        : 0.0;

    return OverallStats(
      totalClasses: total,
      present: present,
      percentage: percentage,
    );
  }

  int get absent => totalClasses - present;
}

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

class DateStats {
  final int total;
  final int present;
  final Map<String, PeriodStats>? periods;

  DateStats({
    required this.total,
    required this.present,
    this.periods,
  });

  factory DateStats.fromMap(Map<dynamic, dynamic> data) {
    Map<String, PeriodStats>? periods;

    if (data['periods'] != null) {
      final periodsData = data['periods'] as Map<dynamic, dynamic>;
      periods = periodsData.map((key, value) =>
          MapEntry(key.toString(), PeriodStats.fromMap(value as Map)));
    }

    return DateStats(
      total: (data['total'] ?? 0) as int,
      present: (data['present'] ?? 0) as int,
      periods: periods,
    );
  }

  int get absent => total - present;
}

class PeriodStats {
  final String subject;
  final String subjectCode;
  final bool isPresent;
  final bool isLab;

  PeriodStats({
    required this.subject,
    required this.subjectCode,
    required this.isPresent,
    required this.isLab,
  });

  factory PeriodStats.fromMap(Map<dynamic, dynamic> data) {
    return PeriodStats(
      subject: data['subject'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      isPresent: data['isPresent'] ?? false,
      isLab: data['isLab'] ?? false,
    );
  }
}
