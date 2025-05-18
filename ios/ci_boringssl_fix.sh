#!/bin/bash

# CI-friendly script to fix BoringSSL-GRPC issues in automated environments
# Compatible with GitHub Actions, Travis CI, Bitrise, etc.
# Usage: ./ci_boringssl_fix.sh

set -eo pipefail  # Exit immediately if a command exits with non-zero status

# Function to log steps
log_step() {
  echo "::group::$1"
}

log_end_step() {
  echo "::endgroup::"
}

log_error() {
  echo "::error::$1"
}

log_warning() {
  echo "::warning::$1"
}

# Verify we're in the iOS directory
if [ ! -f "Podfile" ]; then
  log_error "This script must be run from the iOS directory of your Flutter project"
  exit 1
fi

# Store the directory path
IOS_DIR=$(pwd)

# Start the fix process
log_step "Applying BoringSSL-GRPC fix for CI environment"

# Create a directory for temporary files
TEMP_DIR="${IOS_DIR}/.boringssl-fix"
mkdir -p "${TEMP_DIR}"

# Step 1: Create a permanent CocoaPods patch
log_step "Creating CocoaPods patch"
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
log_end_step

# Step 2: Create a compiler wrapper script
log_step "Creating compiler wrapper script"
cat > "${TEMP_DIR}/clang_wrapper.sh" << 'EOL'
#!/bin/bash
# Wrapper script for clang to filter out -G flags

# Get the original clang compiler
REAL_CLANG=$(xcrun -f clang)

# Process all arguments and filter out -G flags
FILTERED_ARGS=()
for arg in "$@"; do
  if [[ "$arg" != -G* ]]; then
    FILTERED_ARGS+=("$arg")
  fi
done

# Execute the real clang with filtered arguments
exec "${REAL_CLANG}" "${FILTERED_ARGS[@]}"
EOL

chmod +x "${TEMP_DIR}/clang_wrapper.sh"

# Create symlinks to our wrapper in a bin directory
mkdir -p "${TEMP_DIR}/bin"
ln -sf "${TEMP_DIR}/clang_wrapper.sh" "${TEMP_DIR}/bin/clang"
ln -sf "${TEMP_DIR}/clang_wrapper.sh" "${TEMP_DIR}/bin/clang++"
log_end_step

# Step 3: Create build environment configuration
log_step "Creating build environment configuration"
cat > "${TEMP_DIR}/env_setup.sh" << EOL
#!/bin/bash
# Export environment variables needed for the build

# Add our clang wrapper to PATH
export PATH="${TEMP_DIR}/bin:\$PATH"

# Export options to disable problematic flags
export CFLAGS="-w"
export CXXFLAGS="-w"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export SWIFT_VERSION="5.0"

# Set other CocoaPods specific overrides
export COCOAPODS_DISABLE_STATS="true"
EOL

chmod +x "${TEMP_DIR}/env_setup.sh"
log_end_step

# Step 4: Patch the Podfile
log_step "Patching Podfile"
if [ -f "Podfile" ]; then
  # Make a backup of the Podfile
  cp Podfile "${TEMP_DIR}/Podfile.backup"
  
  # Check if post_install hook exists, add our patch
  if grep -q "post_install" Podfile; then
    # If post_install exists but doesn't have our fix
    if ! grep -q "BoringSSL-GRPC" Podfile; then
      # Find post_install line
      POST_INSTALL_LINE=$(grep -n "post_install" Podfile | cut -d: -f1)
      if [ -n "$POST_INSTALL_LINE" ]; then
        # Insert our fix
        sed -i.bak "${POST_INSTALL_LINE}a\\
  # Fix for BoringSSL-GRPC\\
  installer.pods_project.targets.each do |target|\\
    if target.name == \"BoringSSL-GRPC\"\\
      target.build_configurations.each do |config|\\
        config.build_settings['OTHER_CFLAGS'] = '-w'\\
        config.build_settings['OTHER_CXXFLAGS'] = '-w'\\
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'\\
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'\\
      end\\
    end\\
  end" Podfile
        rm Podfile.bak
      fi
    fi
  else
    # Add post_install hook
    cat >> Podfile << 'EOL'

post_install do |installer|
  # Fix for BoringSSL-GRPC
  installer.pods_project.targets.each do |target|
    if target.name == "BoringSSL-GRPC"
      target.build_configurations.each do |config|
        config.build_settings['OTHER_CFLAGS'] = '-w'
        config.build_settings['OTHER_CXXFLAGS'] = '-w'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
      end
    end
  end
end
EOL
  fi
else
  log_error "Podfile not found!"
  exit 1
fi
log_end_step

# Step 5: Clean and install pods
log_step "Cleaning and installing pods"
# Remove existing Pods and lock file
if [ -d "Pods" ]; then
  rm -rf Pods
fi
if [ -f "Podfile.lock" ]; then
  rm Podfile.lock
fi

# Install pods with our environment variables
echo "Installing pods with fixed environment..."
source "${TEMP_DIR}/env_setup.sh"
pod install
log_end_step

# Step 6: Create a script to apply source patches after pod install
log_step "Creating source patch script"
cat > "${TEMP_DIR}/patch_source.sh" << 'EOL'
#!/bin/bash
# This script is called after pod install to patch the source files

# Find the BoringSSL-GRPC directory
BORINGSSL_DIR=$(find ./Pods -type d -name "BoringSSL-GRPC" -print -quit)

if [ -z "$BORINGSSL_DIR" ]; then
  echo "::error::BoringSSL-GRPC directory not found"
  exit 1
fi

echo "Found BoringSSL-GRPC at $BORINGSSL_DIR"

# Patch base.h
BASE_H="$BORINGSSL_DIR/src/include/openssl/base.h"
if [ -f "$BASE_H" ]; then
  echo "Patching base.h..."

  # Make a backup
  cp "$BASE_H" "${BASE_H}.backup"

  # Replace the format attribute
  sed -i.bak 's/__attribute__((__format__(__printf__, \([^)]*\)))/* __attribute__((__format__(__printf__, \1))) */g' "$BASE_H"
  rm "${BASE_H}.bak"

  # Create a patch header
  PATCH_HEADER="$BORINGSSL_DIR/src/include/openssl/boringssl_build_fix.h"
  cat > "$PATCH_HEADER" << 'EOF'
/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)

/* Disable format attributes that might trigger -G flags */
#define __attribute__(x)

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
EOF

  # Include the patch header
  if ! grep -q "boringssl_build_fix.h" "$BASE_H"; then
    FIRST_INCLUDE=$(grep -n "#include" "$BASE_H" | head -1 | cut -d: -f1)
    if [ -n "$FIRST_INCLUDE" ]; then
      sed -i.bak "${FIRST_INCLUDE}a\\
#include <openssl/boringssl_build_fix.h> /* Patch for -G flag issue */" "$BASE_H"
      rm "${BASE_H}.bak"
    fi
  fi

  echo "base.h patched successfully"
fi

# Patch xcconfig files
XCCONFIG_FILES=$(find "$BORINGSSL_DIR" -name "*.xcconfig")
for file in $XCCONFIG_FILES; do
  echo "Patching $file..."
  # Remove -G flags
  sed -i.bak 's/-G[^ ]*//g' "$file"
  rm "${file}.bak"
  # Add our fix
  if ! grep -q "OTHER_CFLAGS" "$file"; then
    echo "OTHER_CFLAGS = -w" >> "$file"
  else
    sed -i.bak 's/OTHER_CFLAGS = .*/OTHER_CFLAGS = -w/g' "$file"
    rm "${file}.bak"
  fi
  echo "GCC_WARN_INHIBIT_ALL_WARNINGS = YES" >> "$file"
  echo "OTHER_CXXFLAGS = -w" >> "$file"
  echo "COMPILER_INDEX_STORE_ENABLE = NO" >> "$file"
done

echo "All source files patched successfully"
EOL

chmod +x "${TEMP_DIR}/patch_source.sh"
"${TEMP_DIR}/patch_source.sh"
log_end_step

# Step 7: Create a launch script for CI builds
log_step "Creating CI build launch script"
cat > "${TEMP_DIR}/build_with_fix.sh" << EOL
#!/bin/bash
# Script to build the iOS app with our fix applied

# Source our environment setup
source "${TEMP_DIR}/env_setup.sh"

# Add additional environment variables if needed
export DEVELOPER_DIR=\$(xcode-select -p)
export IPHONEOS_DEPLOYMENT_TARGET=16.0

# Run xcodebuild with proper settings
echo "Building iOS app with BoringSSL-GRPC fix..."
xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
  COMPILER_INDEX_STORE_ENABLE=NO \
  GCC_WARN_INHIBIT_ALL_WARNINGS=YES \
  OTHER_CFLAGS="-w" \
  OTHER_CXXFLAGS="-w" \
  clean build
EOL

chmod +x "${TEMP_DIR}/build_with_fix.sh"
log_end_step

# Step 8: Create GitHub Actions workflow file
if [ -d "../.github/workflows" ] || [ -d ".github/workflows" ]; then
  log_step "Creating GitHub Actions workflow"
  
  WORKFLOWS_DIR="../.github/workflows"
  if [ ! -d "$WORKFLOWS_DIR" ]; then
    WORKFLOWS_DIR=".github/workflows"
  fi
  
  mkdir -p "$WORKFLOWS_DIR"
  
  cat > "$WORKFLOWS_DIR/ios_build_with_boringssl_fix.yml" << 'EOL'
name: iOS Build with BoringSSL Fix

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.13.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
      
    - name: Apply BoringSSL-GRPC fix
      run: |
        cd ios
        ./ci_boringssl_fix.sh
      
    - name: Build iOS
      run: |
        cd ios
        ./.boringssl-fix/build_with_fix.sh
EOL
  
  log_end_step
fi

# Print final instructions
log_step "BoringSSL-GRPC fix complete"
echo "The fix has been successfully applied for CI environments."
echo ""
echo "To build in CI, use:"
echo "  source ${TEMP_DIR}/env_setup.sh"
echo "  ${TEMP_DIR}/build_with_fix.sh"
echo ""
echo "If manually running:"
echo "1. Use our clang wrapper by adding to PATH:"
echo "   export PATH=\"${TEMP_DIR}/bin:\$PATH\""
echo "2. Source the environment setup:"
echo "   source ${TEMP_DIR}/env_setup.sh"
echo "3. Run xcodebuild or flutter build ios"
echo ""

# Store the fix version and date for future reference
echo "BoringSSL-GRPC Fix v1.1 (CI Edition) - $(date)" > "${TEMP_DIR}/fix_version.txt"

log_end_step

# Exit successfully
exit 0 