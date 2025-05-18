import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as crypto_encrypt;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

part 'encryption_service.g.dart';

@riverpod
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService();
}

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  crypto_encrypt.Encrypter? _encrypter;
  crypto_encrypt.IV? _iv;
  bool _isInitialized = false;

  /// Initialize the encryption service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get or generate encryption key
      String? storedKey = await _secureStorage.read(key: 'encryption_key');
      final key = storedKey ?? _generateKey();
      
      if (storedKey == null) {
        // Save the new key
        await _secureStorage.write(key: 'encryption_key', value: key);
      }

      // Create encrypter with the key
      final encryptKey = crypto_encrypt.Key.fromUtf8(key.padRight(32, '0').substring(0, 32));
      _iv = crypto_encrypt.IV.fromLength(16);
      _encrypter = crypto_encrypt.Encrypter(crypto_encrypt.AES(encryptKey));
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize encryption service: $e');
      // Try to continue with fallback
      _initializeFallback();
    }
  }

  /// Initialize with fallback in case of errors
  void _initializeFallback() {
    try {
      // Create a temporary key that will only last for this session
      final tempKey = crypto_encrypt.Key.fromSecureRandom(32);
      _iv = crypto_encrypt.IV.fromSecureRandom(16);
      _encrypter = crypto_encrypt.Encrypter(crypto_encrypt.AES(tempKey));
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize encryption fallback: $e');
      // Set the flag anyway to prevent repeated initialization attempts
      _isInitialized = true;
    }
  }

  /// Generate a new encryption key
  String _generateKey() {
    final random = crypto_encrypt.SecureRandom(32);
    return base64Url.encode(random.bytes);
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Encrypt a string
  Future<String> encrypt(String plainText) async {
    await _ensureInitialized();
    
    try {
      if (_encrypter == null || _iv == null) {
        throw Exception('Encryption not properly initialized');
      }
      
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      // Return a hash of the text as a fallback
      return _fallbackHash(plainText);
    }
  }

  /// Decrypt a string
  Future<String> decrypt(String encryptedText) async {
    await _ensureInitialized();
    
    try {
      if (_encrypter == null || _iv == null) {
        throw Exception('Encryption not properly initialized');
      }
      
      final encrypted = crypto_encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      debugPrint('Decryption error: $e');
      // Just return the encrypted text on error
      return encryptedText;
    }
  }

  /// Hash a string using SHA-256
  String hash(String input) {
    try {
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Hashing error: $e');
      return _fallbackHash(input);
    }
  }

  /// Fallback hashing method
  String _fallbackHash(String input) {
    // Very basic fallback - not secure but better than nothing
    return base64Encode(utf8.encode(input + DateTime.now().toIso8601String()));
  }

  /// Delete all stored encryption keys
  Future<void> clearKeys() async {
    try {
      await _secureStorage.delete(key: 'encryption_key');
      _isInitialized = false;
    } catch (e) {
      debugPrint('Failed to clear encryption keys: $e');
    }
  }

  /// Handle service initialization from main.dart
  Future<void> handleInitialization() async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('Error during encryption service initialization: $e');
      // Continue with app startup even if encryption fails
    }
  }
}
