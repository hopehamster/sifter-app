#!/bin/bash
# Script to patch BoringSSL-GRPC files

echo "Patching BoringSSL source files..."

# Common directories where BoringSSL may be found
DIRS=(
  "Pods/BoringSSL-GRPC"
  "Pods/gRPC-Core/src/boringssl"
  "~/Library/Developer/Xcode/DerivedData/*/Build/Products/*/BoringSSL-GRPC"
)

for DIR in "${DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    echo "Found BoringSSL in $DIR"
    
    # Patch base.h if it exists
    BASE_H="$DIR/src/include/openssl/base.h"
    if [ -f "$BASE_H" ]; then
      echo "Patching $BASE_H"
      
      # Add our sifter fix at the top
      sed -i '' '/#ifndef OPENSSL_HEADER_BASE_H/a\
/* SIFTER APP FIX */\
#define OPENSSL_PRINTF_FORMAT(a, b)\
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)\
#define OPENSSL_NO_ASM 1\
' "$BASE_H"
      
      # Disable the format attribute section
      sed -i '' 's/#if defined(__has_attribute)/#if 0 \/* disabled *\//' "$BASE_H"
      
      echo "✓ Patched $BASE_H"
    fi
    
    # Find and patch all files with __format__ attributes
    FORMAT_FILES=$(grep -l "__format__" "$DIR"/**/*.{h,c,cc} 2>/dev/null || true)
    for FILE in $FORMAT_FILES; do
      echo "Patching $FILE"
      sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    done
  fi
done

echo "BoringSSL patching completed"
