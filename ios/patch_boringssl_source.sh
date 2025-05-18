#!/bin/bash
# Patch BoringSSL source files to remove __attribute__((__format__)) usage

if [ -d "Pods/BoringSSL-GRPC" ]; then
  echo "Patching BoringSSL-GRPC source files..."
  
  # Find all header files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" -o -name "*.c" -o -name "*.cc" | xargs grep -l "__format__" 2>/dev/null)
  
  for FILE in $FORMAT_FILES; do
    echo "Patching $FILE..."
    
    # Create backup if it doesn't exist
    if [ ! -f "${FILE}.backup" ]; then
      cp "$FILE" "${FILE}.backup"
    fi
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
  done
  
  # Specifically patch base.h which defines the problematic macros
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Patching base.h specifically..."
    
    if [ ! -f "${BASE_H}.backup" ]; then
      cp "$BASE_H" "${BASE_H}.backup"
    fi
    
    # Replace the entire OPENSSL_PRINTF_FORMAT_FUNC definition with an empty one
    sed -i '' 's/#if (defined(__has_attribute) && __has_attribute(format)) || \\
    (defined(__GNUC__) && !defined(__clang__))/#if 0/g' "$BASE_H"
    
    # Also add our own definitions at the top of the file
    sed -i '' '/^#ifndef OPENSSL_HEADER_BASE_H/a\\
/* SIFTER APP FIX: Disable format attributes to prevent -G flag issues */\\
#undef __attribute__\\
#define __attribute__(x)\\
#undef OPENSSL_PRINTF_FORMAT\\
#define OPENSSL_PRINTF_FORMAT(a, b)\\
#undef OPENSSL_PRINTF_FORMAT_FUNC\\
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)\\
#define OPENSSL_NO_ASM 1\\
' "$BASE_H"
  fi
  
  echo "Source patching completed."
else
  echo "ERROR: BoringSSL-GRPC directory not found!"
fi
