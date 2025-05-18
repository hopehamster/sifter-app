/// Configuration file for Sifter app
/// Contains app-wide constants and configuration values

class AppConfig {
  // App identification
  static const String appName = 'Sifter';
  static const String appVersion = '1.0.0';
  static const int versionCode = 1;
  
  // Contact information
  static const String supportEmail = 'mikebradley1980@gmail.com';
  static const String supportWhatsapp = '+14155339170';
  
  // Privacy policy
  static const String privacyPolicyUrl = 'https://sifterapp.com/privacy-policy';
  
  // Content moderation
  static const Duration moderationResponseTime = Duration(hours: 24);
  static const int ageRequirementForNsfw = 21;
  
  // App features
  static const bool enableAdMob = true;
  static const String admobAppId = 'ca-app-pub-4031621145325255~7749576127';
  
  // Location settings
  static const double defaultRadius = 1.0; // kilometers
  static const double maxRadius = 10.0; // kilometers
  static const Duration locationRefreshInterval = Duration(minutes: 1);
  static const Duration backgroundLocationInterval = Duration(minutes: 10);
  
  // Message settings
  static const int messagePageSize = 50;
  static const Duration messageRefreshInterval = Duration(seconds: 10);
  
  // Error tracking
  static const bool enableSentry = true;
} 