#!/bin/bash

# Flutter Build Options for BoringSSL-GRPC Fix
echo "==== Flutter Build Options for BoringSSL-GRPC Fix ===="

# Step 1: Clean previous builds
echo "[1/4] Cleaning previous builds..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "✓ Clean completed"

# Step 2: Set up environment variables to suppress warnings and flags
echo "[2/4] Setting up environment variables..."
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"

# Step 3: Modify the Podfile to use a older version of Firebase/gRPC
echo "[3/4] Modifying Podfile to try with older Firebase/gRPC versions..."
if [ -f "Podfile" ]; then
  # Backup the original Podfile
  cp Podfile Podfile.older_firebase.bak
  
  # Create a modified Podfile with older Firebase version
  cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Environment variables to disable warnings and prevent -G flag issue
ENV['OTHER_CFLAGS'] = '-w -Wno-everything -Wno-format -DOPENSSL_NO_ASM=1'
ENV['OTHER_CXXFLAGS'] = '-w -Wno-everything -Wno-format -DOPENSSL_NO_ASM=1'
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
ENV['COMPILER_INDEX_STORE_ENABLE'] = 'NO'

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

  # Try pinning to a specific older version of Firebase Core (pre-gRPC 1.50)
  # This might avoid the BoringSSL issue in newer versions
  pod 'Firebase/Core', '~> 10.12.0'
  pod 'Firebase/Auth', '~> 10.12.0'
  pod 'Firebase/Firestore', '~> 10.12.0'
  pod 'Firebase/Storage', '~> 10.12.0'
  pod 'Firebase/Messaging', '~> 10.12.0'
  pod 'Firebase/Analytics', '~> 10.12.0'
  pod 'Firebase/Crashlytics', '~> 10.12.0'

  # Try pinning gRPC to an older version
  pod 'gRPC-C++', '~> 1.46.0'
  
  # Install the standard Flutter pods
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Aggressively remove -G flag references from all build settings
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].kind_of?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
        elsif config.build_settings[flag_key].kind_of?(String) && config.build_settings[flag_key]
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
        end
      end
      
      # Special handling for BoringSSL-GRPC
      if target.name == 'BoringSSL-GRPC'
        puts "Applying special configuration for BoringSSL-GRPC"
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['OTHER_CFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1'
        config.build_settings['OTHER_CXXFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'OPENSSL_NO_ASM=1']
      end
    end
  end
end
EOL
  echo "✓ Created modified Podfile with pinned older versions"
else
  echo "✗ ERROR: Podfile not found!"
  exit 1
fi

# Step 4: Create run scripts for different Flutter build options
echo "[4/4] Creating build option scripts..."

# Option 1: Run with --no-codesign
cat > run_no_codesign.sh << 'EOL'
#!/bin/bash
# Run Flutter with --no-codesign option

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter with --no-codesign option..."
flutter run --no-codesign
EOL
chmod +x run_no_codesign.sh

# Option 2: Try with --release flag
cat > run_release.sh << 'EOL'
#!/bin/bash
# Run Flutter in release mode

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1" 
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter in release mode..."
flutter run --release
EOL
chmod +x run_release.sh

# Option 3: Try with --profile flag
cat > run_profile.sh << 'EOL'
#!/bin/bash
# Run Flutter in profile mode 

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter in profile mode..."
flutter run --profile
EOL
chmod +x run_profile.sh

# Option 4: Try with --flavor option (if the app has flavors)
cat > run_flavor.sh << 'EOL'
#!/bin/bash
# Run Flutter with flavor option

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter with flavor option..."
# Use 'dev' as an example flavor - modify as needed
flutter run --flavor dev 
EOL
chmod +x run_flavor.sh

# Option 5: Try with --no-tree-shake-icons flag to simplify the build
cat > run_no_tree_shake.sh << 'EOL'
#!/bin/bash
# Run Flutter with --no-tree-shake-icons option

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter with --no-tree-shake-icons option..."
flutter run --no-tree-shake-icons
EOL
chmod +x run_no_tree_shake.sh

# Option 6: Try with modified xcargs for xcodebuild
cat > run_xcodebuild.sh << 'EOL'
#!/bin/bash
# Run Flutter with modified xcodebuild arguments

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter with custom xcodebuild arguments..."
flutter run --verbose --use-application-binary --enable-experiment=alternative-compilation-options -- \
  --xcargs="-UseModernBuildSystem=YES OTHER_CFLAGS='-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1' ENABLE_BITCODE=NO"
EOL
chmod +x run_xcodebuild.sh

echo ""
echo "==== FLUTTER BUILD OPTIONS SETUP COMPLETED ===="
echo ""
echo "To try different Flutter build options:"
echo "  1. ./run_no_codesign.sh    - Run with --no-codesign option"
echo "  2. ./run_release.sh        - Run in release mode"
echo "  3. ./run_profile.sh        - Run in profile mode"
echo "  4. ./run_flavor.sh         - Run with flavor option"
echo "  5. ./run_no_tree_shake.sh  - Run with --no-tree-shake-icons option"
echo "  6. ./run_xcodebuild.sh     - Run with custom xcodebuild arguments"
echo ""
echo "IMPORTANT: These options use a Podfile with older Firebase/gRPC versions"
echo "which might avoid the BoringSSL-GRPC issue in newer versions."
echo ""

exit 0 