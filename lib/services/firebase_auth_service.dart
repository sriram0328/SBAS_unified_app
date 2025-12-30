import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Stream that notifies when the user's sign-in state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gets the currently signed-in user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs the current user out.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}