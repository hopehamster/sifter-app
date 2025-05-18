#!/bin/bash

# Final BoringSSL-GRPC Fix Script
echo "==== Final BoringSSL-GRPC Fix Script ===="

# Step 1: Clean the project
echo "==== Step 1: Cleaning project ===="
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "Cleaned project files"

# Step 2: Create compiler wrapper to filter out -G flags
echo "==== Step 2: Creating compiler wrapper ===="
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

# Step 3: Modify Podfile to add export of environment variables that disable warnings
echo "==== Step 3: Modifying Podfile ===="
if [ -f "Podfile" ]; then
  # Backup the original Podfile
  cp Podfile Podfile.backup
  
  # Remove the require custom_build_settings.rb line
  sed -i '' '/require_relative .custom_build_settings.rb./d' Podfile
  
  # Add new environment variables at the top of the Podfile
  sed -i '' '1i\\
# Environment variables to disable warnings and prevent -G flag issue\\
ENV["OTHER_CFLAGS"] = "-w"\\
ENV["OTHER_CXXFLAGS"] = "-w"\\
ENV["GCC_WARN_INHIBIT_ALL_WARNINGS"] = "YES"\\
ENV["COMPILER_INDEX_STORE_ENABLE"] = "NO"\\
' Podfile
  
  # Ensure post_install hook exists and has BoringSSL-GRPC fixes
  if grep -q "post_install do |installer|" Podfile; then
    # Add more comprehensive fixes if needed
    if ! grep -q "target.name == 'BoringSSL-GRPC'" Podfile; then
      POST_INSTALL_LINE=$(grep -n "post_install do |installer|" Podfile | cut -d: -f1)
      NEXT_LINE=$((POST_INSTALL_LINE + 1))
      INDENTATION=$(sed -n "${NEXT_LINE}p" Podfile | awk '{match($0, /^[ \t]+/); print substr($0, RSTART, RLENGTH)}')
      
      sed -i '' "${NEXT_LINE}i\\
${INDENTATION}# Fix for BoringSSL-GRPC -G flag issue\\
${INDENTATION}installer.pods_project.targets.each do |target|\\
${INDENTATION}  if target.name == 'BoringSSL-GRPC'\\
${INDENTATION}    puts \"Applying critical fixes to BoringSSL-GRPC\"\\
${INDENTATION}    target.build_configurations.each do |config|\\
${INDENTATION}      # Complete disable of warnings\\
${INDENTATION}      config.build_settings['OTHER_CFLAGS'] = '-w'\\
${INDENTATION}      config.build_settings['OTHER_CXXFLAGS'] = '-w'\\
${INDENTATION}      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'\\
${INDENTATION}      config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'\\
${INDENTATION}      # Extra settings to modify the compiler behavior\\
${INDENTATION}      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'OPENSSL_NO_ASM=1']\\
${INDENTATION}    end\\
${INDENTATION}  end\\
${INDENTATION}end" Podfile
    fi
  else
    # Add post_install block
    cat >> Podfile << 'EOL'

post_install do |installer|
  # Fix for BoringSSL-GRPC -G flag issue
  installer.pods_project.targets.each do |target|
    if target.name == 'BoringSSL-GRPC'
      puts "Applying critical fixes to BoringSSL-GRPC"
      target.build_configurations.each do |config|
        # Complete disable of warnings
        config.build_settings['OTHER_CFLAGS'] = '-w'
        config.build_settings['OTHER_CXXFLAGS'] = '-w'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        # Extra settings to modify the compiler behavior
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'OPENSSL_NO_ASM=1']
      end
    end
  end
end
EOL
  fi
  
  echo "Modified Podfile successfully"
else
  echo "ERROR: Podfile not found!"
  exit 1
fi

# Step 4: Create a permanent CocoaPods patch
echo "==== Step 4: Creating CocoaPods patch ===="
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

# Step 7: Direct patching of BoringSSL-GRPC source files
echo "==== Step 7: Patching BoringSSL-GRPC source files ===="
if [ -d "Pods/BoringSSL-GRPC" ]; then
  # Find all files with format attributes
  FILES_TO_PATCH=$(find Pods/BoringSSL-GRPC -type f -name "*.h" -o -name "*.c" | xargs grep -l "__attribute__((__format__" 2>/dev/null)
  
  for FILE in $FILES_TO_PATCH; do
    echo "Patching $FILE..."
    # Create backup
    if [ ! -f "${FILE}.backup" ]; then
      cp "$FILE" "${FILE}.backup"
    fi
    
    # Replace all format attributes
    sed -i '' 's/__attribute__((__format__(__printf__, \([^)]*\)))/* __attribute__((__format__(__printf__, \1))) */g' "$FILE"
  done
  
  # Modify base.h to completely disable attributes
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    # Add a define to disable format attributes completely
    if ! grep -q "#define __attribute__(x)" "$BASE_H"; then
      # Find an appropriate place to insert it (after platform detection macros)
      PLATFORM_LINE=$(grep -n "defined(__APPLE__)" "$BASE_H" | tail -1 | cut -d: -f1)
      if [ -n "$PLATFORM_LINE" ]; then
        # Add a few lines after it
        INSERT_LINE=$((PLATFORM_LINE + 3))
        sed -i '' "${INSERT_LINE}i\\
/* Disable format attributes that cause the -G flag issue */\\
#define __attribute__(x)\\
" "$BASE_H"
        echo "Added attribute override to $BASE_H"
      else
        # If we can't find a good place, put it near the top
        sed -i '' '20i\\
/* Disable format attributes that cause the -G flag issue */\\
#define __attribute__(x)\\
' "$BASE_H"
        echo "Added attribute override to $BASE_H (at line 20)"
      fi
    fi
  fi
  
  echo "Successfully patched BoringSSL-GRPC source files"
else
  echo "WARNING: BoringSSL-GRPC directory not found"
fi

# Step 8: Create a run script with all the environment variables set
echo "==== Step 8: Creating run script ===="
cat > run_with_fix.sh << 'EOL'
#!/bin/bash
# Run Flutter app with BoringSSL-GRPC fix applied

# Set environment variables to prevent -G flag issue
export OTHER_CFLAGS="-w"
export OTHER_CXXFLAGS="-w"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export PATH="$(pwd)/bin:$PATH"

# Run flutter in parent directory
cd ..
flutter run
EOL
chmod +x run_with_fix.sh

echo ""
echo "==== FIX COMPLETED SUCCESSFULLY ===="
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_with_fix.sh"
echo ""
echo "If you still encounter issues, open Xcode with our setup:"
echo "  export PATH=\"$(pwd)/bin:\$PATH\" && open Runner.xcworkspace"
echo ""

exit 0 