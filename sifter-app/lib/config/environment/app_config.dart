enum Environment {
  dev,
  staging,
  prod,
}

class AppConfig {
  final Environment environment;
  final String apiUrl;
  final String googleMapsApiKey;
  final bool enableAnalytics;
  final bool enableCrashlytics;

  static AppConfig? _instance;
  static String? _envString;
  static String? _apiUrlString;
  static String? _googleMapsApiKeyString;
  static bool? _analyticsEnabled;

  factory AppConfig({
    required Environment environment,
    required String apiUrl,
    required String googleMapsApiKey,
    required bool enableAnalytics,
    required bool enableCrashlytics,
  }) {
    _instance ??= AppConfig._internal(
      environment: environment,
      apiUrl: apiUrl,
      googleMapsApiKey: googleMapsApiKey,
      enableAnalytics: enableAnalytics,
      enableCrashlytics: enableCrashlytics,
    );
    return _instance!;
  }

  AppConfig._internal({
    required this.environment,
    required this.apiUrl,
    required this.googleMapsApiKey,
    required this.enableAnalytics,
    required this.enableCrashlytics,
  });

  static AppConfig get instance {
    return _instance!;
  }

  static bool isProduction() => _instance?.environment == Environment.prod;
  static bool isDevelopment() => _instance?.environment == Environment.dev;
  static bool isStaging() => _instance?.environment == Environment.staging;

  static void reset() {
    _instance = null;
  }

  static String get environmentString => _envString ?? 'development';
  static String get apiUrlString =>
      _apiUrlString ?? 'https://api.sifter-app.com';
  static String get googleMapsApiKeyString => _googleMapsApiKeyString ?? '';
  static bool get analyticsEnabled => _analyticsEnabled ?? false;

  static Future<void> initialize({
    required String environment,
    required String apiUrl,
    required String googleMapsApiKey,
    required bool analyticsEnabled,
  }) async {
    _envString = environment;
    _apiUrlString = apiUrl;
    _googleMapsApiKeyString = googleMapsApiKey;
    _analyticsEnabled = analyticsEnabled;
  }

  static bool get isDevelopmentEnv => environmentString == 'development';
  static bool get isProductionEnv => environmentString == 'production';
  static bool get isStagingEnv => environmentString == 'staging';
}
