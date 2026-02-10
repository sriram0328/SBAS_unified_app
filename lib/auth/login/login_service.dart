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
    } on FirebaseAuthException catch (e) {
      // Convert Firebase errors to user-friendly messages
      throw Exception(_handleAuthError(e));
    } on FirebaseException catch (e) {
      // Handle Firestore errors
      throw Exception(_handleFirestoreError(e));
    } catch (e) {
      // Handle any other errors
      rethrow;
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'Invalid credentials. Please check your ID and password';
      case 'wrong-password':
        return 'Invalid credentials. Please check your ID and password';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your ID and password';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'No internet connection. Please check your network';
      case 'operation-not-allowed':
        return 'Login is currently disabled. Contact support';
      default:
        return 'Login failed. Please try again';
    }
  }

  String _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again';
      case 'permission-denied':
        return 'Access denied. Contact administrator';
      case 'not-found':
        return 'User profile not found';
      default:
        if (e.message?.contains('network') ?? false) {
          return 'No internet connection. Please check your network';
        }
        return 'An error occurred. Please try again';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}