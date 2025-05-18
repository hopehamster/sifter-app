#!/bin/bash

# Firebase Version Fix with BoringSSL-GRPC Fix
echo "==== Firebase Version & BoringSSL-GRPC Fix ===="

# Step 1: Clean previous builds
echo "[1/5] Cleaning previous builds..."
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
mkdir -p bin
echo "✓ Clean completed"

# Step 2: Create a compiler wrapper
echo "[2/5] Creating compiler wrapper..."
cat > bin/clang_wrapper.sh << 'EOL'
#!/bin/bash
# Wrapper script for clang to filter out -G flags

# Get the real clang binary
REAL_CLANG="$(xcrun -f clang)"

# Create filtered arguments
ARGS=()
for arg in "$@"; do
  # Skip any arguments with -G
  if [[ "$arg" != -G* ]]; then
    ARGS+=("$arg")
  fi
done

# Check if we're compiling BoringSSL files
COMPILE_BORINGSSL=0
for arg in "$@"; do
  if [[ "$arg" == *"BoringSSL"* ]]; then
    COMPILE_BORINGSSL=1
    break
  fi
done

# If compiling BoringSSL, add extra flags to suppress format attributes
if [ $COMPILE_BORINGSSL -eq 1 ]; then
  ARGS+=("-DOPENSSL_NO_ASM=1")
  ARGS+=("-w")
  ARGS+=("-Wno-format")
  ARGS+=("-Wno-format-security")
  ARGS+=("-Wno-everything")
fi

# Execute real clang with filtered arguments
"$REAL_CLANG" "${ARGS[@]}"
EOL
chmod +x bin/clang_wrapper.sh

# Create symlinks for all compiler names
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang++"
echo "✓ Compiler wrapper created"

# Step 3: Create a modified Podfile
echo "[3/5] Creating modified Podfile..."
cp Podfile Podfile.original.bak

cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Environment variables for BoringSSL fix
ENV['OTHER_CFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1'
ENV['OTHER_CXXFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1'
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
  
  # DO NOT pin Firebase versions - let cloud_firestore determine the right version
  # This avoids the version conflict
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

# Post install hooks to fix BoringSSL
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Remove any -G flags
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
echo "✓ Modified Podfile created"

# Step 4: Install pods with the wrapper
echo "[4/5] Installing pods with filtered compiler flags..."
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

pod install
echo "✓ Pods installed"

# Step 5: Create a patch script for BoringSSL source files
echo "[5/5] Creating BoringSSL patch script..."
cat > patch_boringssl.sh << 'EOL'
#!/bin/bash
# Directly patch BoringSSL source files to remove format attributes

if [ -d "Pods/BoringSSL-GRPC" ]; then
  # Find all BoringSSL header files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" | xargs grep -l "__format__" 2>/dev/null)
  
  # Counter for modified files
  MODIFIED_COUNT=0
  
  echo "Patching BoringSSL source files..."
  
  # Patch each file
  for FILE in $FORMAT_FILES; do
    # Create backup
    cp "$FILE" "${FILE}.backup"
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
  done
  
  # Specifically patch base.h
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    cp "$BASE_H" "${BASE_H}.backup"
    
    # Add a header block to disable format attributes
    sed -i '' '/^#include <stdint.h>/a\'$'\n''/* SIFTER APP FIX: Disable format attributes to prevent -G flag */\'$'\n''#define __attribute__(x)\'$'\n''#define OPENSSL_PRINTF_FORMAT_FUNC(a,b)\'$'\n''#define OPENSSL_PRINTF_FORMAT(a,b)\'$'\n''#define OPENSSL_NO_ASM 1\'$'\n' "$BASE_H"
    
    echo "✓ Patched base.h"
  fi
  
  echo "✓ Modified $MODIFIED_COUNT BoringSSL source files"
else
  echo "✗ ERROR: BoringSSL-GRPC directory not found!"
fi
EOL
chmod +x patch_boringssl.sh

# Create a runner script
cat > run_with_fixed_firebase.sh << 'EOL'
#!/bin/bash
# Run app with all firebase version and BoringSSL fixes applied

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Apply source patches
./patch_boringssl.sh

# Run Flutter
cd ..
flutter run
EOL
chmod +x run_with_fixed_firebase.sh

echo ""
echo "==== FIX COMPLETED ===="
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_with_fixed_firebase.sh"
echo ""
echo "If you need to make more targeted fixes:"
echo "  1. ./patch_boringssl.sh - Patch BoringSSL source files directly"
echo "  2. export PATH=\"\$(pwd)/bin:\$PATH\" - Use the compiler wrapper"
echo "" 