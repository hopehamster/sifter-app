#!/bin/bash
# Try disabling some Firebase components to narrow down the issue

cd ..
echo "Temporarily modifying pubspec.yaml..."

# Create backup if needed
if [ ! -f "pubspec.yaml.original" ]; then
  cp pubspec.yaml pubspec.yaml.original
fi

# Create a modified pubspec with fewer Firebase dependencies
cat > pubspec.yaml << 'EOF'
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
  # Using only the minimal Firebase components to avoid gRPC issues
  firebase_auth: ^4.9.0
  # firebase_firestore: ^4.9.1 # Commented out to avoid BoringSSL issues
  firebase_storage: ^11.2.6
  # cloud_functions: ^4.4.0 # Commented out to avoid gRPC issues
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
EOF

# Run flutter pub get
flutter pub get

# Create stub implementations for commented dependencies
mkdir -p lib/firebase
cat > lib/firebase/firestore_stub.dart << 'EOF'
// Stub implementation for Firestore

class FirebaseFirestore {
  static FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();
  
  CollectionReference collection(String path) => CollectionReference();
  DocumentReference doc(String path) => DocumentReference();
}

class CollectionReference {
  Future<void> add(Map<String, dynamic> data) async {}
  DocumentReference doc([String? path]) => DocumentReference();
  Stream<QuerySnapshot> snapshots() => Stream.empty();
  Future<QuerySnapshot> get() async => QuerySnapshot();
}

class DocumentReference {
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Stream<DocumentSnapshot> snapshots() => Stream.empty();
  Future<DocumentSnapshot> get() async => DocumentSnapshot();
}

class QuerySnapshot {
  List<DocumentSnapshot> get docs => [];
}

class DocumentSnapshot {
  bool get exists => false;
  Map<String, dynamic>? get data => {};
  dynamic get(String field) => null;
  String get id => 'stub-id';
}
EOF

cat > lib/firebase/functions_stub.dart << 'EOF'
// Stub implementation for Cloud Functions

class FirebaseFunctions {
  static FirebaseFunctions instance = FirebaseFunctions._();
  FirebaseFunctions._();
  
  HttpsCallable httpsCallable(String name) => HttpsCallable();
}

class HttpsCallable {
  Future<HttpsCallableResult> call([dynamic parameters]) async => HttpsCallableResult();
}

class HttpsCallableResult {
  dynamic get data => {'result': 'stub-result'};
}
EOF

# Return to ios directory
cd ios

# Run using our fixes
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Clean and install
rm -rf Pods
rm -f Podfile.lock
pod install

# Try running
cd ..
echo "Running with minimal Firebase dependencies..."
flutter run
