import 'package:elira/values/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty and whitespace-only input', () {
      expect(validateEmail(null), 'emailRequired');
      expect(validateEmail(''), 'emailRequired');
      expect(validateEmail('   '), 'emailRequired');
    });

    test('rejects malformed addresses', () {
      for (final bad in ['nope', 'a@b', 'a@b.', '@b.com', 'a b@c.com', 'a@@b.com']) {
        expect(validateEmail(bad), 'emailInvalid', reason: 'should reject "$bad"');
      }
    });

    test('accepts valid addresses and ignores surrounding whitespace', () {
      for (final good in ['a@b.co', 'first.last@example.com', 'user+tag@sub.domain.org']) {
        expect(validateEmail(good), isNull, reason: 'should accept "$good"');
      }
      expect(validateEmail('  padded@example.com  '), isNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty', () => expect(validatePassword(''), 'passwordRequired'));

    test('rejects below the Firebase minimum', () {
      expect(validatePassword('12345'), 'passwordTooShort');
    });

    test('accepts exactly the minimum length', () {
      expect(validatePassword('123456'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('rejects empty', () => expect(validateConfirmPassword('', 'abcdef'), 'confirmRequired'));
    test('rejects mismatch', () => expect(validateConfirmPassword('abcdeg', 'abcdef'), 'confirmMismatch'));
    test('accepts match', () => expect(validateConfirmPassword('abcdef', 'abcdef'), isNull));
  });

  group('validateDisplayName', () {
    test('rejects empty', () => expect(validateDisplayName('  '), 'nameRequired'));
    test('rejects single character', () => expect(validateDisplayName('A'), 'nameTooShort'));
    test('rejects overlong', () => expect(validateDisplayName('a' * 41), 'nameTooLong'));
    test('accepts a normal name', () => expect(validateDisplayName('  Linh  '), isNull));
  });
}
