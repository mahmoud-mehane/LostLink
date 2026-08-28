import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> createProfile({
    required String uid,
    required String email,
    required String name,
  }) async {
    final document = _firestore.collection('users').doc(uid);

    try {
      final existingProfile = await document.get();
      if (existingProfile.exists) return;

      await document.set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      throw const UserProfileFailure(
        'We could not create your profile. Please try again.',
      );
    }
  }
}

class UserProfileFailure implements Exception {
  const UserProfileFailure(this.message);

  final String message;
}
