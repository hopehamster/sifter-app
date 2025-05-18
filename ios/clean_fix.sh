#!/bin/bash

# Clean BoringSSL-GRPC Fix Script
echo "==== Clean BoringSSL-GRPC Fix Script ===="

# Step 1: Clean the project
echo "==== Step 1: Cleaning project ===="
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "Cleaned project files"

# Step 2: Replace the Podfile with a clean version
echo "==== Step 2: Replacing Podfile ===="
if [ -f "Podfile" ]; then
  # Backup the original Podfile
  mv Podfile Podfile.original.bak
  
  # Create the new Podfile
  cat > Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Environment variables to disable warnings and prevent -G flag issue
ENV['OTHER_CFLAGS'] = '-w'
ENV['OTHER_CXXFLAGS'] = '-w'
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

# Add source repositories
source 'https://github.com/CocoaPods/Specs.git'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Install the specific version of GoogleUtilities before other dependencies
  pod 'GoogleUtilities', '7.13.0'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

# Fix static framework linkage issues
pre_install do |installer|
  # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
  # Fix Swift version and Bitcode settings
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['ENABLE_BITCODE'] = 'NO'
  end
  
  # Configure all target build settings
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Remove problematic compiler flags - more aggressive approach
      if config.build_settings['OTHER_CFLAGS'].kind_of?(Array)
        config.build_settings['OTHER_CFLAGS'] = config.build_settings['OTHER_CFLAGS'].reject { |flag| flag.include?('-G') }
      elsif config.build_settings['OTHER_CFLAGS'].kind_of?(String)
        config.build_settings['OTHER_CFLAGS'] = config.build_settings['OTHER_CFLAGS'].gsub(/-G\S*/, '')
      end

      # Remove the flag from all possible build settings
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].kind_of?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
        elsif config.build_settings[flag_key].kind_of?(String)
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
        end
      end
      
      # Specifically fix BoringSSL-GRPC flags
      if target.name == 'BoringSSL-GRPC'
        puts "Applying special configuration for BoringSSL-GRPC"
        # Disable all warnings completely
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'NO'
        config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'NO'
        config.build_settings['CLANG_WARN_UNGUARDED_AVAILABILITY'] = 'NO'
        
        # Set specific compiler flags (make sure this doesn't include any -G flags)
        config.build_settings['OTHER_CFLAGS'] = '-w'
        config.build_settings['OTHER_CXXFLAGS'] = '-w'
        
        # Add compiler-specific flags that might help
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'OPENSSL_NO_ASM=1']
      end
      
      # Add additional build settings as needed
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
  
  # Specific for GoogleUtilities
  installer.pods_project.targets.each do |target|
    if target.name.start_with?('GoogleUtilities')
      puts "Configuring #{target.name}"
      target.build_configurations.each do |config|
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end
  
  # Special handling for project-level build settings
  installer.pods_project.build_configurations.each do |config|
    # Remove the -G flag from any project-level settings
    ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
      if config.build_settings[flag_key].kind_of?(Array)
        config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
      elsif config.build_settings[flag_key].kind_of?(String)
        config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
      end
    end
  end
end
EOF
  
  echo "Replaced Podfile with clean version"
else
  echo "ERROR: Podfile not found!"
  exit 1
fi

# Step 3: Create a permanent CocoaPods patch
echo "==== Step 3: Creating CocoaPods patch ===="
mkdir -p ~/.cocoapods/patches/BoringSSL-GRPC
cat > ~/.cocoapods/patches/BoringSSL-GRPC/remove_G_flag.patch << 'EOL'
diff --git a/src/include/openssl/base.h b/src/include/openssl/base.h
--- a/src/include/openssl/base.h
+++ b/src/include/openssl/base.h
@@ -103,7 +103,7 @@
 #if defined(__GNUC__) || defined(__clang__)
 // "printf" format attributes are supported on gcc/clang
 #define OPENSSL_PRINTF_FORMAT(string_index, first_to_check) \
-    __attribute__((__format__(__printf__, string_index, first_to_check)))
+    /* __attribute__((__format__(__printf__, string_index, first_to_check))) */
 #else
 #define OPENSSL_PRINTF_FORMAT(string_index, first_to_check)
 #endif
EOL
echo "Created CocoaPods patch"

# Step 4: Create compiler wrapper to filter out -G flags
echo "==== Step 4: Creating compiler wrapper ===="
mkdir -p bin
cat > bin/clang_wrapper.sh << 'EOL'
#!/bin/bash
# Wrapper script for clang to filter out -G flags
REAL_CLANG="$(xcrun -f clang)"
# Filter arguments
ARGS=()
for arg in "$@"; do
  if [[ "$arg" != -G* ]]; then
    ARGS+=("$arg")
  fi
done
# Execute real clang with filtered arguments
exec "$REAL_CLANG" "${ARGS[@]}"
EOL
chmod +x bin/clang_wrapper.sh
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang++"
echo "Created compiler wrapper"

# Step 5: Create a Runner.xcconfig file with custom settings
echo "==== Step 5: Creating Runner.xcconfig ===="
cat > Runner.xcconfig << 'EOL'
// Custom configuration to work around -G flag compilation issue
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) OPENSSL_NO_ASM=1
OTHER_CFLAGS = $(inherited) -w
OTHER_CXXFLAGS = $(inherited) -w
COMPILER_FLAGS = $(inherited)
WARNING_CFLAGS = $(inherited)
// Disable index store which can trigger compiler flags
COMPILER_INDEX_STORE_ENABLE = NO
// Completely inhibit all warnings for problematic dependencies
GCC_WARN_INHIBIT_ALL_WARNINGS = YES
EOL
echo "Created Runner.xcconfig"

# Step 6: Install pods with modified PATH to use our clang wrapper
echo "==== Step 6: Installing pods with fixed environment ===="
# Set environment variables to prevent -G flag issue
export OTHER_CFLAGS="-w"
export OTHER_CXXFLAGS="-w"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export PATH="$(pwd)/bin:$PATH"

# Install pods
pod install

# Step 7: Apply direct source patching for all BoringSSL-GRPC source files
echo "==== Step 7: Direct source patching ===="
if [ -d "Pods/BoringSSL-GRPC" ]; then
  # Find all files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f | xargs grep -l "__attribute__((__format__" 2>/dev/null)
  
  for FILE in $FORMAT_FILES; do
    echo "Patching $FILE..."
    # Create backup
    if [ ! -f "${FILE}.backup" ]; then
      cp "$FILE" "${FILE}.backup"
    fi
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__(__printf__, \([^)]*\)))/* __attribute__((__format__(__printf__, \1))) */g' "$FILE"
  done
  
  # Create a header fix for base.h
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Adding attribute override to $BASE_H"
    
    # Add a #define to override __attribute__ at the beginning
    if ! grep -q "#define __attribute__(x)" "$BASE_H"; then
      sed -i '' '50i\\
/* Disable format attributes that cause the -G flag issue */\\
#define __attribute__(x)\\
' "$BASE_H"
    fi
    
    # Also create a header to completely disable the attribute
    OPENSSL_DIR="Pods/BoringSSL-GRPC/src/include/openssl"
    PATCH_HEADER="$OPENSSL_DIR/boringssl_build_fix.h"
    
    cat > "$PATCH_HEADER" << 'EOL'
/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)

/* Disable format attributes that might trigger -G flags */
#define __attribute__(x)

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
EOL
    
    # Add include for this header at the top of base.h if not there
    if [ -f "$PATCH_HEADER" ] && ! grep -q "boringssl_build_fix.h" "$BASE_H"; then
      sed -i '' '10i\\
#include <openssl/boringssl_build_fix.h>\\
' "$BASE_H"
    fi
  fi
  
  echo "Successfully patched BoringSSL-GRPC source files"
else
  echo "WARNING: BoringSSL-GRPC directory not found"
fi

# Step 8: Create run script
echo "==== Step 8: Creating run script ===="
cat > run_app.sh << 'EOL'
#!/bin/bash
# Script to run Flutter app with BoringSSL-GRPC fix applied

# Set environment variables
export OTHER_CFLAGS="-w"
export OTHER_CXXFLAGS="-w"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export PATH="$(pwd)/bin:$PATH"

cd ..
flutter run
EOL
chmod +x run_app.sh

echo ""
echo "==== FIX COMPLETED SUCCESSFULLY ===="
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_app.sh"
echo ""

exit 0 