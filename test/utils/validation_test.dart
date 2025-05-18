import 'package:flutter_test/flutter_test.dart';
import 'package:sifter/utils/validation.dart';

void main() {
  group('Validator', () {
    group('isValidEmail', () {
      test('returns true for valid emails', () {
        expect(Validator.isValidEmail('test@example.com'), isTrue);
        expect(Validator.isValidEmail('user.name@domain.co.uk'), isTrue);
      });

      test('returns false for invalid emails', () {
        expect(Validator.isValidEmail(''), isFalse);
        expect(Validator.isValidEmail('test'), isFalse);
        expect(Validator.isValidEmail('test@'), isFalse);
        expect(Validator.isValidEmail('@example.com'), isFalse);
      });
    });

    group('isValidPassword', () {
      test('returns true for valid passwords', () {
        expect(Validator.isValidPassword('password123'), isTrue);
        expect(Validator.isValidPassword('Secure1Password'), isTrue);
      });

      test('returns false for invalid passwords', () {
        expect(Validator.isValidPassword(''), isFalse, reason: "'empty string' should be invalid");
        expect(Validator.isValidPassword('short1'), isFalse, reason: "'short1' should be invalid");
        expect(Validator.isValidPassword('onlyletters'), isFalse, reason: "'onlyletters' should be invalid");
        expect(Validator.isValidPassword('12345678'), isFalse, reason: "'12345678' should be invalid");
      });
    });

    group('isValidUsername', () {
      test('returns true for valid usernames', () {
        expect(Validator.isValidUsername('user123'), isTrue);
        expect(Validator.isValidUsername('john_doe'), isTrue);
      });

      test('returns false for invalid usernames', () {
        expect(Validator.isValidUsername(''), isFalse);
        expect(Validator.isValidUsername('ab'), isFalse);
        expect(Validator.isValidUsername('user@name'), isFalse);
        expect(Validator.isValidUsername('very_long_username_over_20_chars'), isFalse);
      });
    });

    group('isEmptyOrWhitespace', () {
      test('returns true for empty or whitespace strings', () {
        expect(Validator.isEmptyOrWhitespace(''), isTrue);
        expect(Validator.isEmptyOrWhitespace('   '), isTrue);
        expect(Validator.isEmptyOrWhitespace(null), isTrue);
      });

      test('returns false for non-empty strings', () {
        expect(Validator.isEmptyOrWhitespace('text'), isFalse);
        expect(Validator.isEmptyOrWhitespace('  text  '), isFalse);
      });
    });

    group('isValidMessageContent', () {
      test('returns true for valid message content', () {
        expect(Validator.isValidMessageContent('Hello world'), isTrue);
        expect(Validator.isValidMessageContent('A' * 2000), isTrue);
      });

      test('returns false for invalid message content', () {
        expect(Validator.isValidMessageContent(''), isFalse);
        expect(Validator.isValidMessageContent('   '), isFalse);
        expect(Validator.isValidMessageContent('A' * 2001), isFalse);
      });
    });

    group('isValidRoomName', () {
      test('returns true for valid room names', () {
        expect(Validator.isValidRoomName('Test Room'), isTrue);
        expect(Validator.isValidRoomName('A' * 50), isTrue);
      });

      test('returns false for invalid room names', () {
        expect(Validator.isValidRoomName(''), isFalse);
        expect(Validator.isValidRoomName('  '), isFalse);
        expect(Validator.isValidRoomName('AB'), isFalse);
        expect(Validator.isValidRoomName('A' * 51), isFalse);
      });
    });
  });
} 