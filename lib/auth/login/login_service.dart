import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      final authUid = user.uid;

      final token = await user.getIdTokenResult(true);
      final role = token.claims?['role'];

      if (role != 'student' && role != 'faculty') {
        await _auth.signOut();
        throw Exception('Invalid role. Contact admin.');
      }

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

      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}