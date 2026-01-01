class FacultyModel {
  final String id;
  final String uid; // Firebase Auth UID
  final String name;
  final String employeeId;
  final String email;
  final String department;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> assignedSubjects;
  final DateTime createdAt;

  FacultyModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.employeeId,
    required this.email,
    required this.department,
    this.phoneNumber,
    this.profileImageUrl,
    this.assignedSubjects = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'employeeId': employeeId,
      'email': email,
      'department': department,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'assignedSubjects': assignedSubjects,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FacultyModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FacultyModel(
      id: documentId,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      employeeId: map['employeeId'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      assignedSubjects: List<String>.from(map['assignedSubjects'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
