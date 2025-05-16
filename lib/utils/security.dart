import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityUtils {
  static final _secureStorage = FlutterSecureStorage();
  
  // Hash a password using SHA-256
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Securely store a token or sensitive value
  static Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  // Retrieve securely stored data
  static Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  // Delete securely stored data
  static Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Check if key exists in secure storage
  static Future<bool> hasSecureData(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }
  
  // Generate a random salt
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  // Verify a password against its hash
  static bool verifyPassword(String password, String salt, String hash) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hash;
  }
} 