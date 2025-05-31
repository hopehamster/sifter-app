# Deployment Documentation

## Overview

The Sifter App deployment process is designed to ensure reliable and consistent delivery of the application to both Android and iOS platforms. This document outlines the deployment procedures, requirements, and best practices.

## Prerequisites

### Required Tools
- Flutter SDK (latest stable version)
- Android Studio / Xcode
- Firebase CLI
- CocoaPods (for iOS)
- Git
- Fastlane (optional)

### Required Accounts
- Google Play Console
- Apple Developer Account
- Firebase Project
- GitHub Account

## Build Configuration

### Android

#### Release Configuration
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        applicationId "com.example.sifter"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }

    signingConfigs {
        release {
            storeFile file("upload-keystore.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### ProGuard Rules
```proguard
# android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
```

### iOS

#### Release Configuration
```ruby
# ios/Podfile
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

#### Xcode Configuration
1. Set up signing certificates
2. Configure provisioning profiles
3. Set up app capabilities
4. Configure app groups

## Build Process

### Android Build

#### Generate Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### Build APK
```bash
flutter build apk --release
```

#### Build App Bundle
```bash
flutter build appbundle
```

### iOS Build

#### Install Dependencies
```bash
cd ios
pod install
cd ..
```

#### Build Archive
```bash
flutter build ios --release
```

#### Archive in Xcode
1. Open `ios/Runner.xcworkspace`
2. Select Product > Archive
3. Follow distribution steps

## Deployment Process

### Android Deployment

#### Google Play Console
1. Create new release
2. Upload APK/App Bundle
3. Set release notes
4. Configure staged rollout
5. Submit for review

#### Fastlane Configuration
```ruby
# fastlane/Fastfile
platform :android do
  desc "Deploy to Play Store"
  lane :deploy do
    gradle(
      task: "clean assembleRelease"
    )
    upload_to_play_store(
      track: 'production',
      release_status: 'completed'
    )
  end
end
```

### iOS Deployment

#### App Store Connect
1. Create new version
2. Upload build
3. Set release notes
4. Configure phased release
5. Submit for review

#### Fastlane Configuration
```ruby
# fastlane/Fastfile
platform :ios do
  desc "Deploy to App Store"
  lane :deploy do
    build_ios_app(
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_app_store(
      force: true,
      skip_metadata: true,
      skip_screenshots: true
    )
  end
end
```

## Environment Configuration

### Android

#### Environment Variables
```bash
# .env
KEYSTORE_PASSWORD=your_keystore_password
KEY_ALIAS=your_key_alias
KEY_PASSWORD=your_key_password
```

#### Firebase Configuration
```dart
// lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'your-api-key',
      appId: 'your-app-id',
      messagingSenderId: 'your-sender-id',
      projectId: 'your-project-id',
    );
  }
}
```

### iOS

#### Environment Variables
```bash
# .env
APPLE_ID=your_apple_id
APPLE_TEAM_ID=your_team_id
```

#### Firebase Configuration
```dart
// lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'your-api-key',
      appId: 'your-app-id',
      messagingSenderId: 'your-sender-id',
      projectId: 'your-project-id',
      iosClientId: 'your-ios-client-id',
      iosBundleId: 'com.example.sifter',
    );
  }
}
```

## Continuous Deployment

### GitHub Actions

#### Android Workflow
```yaml
# .github/workflows/android.yml
name: Android CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release
      - run: flutter build appbundle
```

#### iOS Workflow
```yaml
# .github/workflows/ios.yml
name: iOS CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release
```

## Monitoring

### Crash Reporting
```dart
class CrashReporting {
  static Future<void> initialize() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }
}
```

### Analytics
```dart
class Analytics {
  static Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}
```

## Rollback Procedures

### Android Rollback
1. Access Google Play Console
2. Navigate to Release Management
3. Select previous version
4. Create new release with previous version
5. Submit for review

### iOS Rollback
1. Access App Store Connect
2. Navigate to App Versions
3. Select previous version
4. Create new version with previous build
5. Submit for review

## Best Practices

### 1. Version Management
- Follow semantic versioning
- Maintain changelog
- Document breaking changes
- Test version updates

### 2. Security
- Secure signing keys
- Protect sensitive data
- Use environment variables
- Regular security audits

### 3. Testing
- Test release builds
- Verify app signing
- Check app permissions
- Test app updates

### 4. Documentation
- Update release notes
- Document deployment steps
- Maintain deployment history
- Track known issues

## Troubleshooting

### Common Issues

#### Android
1. Signing issues
   - Verify keystore
   - Check passwords
   - Validate signing config

2. Build failures
   - Check Gradle version
   - Verify dependencies
   - Clean project

#### iOS
1. Signing issues
   - Check certificates
   - Verify profiles
   - Validate capabilities

2. Build failures
   - Check CocoaPods
   - Verify Xcode version
   - Clean build folder

### Debugging

#### Android
```bash
flutter build apk --verbose
```

#### iOS
```bash
flutter build ios --verbose
```

## Support

### Contact Information
- Technical support: support@sifter-app.com
- Deployment issues: deploy@sifter-app.com
- Security concerns: security@sifter-app.com

### Resources
- Documentation: https://docs.sifter-app.com
- Status page: https://status.sifter-app.com
- Support portal: https://support.sifter-app.com 