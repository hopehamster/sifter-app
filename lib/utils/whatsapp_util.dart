import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Utility class for WhatsApp integration
class WhatsAppUtil {
  /// WhatsApp business number to contact support
  static const String supportNumber = '12345678901'; // Replace with your actual WhatsApp support number
  
  /// Creates a support message with user details
  static String createSupportMessage({
    required String userId,
    required String username,
    String? appVersion,
    String? deviceInfo,
    String? problemDescription,
  }) {
    final deviceDetails = deviceInfo ?? _getDeviceInfo();
    final version = appVersion ?? _getAppVersion();
    final problemDesc = problemDescription ?? 'I need help with the Sifter app.';
    
    return '''
Hello Sifter Support,

$problemDesc

User Details:
- ID: $userId
- Username: $username
- $version
- $deviceDetails

Thank you!
''';
  }
  
  /// Launches WhatsApp with a pre-filled message
  static Future<bool> launchWhatsAppChat({
    String? phoneNumber,
    String? message,
  }) async {
    final phone = phoneNumber ?? supportNumber;
    final encodedMessage = Uri.encodeComponent(message ?? '');
    
    Uri whatsappUrl;
    if (Platform.isIOS) {
      whatsappUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    } else {
      whatsappUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');
    }
    
    if (await canLaunchUrl(whatsappUrl)) {
      return launchUrl(whatsappUrl);
    } else {
      // Fallback to web version if the app is not installed
      final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
      if (await canLaunchUrl(webUrl)) {
        return launchUrl(webUrl);
      } else {
        throw 'Could not launch WhatsApp';
      }
    }
  }
  
  /// Get basic device info string
  static String _getDeviceInfo() {
    return 'Device: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }
  
  /// Get app version
  static String _getAppVersion() {
    // In a real app, you would use the package_info_plus package
    return 'App version: 1.0.0';
  }
  
  /// Show a dialog to confirm WhatsApp chat
  static Future<bool> showWhatsAppConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Would you like to contact our support team via WhatsApp?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
} 