# Build Instructions

## Prerequisites

### Required Software
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / Xcode
- Git
- Firebase CLI
- CocoaPods (for iOS)

### Environment Setup
1. Install Flutter SDK
2. Install Android Studio / Xcode
3. Install Firebase CLI
4. Install CocoaPods (for iOS)
5. Set up environment variables

## Project Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/sifter-app.git
cd sifter-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Android
1. Create a new Firebase project
2. Add Android app to Firebase project
3. Download `google-services.json`
4. Place in `android/app/`

#### iOS
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/`
4. Run `pod install` in `ios/` directory

### 4. Configure Environment
1. Copy `.env.example` to `.env`
2. Fill in required environment variables:
   - Firebase configuration
   - API keys
   - Other service credentials

## Building the App

### Android Build

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
flutter build apk --release
```

#### App Bundle
```bash
flutter build appbundle
```

### iOS Build

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
flutter build ios --release
```

## Running the App

### Development Mode
```bash
flutter run
```

### Production Mode
```bash
flutter run --release
```

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

### UI Tests
```bash
flutter test test/widget_test.dart
```

## Code Quality

### Run Linter
```bash
flutter analyze
```

### Format Code
```bash
flutter format .
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Deployment

### Android Deployment

1. Generate Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Configure Signing
- Add keystore details to `android/key.properties`
- Update `android/app/build.gradle`

3. Build Release APK
```bash
flutter build apk --release
```

4. Build App Bundle
```bash
flutter build appbundle
```

### iOS Deployment

1. Configure Certificates
- Open Xcode
- Set up signing certificates
- Configure provisioning profiles

2. Build Archive
- Open Xcode
- Select Product > Archive
- Follow distribution steps

## Troubleshooting

### Common Issues

#### Android
1. Gradle sync fails
   - Check Gradle version
   - Update Android Studio
   - Clear Gradle cache

2. Build fails
   - Check SDK versions
   - Verify dependencies
   - Clean project

#### iOS
1. Pod install fails
   - Update CocoaPods
   - Clear pod cache
   - Check Ruby version

2. Build fails
   - Check signing
   - Verify capabilities
   - Clean build folder

### Debugging

#### Android
1. Enable USB debugging
2. Connect device
3. Run `flutter run`

#### iOS
1. Open Xcode
2. Select device
3. Run from Xcode

## Maintenance

### Update Dependencies
```bash
flutter pub upgrade
```

### Clean Project
```bash
flutter clean
```

### Regenerate Generated Files
```bash
flutter pub run build_runner build
```

## Performance Optimization

### Android
1. Enable R8
2. Configure ProGuard
3. Optimize images
4. Enable multidex

### iOS
1. Enable bitcode
2. Configure app thinning
3. Optimize assets
4. Enable app transport security

## Security

### Android
1. Enable app signing
2. Configure ProGuard rules
3. Implement SSL pinning
4. Secure storage

### iOS
1. Enable app transport security
2. Configure keychain access
3. Implement SSL pinning
4. Secure storage

## Monitoring

### Firebase Analytics
1. Enable analytics
2. Configure events
3. Set up conversion tracking
4. Monitor user engagement

### Crash Reporting
1. Enable Firebase Crashlytics
2. Configure error reporting
3. Set up alerts
4. Monitor crashes

## Support

### Documentation
- API documentation
- Code documentation
- User guides
- Troubleshooting guides

### Contact
- Technical support
- Bug reports
- Feature requests
- General inquiries 