import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for content filtering, NSFW detection, and link validation
class ContentFilterService {
  // Profanity word list (basic implementation - in production, use a comprehensive database)
  static const List<String> _profanityWords = [
    // Add profanity words here - keeping minimal for example
    'badword1',
    'badword2',
    // In production, use a comprehensive profanity filter library
  ];

  // NSFW keywords for content detection
  static const List<String> _nsfwKeywords = [
    // Add NSFW keywords here - keeping minimal for example
    'adult',
    'explicit',
    // In production, use a comprehensive NSFW detection service
  ];

  // Spam indicators
  static const List<String> _spamIndicators = [
    'click here',
    'free money',
    'limited time',
    'act now',
    'buy now',
    'www.',
    'http',
    '.com',
    '.net',
    '.org',
  ];

  /// Check if message contains profanity
  bool containsProfanity(String text) {
    if (text.isEmpty) return false;

    final lowercaseText = text.toLowerCase();
    return _profanityWords
        .any((word) => lowercaseText.contains(word.toLowerCase()));
  }

  /// Check if content contains NSFW material
  bool containsNSFW(String text) {
    if (text.isEmpty) return false;

    final lowercaseText = text.toLowerCase();
    return _nsfwKeywords
        .any((keyword) => lowercaseText.contains(keyword.toLowerCase()));
  }

  /// Check if message appears to be spam
  bool isSpam(String text) {
    if (text.isEmpty) return false;

    final lowercaseText = text.toLowerCase();

    // Check for spam indicators
    int spamScore = 0;

    for (final indicator in _spamIndicators) {
      if (lowercaseText.contains(indicator)) {
        spamScore++;
      }
    }

    // Check for excessive capitalization
    final upperCaseCount =
        text.split('').where((char) => char == char.toUpperCase()).length;
    if (upperCaseCount > text.length * 0.7 && text.length > 10) {
      spamScore += 2;
    }

    // Check for excessive punctuation
    final punctuationCount =
        text.split('').where((char) => '!?.,;:'.contains(char)).length;
    if (punctuationCount > text.length * 0.3) {
      spamScore += 1;
    }

    // Check for repeated characters
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) {
      spamScore += 1;
    }

    return spamScore >= 3;
  }

  /// Check if URL is potentially malicious
  bool isSuspiciousLink(String url) {
    if (url.isEmpty) return false;

    final lowercaseUrl = url.toLowerCase();

    // Known suspicious patterns
    final suspiciousPatterns = [
      'bit.ly',
      'tinyurl',
      'shorturl',
      'redirect',
      'phishing',
      'malware',
      // Add more suspicious patterns
    ];

    return suspiciousPatterns.any((pattern) => lowercaseUrl.contains(pattern));
  }

  /// Validate and clean URL
  String? validateUrl(String url) {
    if (url.isEmpty) return null;

    // Basic URL validation
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(url)) {
      return null; // Invalid URL format
    }

    if (isSuspiciousLink(url)) {
      return null; // Suspicious link
    }

    // Ensure URL starts with https for security
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }

    return url;
  }

  /// Clean message by removing profanity and inappropriate content
  String cleanMessage(String text) {
    if (text.isEmpty) return text;

    String cleanedText = text;

    // Replace profanity with asterisks
    for (final word in _profanityWords) {
      final regex = RegExp(word, caseSensitive: false);
      cleanedText = cleanedText.replaceAll(regex, '*' * word.length);
    }

    return cleanedText;
  }

  /// Check if username is appropriate
  bool isUsernameAppropriate(String username) {
    if (username.isEmpty || username.length > 30) return false;

    // Check for profanity
    if (containsProfanity(username)) return false;

    // Check for NSFW content
    if (containsNSFW(username)) return false;

    // Check for valid characters (alphanumeric and underscores only)
    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validUsernameRegex.hasMatch(username)) return false;

    // Check for reserved words
    final reservedWords = [
      'admin',
      'moderator',
      'system',
      'bot',
      'support',
      'sifter',
      'chat',
      'user',
      'guest',
      'anonymous'
    ];

    return !reservedWords.contains(username.toLowerCase());
  }

  /// Check if chat room name is appropriate
  bool isRoomNameAppropriate(String roomName) {
    if (roomName.isEmpty || roomName.length > 50) return false;

    // Check for profanity
    if (containsProfanity(roomName)) return false;

    // Check for NSFW content (unless explicitly marked as NSFW room)
    if (containsNSFW(roomName)) return false;

    // Check for spam patterns
    if (isSpam(roomName)) return false;

    return true;
  }

  /// Get content severity level
  ContentSeverity getContentSeverity(String text) {
    if (text.isEmpty) return ContentSeverity.clean;

    if (containsProfanity(text)) return ContentSeverity.profanity;
    if (containsNSFW(text)) return ContentSeverity.nsfw;
    if (isSpam(text)) return ContentSeverity.spam;

    return ContentSeverity.clean;
  }

  /// Validate message before sending
  MessageValidationResult validateMessage(String text,
      {bool isNSFWRoom = false}) {
    if (text.isEmpty) {
      return MessageValidationResult(
        isValid: false,
        reason: 'Message cannot be empty',
        severity: ContentSeverity.clean,
      );
    }

    if (text.length > 1000) {
      return MessageValidationResult(
        isValid: false,
        reason: 'Message is too long (max 1000 characters)',
        severity: ContentSeverity.clean,
      );
    }

    final severity = getContentSeverity(text);

    switch (severity) {
      case ContentSeverity.spam:
        return MessageValidationResult(
          isValid: false,
          reason: 'Message appears to be spam',
          severity: severity,
        );
      case ContentSeverity.profanity:
        return MessageValidationResult(
          isValid: true, // Allow but will be cleaned
          reason: 'Message contains profanity and will be filtered',
          severity: severity,
          cleanedText: cleanMessage(text),
        );
      case ContentSeverity.nsfw:
        if (!isNSFWRoom) {
          return MessageValidationResult(
            isValid: false,
            reason: 'NSFW content not allowed in this room',
            severity: severity,
          );
        }
        return MessageValidationResult(
          isValid: true,
          reason: null,
          severity: severity,
        );
      case ContentSeverity.clean:
        return MessageValidationResult(
          isValid: true,
          reason: null,
          severity: severity,
        );
    }
  }

  /// Extract URLs from text
  List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );

    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  /// Validate all URLs in message
  bool areUrlsValid(String text) {
    final urls = extractUrls(text);
    return urls.every((url) => validateUrl(url) != null);
  }
}

/// Content severity levels
enum ContentSeverity {
  clean,
  profanity,
  nsfw,
  spam,
}

/// Message validation result
class MessageValidationResult {
  final bool isValid;
  final String? reason;
  final ContentSeverity severity;
  final String? cleanedText;

  MessageValidationResult({
    required this.isValid,
    this.reason,
    required this.severity,
    this.cleanedText,
  });
}

/// Provider for ContentFilterService
final contentFilterServiceProvider = Provider<ContentFilterService>((ref) {
  return ContentFilterService();
});
