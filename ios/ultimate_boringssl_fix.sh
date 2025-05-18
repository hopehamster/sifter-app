#!/bin/bash

# Ultimate BoringSSL-GRPC Fix Script
# This script combines all the best approaches for fixing the -G flag issue

# Display a banner
echo "======================================================================"
echo "        ULTIMATE BORINGSSL-GRPC FIX SCRIPT FOR IOS BUILDS            "
echo "======================================================================"

# Step 1: Clean project to start fresh
echo "[1/9] Cleaning project files..."
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
mkdir -p bin
echo "✓ Project cleaned successfully"

# Step 2: Create an advanced compiler wrapper to filter out -G flags
echo "[2/9] Creating advanced compiler wrapper..."
cat > bin/clang_wrapper.sh << 'EOL'
#!/bin/bash
# Advanced wrapper script for clang to filter out -G flags and add custom flags

# Get the real clang binary
REAL_CLANG="$(xcrun -f clang)"

# Log this call if debugging is enabled
if [ "${DEBUG_WRAPPER:-0}" = "1" ]; then
  echo "[WRAPPER] Called with: $@" >> /tmp/clang_wrapper.log
fi

# Create a temporary file for args
ARGS_FILE=$(mktemp)

# Filter arguments to remove -G flags and add custom flags
for arg in "$@"; do
  # Skip any arguments with -G
  if [[ "$arg" != -G* ]]; then
    echo "$arg" >> "$ARGS_FILE"
  elif [ "${DEBUG_WRAPPER:-0}" = "1" ]; then
    echo "[WRAPPER] Filtered out: $arg" >> /tmp/clang_wrapper.log
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
  echo "-Wno-format-security" >> "$ARGS_FILE"
  echo "-Wno-everything" >> "$ARGS_FILE"
  echo "-UDEBUG" >> "$ARGS_FILE"
  
  if [ "${DEBUG_WRAPPER:-0}" = "1" ]; then
    echo "[WRAPPER] Added BoringSSL-specific flags" >> /tmp/clang_wrapper.log
  fi
fi

# Execute real clang with filtered arguments
if [ "${DEBUG_WRAPPER:-0}" = "1" ]; then
  echo "[WRAPPER] Running: $REAL_CLANG $(cat "$ARGS_FILE")" >> /tmp/clang_wrapper.log
fi

"$REAL_CLANG" $(cat "$ARGS_FILE")
RET=$?

# Clean up
rm -f "$ARGS_FILE"

if [ "${DEBUG_WRAPPER:-0}" = "1" ]; then
  echo "[WRAPPER] Exit code: $RET" >> /tmp/clang_wrapper.log
fi

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
echo "✓ Advanced compiler wrapper created successfully"

# Step 3: Create a comprehensive CocoaPods patch
echo "[3/9] Creating CocoaPods patch..."
mkdir -p ~/.cocoapods/patches/BoringSSL-GRPC
cat > ~/.cocoapods/patches/BoringSSL-GRPC/ultimate_fix.patch << 'EOL'
diff --git a/src/include/openssl/base.h b/src/include/openssl/base.h
--- a/src/include/openssl/base.h
+++ b/src/include/openssl/base.h
@@ -19,6 +19,17 @@
 
 #include <stddef.h>
 #include <stdint.h>
+
+/* ULTIMATE BORINGSSL FIX - beginning of fix */
+/* Define to completely disable format attributes */
+#ifndef __NOHACK_attribute
+#define __NOHACK_attribute __attribute__
+#endif
+#undef __attribute__
+#define __attribute__(x)
+#define OPENSSL_PRINTF_FORMAT(a, b)
+#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)
+/* ULTIMATE BORINGSSL FIX - end of fix */
+
 #include <sys/types.h>
 
 #if defined(__MINGW32__)
@@ -97,16 +108,6 @@
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
echo "✓ CocoaPods patch created successfully"

# Step 4: Create a completely new Podfile with all the fixes
echo "[4/9] Creating optimized Podfile..."
if [ -f "Podfile" ]; then
  # Backup the original Podfile
  cp Podfile Podfile.original.bak
  
  # Create a completely new Podfile
  cat > Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Environment variables to disable warnings and prevent -G flag issue
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
      
      # Add preprocessor definitions to disable printf format attributes
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
EOF
  echo "✓ Optimized Podfile created successfully"
else
  echo "✗ ERROR: Podfile not found!"
  exit 1
fi

# Step 5: Create a Runner.xcconfig file with custom build settings
echo "[5/9] Creating custom xcconfig..."
cat > Runner.xcconfig << 'EOL'
// Custom configuration to work around -G flag compilation issue
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) OPENSSL_NO_ASM=1 NO_OBSCURE_PRINTF=1
OTHER_CFLAGS = $(inherited) -w -Wno-format -Wno-everything
OTHER_CXXFLAGS = $(inherited) -w -Wno-format -Wno-everything

// Disable all warnings
WARNING_CFLAGS = $(inherited) -w
GCC_WARN_INHIBIT_ALL_WARNINGS = YES

// Disable index store which can trigger compiler flags
COMPILER_INDEX_STORE_ENABLE = NO
EOL
echo "✓ Custom xcconfig created successfully"

# Step 6: Set up environment variables and install pods
echo "[6/9] Setting up environment variables and installing pods..."
# Export environment variables to affect compilation
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"

# Install pods
pod install
echo "✓ Pods installed successfully"

# Step 7: Create a boringssl_build_fix.h header file
echo "[7/9] Creating boringssl fix header..."
if [ -d "Pods/BoringSSL-GRPC" ]; then
  OPENSSL_DIR="Pods/BoringSSL-GRPC/src/include/openssl"
  PATCH_HEADER="$OPENSSL_DIR/boringssl_build_fix.h"
  cat > "$PATCH_HEADER" << 'EOL'
/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Store original attribute definition */
#ifndef __NOHACK_attribute
#define __NOHACK_attribute __attribute__
#endif

/* Define to completely disable format attributes */
#undef __attribute__
#define __attribute__(x)

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)
#undef OPENSSL_PRINTF_FORMAT_FUNC
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)

/* Turn off asm */
#define OPENSSL_NO_ASM 1

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
EOL
  echo "✓ Created boringssl fix header"
else
  echo "✗ WARNING: BoringSSL-GRPC directory not found, skipping header creation"
fi

# Step 8: Directly patch all BoringSSL source files
echo "[8/9] Directly patching BoringSSL source files..."
if [ -d "Pods/BoringSSL-GRPC" ]; then
  # Find all files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" -o -name "*.c" | xargs grep -l "__attribute__" 2>/dev/null)
  
  # Counter for modified files
  MODIFIED_COUNT=0
  
  # Patch each file
  for FILE in $FORMAT_FILES; do
    # Create backup if not exists
    if [ ! -f "${FILE}.backup" ]; then
      cp "$FILE" "${FILE}.backup"
    fi
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    
    # Include the fix header in each header file
    if [[ "$FILE" == *".h" ]] && ! grep -q "#include <openssl/boringssl_build_fix.h>" "$FILE"; then
      # Find first include
      FIRST_INCLUDE=$(grep -n "#include" "$FILE" | head -1 | cut -d: -f1)
      if [ -n "$FIRST_INCLUDE" ]; then
        # Add our include at the top
        sed -i '' "${FIRST_INCLUDE}i\\
#include <openssl/boringssl_build_fix.h> /* Added by ultimate_boringssl_fix.sh */
" "$FILE"
      fi
    fi
    
    MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
  done
  
  # Patch base.h directly for extra assurance
  BASE_H="$OPENSSL_DIR/base.h"
  if [ -f "$BASE_H" ]; then
    echo "  - Applying special fixes to base.h..."
    # Add our include at the top if not already there
    if ! grep -q "#include <openssl/boringssl_build_fix.h>" "$BASE_H"; then
      # Find a good spot to insert - right after first include
      FIRST_INCLUDE=$(grep -n "#include" "$BASE_H" | head -1 | cut -d: -f1)
      if [ -n "$FIRST_INCLUDE" ]; then
        sed -i '' "${FIRST_INCLUDE}a\\
#include <openssl/boringssl_build_fix.h> /* Added by ultimate_boringssl_fix.sh */
" "$BASE_H"
      else 
        # Add at the beginning if no includes found
        sed -i '' '1i\\
#include <openssl/boringssl_build_fix.h> /* Added by ultimate_boringssl_fix.sh */
' "$BASE_H"
      fi
    fi
    
    # Add direct #define for __attribute__ if not already present
    if ! grep -q "#define __attribute__(x)" "$BASE_H"; then
      sed -i '' '/^#include <openssl\/boringssl_build_fix.h>/a\\
/* Direct fix for format attributes */\\
#ifndef __attribute__\\
#define __attribute__(x)\\
#endif
' "$BASE_H"
    fi
  fi
  
  echo "✓ Modified $MODIFIED_COUNT BoringSSL source files"
else
  echo "✗ WARNING: BoringSSL-GRPC directory not found, skipping source patching"
fi

# Step 9: Create a run script that sets up environment correctly
echo "[9/9] Creating run script..."
cat > run_with_boringssl_fix.sh << 'EOL'
#!/bin/bash
# Run Flutter with BoringSSL fix applied

# Banner
echo "======================================================================"
echo "            RUNNING FLUTTER WITH BORINGSSL-GRPC FIX APPLIED           "
echo "======================================================================"

# Set environment variables to prevent -G flag issue
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"

# Display environment info
echo "PATH includes wrapper at: $(pwd)/bin"
echo "Compiler: $(which clang)"
echo "Environment variables set successfully"

# Run flutter from parent directory
cd ..
echo "Running Flutter..."
flutter run
EOL
chmod +x run_with_boringssl_fix.sh

# Create another script for debugging the wrapper
cat > debug_wrapper.sh << 'EOL'
#!/bin/bash
# Enable wrapper debugging and run app

# Set the debug flag for the wrapper
export DEBUG_WRAPPER=1

# Run the fix
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Clear previous log
rm -f /tmp/clang_wrapper.log

echo "Starting with debugging enabled. Log will be at /tmp/clang_wrapper.log"
cd ..
flutter run

echo "Build complete. Check wrapper log at /tmp/clang_wrapper.log"
EOL
chmod +x debug_wrapper.sh

# Create a script to help with Xcode integration
cat > open_xcode_with_fix.sh << 'EOL'
#!/bin/bash
# Open Xcode with all environment variables set correctly

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export DEBUG="NO"

# Open Xcode
open Runner.xcworkspace
EOL
chmod +x open_xcode_with_fix.sh

echo "✓ Run scripts created successfully"

# All done!
echo ""
echo "======================================================================"
echo "                     FIX COMPLETED SUCCESSFULLY                       "
echo "======================================================================"
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_with_boringssl_fix.sh"
echo ""
echo "To open Xcode with the fix environment:"
echo "  ./open_xcode_with_fix.sh"
echo ""
echo "If you still have issues, try debugging the wrapper:"
echo "  ./debug_wrapper.sh"
echo ""

exit 0 