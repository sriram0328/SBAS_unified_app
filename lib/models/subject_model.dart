class SubjectModel {
  final String code;
  final String name;
  final int credits;
  final String department;
  final int semester;
  final String? description;

  SubjectModel({
    required this.code,
    required this.name,
    required this.credits,
    required this.department,
    required this.semester,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'credits': credits,
      'department': department,
      'semester': semester,
      'description': description,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      credits: map['credits'] ?? 0,
      department: map['department'] ?? '',
      semester: map['semester'] ?? 0,
      description: map['description'],
    );
  }
}