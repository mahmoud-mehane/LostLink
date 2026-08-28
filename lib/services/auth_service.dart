import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile_repository.dart';

class AuthService {
  AuthService(this._auth, this._userProfileRepository);

  final FirebaseAuth _auth;
  final UserProfileRepository _userProfileRepository;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const RegistrationFailure(
          'Your account could not be completed. Please try again.',
        );
      }

      try {
        await _userProfileRepository.createProfile(
          uid: user.uid,
          email: user.email ?? email,
          name: name,
        );
      } on UserProfileFailure catch (error) {
        throw RegistrationFailure(error.message);
      }

      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  User? get currentUser => _auth.currentUser;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  factory AuthFailure.fromFirebase(FirebaseAuthException error) =>
      AuthFailure.fromCode(error.code);

  factory AuthFailure.fromCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const AuthFailure('An account already exists for this email.');
      case 'invalid-email':
        return const AuthFailure('Enter a valid email address.');
      case 'weak-password':
        return const AuthFailure('Use a stronger password (at least 6 characters).');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return const AuthFailure('Email or password is incorrect.');
      case 'network-request-failed':
        return const AuthFailure('Network error. Check your connection and try again.');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Please try again later.');
      default:
        return const AuthFailure('Something went wrong. Please try again.');
    }
  }
}

class RegistrationFailure implements Exception {
  const RegistrationFailure(this.message);

  final String message;
}
