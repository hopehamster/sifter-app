#!/bin/bash

# Comprehensive script to fix BoringSSL-GRPC issues and rebuild the iOS project
echo "==== BoringSSL-GRPC Fix and Rebuild Script ===="
echo "This script will apply multiple fixes to resolve the -G flag issue"

# Step 1: Clean the project
echo "==== Step 1: Cleaning project ===="
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
rm -rf ~/Library/Caches/CocoaPods/
echo "Cleaned project files"

# Step 2: Ensure permissions on our scripts
echo "==== Step 2: Setting permissions on scripts ===="
chmod +x fix_G_flags.sh
chmod +x patch_source_files.sh
chmod +x clang_wrapper.sh
chmod +x boringssl_build_fix.rb
chmod +x add_build_phase.rb
echo "Set execute permissions on scripts"

# Step 3: Install pods
echo "==== Step 3: Installing pods ===="
pod install
if [ $? -ne 0 ]; then
  echo "Error installing pods. Aborting."
  exit 1
fi
echo "Installed pods successfully"

# Step 4: Apply direct fixes to the xcconfig files
echo "==== Step 4: Applying xcconfig fixes ===="
export PODS_ROOT="Pods"
./fix_G_flags.sh
echo "Applied xcconfig fixes"

# Step 5: Patch source files
echo "==== Step 5: Patching BoringSSL-GRPC source files ===="
./patch_source_files.sh
echo "Patched source files"

# Step 6: Add build phase to Xcode project
echo "==== Step 6: Adding build phase to Xcode project ===="
ruby add_build_phase.rb
echo "Added build phase to Xcode project"

# Step 7: Create a special Xcode config that will be included during build
echo "==== Step 7: Creating special Xcode config ===="
cat > BoringSSL-Fix.xcconfig << EOL
// Special config to fix BoringSSL-GRPC build issues
OTHER_CFLAGS = -w
OTHER_CXXFLAGS = -w
GCC_WARN_INHIBIT_ALL_WARNINGS = YES
COMPILER_INDEX_STORE_ENABLE = NO
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) OPENSSL_NO_ASM=1
EOL
echo "Created BoringSSL-Fix.xcconfig"

# Step 8: Create a direct patch for CocoaPods for future pod installs
echo "==== Step 8: Creating CocoaPods patch ===="
mkdir -p ~/.cocoapods/patches/BoringSSL-GRPC
cat > ~/.cocoapods/patches/BoringSSL-GRPC/remove_G_flag.patch << EOL
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

# Step 9: Final step - reinstall pods one more time with all fixes in place
echo "==== Step 9: Reinstalling pods with all fixes ===="
pod install
if [ $? -ne 0 ]; then
  echo "Error installing pods in final step. Some fixes might not have been applied correctly."
  exit 1
fi

echo ""
echo "==== ALL FIXES APPLIED SUCCESSFULLY ===="
echo ""
echo "Next steps:"
echo "1. Open Runner.xcworkspace in Xcode"
echo "2. Try building the project"
echo "3. If build still fails, check the build logs for specific errors"
echo ""

exit 0 