#!/bin/bash
# Directly patch BoringSSL source files to remove format attributes

if [ -d "Pods/BoringSSL-GRPC" ]; then
  # Find all BoringSSL header files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" | xargs grep -l "__format__" 2>/dev/null)
  
  # Counter for modified files
  MODIFIED_COUNT=0
  
  echo "Patching BoringSSL source files..."
  
  # Patch each file
  for FILE in $FORMAT_FILES; do
    # Create backup
    cp "$FILE" "${FILE}.backup"
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
  done
  
  # Specifically patch base.h
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    cp "$BASE_H" "${BASE_H}.backup"
    
    # Add a header block to disable format attributes
    sed -i '' '/^#include <stdint.h>/a\'$'\n''/* SIFTER APP FIX: Disable format attributes to prevent -G flag */\'$'\n''#define __attribute__(x)\'$'\n''#define OPENSSL_PRINTF_FORMAT_FUNC(a,b)\'$'\n''#define OPENSSL_PRINTF_FORMAT(a,b)\'$'\n''#define OPENSSL_NO_ASM 1\'$'\n' "$BASE_H"
    
    echo "✓ Patched base.h"
  fi
  
  echo "✓ Modified $MODIFIED_COUNT BoringSSL source files"
else
  echo "✗ ERROR: BoringSSL-GRPC directory not found!"
fi
