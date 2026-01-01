class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final String subjectCode;
  final String subjectName;
  final String facultyId;
  final String facultyName;
  final DateTime timestamp;
  final String status; // 'present', 'absent', 'late'
  final String? location;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyId,
    required this.facultyName,
    required this.timestamp,
    required this.status,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNumber': studentRollNumber,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'location': location,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceRecord(
      id: documentId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentRollNumber: map['studentRollNumber'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      facultyId: map['facultyId'] ?? '',
      facultyName: map['facultyName'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? 'present',
      location: map['location'],
      notes: map['notes'],
    );
  }
}

class AttendanceSession {
  final String id;
  final String facultyId;
  final String subjectCode;
  final String subjectName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final List<String> presentStudents;
  final String? location;

  AttendanceSession({
    required this.id,
    required this.facultyId,
    required this.subjectCode,
    required this.subjectName,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.presentStudents,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facultyId': facultyId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
      'presentStudents': presentStudents,
      'location': location,
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceSession(
      id: documentId,
      facultyId: map['facultyId'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      isActive: map['isActive'] ?? false,
      presentStudents: List<String>.from(map['presentStudents'] ?? []),
      location: map['location'],
    );
  }
}