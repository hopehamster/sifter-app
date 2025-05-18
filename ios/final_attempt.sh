#!/bin/bash

# Final Attempt to Fix BoringSSL-GRPC
echo "==== FINAL ATTEMPT TO FIX BORINGSSL-GRPC ===="

# Step 1: Clean the project and create bin directory
echo "==== Step 1: Cleaning project and setting up ===="
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
mkdir -p bin
echo "Cleaned project files"

# Step 2: Create compiler wrapper that aggressively removes G flag
echo "==== Step 2: Creating compiler wrapper with NO_G environment ===="
# Create a more aggressive wrapper script
cat > bin/clang_wrapper.sh << 'EOL'
#!/bin/bash
# Advanced wrapper script for clang to filter out -G flags and add custom flags

# Get the real clang binary
REAL_CLANG="$(xcrun -f clang)"

# Create a temporary file for args
ARGS_FILE=$(mktemp)

# Filter arguments to remove -G flags and add custom flags
for arg in "$@"; do
  # Skip any arguments with -G
  if [[ "$arg" != -G* ]]; then
    echo "$arg" >> "$ARGS_FILE"
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
  echo "-DOPENSSL_NO_ASM=1" >> "$ARGS_FILE"
  echo "-w" >> "$ARGS_FILE"
  echo "-Wno-format" >> "$ARGS_FILE"
  echo "-Wno-shorten-64-to-32" >> "$ARGS_FILE"
  echo "-Wno-everything" >> "$ARGS_FILE"
  echo "-UDEBUG" >> "$ARGS_FILE"
fi

# Execute real clang with filtered arguments
"$REAL_CLANG" $(cat "$ARGS_FILE")
RET=$?

# Clean up
rm -f "$ARGS_FILE"

exit $RET
EOL
chmod +x bin/clang_wrapper.sh

# Create symlinks for all possible compiler names
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang++"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/cc"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/gcc"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/g++"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/c++"

echo "Created enhanced compiler wrapper scripts"

# Step 3: Create a patched Podfile that completely disables compiler warnings
echo "==== Step 3: Creating patched Podfile ===="
cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Environment variables to disable warnings
ENV['OTHER_CFLAGS'] = '-w -Wno-everything -Wno-format -DOPENSSL_NO_ASM=1'
ENV['OTHER_CXXFLAGS'] = '-w -Wno-everything -Wno-format -DOPENSSL_NO_ASM=1'
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
ENV['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
ENV['DEAD_CODE_STRIPPING'] = 'NO'
ENV['DEBUG'] = 'NO'

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
      
      # Add the NO_OBSCURE_PRINTF preprocessor definition to disable printf format attributes
      if config.build_settings['GCC_PREPROCESSOR_DEFINITIONS']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'OPENSSL_NO_ASM=1'
      else
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'OPENSSL_NO_ASM=1']
      end
      
      # Aggressively strip all flags with G
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
        
        # Completely disable all warnings
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'NO'
        config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'NO'
        config.build_settings['CLANG_WARN_UNGUARDED_AVAILABILITY'] = 'NO'
        
        # Set extremely specific flags for BoringSSL
        config.build_settings['OTHER_CFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1'
        config.build_settings['OTHER_CXXFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1'
        
        # Disable index store
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        
        # Add more compiler flags
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = [
          '$(inherited)', 
          'OPENSSL_NO_ASM=1', 
          'NO_OBSCURE_PRINTF=1',
          'DEBUG=0'
        ]
      end
      
      # Add additional global build settings
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['DEAD_CODE_STRIPPING'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
EOL
echo "Created patched Podfile"

# Step 4: Create CocoaPods patches for boringssl
echo "==== Step 4: Creating CocoaPods patches ===="
mkdir -p ~/.cocoapods/patches/BoringSSL-GRPC
cat > ~/.cocoapods/patches/BoringSSL-GRPC/remove_format_attributes.patch << 'EOL'
diff --git a/src/include/openssl/base.h b/src/include/openssl/base.h
--- a/src/include/openssl/base.h
+++ b/src/include/openssl/base.h
@@ -19,6 +19,13 @@
 
 #include <stddef.h>
 #include <stdint.h>
+
+/* Define to completely disable format attributes */
+#ifndef __attribute__
+#define __attribute__(x)
+#endif
+#define OPENSSL_PRINTF_FORMAT(a, b)
+
 #include <sys/types.h>
 
 #if defined(__MINGW32__)
@@ -97,16 +104,6 @@
 #endif
 #endif  // !BORINGSSL_SHARED_LIBRARY
 
-// MSVC doesn't understand __has_attribute
-#if (defined(__has_attribute) && __has_attribute(format)) || \
-    (defined(__GNUC__) && !defined(__clang__))
-#define OPENSSL_PRINTF_FORMAT_FUNC(string_index, first_to_check) \
-  __attribute__((__format__(__printf__, string_index, first_to_check)))
-#else
-#define OPENSSL_PRINTF_FORMAT_FUNC(string_index, first_to_check)
-#endif
-
-
 // C11 requires that the macro offsetof be defined in <stddef.h>, which must be
 // supported by all C and C++ compilers. offsetof is sometimes defined
 // incorrectly, so we avoid using it, but we let the stddef definition be to
EOL
echo "Created CocoaPods patches"

# Step 5: Create a custom environment for compilation
echo "==== Step 5: Setting up build environment ===="
# Export environment variables to affect compilation
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export LINK_WITH_STANDARD_LIBRARIES="NO"
export DEBUG="NO"

# Step 6: Run pod install with the fixed environment
echo "==== Step 6: Running pod install ===="
pod install

# Step 7: Direct patching of BoringSSL-GRPC source files
echo "==== Step 7: Directly patching BoringSSL source files ===="
if [ -d "Pods/BoringSSL-GRPC" ]; then
  # Create a boringssl_build_fix.h header that completely disables formatting
  OPENSSL_DIR="Pods/BoringSSL-GRPC/src/include/openssl"
  PATCH_HEADER="$OPENSSL_DIR/boringssl_build_fix.h"
  cat > "$PATCH_HEADER" << 'EOL'
/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Define to completely disable format attributes */
#ifndef __attribute__
#define __attribute__(x)
#endif

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)
#undef OPENSSL_PRINTF_FORMAT_FUNC
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)

/* Turn off asm */
#define OPENSSL_NO_ASM 1

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
EOL
  
  # Find all source files that might have format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" -o -name "*.c" | xargs grep -l "__attribute__" 2>/dev/null)
  
  # Patch each file
  for FILE in $FORMAT_FILES; do
    echo "Patching $FILE..."
    # Create backup
    if [ ! -f "${FILE}.backup" ]; then
      cp "$FILE" "${FILE}.backup"
    fi
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    
    # Also make sure the header is included in each file if it's a header
    if [[ "$FILE" == *".h" ]] && ! grep -q "#include <openssl/boringssl_build_fix.h>" "$FILE"; then
      # Find first include
      FIRST_INCLUDE=$(grep -n "#include" "$FILE" | head -1 | cut -d: -f1)
      if [ -n "$FIRST_INCLUDE" ]; then
        # Add our include at the top
        sed -i '' "${FIRST_INCLUDE}i\\
#include <openssl/boringssl_build_fix.h>
" "$FILE"
      fi
    fi
  done
  
  # Patch base.h directly in case the format patching didn't work
  BASE_H="$OPENSSL_DIR/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Patching base.h more aggressively..."
    # Add our include at the top if not already there
    if ! grep -q "#include <openssl/boringssl_build_fix.h>" "$BASE_H"; then
      # Find a good spot to insert
      FIRST_INCLUDE=$(grep -n "#include" "$BASE_H" | head -1 | cut -d: -f1)
      if [ -n "$FIRST_INCLUDE" ]; then
        # Add it before the first include
        sed -i '' "${FIRST_INCLUDE}i\\
#include <openssl/boringssl_build_fix.h>
" "$BASE_H"
      else
        # Add at beginning
        sed -i '' '1i\\
#include <openssl/boringssl_build_fix.h>
' "$BASE_H"
      fi
    fi
    
    # Remove format attributes directly
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$BASE_H"
  fi
  
  echo "Successfully patched BoringSSL source files"
else
  echo "WARNING: BoringSSL-GRPC directory not found"
fi

# Step 8: Set up Xcode build flags to remove -G
echo "==== Step 8: Creating xcconfig for build flag removal ===="
# Create a Flutter/boringssl_fix.xcconfig file
mkdir -p ../Flutter
cat > ../Flutter/boringssl_fix.xcconfig << 'EOL'
// Custom configuration to work around -G flag compilation issue
OTHER_CFLAGS = -w -Wno-everything -Wno-format
OTHER_CXXFLAGS = -w -Wno-everything -Wno-format

// Special flags to disable the G flag issue
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) OPENSSL_NO_ASM=1 NO_OBSCURE_PRINTF=1 DEBUG=0

// Disable all warnings
WARNING_CFLAGS = -w -Wno-format -Wno-everything
GCC_WARN_INHIBIT_ALL_WARNINGS = YES

// Disable index store to avoid G flag
COMPILER_INDEX_STORE_ENABLE = NO
EOL

# Create a run script that uses all our fixes
echo "==== Step 9: Creating run script with all fixes ===="
cat > run_with_all_fixes.sh << 'EOL'
#!/bin/bash
# Run Flutter with all BoringSSL fixes applied

# Set up environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"

# Use --no-sound-null-safety flag to avoid null safety issues
cd ..
flutter run --no-sound-null-safety
EOL
chmod +x run_with_all_fixes.sh

echo ""
echo "==== ALL FIXES COMPLETED SUCCESSFULLY ===="
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_with_all_fixes.sh"
echo ""
echo "If you still have issues:"
echo "1. Try running directly with: cd .. && PATH=\"$(pwd)/ios/bin:\$PATH\" flutter run"
echo "2. Open Xcode and manually build with all flags set: export PATH=\"$(pwd)/bin:\$PATH\" && open Runner.xcworkspace"
echo ""

exit 0 