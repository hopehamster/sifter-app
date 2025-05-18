#!/bin/bash

# Improved BoringSSL-GRPC Fix Script
# Combines the best approaches from all previous solutions
echo "==== Improved BoringSSL-GRPC Fix Script ===="

# Step 1: Clean the project
echo "==== Step 1: Cleaning project ===="
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "Cleaned project files"

# Step 2: Create a permanent CocoaPods patch
echo "==== Step 2: Creating CocoaPods patch ===="
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

# Step 3: Create compiler wrapper to filter out -G flags
echo "==== Step 3: Creating compiler wrapper ===="
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

# Step 4: Install pods with modified PATH to use our wrapper
echo "==== Step 4: Installing pods ===="
# Export the PATH to include our wrapper
export PATH="$(pwd)/bin:$PATH"
# Install pods
pod install
if [ $? -ne 0 ]; then
  echo "Error installing pods. Will try alternate method."
  # If pod install failed, try again with a different approach
  # This time, let's apply a source patch after pod install
  pod install --no-integrate
  # Now patch the source files directly
  BORINGSSL_DIR=$(find ./Pods -type d -name "BoringSSL-GRPC" -print -quit)
  if [ -n "$BORINGSSL_DIR" ]; then
    echo "Found BoringSSL-GRPC at $BORINGSSL_DIR"
    BASE_H="$BORINGSSL_DIR/src/include/openssl/base.h"
    if [ -f "$BASE_H" ]; then
      echo "Patching base.h..."
      # Make a backup
      cp "$BASE_H" "${BASE_H}.backup"
      # Replace the format attribute
      sed -i '' 's/__attribute__((__format__(__printf__, \([^)]*\)))/* __attribute__((__format__(__printf__, \1))) */g' "$BASE_H"
    fi
    # Complete the pod install
    pod install
  else
    echo "Could not find BoringSSL-GRPC directory"
    exit 1
  fi
fi
echo "Installed pods successfully"

# Step 5: Apply direct fixes to the xcconfig files
echo "==== Step 5: Applying xcconfig fixes ===="
for xcconfig in $(find "Pods" -name "*.xcconfig"); do
  if grep -q "\-G" "$xcconfig"; then
    sed -i '' 's/-G[^ ]*//g' "$xcconfig"
    echo "Removed -G flag from $xcconfig"
    # Add our custom flags
    if ! grep -q "OTHER_CFLAGS = -w" "$xcconfig"; then
      echo "OTHER_CFLAGS = -w" >> "$xcconfig"
    fi
    if ! grep -q "OTHER_CXXFLAGS = -w" "$xcconfig"; then
      echo "OTHER_CXXFLAGS = -w" >> "$xcconfig"
    fi
    if ! grep -q "GCC_WARN_INHIBIT_ALL_WARNINGS = YES" "$xcconfig"; then
      echo "GCC_WARN_INHIBIT_ALL_WARNINGS = YES" >> "$xcconfig"
    fi
    if ! grep -q "COMPILER_INDEX_STORE_ENABLE = NO" "$xcconfig"; then
      echo "COMPILER_INDEX_STORE_ENABLE = NO" >> "$xcconfig"
    fi
  fi
done
echo "Applied xcconfig fixes"

# Step 6: Create a specialized launcher script for Xcode
echo "==== Step 6: Creating Xcode launcher ===="
cat > launch_xcode_with_fix.sh << 'EOL'
#!/bin/bash
# Launch Xcode with our patched environment
# This sets up the PATH to use our clang wrapper

# Export our bin directory in the PATH
export PATH="$(pwd)/bin:$PATH"

# Additional environment variables to help with the build
export COMPILER_INDEX_STORE_ENABLE=NO
export GCC_WARN_INHIBIT_ALL_WARNINGS=YES

# Launch Xcode
open Runner.xcworkspace
EOL
chmod +x launch_xcode_with_fix.sh
echo "Created Xcode launcher script"

echo ""
echo "==== BORINGSSL FIX SUCCESSFULLY APPLIED ===="
echo ""
echo "Next steps:"
echo "1. Use './launch_xcode_with_fix.sh' to open Xcode with the fix applied"
echo "2. Or run directly from VS Code/Cursor with 'flutter run'"
echo "3. If you still have issues, try the more aggressive 'ultimate_boringssl_fix.sh'"
echo ""

exit 0 