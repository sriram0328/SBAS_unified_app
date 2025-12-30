import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoginService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Login with Firestore database
  /// Uses rollNo/facultyId as both username AND password
  Future<Map<String, dynamic>> login(String userId, String password) async {
    try {
      // Step 1: Try to find user in students collection by rollno
      QuerySnapshot studentQuery = await _db
          .collection('students')
          .where('rollno', isEqualTo: userId)
          .limit(1)
          .get();

      DocumentSnapshot? userDoc;
      String role = 'student';
      String docId = '';

      if (studentQuery.docs.isNotEmpty) {
        // Found in students
        userDoc = studentQuery.docs.first;
        docId = userDoc.id;
        role = 'student';
      } else {
        // Step 2: Try faculty collection by facultyId
        QuerySnapshot facultyQuery = await _db
            .collection('faculty')
            .where('facultyId', isEqualTo: userId)
            .limit(1)
            .get();

        if (facultyQuery.docs.isNotEmpty) {
          userDoc = facultyQuery.docs.first;
          docId = userDoc.id;
          role = 'faculty';
        }
      }

      // Step 3: If not found in either collection
      if (userDoc == null) {
        throw Exception('User not found. Please check your ID.');
      }

      // Step 4: Get user data
      final userData = userDoc.data() as Map<String, dynamic>;

      // Step 5: Verify password (using rollno/facultyId as password)
      if (role == 'student') {
        final storedRollNo = userData['rollno'] as String?;
        if (storedRollNo == null || storedRollNo != password) {
          throw Exception('Invalid credentials.');
        }
      } else {
        final storedFacultyId = userData['facultyId'] as String?;
        if (storedFacultyId == null || storedFacultyId != password) {
          throw Exception('Invalid credentials.');
        }
      }

      // Step 6: Sign in to Firebase Auth anonymously
      await _firebaseAuth.signInAnonymously();

      // Step 7: Map your DB fields to app fields
      final mappedData = {
        'userId': docId,
        'role': role,
        'name': userData['name'] ?? '',
        'email': userData['email'] ?? '',
        'branch': userData['branch'] ?? '',
        'year': userData['year'] ?? '',
        'section': userData['section'] ?? '',
        
        // Student specific fields
        if (role == 'student') ...{
          'rollNo': userData['rollno'] ?? '',
          'phone': userData['studentPhone'] ?? '',
          'parentPhone': userData['parentPhone'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'barcodeImageUrl': userData['barcodeImageUrl'] ?? '',
          'department': _getDepartmentName(userData['branch'] ?? ''),
        },
        
        // Faculty specific fields
        if (role == 'faculty') ...{
          'facultyId': userData['facultyId'] ?? '',
          'phone': userData['facultyPhone'] ?? '',
          'department': userData['department'] ?? '',
          'subjects': userData['subjects'] ?? [],
        },
      };

      debugPrint('✅ Login successful: $userId ($role)');
      
      return mappedData;

    } catch (e) {
      debugPrint('LoginService Error: $e');
      rethrow;
    }
  }

  /// Helper to get full department name from branch code
  String _getDepartmentName(String branch) {
    const departments = {
      'AIML': 'Artificial Intelligence & Machine Learning',
      'CSE': 'Computer Science & Engineering',
      'ECE': 'Electronics & Communication Engineering',
      'EEE': 'Electrical & Electronics Engineering',
      'MECH': 'Mechanical Engineering',
      'CIVIL': 'Civil Engineering',
    };
    return departments[branch] ?? branch;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}