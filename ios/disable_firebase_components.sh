#!/bin/bash

# Disable Firebase Components Script
echo "==== Disable Firebase Components Script ===="

# Step 1: Clean previous builds
echo "[1/5] Cleaning previous builds..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "✓ Clean completed"

# Step 2: Create backup of pubspec.yaml
echo "[2/5] Creating backup of pubspec.yaml..."
if [ -f "../pubspec.yaml" ]; then
  cp "../pubspec.yaml" "../pubspec.yaml.backup"
  echo "✓ Backup created"
else
  echo "✗ ERROR: pubspec.yaml not found!"
  exit 1
fi

# Step 3: Create modified pubspec files with different Firebase components disabled
echo "[3/5] Creating modified pubspec files..."

# Disable Firestore
cat > "../pubspec.yaml.no_firestore" << 'EOL'
name: sifter
description: Location-based Chat App

publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.3.0
  location: ^5.0.0
  provider: ^6.0.5
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  firebase_core: ^2.17.0
  firebase_auth: ^4.9.0
  # firebase_firestore: ^4.9.1  # DISABLED
  firebase_storage: ^11.2.6
  firebase_analytics: ^10.5.0
  firebase_messaging: ^14.7.3
  firebase_crashlytics: ^3.3.5
  firebase_performance: ^0.9.2+5
  cloud_functions: ^4.4.0
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_local_notifications: ^15.1.0+1
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  share_plus: ^7.1.0
  url_launcher: ^6.1.14
  connectivity_plus: ^4.0.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  flutter_quill: ^7.4.4
  flutter_keyboard_visibility: ^5.4.1
  flutter_background_service: ^3.0.1
  emoji_picker_flutter: ^1.6.1
  audio_session: ^0.1.16
  audioplayers: ^5.1.0
  path: ^1.8.3
  just_audio: ^0.9.35
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  device_info_plus: ^9.0.3
  google_mobile_ads: ^3.0.0
  file_picker: ^5.5.0
  app_settings: ^5.0.0
  record: ^5.0.1
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.3
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
EOL

# Disable Auth
cat > "../pubspec.yaml.no_auth" << 'EOL'
name: sifter
description: Location-based Chat App

publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.3.0
  location: ^5.0.0
  provider: ^6.0.5
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  firebase_core: ^2.17.0
  # firebase_auth: ^4.9.0  # DISABLED
  firebase_firestore: ^4.9.1
  firebase_storage: ^11.2.6
  firebase_analytics: ^10.5.0
  firebase_messaging: ^14.7.3
  firebase_crashlytics: ^3.3.5
  firebase_performance: ^0.9.2+5
  cloud_functions: ^4.4.0
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_local_notifications: ^15.1.0+1
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  share_plus: ^7.1.0
  url_launcher: ^6.1.14
  connectivity_plus: ^4.0.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  flutter_quill: ^7.4.4
  flutter_keyboard_visibility: ^5.4.1
  flutter_background_service: ^3.0.1
  emoji_picker_flutter: ^1.6.1
  audio_session: ^0.1.16
  audioplayers: ^5.1.0
  path: ^1.8.3
  just_audio: ^0.9.35
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  device_info_plus: ^9.0.3
  google_mobile_ads: ^3.0.0
  file_picker: ^5.5.0
  app_settings: ^5.0.0
  record: ^5.0.1
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.3
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
EOL

# Disable Storage
cat > "../pubspec.yaml.no_storage" << 'EOL'
name: sifter
description: Location-based Chat App

publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.3.0
  location: ^5.0.0
  provider: ^6.0.5
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  firebase_core: ^2.17.0
  firebase_auth: ^4.9.0
  firebase_firestore: ^4.9.1
  # firebase_storage: ^11.2.6  # DISABLED
  firebase_analytics: ^10.5.0
  firebase_messaging: ^14.7.3
  firebase_crashlytics: ^3.3.5
  firebase_performance: ^0.9.2+5
  cloud_functions: ^4.4.0
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_local_notifications: ^15.1.0+1
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  share_plus: ^7.1.0
  url_launcher: ^6.1.14
  connectivity_plus: ^4.0.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  flutter_quill: ^7.4.4
  flutter_keyboard_visibility: ^5.4.1
  flutter_background_service: ^3.0.1
  emoji_picker_flutter: ^1.6.1
  audio_session: ^0.1.16
  audioplayers: ^5.1.0
  path: ^1.8.3
  just_audio: ^0.9.35
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  device_info_plus: ^9.0.3
  google_mobile_ads: ^3.0.0
  file_picker: ^5.5.0
  app_settings: ^5.0.0
  record: ^5.0.1
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.3
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
EOL

# Disable Cloud Functions
cat > "../pubspec.yaml.no_functions" << 'EOL'
name: sifter
description: Location-based Chat App

publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.3.0
  location: ^5.0.0
  provider: ^6.0.5
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  firebase_core: ^2.17.0
  firebase_auth: ^4.9.0
  firebase_firestore: ^4.9.1
  firebase_storage: ^11.2.6
  firebase_analytics: ^10.5.0
  firebase_messaging: ^14.7.3
  firebase_crashlytics: ^3.3.5
  firebase_performance: ^0.9.2+5
  # cloud_functions: ^4.4.0  # DISABLED
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_local_notifications: ^15.1.0+1
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  share_plus: ^7.1.0
  url_launcher: ^6.1.14
  connectivity_plus: ^4.0.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  flutter_quill: ^7.4.4
  flutter_keyboard_visibility: ^5.4.1
  flutter_background_service: ^3.0.1
  emoji_picker_flutter: ^1.6.1
  audio_session: ^0.1.16
  audioplayers: ^5.1.0
  path: ^1.8.3
  just_audio: ^0.9.35
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  device_info_plus: ^9.0.3
  google_mobile_ads: ^3.0.0
  file_picker: ^5.5.0
  app_settings: ^5.0.0
  record: ^5.0.1
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.3
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
EOL

# Disable all Firebase components except core
cat > "../pubspec.yaml.core_only" << 'EOL'
name: sifter
description: Location-based Chat App

publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.3.0
  location: ^5.0.0
  provider: ^6.0.5
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  firebase_core: ^2.17.0
  # firebase_auth: ^4.9.0  # DISABLED
  # firebase_firestore: ^4.9.1  # DISABLED
  # firebase_storage: ^11.2.6  # DISABLED
  # firebase_analytics: ^10.5.0  # DISABLED
  # firebase_messaging: ^14.7.3  # DISABLED
  # firebase_crashlytics: ^3.3.5  # DISABLED
  # firebase_performance: ^0.9.2+5  # DISABLED
  # cloud_functions: ^4.4.0  # DISABLED
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_local_notifications: ^15.1.0+1
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  share_plus: ^7.1.0
  url_launcher: ^6.1.14
  connectivity_plus: ^4.0.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  flutter_quill: ^7.4.4
  flutter_keyboard_visibility: ^5.4.1
  flutter_background_service: ^3.0.1
  emoji_picker_flutter: ^1.6.1
  audio_session: ^0.1.16
  audioplayers: ^5.1.0
  path: ^1.8.3
  just_audio: ^0.9.35
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  device_info_plus: ^9.0.3
  google_mobile_ads: ^3.0.0
  file_picker: ^5.5.0
  app_settings: ^5.0.0
  record: ^5.0.1
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.3
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
EOL

echo "✓ Created modified pubspec files"

# Step 4: Create temporary implementation files for disabled components
echo "[4/5] Creating temporary implementation files..."

mkdir -p ../lib/firebase_disabled
cat > ../lib/firebase_disabled/firebase_stub.dart << 'EOL'
// This file provides stub implementations for disabled Firebase components
// It allows the app to compile and run without the actual Firebase dependencies

class FirebaseFirestoreStub {
  static final FirebaseFirestoreStub _instance = FirebaseFirestoreStub._();
  static FirebaseFirestoreStub get instance => _instance;
  FirebaseFirestoreStub._();
  
  CollectionReference collection(String path) => CollectionReferenceStub();
  DocumentReference doc(String path) => DocumentReferenceStub();
}

class CollectionReferenceStub {
  Future<void> add(Map<String, dynamic> data) async {}
  DocumentReference doc([String? path]) => DocumentReferenceStub();
  Stream<QuerySnapshotStub> snapshots() => Stream.value(QuerySnapshotStub());
  Future<QuerySnapshotStub> get() async => QuerySnapshotStub();
}

class DocumentReferenceStub {
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Stream<DocumentSnapshotStub> snapshots() => Stream.value(DocumentSnapshotStub());
  Future<DocumentSnapshotStub> get() async => DocumentSnapshotStub();
}

class QuerySnapshotStub {
  List<DocumentSnapshotStub> get docs => [];
}

class DocumentSnapshotStub {
  bool get exists => false;
  Map<String, dynamic>? get data => {};
  dynamic get(String field) => null;
  String get id => 'stub-id';
}

// Auth stubs
class FirebaseAuthStub {
  static final FirebaseAuthStub _instance = FirebaseAuthStub._();
  static FirebaseAuthStub get instance => _instance;
  FirebaseAuthStub._();
  
  Stream<UserStub?> authStateChanges() => Stream.value(null);
  UserStub? get currentUser => null;
  Future<UserCredentialStub> signInAnonymously() async => UserCredentialStub();
  Future<void> signOut() async {}
}

class UserStub {
  String get uid => 'stub-uid';
  String? get displayName => 'Stub User';
  String? get email => 'stub@example.com';
}

class UserCredentialStub {
  UserStub? get user => UserStub();
}

// Storage stubs
class FirebaseStorageStub {
  static final FirebaseStorageStub _instance = FirebaseStorageStub._();
  static FirebaseStorageStub get instance => _instance;
  FirebaseStorageStub._();
  
  ReferenceStub ref([String? path]) => ReferenceStub();
}

class ReferenceStub {
  Future<String> getDownloadURL() async => 'https://example.com/stub-image.jpg';
  UploadTaskStub putFile(dynamic file) => UploadTaskStub();
  ReferenceStub child(String path) => ReferenceStub();
}

class UploadTaskStub {
  Future<void> snapshot() async {}
}

// Functions stubs
class FirebaseFunctionsStub {
  static final FirebaseFunctionsStub _instance = FirebaseFunctionsStub._();
  static FirebaseFunctionsStub get instance => _instance;
  FirebaseFunctionsStub._();
  
  HttpsCallableStub httpsCallable(String name) => HttpsCallableStub();
}

class HttpsCallableStub {
  Future<HttpsCallableResultStub> call([dynamic parameters]) async => HttpsCallableResultStub();
}

class HttpsCallableResultStub {
  dynamic get data => {'result': 'stub-result'};
}
EOL

echo "✓ Created stub implementation files"

# Step 5: Create scripts to run with different disabled components
echo "[5/5] Creating run scripts..."

# No Firestore script
cat > run_no_firestore.sh << 'EOL'
#!/bin/bash
# Test app with Firestore disabled

# Step 1: Replace pubspec.yaml with modified version
cp "../pubspec.yaml.no_firestore" "../pubspec.yaml"

# Step 2: Run flutter pub get to update dependencies
cd ..
flutter pub get

# Step 3: Create temporary implementations for FirebaseFirestore
mkdir -p lib/firebase
cat > lib/firebase/firestore_helpers.dart << 'EOF'
import '../firebase_disabled/firebase_stub.dart';

// Stub implementation to replace Firestore
final firestoreInstance = FirebaseFirestoreStub.instance;
EOF

# Step 4: Run the app
echo "Running app with Firestore disabled..."
flutter run

# Step 5: Restore original pubspec.yaml
cp "pubspec.yaml.backup" "pubspec.yaml"
flutter pub get
EOF
chmod +x run_no_firestore.sh

# No Auth script
cat > run_no_auth.sh << 'EOL'
#!/bin/bash
# Test app with Auth disabled

# Step 1: Replace pubspec.yaml with modified version
cp "../pubspec.yaml.no_auth" "../pubspec.yaml"

# Step 2: Run flutter pub get to update dependencies
cd ..
flutter pub get

# Step 3: Create temporary implementations for FirebaseAuth
mkdir -p lib/firebase
cat > lib/firebase/auth_helpers.dart << 'EOF'
import '../firebase_disabled/firebase_stub.dart';

// Stub implementation to replace Auth
final authInstance = FirebaseAuthStub.instance;
EOF

# Step 4: Run the app
echo "Running app with Auth disabled..."
flutter run

# Step 5: Restore original pubspec.yaml
cp "pubspec.yaml.backup" "pubspec.yaml"
flutter pub get
EOF
chmod +x run_no_auth.sh

# No Storage script
cat > run_no_storage.sh << 'EOL'
#!/bin/bash
# Test app with Storage disabled

# Step 1: Replace pubspec.yaml with modified version
cp "../pubspec.yaml.no_storage" "../pubspec.yaml"

# Step 2: Run flutter pub get to update dependencies
cd ..
flutter pub get

# Step 3: Create temporary implementations for FirebaseStorage
mkdir -p lib/firebase
cat > lib/firebase/storage_helpers.dart << 'EOF'
import '../firebase_disabled/firebase_stub.dart';

// Stub implementation to replace Storage
final storageInstance = FirebaseStorageStub.instance;
EOF

# Step 4: Run the app
echo "Running app with Storage disabled..."
flutter run

# Step 5: Restore original pubspec.yaml
cp "pubspec.yaml.backup" "pubspec.yaml"
flutter pub get
EOF
chmod +x run_no_storage.sh

# No Cloud Functions script
cat > run_no_functions.sh << 'EOL'
#!/bin/bash
# Test app with Cloud Functions disabled

# Step 1: Replace pubspec.yaml with modified version
cp "../pubspec.yaml.no_functions" "../pubspec.yaml"

# Step 2: Run flutter pub get to update dependencies
cd ..
flutter pub get

# Step 3: Create temporary implementations for Cloud Functions
mkdir -p lib/firebase
cat > lib/firebase/functions_helpers.dart << 'EOF'
import '../firebase_disabled/firebase_stub.dart';

// Stub implementation to replace Cloud Functions
final functionsInstance = FirebaseFunctionsStub.instance;
EOF

# Step 4: Run the app
echo "Running app with Cloud Functions disabled..."
flutter run

# Step 5: Restore original pubspec.yaml
cp "pubspec.yaml.backup" "pubspec.yaml"
flutter pub get
EOF
chmod +x run_no_functions.sh

# Core Only script
cat > run_core_only.sh << 'EOL'
#!/bin/bash
# Test app with only Firebase Core enabled

# Step 1: Replace pubspec.yaml with modified version
cp "../pubspec.yaml.core_only" "../pubspec.yaml"

# Step 2: Run flutter pub get to update dependencies
cd ..
flutter pub get

# Step 3: Create temporary implementations for all Firebase components
mkdir -p lib/firebase
cat > lib/firebase/firebase_helpers.dart << 'EOF'
import '../firebase_disabled/firebase_stub.dart';

// Stub implementations for all Firebase components
final firestoreInstance = FirebaseFirestoreStub.instance;
final authInstance = FirebaseAuthStub.instance;
final storageInstance = FirebaseStorageStub.instance;
final functionsInstance = FirebaseFunctionsStub.instance;
EOF

# Step 4: Run the app
echo "Running app with only Firebase Core enabled..."
flutter run

# Step 5: Restore original pubspec.yaml
cp "pubspec.yaml.backup" "pubspec.yaml"
flutter pub get
EOF
chmod +x run_core_only.sh

# Restore script
cat > restore_firebase.sh << 'EOL'
#!/bin/bash
# Restore original Firebase configuration

cd ..

# Restore original pubspec.yaml
cp "pubspec.yaml.backup" "pubspec.yaml"
flutter pub get

# Remove any temporary implementation files
rm -rf lib/firebase/firebase_helpers.dart
rm -rf lib/firebase/auth_helpers.dart
rm -rf lib/firebase/firestore_helpers.dart
rm -rf lib/firebase/storage_helpers.dart
rm -rf lib/firebase/functions_helpers.dart
rm -rf lib/firebase_disabled

echo "Restored original Firebase configuration"
EOF
chmod +x restore_firebase.sh

echo ""
echo "==== FIREBASE COMPONENT DISABLING SETUP COMPLETED ===="
echo ""
echo "To test the app with different Firebase components disabled:"
echo "  1. ./run_no_firestore.sh    - Run with Firestore disabled"
echo "  2. ./run_no_auth.sh         - Run with Auth disabled"
echo "  3. ./run_no_storage.sh      - Run with Storage disabled"
echo "  4. ./run_no_functions.sh    - Run with Cloud Functions disabled"
echo "  5. ./run_core_only.sh       - Run with only Firebase Core enabled"
echo ""
echo "After testing, run ./restore_firebase.sh to restore the original configuration"
echo ""
echo "IMPORTANT: These scripts create temporary stub implementations"
echo "to allow the app to compile and run without the actual Firebase dependencies."
echo "This is helpful to identify which specific component is causing the BoringSSL-GRPC issue."
echo ""

exit 0 