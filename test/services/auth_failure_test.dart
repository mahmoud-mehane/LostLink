import 'package:flutter_test/flutter_test.dart';
import 'package:lostlink/services/auth_service.dart';

void main() {
  group('AuthFailure', () {
    test('maps invalid credentials to a readable message', () {
      expect(
        AuthFailure.fromCode('invalid-credential').message,
        'Email or password is incorrect.',
      );
    });

    test('maps an existing email to a readable message', () {
      expect(
        AuthFailure.fromCode('email-already-in-use').message,
        'An account already exists for this email.',
      );
    });
  });
}
