import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() => _auth.signOut();

  static String readableError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account is disabled.';
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return 'Authentication failed. Please try again.';
  }
}
