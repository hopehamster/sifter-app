import 'package:flutter_test/flutter_test.dart';
import 'package:sifter/utils/security.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mock the FlutterSecureStorage
class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String value, Map<String, String>? options}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key, Map<String, String>? options}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key, Map<String, String>? options}) async {
    _storage.remove(key);
  }
}

void main() {
  group('SecurityUtils', () {
    group('hashPassword', () {
      test('returns consistent hash for same password and salt', () {
        const password = 'password123';
        const salt = 'abcdef1234567890';
        
        final hash1 = SecurityUtils.hashPassword(password, salt);
        final hash2 = SecurityUtils.hashPassword(password, salt);
        
        expect(hash1, equals(hash2));
      });
      
      test('returns different hashes for different passwords', () {
        const salt = 'abcdef1234567890';
        
        final hash1 = SecurityUtils.hashPassword('password123', salt);
        final hash2 = SecurityUtils.hashPassword('differentPassword', salt);
        
        expect(hash1, isNot(equals(hash2)));
      });
      
      test('returns different hashes for different salts', () {
        const password = 'password123';
        
        final hash1 = SecurityUtils.hashPassword(password, 'salt1');
        final hash2 = SecurityUtils.hashPassword(password, 'salt2');
        
        expect(hash1, isNot(equals(hash2)));
      });
    });
    
    group('verifyPassword', () {
      test('returns true for correct password', () {
        const password = 'correctPassword';
        const salt = 'abcdef1234567890';
        
        final hash = SecurityUtils.hashPassword(password, salt);
        
        expect(SecurityUtils.verifyPassword(password, salt, hash), isTrue);
      });
      
      test('returns false for incorrect password', () {
        const correctPassword = 'correctPassword';
        const wrongPassword = 'wrongPassword';
        const salt = 'abcdef1234567890';
        
        final hash = SecurityUtils.hashPassword(correctPassword, salt);
        
        expect(SecurityUtils.verifyPassword(wrongPassword, salt, hash), isFalse);
      });
    });
    
    group('generateSalt', () {
      test('generates salt of correct length', () {
        final salt = SecurityUtils.generateSalt();
        expect(salt.length, equals(16));
      });
      
      test('generates different salts on consecutive calls', () {
        final salt1 = SecurityUtils.generateSalt();
        final salt2 = SecurityUtils.generateSalt();
        
        expect(salt1, isNot(equals(salt2)));
      });
    });
  });
} 