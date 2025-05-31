import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Service for secure password hashing and verification
class PasswordService {
  /// Generate a random salt for password hashing
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List.generate(32, (index) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hash a password with salt using PBKDF2
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hashedPassword = _hashWithSalt(password, salt);

    // Store salt and hash together: salt:hash
    return '$salt:$hashedPassword';
  }

  /// Hash password with existing salt
  static String _hashWithSalt(String password, String salt) {
    // Use PBKDF2 with SHA256 for secure password hashing
    const codec = Utf8Codec();
    final passwordBytes = codec.encode(password);
    final saltBytes = base64Decode(salt);

    // Simple implementation - in production, use proper PBKDF2
    final combined = [...passwordBytes, ...saltBytes];

    // Apply multiple rounds of hashing for security
    var hash = sha256.convert(combined);
    for (int i = 0; i < 10000; i++) {
      hash = sha256.convert([...hash.bytes, ...saltBytes]);
    }

    return base64Encode(hash.bytes);
  }

  /// Verify a password against a stored hash
  static bool verifyPassword(String password, String storedHash) {
    try {
      // Parse stored hash: salt:hash
      final parts = storedHash.split(':');
      if (parts.length != 2) {
        return false; // Invalid stored hash format
      }

      final salt = parts[0];
      final expectedHash = parts[1];

      // Hash the provided password with the stored salt
      final actualHash = _hashWithSalt(password, salt);

      // Compare hashes
      return actualHash == expectedHash;
    } catch (e) {
      return false; // Error in verification process
    }
  }

  /// Validate password strength for room creation
  static PasswordStrengthResult validatePasswordStrength(String password) {
    if (password.length < 4) {
      return PasswordStrengthResult(
        isValid: false,
        message: 'Password must be at least 4 characters',
        strength: PasswordStrength.weak,
      );
    }

    if (password.length > 50) {
      return PasswordStrengthResult(
        isValid: false,
        message: 'Password must be less than 50 characters',
        strength: PasswordStrength.weak,
      );
    }

    // Check password strength
    PasswordStrength strength = PasswordStrength.weak;
    String message = 'Weak password';

    if (password.length >= 8) {
      bool hasUpper = password.contains(RegExp(r'[A-Z]'));
      bool hasLower = password.contains(RegExp(r'[a-z]'));
      bool hasNumber = password.contains(RegExp(r'[0-9]'));
      bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      int criteria = 0;
      if (hasUpper) criteria++;
      if (hasLower) criteria++;
      if (hasNumber) criteria++;
      if (hasSpecial) criteria++;

      if (criteria >= 3) {
        strength = PasswordStrength.strong;
        message = 'Strong password';
      } else if (criteria >= 2) {
        strength = PasswordStrength.medium;
        message = 'Medium password';
      }
    } else if (password.length >= 6) {
      strength = PasswordStrength.medium;
      message = 'Medium password';
    }

    return PasswordStrengthResult(
      isValid: true,
      message: message,
      strength: strength,
    );
  }

  /// Check if a password looks like it might be plain text (for migration)
  static bool isPlainTextPassword(String? storedPassword) {
    if (storedPassword == null || storedPassword.isEmpty) {
      return false;
    }

    // If it doesn't contain a colon, it's likely plain text
    return !storedPassword.contains(':');
  }

  /// Migrate old plain text password to hashed format
  static String? migratePasswordToHash(String? plainTextPassword) {
    if (plainTextPassword == null || plainTextPassword.isEmpty) {
      return null;
    }

    return hashPassword(plainTextPassword);
  }
}

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Result of password strength validation
class PasswordStrengthResult {
  final bool isValid;
  final String message;
  final PasswordStrength strength;

  PasswordStrengthResult({
    required this.isValid,
    required this.message,
    required this.strength,
  });
}
