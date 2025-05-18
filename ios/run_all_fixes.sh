#!/bin/bash
# Run app with all fixes applied

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"
export USE_HEADERMAP="NO"

# Directly patch BoringSSL source files (if not already done)
if [ -d "Pods/BoringSSL-GRPC" ]; then
  echo "Patching BoringSSL-GRPC source files..."
  
  # Find all header files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" | xargs grep -l "__format__" 2>/dev/null)
  
  for FILE in $FORMAT_FILES; do
    echo "Patching $FILE..."
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    
    # Add our header include if not already present
    if ! grep -q "boringssl_fix.h" "$FILE"; then
      sed -i '' '1i\
#include "'"$(pwd)"'/headers/boringssl_fix.h"
' "$FILE"
    fi
  done
  
  # Patch base.h directly
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Patching base.h..."
    if ! grep -q "#define __attribute__(x)" "$BASE_H"; then
      sed -i '' '/^#include <stddef.h>/i\
/* SIFTER APP FIX */\
#define __attribute__(x)\
#define OPENSSL_PRINTF_FORMAT(a,b)\
#define OPENSSL_PRINTF_FORMAT_FUNC(a,b)\
#define OPENSSL_NO_ASM 1\

' "$BASE_H"
    fi
  fi
fi

# Try to add the build phase using Ruby
ruby add_build_phase.rb

# Run Flutter using 'flutter build ios' first
cd ..
echo "Building with Flutter first..."
flutter build ios --debug

# Then run the app
echo "Running app..."
flutter run --verbose
