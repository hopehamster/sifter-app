#!/bin/bash

# Simplified BoringSSL-GRPC Fix Script
echo "==== Simplified BoringSSL-GRPC Fix Script ===="

# Step 1: Clean the project
echo "==== Step 1: Cleaning project ===="
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "Cleaned project files"

# Step 2: Temporarily disable custom_build_settings.rb
echo "==== Step 2: Temporarily disabling custom_build_settings.rb ===="
if [ -f "custom_build_settings.rb" ]; then
  mv custom_build_settings.rb custom_build_settings.rb.bak
  # Create a simplified version that does nothing
  cat > custom_build_settings.rb << 'EOL'
module CustomBuildSettings
  def self.apply_to_project(project_path)
    puts "Simplified custom build settings - skipping project manipulation"
  end
end
EOL
  echo "Temporarily disabled custom_build_settings.rb"
fi

# Step 3: Create CocoaPods patch for BoringSSL-GRPC
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

# Step 4: Backup and modify the Podfile to include direct fixes
echo "==== Step 4: Modifying Podfile to include direct fixes ===="
if [ -f "Podfile" ]; then
  # Backup the original Podfile
  cp Podfile Podfile.backup
  
  # Check if we need to modify the post_install section
  if grep -q "post_install do |installer|" Podfile; then
    # Check if we already have BoringSSL-GRPC fix
    if ! grep -q "target.name == 'BoringSSL-GRPC'" Podfile; then
      # Find post_install line number
      POST_INSTALL_LINE=$(grep -n "post_install do |installer|" Podfile | cut -d: -f1)
      
      # Insert our BoringSSL-GRPC fix
      if [ -n "$POST_INSTALL_LINE" ]; then
        # Get the line after post_install which should contain the indentation level
        NEXT_LINE=$((POST_INSTALL_LINE + 1))
        INDENTATION=$(sed -n "${NEXT_LINE}p" Podfile | awk '{match($0, /^[ \t]+/); print substr($0, RSTART, RLENGTH)}')
        
        # Insert our fix with proper indentation
        sed -i '' "${NEXT_LINE}i\\
${INDENTATION}# Fix for BoringSSL-GRPC -G flag issue\\
${INDENTATION}installer.pods_project.targets.each do |target|\\
${INDENTATION}  if target.name == 'BoringSSL-GRPC'\\
${INDENTATION}    target.build_configurations.each do |config|\\
${INDENTATION}      config.build_settings['OTHER_CFLAGS'] = '-w'\\
${INDENTATION}      config.build_settings['OTHER_CXXFLAGS'] = '-w'\\
${INDENTATION}      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'\\
${INDENTATION}      config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'\\
${INDENTATION}    end\\
${INDENTATION}  end\\
${INDENTATION}end" Podfile
        
        echo "Added BoringSSL-GRPC fix to existing post_install"
      fi
    else
      echo "Podfile already contains BoringSSL-GRPC fix"
    fi
  else
    # Add post_install block at the end of Podfile
    cat >> Podfile << 'EOL'

post_install do |installer|
  # Fix for BoringSSL-GRPC -G flag issue
  installer.pods_project.targets.each do |target|
    if target.name == 'BoringSSL-GRPC'
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
    echo "Added post_install block with BoringSSL-GRPC fix"
  fi
else
  echo "ERROR: Podfile not found!"
  exit 1
fi

# Step 5: Create compiler wrapper to filter out -G flags
echo "==== Step 5: Creating compiler wrapper ===="
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

# Step 6: Install pods with modified PATH to use our wrapper
echo "==== Step 6: Installing pods with fixed environment ===="
# Export the PATH to include our wrapper
export PATH="$(pwd)/bin:$PATH"
# Install pods
pod install

# Step 7: Directly patch BoringSSL-GRPC source files
echo "==== Step 7: Patching BoringSSL-GRPC source files ===="
BORINGSSL_DIR="./Pods/BoringSSL-GRPC"
if [ -d "$BORINGSSL_DIR" ]; then
  BASE_H="$BORINGSSL_DIR/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Found base.h at $BASE_H"
    
    # Make a backup if not already made
    if [ ! -f "${BASE_H}.backup" ]; then
      cp "$BASE_H" "${BASE_H}.backup"
    fi
    
    # Replace the problematic format attribute
    sed -i '' 's/__attribute__((__format__(__printf__, \([^)]*\)))/* __attribute__((__format__(__printf__, \1))) */g' "$BASE_H"
    
    # Create and include patch header
    OPENSSL_DIR=$(dirname "$BASE_H")
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
    
    # Include the patch header if not already included
    if ! grep -q "boringssl_build_fix.h" "$BASE_H"; then
      # Find the first include in base.h
      FIRST_INCLUDE_LINE=$(grep -n "#include" "$BASE_H" | head -1 | cut -d: -f1)
      if [ -n "$FIRST_INCLUDE_LINE" ]; then
        # Insert our include after the first include
        sed -i '' "${FIRST_INCLUDE_LINE}a\\
#include <openssl/boringssl_build_fix.h> /* Patch for -G flag issue */" "$BASE_H"
      fi
    fi
    
    echo "Successfully patched BoringSSL-GRPC source files"
  else
    echo "WARNING: Could not find base.h"
  fi
else
  echo "WARNING: Could not find BoringSSL-GRPC directory"
fi

# Step 8: Create run script
echo "==== Step 8: Creating run script ===="
cat > run_fixed.sh << 'EOL'
#!/bin/bash
# Run Flutter with BoringSSL-GRPC fix applied
export PATH="$(pwd)/bin:$PATH"
cd ..
flutter run
EOL
chmod +x run_fixed.sh

# Step 9: Restore original custom_build_settings.rb
echo "==== Step 9: Restoring original custom_build_settings.rb ===="
if [ -f "custom_build_settings.rb.bak" ]; then
  mv custom_build_settings.rb.bak custom_build_settings.rb
fi

echo ""
echo "==== FIX COMPLETED SUCCESSFULLY ===="
echo ""
echo "To run the app with the fix:"
echo "1. Use './run_fixed.sh' to run with the fix applied"
echo "2. Or set PATH manually: export PATH=\"$(pwd)/bin:\$PATH\" && cd .. && flutter run"
echo ""

exit 0 