class StudentModel {
  final String id;
  final String uid; // Firebase Auth UID
  final String name;
  final String rollNumber;
  final String email;
  final String department;
  final int year;
  final String section;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> enrolledSubjects;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.department,
    required this.year,
    required this.section,
    this.phoneNumber,
    this.profileImageUrl,
    this.enrolledSubjects = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'department': department,
      'year': year,
      'section': section,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'enrolledSubjects': enrolledSubjects,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      id: documentId,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? 1,
      section: map['section'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      enrolledSubjects: List<String>.from(map['enrolledSubjects'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Generate Barcode data (typically uses roll number or student ID)
  String get barcodeData => rollNumber; // Use roll number as barcode
  
  // Alternative: use student ID as barcode
  String get barcodeId => id;
  
  // Validate scanned barcode
  bool isValidBarcode(String scannedData) {
    return scannedData == rollNumber || scannedData == id;
  }
}