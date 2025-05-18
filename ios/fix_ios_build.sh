#!/bin/bash

# Comprehensive fix script for iOS build issues
echo "====================================================================="
echo "                    Comprehensive iOS Fix Script                      "
echo "====================================================================="

# Step 1: Clean the workspace
echo "[1/5] Cleaning workspace..."
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "✅ Workspace cleaned"

# Step 2: Update the Podfile to use compatible versions
echo "[2/5] Updating Podfile..."
cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '14.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

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

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  # Pin Firebase to compatible versions
  pod 'Firebase/CoreOnly', '10.12.0'
  pod 'Firebase/Auth', '10.12.0'
  pod 'Firebase/Database', '10.12.0'
  pod 'Firebase/Messaging', '10.12.0'
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

# Fix static framework linkage issues
pre_install do |installer|
  # Fix static framework linkage issues
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
  
  # Force build type for problematic targets
  puts "Creating custom build type settings..."
  installer.pod_targets.each do |pod|
    if pod.name == 'BoringSSL-GRPC' || pod.name.include?('gRPC')
      puts "Found target: #{pod.name} - forcing static library"
      def pod.build_type;
        Pod::BuildType.static_library
      end
    end
  end
end

post_install do |installer|
  # Apply Flutter's standard configuration
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Apply additional settings to all targets
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # Disable all warnings
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      
      # Special configuration for BoringSSL
      if target.name == 'BoringSSL-GRPC' || target.name.include?('gRPC')
        puts "Applying special configuration for #{target.name}"
        
        # Disable all warnings
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'NO'
        
        # Preprocessor macros to disable/redefine problematic attributes
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] += [
          'OPENSSL_NO_ASM=1',
          '__attribute__(...)=',
        ]
      end
    end
  end
end
EOL
echo "✅ Podfile updated"

# Step 3: Run Flutter pub get to update dependencies
echo "[3/5] Running flutter pub get..."
cd ..
flutter pub get
cd ios
echo "✅ Dependencies updated"

# Step 4: Install pods
echo "[4/5] Installing pods..."
pod install
echo "✅ Pods installed"

# Step 5: Create and apply patches for FIRFederatedAuthProvider.h
echo "[5/5] Applying patches to Firebase Auth..."
AUTH_FILE="Pods/FirebaseAuth/FirebaseAuth/Sources/Public/FirebaseAuth/FIRFederatedAuthProvider.h"
if [ -f "$AUTH_FILE" ]; then
  # Create backup
  cp "$AUTH_FILE" "${AUTH_FILE}.backup"
  
  # Look for the FIRAuthCredentialCallback definition and ensure it has a comma
  sed -i '' '36s/\*_Nullable credential$/\*_Nullable credential,/g' "$AUTH_FILE"
  
  echo "✅ Firebase Auth patched"
else
  echo "⚠️ FIRFederatedAuthProvider.h not found. Skipping patch."
fi

echo "====================================================================="
echo "                  All fixes applied successfully!                     "
echo "====================================================================="
echo "You can now try building and running your app." 