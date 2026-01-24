// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches a user's full profile data from either the 'students' or 'faculty' collection.
  ///
  /// [userId] is the document ID (e.g., roll number or faculty ID).
  /// [role] should be either 'student' or 'faculty'.
  Future<Map<String, dynamic>?> getUserData(String userId, String role) async {
    try {
      final collectionName = role == 'student' ? 'students' : 'faculty';
      final docRef = _db.collection(collectionName).doc(userId);
      final docSnap = await docRef.get();
      

      if (docSnap.exists) {
        return docSnap.data();
      } else {
        print('No user data found for ID: $userId in collection: $collectionName');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Fetches the timetable for a specific faculty member.
  /// Returns a stream so the UI can update in real-time if the timetable changes.
  Stream<DocumentSnapshot> getFacultyTimetableStream(String facultyId) {
    return _db.collection('faculty_timetables').doc(facultyId).snapshots();
  }

  /// Generic function to fetch a single document from any collection.
  Future<DocumentSnapshot> getDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).get();
  }
}