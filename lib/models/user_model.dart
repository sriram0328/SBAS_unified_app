class UserModel {
  final String uid;
  final String email;
  final String role; // 'student' or 'faculty'
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.parse(map['lastLogin']) 
          : null,
    );
  }
}
