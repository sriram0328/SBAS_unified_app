import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Unified login for Student & Faculty
  /// Username = ID
  /// Password = ID
  Future<Map<String, dynamic>> login(String userId, String password) async {
    try {
      DocumentSnapshot? userDoc;
      String role = '';
      final authEmail = '$userId@ex.com';

      /* ---------- STUDENT ---------- */
      final studentDoc =
          await _db.collection('students').doc(userId).get();

      if (studentDoc.exists) {
        role = 'student';
        userDoc = studentDoc;
      }

      /* ---------- FACULTY ---------- */
      if (userDoc == null) {
        final facultyDoc =
            await _db.collection('faculty').doc(userId).get();

        if (facultyDoc.exists) {
          role = 'faculty';
          userDoc = facultyDoc;
        }
      }

      if (userDoc == null) {
        throw Exception('User not found');
      }

      /* ---------- PASSWORD CHECK ---------- */
      if (password != userId) {
        throw Exception('Invalid credentials');
      }

      /* ---------- AUTH LOGIN ---------- */
      await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      final authUid = _auth.currentUser!.uid;
      final data = userDoc.data() as Map<String, dynamic>;

      /* ---------- UID VALIDATION ---------- */
      if (data['authUid'] != authUid) {
        await _auth.signOut();
        throw Exception('Auth mismatch. Contact admin.');
      }

      /* ---------- MAP DATA ---------- */
      final result = {
        'userId': userDoc.id,
        'authUid': authUid,
        'role': role,
        'name': data['name'] ?? '',
        'email': authEmail,
      };

      if (role == 'student') {
        result.addAll({
          'rollNo': userDoc.id,
          'branch': data['branch'] ?? '',
          'year': data['year'] ?? '',
          'section': data['section'] ?? '',
          'phone': data['studentPhone'] ?? '',
          'parentPhone': data['parentPhone'] ?? '',
        });
      }

      if (role == 'faculty') {
        result.addAll({
          'facultyId': userDoc.id,
          'department': data['department'] ?? '',
          'phone': data['facultyPhone'] ?? '',
          'subjects': data['subjects'] ?? [],
        });
      }

      debugPrint('✅ Login success: $userId ($role)');
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
