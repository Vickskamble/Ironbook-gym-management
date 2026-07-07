import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user@domain.co'), isNull);
      });

      test('returns error for invalid email', () {
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail('not-an-email'), isNotNull);
        expect(Validators.validateEmail('@domain.com'), isNotNull);
      });
    });

    group('validatePhone', () {
      test('returns null for valid phone', () {
        expect(Validators.validatePhone('9876543210'), isNull);
        expect(Validators.validatePhone('1234567890'), isNull);
      });

      test('returns error for invalid phone', () {
        expect(Validators.validatePhone(''), isNotNull);
        expect(Validators.validatePhone('123'), isNotNull);
        expect(Validators.validatePhone('abcdefghij'), isNotNull);
      });
    });

    group('validatePassword', () {
      test('returns null for valid password (8+ chars)', () {
        expect(Validators.validatePassword('Password1'), isNull);
        expect(Validators.validatePassword('MyPass123'), isNull);
      });

      test('returns error for short password (< 8 chars)', () {
        expect(Validators.validatePassword(''), isNotNull);
        expect(Validators.validatePassword('1234567'), isNotNull);
      });
    });

    group('validateRequired', () {
      test('returns null for non-empty value', () {
        expect(Validators.validateRequired('Rahul', 'Name'), isNull);
        expect(Validators.validateRequired('Rahul Sharma', 'Name'), isNull);
      });

      test('returns error for empty value', () {
        expect(Validators.validateRequired('', 'Name'), isNotNull);
        expect(Validators.validateRequired('   ', 'Name'), isNotNull);
      });
    });

    group('validateConfirmPassword', () {
      test('returns null when passwords match', () {
        expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
      });

      test('returns error when passwords do not match', () {
        expect(Validators.validateConfirmPassword('pass123', 'pass456'), isNotNull);
      });

      test('returns error when empty', () {
        expect(Validators.validateConfirmPassword('', 'pass123'), isNotNull);
      });
    });

    group('validatePositiveNumber', () {
      test('returns null for positive number', () {
        expect(Validators.validatePositiveNumber('100', 'Price'), isNull);
      });

      test('returns error for zero or negative', () {
        expect(Validators.validatePositiveNumber('0', 'Price'), isNotNull);
        expect(Validators.validatePositiveNumber('-5', 'Price'), isNotNull);
        expect(Validators.validatePositiveNumber('abc', 'Price'), isNotNull);
      });
    });
  });
}
