#!/bin/bash

# Disable Firebase and Fix BoringSSL-GRPC for iOS
echo "======================================================================"
echo "        DISABLE FIREBASE AND FIX BORINGSSL-GRPC FOR iOS               "
echo "======================================================================"

# Step 1: Complete cleanup of all build artifacts
echo "[1/5] Performing complete cleanup..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "✓ Complete cleanup done"

# Step 2: Update pub file to temporarily disable Firebase
echo "[2/5] Updating Flutter dependencies to disable Firebase..."
cd ..
# Create backup of pubspec.yaml if it doesn't exist
if [ ! -f "pubspec.yaml.backup" ]; then
  cp pubspec.yaml pubspec.yaml.backup
fi

# Update the pubspec to disable Firebase
cat > pubspec.yaml << 'EOL'
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

  # Firebase is temporarily disabled
  # firebase_core: 2.15.1 
  # firebase_auth: 4.7.3
  # firebase_storage: 11.2.6

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

# Step 3: Create a temporary main.dart that disables Firebase features
echo "[3/5] Creating temporary main.dart with Firebase features disabled..."
cat > lib/main_no_firebase.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sifter App - No Firebase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sifter App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Success!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'The app is running without Firebase dependencies',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              'This means the BoringSSL-GRPC issue is related to Firebase',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button pressed successfully')),
                );
              },
              child: const Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }
}
EOL

# Run flutter pub get to update dependencies
flutter pub get
echo "✓ Dependencies updated to disable Firebase"

# Step 4: Create a modified Podfile without Firebase
echo "[4/5] Creating Podfile without Firebase..."
cd ios
cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Add environment variables to disable warnings
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

# Add source repositories
source 'https://github.com/CocoaPods/Specs.git'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  # Firebase is disabled - no Firebase pods
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  # Apply Flutter's standard configuration
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Apply additional settings to all targets
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Strip all flags with -G
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].kind_of?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
        elsif config.build_settings[flag_key].kind_of?(String) && config.build_settings[flag_key]
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
        end
      end
      
      # Special configuration for BoringSSL-GRPC if it's still included
      if target.name == 'BoringSSL-GRPC' || target.name.include?('gRPC')
        puts "Applying special configuration for #{target.name}"
        
        # Disable all warnings
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        
        # Preprocessor macros to disable/redefine problematic attributes
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] += [
          'OPENSSL_NO_ASM=1',
          '__attribute__(...)=',
          'OPENSSL_PRINTF_FORMAT(a,b)=',
          'OPENSSL_PRINTF_FORMAT_FUNC(a,b)='
        ]
        
        # Disable compiler index store and more flags
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        config.build_settings['OTHER_CFLAGS'] = ['-w', '-Wno-format', '-Wno-everything']
        config.build_settings['OTHER_CXXFLAGS'] = ['-w', '-Wno-format', '-Wno-everything']
      end
    end
  end
end
EOL
echo "✓ Created Podfile without Firebase"

# Step 5: Install pods and create run script
echo "[5/5] Installing pods and creating run script..."
# Update CocoaPods repos
pod repo update
# Install pods with repo update
pod install --repo-update

# Create a run script
cat > run_without_firebase.sh << 'EOL'
#!/bin/bash
# Run app without Firebase

# Run flutter with alternative main file
cd ..
echo "Running Flutter without Firebase..."
flutter run --no-fast-start -t lib/main_no_firebase.dart
EOL
chmod +x run_without_firebase.sh

echo ""
echo "======================================================================"
echo "                NO-FIREBASE FIX HAS BEEN COMPLETED                     " 
echo "======================================================================"
echo ""
echo "To run the app without Firebase:"
echo "  ./run_without_firebase.sh"
echo ""
echo "This fix:"
echo "1. Disables all Firebase dependencies"
echo "2. Creates an alternative main.dart file without Firebase"
echo "3. Provides a simplified app that can be used to verify the basic functionality"
echo ""
echo "NOTE: This is a temporary solution to verify that BoringSSL-GRPC issue is"
echo "      related to Firebase. After verification, you'll need to implement"
echo "      a proper fix for the Firebase integration."
echo ""

exit 0 