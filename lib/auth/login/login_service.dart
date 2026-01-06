import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Unified login for Student & Faculty
  /// email = REAL email address
  /// password = password
  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      /* ---------- AUTH FIRST ---------- */
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(), // ✅ REAL email
        password: password,
      );

      final user = credential.user!;
      final authUid = user.uid;

      /* ---------- ROLE FROM CUSTOM CLAIM ---------- */
      final token = await user.getIdTokenResult(true);
      final role = token.claims?['role'];

      if (role != 'student' && role != 'faculty') {
        await _auth.signOut();
        throw Exception('Invalid role. Contact admin.');
      }

      /* ---------- READ PROFILE BY UID ---------- */
      final collection = role == 'student' ? 'students' : 'faculty';

      final userDoc = await _db
          .collection(collection)
          .doc(authUid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception(
          '${role.toString().toUpperCase()} profile not found',
        );
      }

      final data = userDoc.data() as Map<String, dynamic>;

      /* ---------- MAP RESULT ---------- */
      final result = <String, dynamic>{
        'authUid': authUid,
        'role': role,
        'name': data['name'] ?? '',
        'email': email.trim(),
      };

      if (role == 'student') {
        result.addAll({
          'studentId': authUid,
          'rollNo': data['rollno'] ?? '',
          'branch': data['branch'] ?? '',
          'section': data['section'] ?? '',
          'phone': data['studentPhone'] ?? '',
          'parentPhone': data['parentPhone'] ?? '',
        });
      }

      if (role == 'faculty') {
        result.addAll({
          'facultyId': authUid,
          'department': data['department'] ?? '',
          'phone': data['facultyPhone'] ?? '',
          'subjects': data['subjects'] ?? [],
        });
      }

      debugPrint('✅ Login success [$role]: $authUid');
      return result;
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
