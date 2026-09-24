import 'package:elira/data/auth/auth_failure.dart';
import 'package:elira/values/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFailure.codeFromString', () {
    test('collapses every bad-login variant into one code', () {
      // Email Enumeration Protection returns invalid-credential for what used
      // to be wrong-password and user-not-found. Telling them apart again is
      // the account-enumeration hole the protection exists to close.
      for (final raw in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'invalid-login-credentials',
      ]) {
        expect(AuthFailure.codeFromString(raw), AuthFailureCode.invalidCredential);
      }
    });

    test('maps the signup and recovery codes', () {
      expect(AuthFailure.codeFromString('email-already-in-use'), AuthFailureCode.emailAlreadyInUse);
      expect(AuthFailure.codeFromString('weak-password'), AuthFailureCode.weakPassword);
      expect(AuthFailure.codeFromString('invalid-email'), AuthFailureCode.invalidEmail);
      expect(AuthFailure.codeFromString('user-disabled'), AuthFailureCode.userDisabled);
      expect(AuthFailure.codeFromString('network-request-failed'), AuthFailureCode.network);
      expect(AuthFailure.codeFromString('too-many-requests'), AuthFailureCode.tooManyRequests);
      expect(AuthFailure.codeFromString('operation-not-allowed'), AuthFailureCode.operationNotAllowed);
    });

    test('falls back to unknown for unrecognised codes', () {
      expect(AuthFailure.codeFromString('something-new-from-firebase'), AuthFailureCode.unknown);
    });
  });

  group('AppStrings.authError', () {
    test('has a message for every failure code', () {
      for (final code in AuthFailureCode.values) {
        expect(AppStrings.authError(code), isNotEmpty, reason: 'missing copy for ${code.name}');
      }
    });

    test('does not reveal whether an account exists', () {
      final message = AppStrings.authError(AuthFailureCode.invalidCredential).toLowerCase();
      expect(message.contains('no account'), isFalse);
      expect(message.contains('not found'), isFalse);
      expect(message.contains('not registered'), isFalse);
    });

    test('returns empty for a null code so the banner hides', () {
      expect(AppStrings.authError(null), isEmpty);
    });
  });
}
