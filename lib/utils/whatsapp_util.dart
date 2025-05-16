import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sifter/utils/security.dart';

/// Utility class for WhatsApp interactions without exposing phone numbers
class WhatsAppUtil {
  /// Launches WhatsApp chat with pre-defined text message
  /// Phone number is securely retrieved from storage
  static Future<void> launchWhatsAppChat({
    String? message,
  }) async {
    try {
      // Get the securely stored phone number
      final encryptedNumber = await SecurityUtils.getSecureData('support_whatsapp');
      final phoneNumber = encryptedNumber ?? '1234567890'; // Fallback or default
      
      // Build the WhatsApp URL with optional text
      String whatsappUrl = 'https://wa.me/$phoneNumber';
      
      // Add message text if provided
      if (message != null && message.isNotEmpty) {
        // URL encode the message
        final encodedMessage = Uri.encodeComponent(message);
        whatsappUrl += '?text=$encodedMessage';
      }
      
      // Launch WhatsApp
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }
  
  /// Creates a pre-filled support message with user info
  static String createSupportMessage({
    required String userId,
    required String username,
    String? issueDescription,
  }) {
    return '''
Hello, I need support with the Sifter app.

User ID: $userId
Username: $username
${issueDescription != null ? 'Issue: $issueDescription' : ''}

Device info: ${_getDeviceInfo()}
App version: ${_getAppVersion()}
    '''.trim();
  }
  
  // Helper method to get device info
  static String _getDeviceInfo() {
    // In a real app, you would use a package like device_info_plus
    // This is a placeholder
    return 'Unknown device';
  }
  
  // Helper method to get app version
  static String _getAppVersion() {
    // In a real app, you would use the package_info_plus package
    // This is a placeholder
    return '1.0.0';
  }
  
  /// Creates a click-to-WhatsApp link for web
  static Future<String> generateWhatsAppLink({
    String? message,
  }) async {
    // Get the securely stored phone number
    final encryptedNumber = await SecurityUtils.getSecureData('support_whatsapp');
    final phoneNumber = encryptedNumber ?? '1234567890'; // Fallback or default
    
    // Build the WhatsApp URL with optional text
    String whatsappUrl = 'https://wa.me/$phoneNumber';
    
    // Add message text if provided
    if (message != null && message.isNotEmpty) {
      // URL encode the message
      final encodedMessage = Uri.encodeComponent(message);
      whatsappUrl += '?text=$encodedMessage';
    }
    
    return whatsappUrl;
  }
} 