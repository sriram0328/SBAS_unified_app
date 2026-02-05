import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// ✅ ONE-TIME FETCH of user data
  Future<Map<String, dynamic>?> getUserData(String userId, String role) async {
    try {
      final collectionName = role == 'student' ? 'students' : 'faculty';
      final docRef = _db.collection(collectionName).doc(userId);
      final docSnap = await docRef.get(); // ✅ Single read

      if (docSnap.exists) {
        return docSnap.data();
      } else {
        _logger.i('No user data found for ID: $userId in collection: $collectionName');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting user data: $e');
      return null;
    }
  }

  // ❌ REMOVED: getFacultyTimetableStream() - was causing continuous reads!
  
  /// ✅ NEW: One-time fetch of timetable
  Future<Map<String, dynamic>?> getFacultyTimetable(String facultyId) async {
    try {
      final doc = await _db
          .collection('faculty_timetables')
          .doc(facultyId)
          .get();
          
      if (!doc.exists) {
        _logger.i('No timetable found for faculty: $facultyId');
        return null;
      }
      
      return doc.data();
    } catch (e) {
      _logger.e('Error getting faculty timetable: $e');
      return null;
    }
  }

  /// Generic function to fetch a single document from any collection
  Future<DocumentSnapshot> getDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).get();
  }
}
